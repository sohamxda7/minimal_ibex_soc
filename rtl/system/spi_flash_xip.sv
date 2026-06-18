module spi_flash_xip #(
  parameter int AW = 24,
  parameter int DW = 32,
  parameter int CLK_DIV = 4     // SPI clock = sys_clk / (2*CLK_DIV)
)(
  input  logic        clk_i,
  input  logic        rst_ni,

  // XIP request/response interface
  input  logic             xip_req_i,
  input  logic             xip_we_i,
  input  logic [AW-1:0]    xip_addr_i,
  input  logic [DW-1:0]    xip_wdata_i,  // unused in XIP read-only mode
  input  logic [DW/8-1:0]  xip_be_i,     // unused in XIP read-only mode
  output logic             xip_rvalid_o,
  output logic [DW-1:0]    xip_rdata_o,

  // SPI signals (directly to pads)
  output logic        spi_sck_o,
  output logic        spi_csn_o,
  output logic        spi_mosi_o,
  input  logic        spi_miso_i
);

  // State machine: IDLE -> CMD -> ADDR -> DATA -> ACK
  typedef enum logic [2:0] {
    S_IDLE,
    S_CMD,
    S_ADDR,
    S_DATA,
    S_ACK
  } state_e;

  localparam logic [7:0] READ_CMD = 8'h03;
  localparam logic [7:0] CLK_DIV_LAST = 8'(CLK_DIV - 1);
  localparam logic [5:0] DATA_LAST_BIT = 6'(DW - 1);

  state_e       state_q;
  logic [DW-2:0]  data_shift_q;
  logic [AW-1:0]  addr_reg_q;
  logic [7:0]   out_shift_q;
  logic [5:0]   bit_cnt_q;
  logic [1:0]   addr_byte_q;
  logic [7:0]   clk_cnt_q;
  logic         spi_sck_q;

  logic xip_read_req;
  logic spi_tick;
  logic spi_rise;
  logic spi_fall;

  assign xip_read_req = xip_req_i & ~xip_we_i;

  // SPI pad outputs
  assign spi_csn_o  = (state_q == S_IDLE) || (state_q == S_ACK);
  assign spi_sck_o  = spi_sck_q & ~spi_csn_o;
  assign spi_mosi_o = out_shift_q[7];

  // Divider tick used to toggle SPI clock
  assign spi_tick = (clk_cnt_q == CLK_DIV_LAST);
  assign spi_rise = spi_tick && (spi_sck_q == 1'b0) && (state_q != S_IDLE) && (state_q != S_ACK);
  assign spi_fall = spi_tick && (spi_sck_q == 1'b1) && (state_q != S_IDLE) && (state_q != S_ACK);

  always_ff @(posedge clk_i or negedge rst_ni) begin
    if (!rst_ni) begin
      state_q      <= S_IDLE;
      data_shift_q <= '0;
      addr_reg_q   <= '0;
      out_shift_q  <= '0;
      bit_cnt_q    <= '0;
      addr_byte_q  <= '0;
      clk_cnt_q    <= '0;
      spi_sck_q    <= 1'b0;
      xip_rvalid_o <= 1'b0;
      xip_rdata_o  <= '0;
    end else begin
      xip_rvalid_o <= 1'b0;  // pulse in S_ACK

      if ((state_q != S_IDLE) && (state_q != S_ACK)) begin
        if (spi_tick) begin
          clk_cnt_q <= '0;
          spi_sck_q <= ~spi_sck_q;
        end else begin
          clk_cnt_q <= clk_cnt_q + 1'b1;
        end
      end else begin
        clk_cnt_q <= '0;
        spi_sck_q <= 1'b0;
      end

      case (state_q)
        S_IDLE: begin
          if (xip_read_req) begin
            addr_reg_q   <= xip_addr_i;
            out_shift_q  <= READ_CMD;
            bit_cnt_q    <= 6'd7;
            addr_byte_q  <= 2'd0;
            data_shift_q <= '0;
            state_q      <= S_CMD;
          end
        end

        S_CMD: begin
          if (spi_fall) begin
            if (bit_cnt_q == 0) begin
              out_shift_q <= addr_reg_q[23:16];
              bit_cnt_q   <= 6'd7;
              addr_byte_q <= 2'd0;
              state_q     <= S_ADDR;
            end else begin
              out_shift_q <= {out_shift_q[6:0], 1'b0};
              bit_cnt_q   <= bit_cnt_q - 1'b1;
            end
          end
        end

        S_ADDR: begin
          if (spi_fall) begin
            if (bit_cnt_q == 0) begin
              if (addr_byte_q == 2'd0) begin
                out_shift_q <= addr_reg_q[15:8];
                bit_cnt_q   <= 6'd7;
                addr_byte_q <= 2'd1;
              end else if (addr_byte_q == 2'd1) begin
                out_shift_q <= addr_reg_q[7:0];
                bit_cnt_q   <= 6'd7;
                addr_byte_q <= 2'd2;
              end else begin
                out_shift_q <= 8'h00;
                bit_cnt_q   <= DATA_LAST_BIT;
                state_q     <= S_DATA;
              end
            end else begin
              out_shift_q <= {out_shift_q[6:0], 1'b0};
              bit_cnt_q   <= bit_cnt_q - 1'b1;
            end
          end
        end

        S_DATA: begin
          if (spi_rise) begin
            data_shift_q <= {data_shift_q[DW-3:0], spi_miso_i};
            if (bit_cnt_q == 0) begin
              xip_rdata_o <= {data_shift_q, spi_miso_i};
              state_q  <= S_ACK;
            end else begin
              bit_cnt_q <= bit_cnt_q - 1'b1;
            end
          end
        end

        S_ACK: begin
          xip_rvalid_o <= 1'b1;
          state_q  <= S_IDLE;
        end

        default: state_q <= S_IDLE;
      endcase
    end
  end

endmodule
