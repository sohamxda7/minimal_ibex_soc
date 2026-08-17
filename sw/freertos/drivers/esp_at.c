/*
 * ESP32 AT-command client over UART2 (v1.1) - the chip's entire WiFi and
 * internet story. The ESP32 module owns the radio and the TCP/IP stack;
 * this driver sends it text commands and collects replies.
 *
 * Two operating modes (lead-requested architecture, 2026-08-17):
 *
 *   POLLED (before esp_at_init): the original bring-up path - esp_at_cmd
 *   busy-polls UART2. Zero RAM cost; used by Phase-3 first-contact tests.
 *
 *   INTERRUPT (after esp_at_init): UART2 RX is Ibex fast IRQ 1 (level,
 *   RX-FIFO-not-empty). esp_at_isr() - called from the application
 *   interrupt handler in main.c - drains the 128-byte hardware FIFO into
 *   a 256-byte software ring and wakes a high-priority RX task. The task
 *   assembles lines and classifies each one:
 *     - unsolicited ESP-AT events (WIFI DISCONNECT, +IPD, ready...) go to
 *       the esp_at_on_event callback, even mid-command;
 *     - OK/ERROR/FAIL terminate the pending esp_at_cmd, which sleeps on a
 *       task notification instead of burning CPU.
 *   The RTL contract (IRQ 17 vectoring, FIFO burst/overflow, recovery) is
 *   regression-proven by dv/xsim/tb_uart2_irq.sv.
 */

#include "FreeRTOS.h"
#include "task.h"
#include "semphr.h"

#include "soc.h"
#include "drivers/psram.h"
#include "esp_at.h"

/* ---- raw UART2 access ----------------------------------------------------- */

static void prv_putc( char c )
{
    while( soc_read32( UART2_STATUS_REG ) & 0x2u )   /* tx_full */
    {
    }
    soc_write32( UART2_TX_REG, ( uint32_t ) ( uint8_t ) c );
}

static int prv_getc( void )
{
    if( soc_read32( UART2_STATUS_REG ) & 0x1u )      /* rx_empty */
    {
        return -1;
    }

    return ( int ) ( soc_read32( UART2_RX_REG ) & 0xFFu );
}

static void prv_send_cmd( const char * cmd )
{
    for( const char * p = cmd; *p != '\0'; p++ )
    {
        prv_putc( *p );
    }
    prv_putc( '\r' );
    prv_putc( '\n' );
}

/* ---- interrupt mode state ------------------------------------------------- */

#define RX_RING_SIZE    256u             /* power of two */
#define RX_LINE_MAX     96u

static volatile uint8_t  rx_ring[ RX_RING_SIZE ];
static volatile uint32_t rx_wr;          /* written by the ISR only        */
static volatile uint32_t rx_rd;          /* read by the RX task only       */
static volatile uint32_t rx_drop;        /* ring-full drops (diagnostic)   */

static TaskHandle_t      rx_task_h;      /* NULL = polled mode             */
static SemaphoreHandle_t cmd_lock;       /* one AT command at a time       */
static esp_at_event_cb_t event_cb;

/* rendezvous between the RX task and the task inside esp_at_cmd() */
static char * volatile        cmd_resp;
static volatile uint32_t      cmd_resp_len;
static volatile uint32_t      cmd_resp_n;
static TaskHandle_t volatile  cmd_waiter;
static volatile int           cmd_result;

/* Fast IRQ 1 hook. Runs inside the FreeRTOS trap handler with context
 * saved. The IRQ is LEVEL (RX-FIFO-not-empty): the hardware FIFO must be
 * left empty on return or the trap refires forever. */
void esp_at_isr( void )
{
    BaseType_t woken = pdFALSE;
    int c;

    while( ( c = prv_getc() ) >= 0 )
    {
        if( ( rx_wr - rx_rd ) < RX_RING_SIZE )
        {
            rx_ring[ rx_wr % RX_RING_SIZE ] = ( uint8_t ) c;
            rx_wr++;
        }
        else
        {
            rx_drop++;                   /* ring full: count, never block  */
        }
    }

    if( rx_task_h != NULL )
    {
        vTaskNotifyGiveFromISR( rx_task_h, &woken );
        portYIELD_FROM_ISR( woken );
    }
}

