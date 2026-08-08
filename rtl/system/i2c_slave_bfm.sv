`timescale 1ns/1ps

module i2c_slave_bfm
#(
    parameter SLAVE_ADDR = 7'h50
)
(
    input  logic clk,
    input  logic rst_n,

    inout tri scl,
    inout tri sda
);

/////////////////////////////////////////////////////////////
// Open Drain
/////////////////////////////////////////////////////////////

logic sda_drive_low;

assign sda = (sda_drive_low) ? 1'b0 : 1'bz;

/////////////////////////////////////////////////////////////
// Memory
/////////////////////////////////////////////////////////////

logic [7:0] mem [0:255];

integer i;

initial begin
    for(i=0;i<256;i=i+1)
        mem[i]=byte'(i);
end

/////////////////////////////////////////////////////////////
// Synchronizers
/////////////////////////////////////////////////////////////

logic scl_ff1,scl_ff2;
logic sda_ff1,sda_ff2;

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        scl_ff1<=1'b1;
        scl_ff2<=1'b1;

        sda_ff1<=1'b1;
        sda_ff2<=1'b1;
    end
    else
    begin
        scl_ff1<=scl;
        scl_ff2<=scl_ff1;

        sda_ff1<=sda;
        sda_ff2<=sda_ff1;
    end
end

/////////////////////////////////////////////////////////////
// Edge Detect
/////////////////////////////////////////////////////////////

wire scl_rise;
wire scl_fall;

wire start_cond;
wire stop_cond;

assign scl_rise = (scl_ff2==0)&&(scl_ff1==1);
assign scl_fall = (scl_ff2==1)&&(scl_ff1==0);

assign start_cond =
        (sda_ff2==1)&&
        (sda_ff1==0)&&
        (scl_ff1==1);

assign stop_cond =
        (sda_ff2==0)&&
        (sda_ff1==1)&&
        (scl_ff1==1);

/////////////////////////////////////////////////////////////
// FSM
/////////////////////////////////////////////////////////////

typedef enum logic[3:0]
{
    ST_IDLE,

    ST_ADDRESS,

    ST_ACK_ADDR,

    ST_MEMADDR,

    ST_ACK_MEM,

    ST_WRITE,

    ST_ACK_WRITE,

    ST_READ,

    ST_READ_ACK

}state_t;

state_t state;

/////////////////////////////////////////////////////////////
// Registers
/////////////////////////////////////////////////////////////

logic [7:0] shift_reg;

logic [7:0] mem_addr;

logic rw;

logic [2:0] bit_cnt;

logic addr_ok;

logic master_ack;

logic [7:0] tx_data;

logic [7:0] rx_data;

/////////////////////////////////////////////////////////////
// Main FSM
/////////////////////////////////////////////////////////////

always_ff @(posedge clk or negedge rst_n)
begin
    if(!rst_n)
    begin
        state         <= ST_IDLE;

        bit_cnt       <= 3'd7;

        shift_reg     <= 8'h00;

        mem_addr      <= 8'h00;

        rw            <= 1'b0;

        addr_ok       <= 1'b0;

        sda_drive_low <= 1'b0;

        tx_data       <= 8'h00;

        rx_data       <= 8'h00;

        master_ack    <= 1'b0;
    end
    else
    begin

        //-----------------------------------------------------
        // Bus condition monitor: STOP and repeated START are
        // checked globally, regardless of current state, since
        // either can occur mid-transaction on the real bus.
        //-----------------------------------------------------

        if(stop_cond)
        begin
            state         <= ST_IDLE;
            sda_drive_low <= 1'b0;
        end

        else if(start_cond && state != ST_IDLE)
        begin
            // Repeated START: abandon whatever we were doing and
            // restart address reception immediately.
            state         <= ST_ADDRESS;
            bit_cnt       <= 3'd7;
            shift_reg     <= 8'h00;
            sda_drive_low <= 1'b0;
        end

        else

        begin

            case(state)

            ////////////////////////////////////////////////////
            // IDLE
            ////////////////////////////////////////////////////

            ST_IDLE:
            begin
                sda_drive_low <= 1'b0;

                if(start_cond)
                begin
                    state     <= ST_ADDRESS;
                    bit_cnt   <= 3'd7;
                    shift_reg <= 8'h00;
                end
            end

            ////////////////////////////////////////////////////
            // Receive Slave Address
            ////////////////////////////////////////////////////

            ST_ADDRESS:
            begin
                if(scl_rise)
                begin
                    shift_reg[bit_cnt] <= sda_ff1;

                    if(bit_cnt == 0)
                    begin
                        // Save the R/W bit
                        rw <= sda_ff1;

                        if(shift_reg[7:1] == SLAVE_ADDR)
                        begin
                            addr_ok <= 1'b1;

                            state <= ST_ACK_ADDR;

                            $display("[%0t] Slave Address Matched  RW=%0b",
                                     $time, sda_ff1);
                        end
                        else
                        begin
                            addr_ok <= 1'b0;

                            state <= ST_IDLE;

                            $display("[%0t] Address Mismatch",
                                     $time);
                        end

                        bit_cnt <= 3'd7;
                    end
                    else
                    begin
                        bit_cnt <= bit_cnt - 1;
                    end
                end
            end

            ////////////////////////////////////////////////////
            // ACK Address
            //
            // I2C requires the ACK bit to remain stable for the
            // ENTIRE time SCL is high, and may only change after
            // SCL has returned low again. We therefore:
            //   1st scl_fall -> assert ACK (SDA=0)
            //   2nd scl_fall -> release ACK, advance state
            // Releasing on scl_rise (the old, buggy approach)
            // makes SDA transition to 1 while SCL is high, which
            // the master's bit-controller misinterprets as a
            // STOP condition -> arbitration-lost -> hang.
            ////////////////////////////////////////////////////

            ST_ACK_ADDR:
            begin
                if(scl_fall)
                begin
                    if(sda_drive_low)
                    begin
                        // Second scl_fall: SCL is low, safe to release.
                        // Default: release (covers the write-direction
                        // case, i.e. rw==0, where nothing more is driven
                        // here).
                        sda_drive_low <= 1'b0;
                        bit_cnt       <= 3'd7;

                        if(rw)
                        begin
                            tx_data <= mem[mem_addr];
                            state   <= ST_READ;

                            // IMPORTANT: this scl_fall is ALREADY the
                            // start of bit 7's low period - ST_READ's
                            // own scl_fall-triggered drive logic won't
                            // run until the *next* clock, by which time
                            // this edge is gone. Drive bit 7 immediately
                            // here, or it defaults to "released" (reads
                            // as 1) regardless of the actual data bit.
                            sda_drive_low <= ~mem[mem_addr][7];
                        end
                        else
                        begin
                            state <= ST_MEMADDR;
                        end
                    end
                    else
                    begin
                        // First scl_fall: assert ACK.
                        sda_drive_low <= 1'b1;
                    end
                end
            end

            ////////////////////////////////////////////////////
            // Receive Memory Address
            ////////////////////////////////////////////////////

            ST_MEMADDR:
            begin
                if(scl_rise)
                begin
                    shift_reg[bit_cnt] <= sda_ff1;

                    if(bit_cnt==0)
                    begin
                        mem_addr <= {shift_reg[7:1],sda_ff1};

                        $display("[%0t] Memory Address = %02h",
                                 $time,
                                 {shift_reg[7:1],sda_ff1});

                        state <= ST_ACK_MEM;

                        bit_cnt <= 3'd7;
                    end
                    else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            ////////////////////////////////////////////////////
            // ACK Memory Address
            // (same two-phase release as ST_ACK_ADDR)
            ////////////////////////////////////////////////////

            ST_ACK_MEM:
            begin
                if(scl_fall)
                begin
                    if(sda_drive_low)
                    begin
                        sda_drive_low <= 1'b0;
                        bit_cnt       <= 3'd7;
                        state         <= ST_WRITE;
                    end
                    else
                    begin
                        sda_drive_low <= 1'b1;
                    end
                end
            end

            ////////////////////////////////////////////////////
            // Receive Write Data
            ////////////////////////////////////////////////////

            ST_WRITE:
            begin
                if(scl_rise)
                begin
                    shift_reg[bit_cnt] <= sda_ff1;

                    if(bit_cnt==0)
                    begin
                        rx_data <= {shift_reg[7:1],sda_ff1};

                        mem[mem_addr] <= {shift_reg[7:1],sda_ff1};

                        $display("[%0t] WRITE MEM[%02h] = %02h",
                                 $time,
                                 mem_addr,
                                 {shift_reg[7:1],sda_ff1});

                        mem_addr <= mem_addr + 1;

                        state <= ST_ACK_WRITE;

                        bit_cnt <= 3'd7;
                    end
                    else
                        bit_cnt <= bit_cnt - 1;
                end
            end

            ////////////////////////////////////////////////////
            // ACK Write Data
            // (same two-phase release as ST_ACK_ADDR)
            ////////////////////////////////////////////////////

            ST_ACK_WRITE:
            begin
                if(scl_fall)
                begin
                    if(sda_drive_low)
                    begin
                        sda_drive_low <= 1'b0;
                        bit_cnt       <= 3'd7;

                        // Continue receiving more bytes until STOP
                        // (or a repeated START, handled globally above)
                        state <= ST_WRITE;
                    end
                    else
                    begin
                        sda_drive_low <= 1'b1;
                    end
                end
            end

            ////////////////////////////////////////////////////
            // Read Data
            //
            // Here the slave is driving every bit, so there is no
            // "release while SCL high" hazard - this state was
            // already correct.
            ////////////////////////////////////////////////////

            ST_READ:
            begin

                if(scl_fall)
                begin
                    if(tx_data[bit_cnt])
                        sda_drive_low <= 1'b0;
                    else
                        sda_drive_low <= 1'b1;
                end

                if(scl_rise)
                begin
                    if(bit_cnt==0)
                    begin
                        // Do NOT release SDA here: this scl_rise is the
                        // master's sampling edge for bit 0, and releasing
                        // now makes SDA rise while SCL is high — a phantom
                        // STOP condition (same bug class as the old
                        // ST_ACK_ADDR release-on-rise, see comment there).
                        // The release happens on the next scl_fall, in
                        // ST_READ_ACK.
                        state <= ST_READ_ACK;
                    end
                    else
                    begin
                        bit_cnt <= bit_cnt-1;
                    end
                end

            end

            ////////////////////////////////////////////////////
            // Master ACK/NACK
            ////////////////////////////////////////////////////

            ST_READ_ACK:
            begin

                // First scl_fall after the last data bit: SCL is low, so
                // it is now safe to release SDA for the master's ACK/NACK.
                if(scl_fall)
                    sda_drive_low <= 1'b0;

                if(scl_rise)
                begin
                    master_ack <= ~sda_ff1;

                    if(sda_ff1==0)
                    begin
                        mem_addr <= mem_addr + 1;
                        tx_data  <= mem[mem_addr+1];
                        bit_cnt  <= 3'd7;

                        $display("[%0t] Master ACK",$time);

                        state <= ST_READ;

                        // NOTE: no pre-drive of bit 7 here. Driving SDA on
                        // this scl_rise changes the line while SCL is high
                        // (phantom START/STOP hazard). The state/tx_data
                        // updates land within one 20 MHz clock, long before
                        // the next scl_fall (~2.5 us at 100 kHz), so
                        // ST_READ's own scl_fall logic drives bit 7 safely
                        // in its low period.
                    end
                    else
                    begin
                        $display("[%0t] Master NACK",$time);

                        state <= ST_IDLE;
                    end
                end

            end

            ////////////////////////////////////////////////////
            // Default
            ////////////////////////////////////////////////////

            default:
            begin
                state <= ST_IDLE;
            end

            endcase

        end

    end

end

always @(posedge clk)
begin
    if(start_cond)
        $display("[%0t] START detected",$time);
end

always @(posedge clk)
begin
    if(stop_cond)
        $display("[%0t] STOP detected (state=%0d)", $time, state);
end

/*always @(posedge clk)
begin
    if(state == ST_ACK_ADDR)
        $display("[%0t] scl=%b sda=%b drive_low=%b",
                 $time,
                 scl,
                 sda,
                 sda_drive_low);
end*/

endmodule
