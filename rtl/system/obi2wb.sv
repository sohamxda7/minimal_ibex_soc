module obi2wb #(
  parameter AW = 32,
  parameter DW = 32
)(
  input  logic             clk_i,
  input  logic             rst_ni,
 
  // OBI
  input  logic             obi_req_i,
  output logic             obi_gnt_o,
  input  logic [AW-1:0]    obi_addr_i,
  input  logic             obi_we_i,
  input  logic [DW/8-1:0]  obi_be_i,
  input  logic [DW-1:0]    obi_wdata_i,
 
  output logic             obi_rvalid_o,
  output logic [DW-1:0]    obi_rdata_o,
 
  // Wishbone master
  output logic             wb_cyc_o,
  output logic             wb_stb_o,
  output logic             wb_we_o,
  output logic [AW-1:0]    wb_adr_o,
  output logic [DW-1:0]    wb_dat_o,
  output logic [DW/8-1:0]  wb_sel_o,
 
  input  logic             wb_ack_i,
  input  logic [DW-1:0]    wb_dat_i,
  input  logic             wb_stall_i
);
 
  typedef enum logic [0:0] { IDLE, WAIT_ACK } state_e;
  state_e state_q, state_d;
 
  logic [AW-1:0]   addr_q;
  logic [DW-1:0]   wdata_q;
  logic [DW/8-1:0] be_q;
  logic            we_q;
 
  logic [DW-1:0]   rdata_q;
 
  logic req_sent_q;
  logic wb_active_q;
 
  logic obi_gnt_q;
  logic obi_rvalid_q;
 
  // =========================================================
  // Sequential
  // =========================================================
  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q      <= IDLE;
      addr_q       <= '0;
      wdata_q      <= '0;
      be_q         <= '0;
      we_q         <= '0;
      rdata_q      <= '0;
      req_sent_q   <= 1'b0;
      wb_active_q  <= 1'b0;
      obi_gnt_q    <= 1'b0;
      obi_rvalid_q <= 1'b0;
    end else begin
 
      state_q <= state_d;
 
      obi_gnt_q    <= 1'b0;
      obi_rvalid_q <= 1'b0;
 
      // latch request
      if (state_q == IDLE && obi_req_i && !req_sent_q && !wb_stall_i) begin
        addr_q     <= obi_addr_i;
        wdata_q    <= obi_wdata_i;
        be_q       <= obi_be_i;
        we_q       <= obi_we_i;
        req_sent_q <= 1'b1;
        obi_gnt_q  <= 1'b1;
      end
 
      // WB active control
      if (state_q == IDLE && obi_req_i && !req_sent_q && !wb_stall_i)
        wb_active_q <= 1'b1;
      else if (state_q == WAIT_ACK && wb_ack_i)
        wb_active_q <= 1'b0;
 
      // response
      if (state_q == WAIT_ACK && wb_ack_i) begin
        rdata_q       <= wb_dat_i;
        obi_rvalid_q  <= 1'b1;
        req_sent_q    <= 1'b0;
      end
 
    end
  end
 
  // =========================================================
  // Combinational FSM
  // =========================================================
  always_comb begin
    state_d = state_q;
 
    case (state_q)
 
      IDLE: begin
        if (obi_req_i && !req_sent_q)
          state_d = WAIT_ACK;
      end
 
      WAIT_ACK: begin
        if (wb_ack_i)
          state_d = IDLE;
      end
 
    endcase
  end
 
  // =========================================================
  // Wishbone outputs (clean + registered control)
  // =========================================================
  assign wb_cyc_o = wb_active_q;
  assign wb_stb_o = wb_active_q;
  assign wb_we_o  = we_q;
  assign wb_adr_o = addr_q;
  assign wb_dat_o = wdata_q;
  assign wb_sel_o = be_q;
 
  // =========================================================
  // OBI outputs
  // =========================================================
  assign obi_gnt_o    = obi_gnt_q;
  assign obi_rvalid_o = obi_rvalid_q;
  assign obi_rdata_o  = rdata_q;
 
endmodule
