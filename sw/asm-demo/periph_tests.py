#!/usr/bin/env python3
"""v1.1 production-peripheral proof programs (simulation images).

Generates four 8 KiB SRAM images, one per new external device, each printing
a two-letter verdict on the console UART (checked by the matching tb):

  psram_test.vmem   SPI PSRAM write+readback via SPI host + RX reg  -> "PSR OK"
  wifi_test.vmem    "AT" -> "OK" exchange with the ESP32 model      -> "NET OK"
  audio_test.vmem   4 MCP3202 ADC samples (strictly increasing) +
                    PWM ch3 driven from the last sample             -> "AUD OK"
  cam_test.vmem     OV7670-FIFO frame readout via RRST/RCLK/gp_i,
                    16-byte checksum vs expected                    -> "CAM OK"

Register map facts used (docs/PRODUCTION_PERIPHERALS.md):
  GPIO 0x4000_0100: OUT +0, IN(raw) +4  (camera bus gp_i[15:8] is read RAW -
                    the debounced +8 register would add ~500-cycle latency)
  SPI  0x4000_0500: TX +0, STATUS +4 (bit1 empty), RX +8 (byte in [7:0])
  UART2 0x4000_0700: RX +0, TX +4, STATUS +8 (bit0 rx_empty, bit1 tx_full)
  PWM ch3: pulse 0x4000_0618, max 0x4000_061C
  GPO map: [8] PSRAM_CS, [9] ADC_CS, [10] CAM_WEN, [11] CAM_RRST(act-low),
           [12] CAM_RCLK.  Idle = 0x0B00 (both CS + RRST high, WEN/RCLK low).

SPI read pacing: the RX register returns the receive shift register, which is
stable once the byte finished; software waits for FIFO-empty then a ~30-loop
drain (the empty flag rises when the LAST byte STARTS shifting).

Run:  python sw/asm-demo/periph_tests.py
"""

import os
from assemble import assemble

# Register use: s0=console uart, s1=GPIO base, s2=SPI base, s3=GPO idle shadow

PROLOG = [
    "start:",
    "  lui s0, 0x40000",          # console UART
    "  lui s1, 0x40000",
    "  addi s1, s1, 0x100",       # GPIO
    "  lui s2, 0x40000",
    "  addi s2, s2, 0x500",       # SPI host
    "  lui s3, 0x1",
    "  addi s3, s3, -0x500",      # 0x1000 - 0x500 = 0x0B00 idle GPO
    "  sw s3, 0(s1)",             # CS lines high before anything else
]

PUTC = [
    "putc:",                      # char in a1, clobbers t1
    "  lw t1, 8(s0)",
    "  andi t1, t1, 2",
    "  bne t1, zero, putc",
    "  sw a1, 4(s0)",
    "  jalr zero, ra, 0",
]

SPI_SEND = [
    "spi_send:",                  # byte in a1; returns after full shift-out
    "  sw a1, 0(s2)",
    "spisend_wait:",
    "  lw t1, 4(s2)",
    "  andi t1, t1, 2",
    "  beq t1, zero, spisend_wait",
    "  addi t1, zero, 30",
    "spisend_drain:",
    "  addi t1, t1, -1",
    "  bne t1, zero, spisend_drain",
    "  jalr zero, ra, 0",
]

SPI_XFER = [
    "spi_xfer:",                  # send a1, received byte -> a2
    "  sw a1, 0(s2)",
    "spixfer_wait:",
    "  lw t1, 4(s2)",
    "  andi t1, t1, 2",
    "  beq t1, zero, spixfer_wait",
    "  addi t1, zero, 30",
    "spixfer_drain:",
    "  addi t1, t1, -1",
    "  bne t1, zero, spixfer_drain",
    "  lw a2, 8(s2)",
    "  andi a2, a2, 0xFF",
    "  jalr zero, ra, 0",
]


def puts(text):
    out = []
    for ch in text:
        out += [f"  addi a1, zero, {ord(ch)}", "  jal ra, putc"]
    return out


def verdict(tag):
    return ([f"ok_{tag}:"] + puts(f"{tag} OK\r\n") +
            ["done_ok:", "  jal zero, done_ok"] +
            [f"er_{tag}:"] + puts(f"{tag} ER\r\n") +
            ["done_er:", "  jal zero, done_er"])