uint32_t esp_at_rx_dropped( void )
{
    return rx_drop;
}

void esp_at_on_event( esp_at_event_cb_t cb )
{
    event_cb = cb;
}

/* True for lines the ESP32 sends on its own (no command pending needed).
 * These may interleave with command responses at any time. */
static int prv_is_event( const char * line )
{
    static const char * const evts[] =
    {
        "WIFI ",                         /* WIFI CONNECTED/GOT IP/DISCONNECT */
        "+IPD",                          /* incoming TCP/UDP data            */
        "ready",
        "busy ",
        "+CWJAP:",                       /* async join status                */
        "SEND FAIL",
    };

    for( uint32_t i = 0; i < sizeof( evts ) / sizeof( evts[ 0 ] ); i++ )
    {
        const char * e = evts[ i ];
        uint32_t     j = 0;

        while( ( e[ j ] != '\0' ) && ( line[ j ] == e[ j ] ) )
        {
            j++;
        }

        if( e[ j ] == '\0' )
        {
            return 1;
        }
    }

    return 0;
}

static int prv_str_eq( const char * a, const char * b )
{
    uint32_t i = 0;

    while( ( a[ i ] != '\0' ) && ( a[ i ] == b[ i ] ) )
    {
        i++;
    }

    return ( a[ i ] == b[ i ] );
}

static void prv_classify( const char * line )
{
    if( prv_is_event( line ) )
    {
        if( event_cb != NULL )
        {
            event_cb( line );
        }
        return;
    }

    if( cmd_waiter == NULL )
    {
        /* nothing pending: every line is unsolicited */
        if( event_cb != NULL )
        {
            event_cb( line );
        }
        return;
    }

    /* response text for the pending command */
    if( cmd_resp != NULL )
    {
        for( uint32_t i = 0; line[ i ] != '\0'; i++ )
        {
            if( cmd_resp_n < cmd_resp_len - 1u )
            {
                cmd_resp[ cmd_resp_n++ ] = line[ i ];
            }
        }

        if( cmd_resp_n < cmd_resp_len - 1u )
        {
            cmd_resp[ cmd_resp_n++ ] = '\n';
        }
    }

    if( prv_str_eq( line, "OK" ) || prv_str_eq( line, "SEND OK" ) )
    {
        cmd_result = ESP_AT_OK;
        xTaskNotifyGive( cmd_waiter );
    }
    else if( prv_str_eq( line, "ERROR" ) || prv_str_eq( line, "FAIL" ) )
    {
        cmd_result = ESP_AT_ERROR;
        xTaskNotifyGive( cmd_waiter );
    }
}

/* High-priority receive task: ring bytes -> lines -> classify. Priority
 * configMAX_PRIORITIES-1 so ESP32 output is parsed promptly even while
 * app tasks compute (Ravi's item 4). */
static void prv_rx_task( void * arg )
{
    static char line[ RX_LINE_MAX ];
    uint32_t    n = 0;

    ( void ) arg;

    for( ; ; )
    {
        ulTaskNotifyTake( pdTRUE, portMAX_DELAY );

        while( rx_rd != rx_wr )
        {
            char c = ( char ) rx_ring[ rx_rd % RX_RING_SIZE ];
            rx_rd++;

            if( c == '\n' )
            {
                if( n > 0u )
                {
                    line[ n ] = '\0';
                    prv_classify( line );
                    n = 0;
                }
            }
            else if( ( c >= ' ' ) && ( c <= '~' ) && ( n < RX_LINE_MAX - 1u ) )
            {
                line[ n++ ] = c;         /* printable only: reset-glitch
                                          * 0xFF frames must not poison
                                          * the line (gotcha 19b)         */
            }
        }
    }
}

/* Switch to interrupt mode: spawn the RX task, then unmask fast IRQ 1.
 * Returns 0 on success, -1 if the heap could not hold the task. */
int esp_at_init( void )
{
    if( rx_task_h != NULL )
    {
        return 0;                        /* already up */
    }

    cmd_lock = xSemaphoreCreateMutex();

    if( cmd_lock == NULL )
    {
        return -1;
    }

    if( xTaskCreate( prv_rx_task, "esp-rx", 110, NULL,
                     configMAX_PRIORITIES - 1, &rx_task_h ) != pdPASS )
    {
        rx_task_h = NULL;
        return -1;
    }

    /* mie.fast1: UART2 RX (mcause 17, startup.S vector entry 17) */
    __asm__ volatile ( "csrs mie, %0" : : "r" ( 1u << 17 ) );

    return 0;
}

