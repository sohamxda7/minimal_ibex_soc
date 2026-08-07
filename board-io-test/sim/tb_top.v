// ============================================================================
// Testbench for the Arty A7 IO test design.
//
// WHY THIS EXISTS: simulating the real design as-is looks broken. On hardware
// the LED chase moves every 0.17 s and colours change every 0.67 s - but a
// simulator typically only covers MICROseconds of circuit time, so those
// signals look frozen in the waveform, while the RGB PWM (a few microseconds
// per cycle) toggles like mad. Nothing is wrong; the timescales are just
// worlds apart.
//
// This testbench fixes that by instantiating the design with:
//   SPEEDUP      = 12  -> chase moves every ~41 us, colours every ~164 us
//   CLKS_PER_BIT = 100 -> one UART byte takes ~10 us instead of ~87 us
//
// It runs the full IO story in about 8 ms of simulated time:
//   startup status message -> switch change message -> button press message
//   -> UART echo test -> LED/chase checks. Everything the FPGA "types" over
//   UART is printed to the simulator console.
//
// Run it in Vivado:  add sim\tb_top.v as a *simulation-only* source, set
// tb_top as simulation top, Run Simulation -> run all (or `run 8 ms`).
// ============================================================================

`timescale 1ns / 1ps

module tb_top;

    localparam CPB    = 100;          // sim-friendly clocks per UART bit
    localparam BIT_NS = CPB * 10;     // one UART bit in nanoseconds

    // 100 MHz clock
    reg clk = 1'b0;
    always #5 clk = ~clk;

    // Inputs we control
    reg [3:0] sw      = 4'b0000;
    reg [3:0] btn     = 4'b0000;
    reg       host_tx = 1'b1;         // the "PC typing" line, idle high

    // Outputs we watch
    wire [3:0] led;
    wire       fpga_tx;
    wire       l0r, l0g, l0b, l1r, l1g, l1b;
    wire       l2r, l2g, l2b, l3r, l3g, l3b;
    wire [7:0] ja, jb, jc, jd;

    top #(
        .SPEEDUP      (12),
        .CLKS_PER_BIT (CPB)
    ) dut (
        .clk100       (clk),
        .sw           (sw),
        .btn          (btn),
        .led          (led),
        .led0_r(l0r), .led0_g(l0g), .led0_b(l0b),
        .led1_r(l1r), .led1_g(l1g), .led1_b(l1b),
        .led2_r(l2r), .led2_g(l2g), .led2_b(l2b),
        .led3_r(l3r), .led3_g(l3g), .led3_b(l3b),
        .uart_txd_in  (host_tx),
        .uart_rxd_out (fpga_tx),
        .ja(ja), .jb(jb), .jc(jc), .jd(jd)
    );

    // ------------------------------------------------------------------
    // Act like a PC terminal: decode every byte the FPGA sends and print
    // it to the simulator console.
    // ------------------------------------------------------------------
    reg [7:0] rx_byte;
    integer i;
    initial begin
        forever begin
            @(negedge fpga_tx);                   // start bit begins
            #(BIT_NS + BIT_NS/2);                 // centre of data bit 0
            for (i = 0; i < 8; i = i + 1) begin
                rx_byte[i] = fpga_tx;             // UART sends LSB first
                #(BIT_NS);
            end
            $write("%c", rx_byte);
            $fflush;
        end
    end

    // "PC types a character" helper
    task send_byte(input [7:0] b);
        integer j;
        begin
            host_tx = 1'b0;  #(BIT_NS);           // start bit
            for (j = 0; j < 8; j = j + 1) begin
                host_tx = b[j];  #(BIT_NS);       // data, LSB first
            end
            host_tx = 1'b1;  #(BIT_NS);           // stop bit
        end
    endtask

    // ------------------------------------------------------------------
    // The test story
    // ------------------------------------------------------------------
    initial begin
        // Waveform dump (used by open-source simulators; Vivado has its own)
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        $display("=== Arty A7 IO test simulation (sped-up timebase) ===");
        $display("--- FPGA UART output appears below as plain text ---");

        // 1) Right after "power-up" the design sends its startup status
        #2_000_000;   // 2 ms

        // 2) Flip switches -> LEDs must mirror them + a status message
        sw = 4'b0101;
        #2_000_000;
        if (led === 4'b0101)
            $display("--- PASS: LEDs mirror the switches (led=%b)", led);
        else
            $display("--- FAIL: led=%b, expected 0101", led);

        // 3) Press button 0 -> RGB LED 0 starts cycling + status message
        btn = 4'b0001;
        #2_000_000;
        btn = 4'b0000;
        #500_000;

        // 4) PC types "Hi" -> FPGA must echo both characters back
        $display("--- PC sends 'H' and 'i', watch for the echo:");
        send_byte("H");  #200_000;
        send_byte("i");  #200_000;

        // 5) Switches back down -> chase pattern takes over again
        sw = 4'b0000;
        #1_000_000;
        $display("");
        $display("--- Chase pattern now on LEDs: led=%b (one-hot, moving)", led);
        $display("--- Pmod pin JA1 toggles ~every 20 us in this sim: ja[0]=%b", ja[0]);

        $display("=== Simulation done. In the waveform viewer, look at:");
        $display("===   led (changes every ~41 us), phase/RGB (every ~164 us),");
        $display("===   fpga_tx & host_tx (UART frames), ja (square waves).");
        $finish;
    end

endmodule