def emit(name, program):
    words = assemble(program, base_addr=0x80)
    image = [0] * 2048
    for i, w in enumerate(words):
        image[0x80 // 4 + i] = w
    here = os.path.dirname(os.path.abspath(__file__))
    with open(os.path.join(here, name), "w") as f:
        for w in image:
            f.write(f"{w:08X}\n")
    print(f"assembled {len(words)} instructions -> {name}")


# --- 1. PSRAM ---------------------------------------------------------------
def psram_program():
    p = list(PROLOG)
    p += ["  xori s4, s3, 0x100", "  sw s4, 0(s1)"]          # PSRAM_CS low
    for b in [0x02, 0x00, 0x00, 0x10, 0xA5, 0x5A, 0xC3, 0x3C]:
        p += [f"  addi a1, zero, {b}", "  jal ra, spi_send"]
    p += ["  sw s3, 0(s1)"]                                   # CS high
    p += ["  addi t1, zero, 20", "gap1:", "  addi t1, t1, -1",
          "  bne t1, zero, gap1"]
    p += ["  xori s4, s3, 0x100", "  sw s4, 0(s1)"]          # CS low
    for b in [0x03, 0x00, 0x00, 0x10]:
        p += [f"  addi a1, zero, {b}", "  jal ra, spi_send"]
    for reg in ["s5", "s6", "s7", "s8"]:
        p += ["  addi a1, zero, 0xFF", "  jal ra, spi_xfer",
              f"  add {reg}, a2, zero"]
    p += ["  sw s3, 0(s1)"]                                   # CS high
    for reg, val in [("s5", 0xA5), ("s6", 0x5A), ("s7", 0xC3), ("s8", 0x3C)]:
        p += [f"  addi t2, zero, {val}", f"  bne {reg}, t2, er_PSR"]
    p += ["  jal zero, ok_PSR"]
    return p + verdict("PSR") + PUTC + SPI_SEND + SPI_XFER


# --- 2. WiFi ----------------------------------------------------------------
def wifi_program():
    p = list(PROLOG)
    p += ["  lui s5, 0x40000", "  addi s5, s5, 0x700"]       # UART2
    for ch in "AT\r\n":
        p += [f"  addi a1, zero, {ord(ch)}",
              "u2f_%d:" % ord(ch),
              "  lw t1, 8(s5)", "  andi t1, t1, 2",
              "  bne t1, zero, u2f_%d" % ord(ch),
              "  sw a1, 4(s5)"]
    p += [
        "  add s7, zero, zero",       # previous char
        "  addi s6, zero, 2047",      # ~2 ms timeout (inside tb window)
        "rx_loop:",
        "  addi s6, s6, -1",
        "  beq s6, zero, er_NET",
        "  lw t1, 8(s5)",
        "  andi t1, t1, 1",
        "  bne t1, zero, rx_loop",    # rx_empty -> poll again
        "  lw t2, 0(s5)",
        "  andi t2, t2, 0xFF",
        "  addi t3, zero, 79",        # 'O'
        "  bne s7, t3, not_ok",
        "  addi t3, zero, 75",        # 'K'
        "  beq t2, t3, ok_NET",
        "not_ok:",
        "  add s7, t2, zero",
        "  jal zero, rx_loop",
    ]
    return p + verdict("NET") + PUTC


# --- 3. Audio (mic ADC + speaker PWM) --------------------------------------
def audio_program():
    p = list(PROLOG)
    p += ["  add s5, zero, zero",     # previous sample
          "  addi s6, zero, 4"]       # conversions
    p += [
        "adc_loop:",
        "  xori s4, s3, 0x200", "  sw s4, 0(s1)",            # ADC_CS low
        "  addi a1, zero, 0x01", "  jal ra, spi_xfer",
        "  addi a1, zero, 0xA0", "  jal ra, spi_xfer", "  add s8, a2, zero",
        "  addi a1, zero, 0x00", "  jal ra, spi_xfer", "  add s9, a2, zero",
        "  sw s3, 0(s1)",                                     # CS high
        "  andi s8, s8, 0xF",
        "  slli s8, s8, 8",
        "  add s8, s8, s9",
        "  blt s5, s8, adc_inc_ok",
        "  jal zero, er_AUD",
        "adc_inc_ok:",
        "  add s5, s8, zero",
        "  addi s6, s6, -1",
        "  bne s6, zero, adc_loop",
        # speaker: PWM ch3 max=255, pulse=sample>>4
        "  lui t4, 0x40000",
        "  addi t4, t4, 0x618",
        "  addi t5, zero, 255",
        "  sw t5, 4(t4)",
        "  srli t6, s5, 4",
        "  sw t6, 0(t4)",
        "  jal zero, ok_AUD",
    ]
    return p + verdict("AUD") + PUTC + SPI_XFER


# --- 4. Camera --------------------------------------------------------------
CAM_FRAME = [(i * 7 + 3) & 0xFF for i in range(16)]
CAM_SUM = sum(CAM_FRAME)          # 888, fits an addi immediate
assert CAM_SUM < 2048

def cam_program():
    p = list(PROLOG)
    p += [
        "  addi t5, zero, 1",
        "  slli t5, t5, 11",          # 0x800 = CAM_RRST mask
        "  addi t6, zero, 1",
        "  slli t6, t6, 12",          # 0x1000 = CAM_RCLK mask
        # RRST low pulse (resets FIFO read pointer)
        "  xori t4, t5, -1",
        "  and s4, s3, t4",
        "  sw s4, 0(s1)",
        "  addi t1, zero, 10", "rrst_d:", "  addi t1, t1, -1",
        "  bne t1, zero, rrst_d",
        "  sw s3, 0(s1)",
        # clock out 16 bytes, summing
        "  add s5, zero, zero",
        "  addi s6, zero, 16",
        "cam_loop:",
        "  lw t1, 4(s1)",             # RAW gp_i
        "  srli t1, t1, 8",
        "  andi t1, t1, 0xFF",
        "  add s5, s5, t1",
        "  add s4, s3, t6",           # RCLK high (bit clear in idle)
        "  sw s4, 0(s1)",
        "  addi t1, zero, 6", "rclk_h:", "  addi t1, t1, -1",
        "  bne t1, zero, rclk_h",
        "  sw s3, 0(s1)",             # RCLK low
        "  addi t1, zero, 6", "rclk_l:", "  addi t1, t1, -1",
        "  bne t1, zero, rclk_l",
        "  addi s6, s6, -1",
        "  bne s6, zero, cam_loop",
        f"  addi t2, zero, {CAM_SUM}",
        "  beq s5, t2, ok_CAM",
        "  jal zero, er_CAM",
    ]
    return p + verdict("CAM") + PUTC


def main():
    emit("psram_test.vmem", psram_program())
    emit("wifi_test.vmem", wifi_program())
    emit("audio_test.vmem", audio_program())
    emit("cam_test.vmem", cam_program())
    print(f"camera frame checksum expected: {CAM_SUM}")


if __name__ == "__main__":
    main()