void esp_at_drain( void )
{
    if( rx_task_h != NULL )
    {
        rx_rd = rx_wr;                   /* flush the software ring */
        return;
    }

    while( prv_getc() >= 0 )
    {
    }
}

/* Send "<cmd>\r\n", collect the reply until OK/ERROR/timeout.
 * Returns ESP_AT_OK / ESP_AT_ERROR / ESP_AT_TIMEOUT; reply text (NUL
 * terminated, truncated to len-1) lands in resp when non-NULL. */
int esp_at_cmd( const char * cmd, char * resp, uint32_t len, uint32_t timeout_ticks )
{
    if( rx_task_h != NULL )
    {
        int result;

        xSemaphoreTake( cmd_lock, portMAX_DELAY );

        cmd_resp     = resp;
        cmd_resp_len = ( resp != NULL ) ? len : 0u;
        cmd_resp_n   = 0;
        cmd_result   = ESP_AT_TIMEOUT;
        ulTaskNotifyTake( pdTRUE, 0 );   /* clear a stale notification */
        cmd_waiter   = xTaskGetCurrentTaskHandle();

        prv_send_cmd( cmd );

        if( ulTaskNotifyTake( pdTRUE, timeout_ticks ) == 0u )
        {
            result = ESP_AT_TIMEOUT;
        }
        else
        {
            result = cmd_result;
        }

        cmd_waiter = NULL;

        if( ( resp != NULL ) && ( len > 0u ) )
        {
            resp[ cmd_resp_n < len ? cmd_resp_n : len - 1u ] = '\0';
        }

        cmd_resp = NULL;
        xSemaphoreGive( cmd_lock );
        return result;
    }

    /* ---- polled mode (pre-init bring-up path, tb_wifi-proven) ---------- */
    {
        TickType_t deadline = xTaskGetTickCount() + timeout_ticks;
        uint32_t   n = 0;
        char       prev = 0;

        esp_at_drain();
        prv_send_cmd( cmd );

        for( ; ; )
        {
            int c = prv_getc();

            if( c < 0 )
            {
                if( xTaskGetTickCount() >= deadline )
                {
                    if( resp != NULL ) resp[ n < len ? n : len - 1u ] = '\0';
                    return ESP_AT_TIMEOUT;
                }

                taskYIELD();
                continue;
            }

            if( ( resp != NULL ) && ( n < len - 1u ) )
            {
                resp[ n ] = ( char ) c;
            }
            n++;

            if( ( prev == 'O' ) && ( c == 'K' ) )
            {
                if( resp != NULL ) resp[ n < len ? n : len - 1u ] = '\0';
                return ESP_AT_OK;
            }

            if( ( prev == 'O' ) && ( c == 'R' ) )    /* ...ERR"OR" */
            {
                if( resp != NULL ) resp[ n < len ? n : len - 1u ] = '\0';
                return ESP_AT_ERROR;
            }

            prev = ( char ) c;
        }
    }
}

int esp_at_ping( void )
{
    return esp_at_cmd( "AT", NULL, 0, pdMS_TO_TICKS( 1000 ) );
}

int esp_at_join( const char * cmd_cwjap )
{
    /* caller formats: AT+CWJAP="ssid","pass" - joining can take ~10 s */
    return esp_at_cmd( cmd_cwjap, NULL, 0, pdMS_TO_TICKS( 15000 ) );
}

/* Stream len bytes out of PSRAM to the ESP32 (for use inside a CIPSEND
 * session). 64-byte SRAM bounce buffer - PSRAM is the bulk store. */
void esp_at_send_raw( uint32_t psram_addr, uint32_t len )
{
    uint8_t chunk[ 64 ];

    while( len > 0u )
    {
        uint32_t n = ( len > sizeof( chunk ) ) ? sizeof( chunk ) : len;

        psram_read( psram_addr, chunk, n );

        for( uint32_t i = 0; i < n; i++ )
        {
            prv_putc( ( char ) chunk[ i ] );
        }

        psram_addr += n;
        len -= n;
    }
}
