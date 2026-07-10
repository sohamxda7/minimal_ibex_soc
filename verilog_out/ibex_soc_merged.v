module prim_generic_buf (
	in_i,
	out_o
);
	parameter signed [31:0] Width = 1;
	input [Width - 1:0] in_i;
	output wire [Width - 1:0] out_o;
	wire [Width - 1:0] inv;
	assign inv = ~in_i;
	assign out_o = ~inv;
endmodule
module prim_generic_clock_gating (
	clk_i,
	en_i,
	test_en_i,
	clk_o
);
	reg _sv2v_0;
	parameter [0:0] NoFpgaGate = 1'b0;
	parameter [0:0] FpgaBufGlobal = 1'b1;
	input clk_i;
	input en_i;
	input test_en_i;
	output wire clk_o;
	reg en_latch;
	always @(*) begin
		if (_sv2v_0)
			;
		if (!clk_i)
			en_latch = en_i | test_en_i;
	end
	assign clk_o = en_latch & clk_i;
	initial _sv2v_0 = 0;
endmodule
module prim_generic_clock_inv (
	clk_i,
	scanmode_i,
	clk_no
);
	parameter [0:0] HasScanMode = 1'b1;
	parameter [0:0] NoFpgaBufG = 1'b0;
	input clk_i;
	input scanmode_i;
	output wire clk_no;
	generate
		if (HasScanMode) begin : gen_scan
			prim_clock_mux2 #(.NoFpgaBufG(NoFpgaBufG)) i_dft_tck_mux(
				.clk0_i(~clk_i),
				.clk1_i(clk_i),
				.sel_i(scanmode_i),
				.clk_o(clk_no)
			);
		end
		else begin : gen_noscan
			wire unused_scanmode;
			assign unused_scanmode = scanmode_i;
			assign clk_no = ~clk_i;
		end
	endgenerate
endmodule
module prim_generic_clock_mux2 (
	clk0_i,
	clk1_i,
	sel_i,
	clk_o
);
	parameter [0:0] NoFpgaBufG = 1'b0;
	input clk0_i;
	input clk1_i;
	input sel_i;
	output wire clk_o;
	assign clk_o = (sel_i & clk1_i) | (~sel_i & clk0_i);
endmodule
module prim_clock_inv (
	clk_i,
	scanmode_i,
	clk_no
);
	parameter [0:0] HasScanMode = 1'b1;
	parameter [0:0] NoFpgaBufG = 1'b0;
	input clk_i;
	input scanmode_i;
	output wire clk_no;
	generate
		if (1) begin : gen_generic
			prim_generic_clock_inv #(
				.HasScanMode(HasScanMode),
				.NoFpgaBufG(NoFpgaBufG)
			) u_impl_generic(
				.clk_i(clk_i),
				.scanmode_i(scanmode_i),
				.clk_no(clk_no)
			);
		end
	endgenerate
endmodule
module prim_clock_mux2 (
	clk0_i,
	clk1_i,
	sel_i,
	clk_o
);
	parameter [0:0] NoFpgaBufG = 1'b0;
	input clk0_i;
	input clk1_i;
	input sel_i;
	output wire clk_o;
	localparam integer Impl = 32'sd0;
	generate
		if (Impl == 32'sd1) begin : gen_xilinx
			prim_xilinx_clock_mux2 #(.NoFpgaBufG(NoFpgaBufG)) u_impl_xilinx();
		end
		else begin : gen_generic
			prim_generic_clock_mux2 #(.NoFpgaBufG(NoFpgaBufG)) u_impl_generic(
				.clk0_i(clk0_i),
				.clk1_i(clk1_i),
				.sel_i(sel_i),
				.clk_o(clk_o)
			);
		end
	endgenerate
endmodule
module prim_flop (
	clk_i,
	rst_ni,
	d_i,
	q_o
);
	parameter signed [31:0] Width = 1;
	parameter [Width - 1:0] ResetValue = 0;
	input clk_i;
	input rst_ni;
	input [Width - 1:0] d_i;
	output wire [Width - 1:0] q_o;
	localparam integer Impl = 32'sd0;
	generate
		if (Impl == 32'sd1) begin : gen_xilinx
			prim_xilinx_flop #(
				.ResetValue(ResetValue),
				.Width(Width)
			) u_impl_xilinx();
		end
		else begin : gen_generic
			prim_generic_flop #(
				.ResetValue(ResetValue),
				.Width(Width)
			) u_impl_generic(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.d_i(d_i),
				.q_o(q_o)
			);
		end
	endgenerate
endmodule
module prim_flop_2sync (
	clk_i,
	rst_ni,
	d_i,
	q_o
);
	reg _sv2v_0;
	parameter signed [31:0] Width = 16;
	parameter [Width - 1:0] ResetValue = 1'sb0;
	parameter [0:0] EnablePrimCdcRand = 1;
	input clk_i;
	input rst_ni;
	input [Width - 1:0] d_i;
	output wire [Width - 1:0] q_o;
	reg [Width - 1:0] d_o;
	wire [Width - 1:0] intq;
	wire unused_sig;
	assign unused_sig = EnablePrimCdcRand;
	always @(*) begin
		if (_sv2v_0)
			;
		d_o = d_i;
	end
	prim_flop #(
		.Width(Width),
		.ResetValue(ResetValue)
	) u_sync_1(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d_i(d_o),
		.q_o(intq)
	);
	prim_flop #(
		.Width(Width),
		.ResetValue(ResetValue)
	) u_sync_2(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d_i(intq),
		.q_o(q_o)
	);
	initial _sv2v_0 = 0;
endmodule
module prim_generic_flop (
	clk_i,
	rst_ni,
	d_i,
	q_o
);
	parameter signed [31:0] Width = 1;
	parameter [Width - 1:0] ResetValue = 0;
	input clk_i;
	input rst_ni;
	input [Width - 1:0] d_i;
	output reg [Width - 1:0] q_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			q_o <= ResetValue;
		else
			q_o <= d_i;
endmodule
module prim_sync_reqack (
	clk_src_i,
	rst_src_ni,
	clk_dst_i,
	rst_dst_ni,
	req_chk_i,
	src_req_i,
	src_ack_o,
	dst_req_o,
	dst_ack_i
);
	reg _sv2v_0;
	parameter [0:0] EnRstChks = 1'b0;
	parameter [0:0] EnRzHs = 1'b0;
	input clk_src_i;
	input rst_src_ni;
	input clk_dst_i;
	input rst_dst_ni;
	input wire req_chk_i;
	input wire src_req_i;
	output reg src_ack_o;
	output reg dst_req_o;
	input wire dst_ack_i;
	wire unused_req_chk;
	assign unused_req_chk = req_chk_i;
	generate
		if (EnRzHs) begin : gen_rz_hs_protocol
			reg src_fsm_d;
			reg src_fsm_q;
			reg dst_fsm_d;
			reg dst_fsm_q;
			wire src_ack;
			reg dst_ack;
			reg src_req;
			wire dst_req;
			always @(*) begin : src_fsm
				if (_sv2v_0)
					;
				src_fsm_d = src_fsm_q;
				src_ack_o = 1'b0;
				src_req = 1'b0;
				(* full_case, parallel_case *)
				case (src_fsm_q)
					1'd0:
						if (!src_ack && src_req_i)
							src_fsm_d = 1'd1;
					1'd1: begin
						src_req = 1'b1;
						src_ack_o = src_ack;
						if (!src_req_i || src_ack)
							src_fsm_d = 1'd0;
					end
					default:
						;
				endcase
			end
			prim_flop_2sync #(.Width(1)) ack_sync(
				.clk_i(clk_src_i),
				.rst_ni(rst_src_ni),
				.d_i(dst_ack),
				.q_o(src_ack)
			);
			always @(posedge clk_src_i or negedge rst_src_ni)
				if (!rst_src_ni)
					src_fsm_q <= 1'd0;
				else
					src_fsm_q <= src_fsm_d;
			always @(*) begin : dst_fsm
				if (_sv2v_0)
					;
				dst_fsm_d = dst_fsm_q;
				dst_req_o = 1'b0;
				dst_ack = 1'b0;
				(* full_case, parallel_case *)
				case (dst_fsm_q)
					1'd0:
						if (dst_req) begin
							dst_req_o = 1'b1;
							if (dst_ack_i)
								dst_fsm_d = 1'd1;
						end
					1'd1: begin
						dst_ack = 1'b1;
						if (!dst_req)
							dst_fsm_d = 1'd0;
					end
					default:
						;
				endcase
			end
			prim_flop_2sync #(.Width(1)) req_sync(
				.clk_i(clk_dst_i),
				.rst_ni(rst_dst_ni),
				.d_i(src_req),
				.q_o(dst_req)
			);
			always @(posedge clk_dst_i or negedge rst_dst_ni)
				if (!rst_dst_ni)
					dst_fsm_q <= 1'd0;
				else
					dst_fsm_q <= dst_fsm_d;
		end
		else begin : gen_nrz_hs_protocol
			reg src_fsm_ns;
			reg src_fsm_cs;
			reg dst_fsm_ns;
			reg dst_fsm_cs;
			reg src_req_d;
			reg src_req_q;
			wire src_ack;
			reg dst_ack_d;
			reg dst_ack_q;
			wire dst_req;
			wire src_handshake;
			wire dst_handshake;
			assign src_handshake = src_req_i & src_ack_o;
			assign dst_handshake = dst_req_o & dst_ack_i;
			prim_flop_2sync #(.Width(1)) req_sync(
				.clk_i(clk_dst_i),
				.rst_ni(rst_dst_ni),
				.d_i(src_req_q),
				.q_o(dst_req)
			);
			prim_flop_2sync #(.Width(1)) ack_sync(
				.clk_i(clk_src_i),
				.rst_ni(rst_src_ni),
				.d_i(dst_ack_q),
				.q_o(src_ack)
			);
			always @(*) begin : src_fsm
				if (_sv2v_0)
					;
				src_fsm_ns = src_fsm_cs;
				src_req_d = src_req_q;
				src_ack_o = 1'b0;
				(* full_case, parallel_case *)
				case (src_fsm_cs)
					1'd0: begin
						src_req_d = src_req_i;
						src_ack_o = src_ack;
						if (src_handshake)
							src_fsm_ns = 1'd1;
					end
					1'd1: begin
						src_req_d = ~src_req_i;
						src_ack_o = ~src_ack;
						if (src_handshake)
							src_fsm_ns = 1'd0;
					end
					default:
						;
				endcase
			end
			always @(*) begin : dst_fsm
				if (_sv2v_0)
					;
				dst_fsm_ns = dst_fsm_cs;
				dst_req_o = 1'b0;
				dst_ack_d = dst_ack_q;
				(* full_case, parallel_case *)
				case (dst_fsm_cs)
					1'd0: begin
						dst_req_o = dst_req;
						dst_ack_d = dst_ack_i;
						if (dst_handshake)
							dst_fsm_ns = 1'd1;
					end
					1'd1: begin
						dst_req_o = ~dst_req;
						dst_ack_d = ~dst_ack_i;
						if (dst_handshake)
							dst_fsm_ns = 1'd0;
					end
					default:
						;
				endcase
			end
			always @(posedge clk_src_i or negedge rst_src_ni)
				if (!rst_src_ni) begin
					src_fsm_cs <= 1'd0;
					src_req_q <= 1'b0;
				end
				else begin
					src_fsm_cs <= src_fsm_ns;
					src_req_q <= src_req_d;
				end
			always @(posedge clk_dst_i or negedge rst_dst_ni)
				if (!rst_dst_ni) begin
					dst_fsm_cs <= 1'd0;
					dst_ack_q <= 1'b0;
				end
				else begin
					dst_fsm_cs <= dst_fsm_ns;
					dst_ack_q <= dst_ack_d;
				end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module prim_fifo_async_simple (
	clk_wr_i,
	rst_wr_ni,
	wvalid_i,
	wready_o,
	wdata_i,
	clk_rd_i,
	rst_rd_ni,
	rvalid_o,
	rready_i,
	rdata_o
);
	parameter [31:0] Width = 16;
	parameter [0:0] EnRstChks = 1'b0;
	parameter [0:0] EnRzHs = 1'b0;
	input wire clk_wr_i;
	input wire rst_wr_ni;
	input wire wvalid_i;
	output wire wready_o;
	input wire [Width - 1:0] wdata_i;
	input wire clk_rd_i;
	input wire rst_rd_ni;
	output wire rvalid_o;
	input wire rready_i;
	output wire [Width - 1:0] rdata_o;
	wire wr_en;
	wire src_req;
	wire src_ack;
	wire pending_d;
	reg pending_q;
	reg not_in_reset_q;
	assign wready_o = !pending_q && not_in_reset_q;
	assign wr_en = wvalid_i && wready_o;
	assign src_req = pending_q || wvalid_i;
	assign pending_d = (src_ack ? 1'b0 : (wr_en ? 1'b1 : pending_q));
	wire dst_req;
	wire dst_ack;
	assign rvalid_o = dst_req;
	assign dst_ack = dst_req && rready_i;
	always @(posedge clk_wr_i or negedge rst_wr_ni)
		if (!rst_wr_ni) begin
			pending_q <= 1'b0;
			not_in_reset_q <= 1'b0;
		end
		else begin
			pending_q <= pending_d;
			not_in_reset_q <= 1'b1;
		end
	prim_sync_reqack #(
		.EnRstChks(EnRstChks),
		.EnRzHs(EnRzHs)
	) u_prim_sync_reqack(
		.clk_src_i(clk_wr_i),
		.rst_src_ni(rst_wr_ni),
		.clk_dst_i(clk_rd_i),
		.rst_dst_ni(rst_rd_ni),
		.req_chk_i(1'b0),
		.src_req_i(src_req),
		.src_ack_o(src_ack),
		.dst_req_o(dst_req),
		.dst_ack_i(dst_ack)
	);
	reg [Width - 1:0] data_q;
	always @(posedge clk_wr_i)
		if (wr_en)
			data_q <= wdata_i;
	assign rdata_o = data_q;
endmodule
module prim_buf (
	in_i,
	out_o
);
	parameter signed [31:0] Width = 1;
	input [Width - 1:0] in_i;
	output wire [Width - 1:0] out_o;
	generate
		if (1) begin : gen_generic
			prim_generic_buf #(.Width(Width)) u_impl_generic(
				.in_i(in_i),
				.out_o(out_o)
			);
		end
	endgenerate
endmodule
module prim_clock_gating (
	clk_i,
	en_i,
	test_en_i,
	clk_o
);
	input clk_i;
	input en_i;
	input test_en_i;
	output wire clk_o;
	parameter integer Impl = 32'sd0;
	generate
		if (Impl == 32'sd0) begin : gen_generic
			prim_generic_clock_gating u_impl_generic(
				.clk_i(clk_i),
				.en_i(en_i),
				.test_en_i(test_en_i),
				.clk_o(clk_o)
			);
		end
		else if (Impl == 32'sd1) begin : gen_xilinx
			prim_xilinx_clock_gating u_impl_xilinx(
				.clk_i(clk_i),
				.en_i(en_i),
				.test_en_i(test_en_i),
				.clk_o(clk_o)
			);
		end
	endgenerate
endmodule
module prim_xilinx_clock_gating (
	clk_i,
	en_i,
	test_en_i,
	clk_o
);
	parameter [0:0] NoFpgaGate = 1'b0;
	parameter [0:0] FpgaBufGlobal = 1'b1;
	input clk_i;
	input en_i;
	input test_en_i;
	output wire clk_o;
	generate
		if (NoFpgaGate) begin : gen_no_gate
			assign clk_o = clk_i;
		end
		else begin : gen_gate
			if (FpgaBufGlobal) begin : gen_bufgce
				BUFGCE #(.SIM_DEVICE("7SERIES")) u_bufgce(
					.I(clk_i),
					.CE(en_i | test_en_i),
					.O(clk_o)
				);
			end
			else begin : gen_bufhce
				BUFHCE u_bufhce(
					.I(clk_i),
					.CE(en_i | test_en_i),
					.O(clk_o)
				);
			end
		end
	endgenerate
endmodule
module prim_fifo_sync (
	clk_i,
	rst_ni,
	clr_i,
	wvalid_i,
	wready_o,
	wdata_i,
	rvalid_o,
	rready_i,
	rdata_o,
	full_o,
	depth_o,
	err_o
);
	parameter [31:0] Width = 16;
	parameter [0:0] Pass = 1'b1;
	parameter [31:0] Depth = 4;
	parameter [0:0] OutputZeroIfEmpty = 1'b1;
	parameter [0:0] Secure = 1'b0;
	function automatic integer prim_util_pkg_vbits;
		input integer value;
		prim_util_pkg_vbits = (value == 1 ? 1 : $clog2(value));
	endfunction
	localparam signed [31:0] DepthW = prim_util_pkg_vbits(Depth + 1);
	input clk_i;
	input rst_ni;
	input clr_i;
	input wvalid_i;
	output wire wready_o;
	input [Width - 1:0] wdata_i;
	output wire rvalid_o;
	input rready_i;
	output wire [Width - 1:0] rdata_o;
	output wire full_o;
	output wire [DepthW - 1:0] depth_o;
	output wire err_o;
	function automatic signed [Width - 1:0] sv2v_cast_62596_signed;
		input reg signed [Width - 1:0] inp;
		sv2v_cast_62596_signed = inp;
	endfunction
	generate
		if (Depth == 0) begin : gen_passthru_fifo
			assign depth_o = 1'b0;
			assign rvalid_o = wvalid_i;
			assign rdata_o = wdata_i;
			assign wready_o = rready_i;
			assign full_o = rready_i;
			wire unused_clr;
			assign unused_clr = clr_i;
			assign err_o = 1'b0;
		end
		else begin : gen_normal_fifo
			localparam [31:0] PtrW = prim_util_pkg_vbits(Depth);
			wire [PtrW - 1:0] fifo_wptr;
			wire [PtrW - 1:0] fifo_rptr;
			wire fifo_incr_wptr;
			wire fifo_incr_rptr;
			wire fifo_empty;
			reg under_rst;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					under_rst <= 1'b1;
				else if (under_rst)
					under_rst <= ~under_rst;
			wire empty;
			assign wready_o = ~full_o & ~under_rst;
			assign rvalid_o = ~empty & ~under_rst;
			prim_fifo_sync_cnt #(
				.Depth(Depth),
				.Secure(Secure)
			) u_fifo_cnt(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.clr_i(clr_i),
				.incr_wptr_i(fifo_incr_wptr),
				.incr_rptr_i(fifo_incr_rptr),
				.wptr_o(fifo_wptr),
				.rptr_o(fifo_rptr),
				.full_o(full_o),
				.empty_o(fifo_empty),
				.depth_o(depth_o),
				.err_o(err_o)
			);
			assign fifo_incr_wptr = (wvalid_i & wready_o) & ~under_rst;
			assign fifo_incr_rptr = (rvalid_o & rready_i) & ~under_rst;
			reg [(Depth * Width) - 1:0] storage;
			wire [Width - 1:0] storage_rdata;
			if (Depth == 1) begin : gen_depth_eq1
				assign storage_rdata = storage[0+:Width];
				always @(posedge clk_i)
					if (fifo_incr_wptr)
						storage[0+:Width] <= wdata_i;
				wire unused_ptrs;
				assign unused_ptrs = ^{fifo_wptr, fifo_rptr};
			end
			else begin : gen_depth_gt1
				assign storage_rdata = storage[fifo_rptr * Width+:Width];
				always @(posedge clk_i)
					if (fifo_incr_wptr)
						storage[fifo_wptr * Width+:Width] <= wdata_i;
			end
			wire [Width - 1:0] rdata_int;
			if (Pass == 1'b1) begin : gen_pass
				assign rdata_int = (fifo_empty && wvalid_i ? wdata_i : storage_rdata);
				assign empty = fifo_empty & ~wvalid_i;
			end
			else begin : gen_nopass
				assign rdata_int = storage_rdata;
				assign empty = fifo_empty;
			end
			if (OutputZeroIfEmpty == 1'b1) begin : gen_output_zero
				assign rdata_o = (empty ? sv2v_cast_62596_signed(0) : rdata_int);
			end
			else begin : gen_no_output_zero
				assign rdata_o = rdata_int;
			end
		end
	endgenerate
endmodule
module prim_fifo_sync_cnt (
	clk_i,
	rst_ni,
	clr_i,
	incr_wptr_i,
	incr_rptr_i,
	wptr_o,
	rptr_o,
	full_o,
	empty_o,
	depth_o,
	err_o
);
	parameter [31:0] Depth = 4;
	parameter [0:0] Secure = 1'b0;
	function automatic integer prim_util_pkg_vbits;
		input integer value;
		prim_util_pkg_vbits = (value == 1 ? 1 : $clog2(value));
	endfunction
	localparam [31:0] PtrW = prim_util_pkg_vbits(Depth);
	localparam [31:0] DepthW = prim_util_pkg_vbits(Depth + 1);
	input clk_i;
	input rst_ni;
	input clr_i;
	input incr_wptr_i;
	input incr_rptr_i;
	output wire [PtrW - 1:0] wptr_o;
	output wire [PtrW - 1:0] rptr_o;
	output wire full_o;
	output wire empty_o;
	output wire [DepthW - 1:0] depth_o;
	output wire err_o;
	localparam [31:0] WrapPtrW = PtrW + 1;
	reg [WrapPtrW - 1:0] wptr_wrap_cnt_q;
	wire [WrapPtrW - 1:0] wptr_wrap_set_cnt;
	reg [WrapPtrW - 1:0] rptr_wrap_cnt_q;
	wire [WrapPtrW - 1:0] rptr_wrap_set_cnt;
	assign wptr_o = wptr_wrap_cnt_q[PtrW - 1:0];
	assign rptr_o = rptr_wrap_cnt_q[PtrW - 1:0];
	wire wptr_wrap_msb;
	wire rptr_wrap_msb;
	assign wptr_wrap_msb = wptr_wrap_cnt_q[WrapPtrW - 1];
	assign rptr_wrap_msb = rptr_wrap_cnt_q[WrapPtrW - 1];
	wire wptr_wrap_set;
	wire rptr_wrap_set;
	function automatic [PtrW - 1:0] sv2v_cast_09B00;
		input reg [PtrW - 1:0] inp;
		sv2v_cast_09B00 = inp;
	endfunction
	assign wptr_wrap_set = incr_wptr_i & (wptr_o == sv2v_cast_09B00(Depth - 1));
	assign rptr_wrap_set = incr_rptr_i & (rptr_o == sv2v_cast_09B00(Depth - 1));
	assign wptr_wrap_set_cnt = {~wptr_wrap_msb, {WrapPtrW - 1 {1'b0}}};
	assign rptr_wrap_set_cnt = {~rptr_wrap_msb, {WrapPtrW - 1 {1'b0}}};
	assign full_o = wptr_wrap_cnt_q == (rptr_wrap_cnt_q ^ {1'b1, {WrapPtrW - 1 {1'b0}}});
	assign empty_o = wptr_wrap_cnt_q == rptr_wrap_cnt_q;
	function automatic [DepthW - 1:0] sv2v_cast_2DA09;
		input reg [DepthW - 1:0] inp;
		sv2v_cast_2DA09 = inp;
	endfunction
	assign depth_o = (full_o ? sv2v_cast_2DA09(Depth) : (wptr_wrap_msb == rptr_wrap_msb ? sv2v_cast_2DA09(wptr_o) - sv2v_cast_2DA09(rptr_o) : (sv2v_cast_2DA09(Depth) - sv2v_cast_2DA09(rptr_o)) + sv2v_cast_2DA09(wptr_o)));
	function automatic [WrapPtrW - 1:0] sv2v_cast_00CF8;
		input reg [WrapPtrW - 1:0] inp;
		sv2v_cast_00CF8 = inp;
	endfunction
	generate
		if (Secure) begin : gen_secure_ptrs
			wire wptr_err;
			prim_count #(.Width(WrapPtrW)) u_wptr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.clr_i(clr_i),
				.set_i(wptr_wrap_set),
				.set_cnt_i(wptr_wrap_set_cnt),
				.incr_en_i(incr_wptr_i),
				.decr_en_i(1'b0),
				.step_i(sv2v_cast_00CF8(1'b1)),
				.commit_i(1'b1),
				.cnt_o(wptr_wrap_cnt_q),
				.cnt_after_commit_o(),
				.err_o(wptr_err)
			);
			wire rptr_err;
			prim_count #(.Width(WrapPtrW)) u_rptr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.clr_i(clr_i),
				.set_i(rptr_wrap_set),
				.set_cnt_i(rptr_wrap_set_cnt),
				.incr_en_i(incr_rptr_i),
				.decr_en_i(1'b0),
				.step_i(sv2v_cast_00CF8(1'b1)),
				.commit_i(1'b1),
				.cnt_o(rptr_wrap_cnt_q),
				.cnt_after_commit_o(),
				.err_o(rptr_err)
			);
			assign err_o = wptr_err | rptr_err;
		end
		else begin : gen_normal_ptrs
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					wptr_wrap_cnt_q <= {WrapPtrW {1'b0}};
				else if (clr_i)
					wptr_wrap_cnt_q <= {WrapPtrW {1'b0}};
				else if (wptr_wrap_set)
					wptr_wrap_cnt_q <= wptr_wrap_set_cnt;
				else if (incr_wptr_i)
					wptr_wrap_cnt_q <= wptr_wrap_cnt_q + {{WrapPtrW - 1 {1'b0}}, 1'b1};
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					rptr_wrap_cnt_q <= {WrapPtrW {1'b0}};
				else if (clr_i)
					rptr_wrap_cnt_q <= {WrapPtrW {1'b0}};
				else if (rptr_wrap_set)
					rptr_wrap_cnt_q <= rptr_wrap_set_cnt;
				else if (incr_rptr_i)
					rptr_wrap_cnt_q <= rptr_wrap_cnt_q + {{WrapPtrW - 1 {1'b0}}, 1'b1};
			assign err_o = 1'sb0;
		end
	endgenerate
endmodule
module prim_clock_gating_sync (
	clk_i,
	rst_ni,
	test_en_i,
	async_en_i,
	en_o,
	clk_o
);
	input clk_i;
	input rst_ni;
	input test_en_i;
	input async_en_i;
	output wire en_o;
	output wire clk_o;
	prim_flop_2sync #(.Width(1)) i_sync(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.d_i(async_en_i),
		.q_o(en_o)
	);
	prim_clock_gating i_cg(
		.clk_i(clk_i),
		.en_i(en_o),
		.test_en_i(test_en_i),
		.clk_o(clk_o)
	);
endmodule
module ibex_alu (
	operator_i,
	operand_a_i,
	operand_b_i,
	instr_first_cycle_i,
	multdiv_operand_a_i,
	multdiv_operand_b_i,
	multdiv_sel_i,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	adder_result_o,
	adder_result_ext_o,
	result_o,
	comparison_result_o,
	is_equal_result_o
);
	reg _sv2v_0;
	parameter integer RV32B = 32'sd0;
	input wire [6:0] operator_i;
	input wire [31:0] operand_a_i;
	input wire [31:0] operand_b_i;
	input wire instr_first_cycle_i;
	input wire [32:0] multdiv_operand_a_i;
	input wire [32:0] multdiv_operand_b_i;
	input wire multdiv_sel_i;
	input wire [63:0] imd_val_q_i;
	output reg [63:0] imd_val_d_o;
	output reg [1:0] imd_val_we_o;
	output wire [31:0] adder_result_o;
	output wire [33:0] adder_result_ext_o;
	output reg [31:0] result_o;
	output wire comparison_result_o;
	output wire is_equal_result_o;
	wire [31:0] operand_a_rev;
	wire [32:0] operand_b_neg;
	genvar _gv_k_1;
	generate
		for (_gv_k_1 = 0; _gv_k_1 < 32; _gv_k_1 = _gv_k_1 + 1) begin : gen_rev_operand_a
			localparam k = _gv_k_1;
			assign operand_a_rev[k] = operand_a_i[31 - k];
		end
	endgenerate
	reg adder_op_a_shift1;
	reg adder_op_a_shift2;
	reg adder_op_a_shift3;
	reg adder_op_b_negate;
	reg [32:0] adder_in_a;
	reg [32:0] adder_in_b;
	wire [31:0] adder_result;
	always @(*) begin
		if (_sv2v_0)
			;
		adder_op_a_shift1 = 1'b0;
		adder_op_a_shift2 = 1'b0;
		adder_op_a_shift3 = 1'b0;
		adder_op_b_negate = 1'b0;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd1, 7'd29, 7'd30, 7'd27, 7'd28, 7'd25, 7'd26, 7'd43, 7'd44, 7'd31, 7'd32, 7'd33, 7'd34: adder_op_b_negate = 1'b1;
			7'd22:
				if (RV32B != 32'sd0)
					adder_op_a_shift1 = 1'b1;
			7'd23:
				if (RV32B != 32'sd0)
					adder_op_a_shift2 = 1'b1;
			7'd24:
				if (RV32B != 32'sd0)
					adder_op_a_shift3 = 1'b1;
			default:
				;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			multdiv_sel_i: adder_in_a = multdiv_operand_a_i;
			adder_op_a_shift1: adder_in_a = {operand_a_i[30:0], 2'b01};
			adder_op_a_shift2: adder_in_a = {operand_a_i[29:0], 3'b001};
			adder_op_a_shift3: adder_in_a = {operand_a_i[28:0], 4'b0001};
			default: adder_in_a = {operand_a_i, 1'b1};
		endcase
	end
	assign operand_b_neg = {operand_b_i, 1'b0} ^ {33 {1'b1}};
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			multdiv_sel_i: adder_in_b = multdiv_operand_b_i;
			adder_op_b_negate: adder_in_b = operand_b_neg;
			default: adder_in_b = {operand_b_i, 1'b0};
		endcase
	end
	assign adder_result_ext_o = $unsigned(adder_in_a) + $unsigned(adder_in_b);
	assign adder_result = adder_result_ext_o[32:1];
	assign adder_result_o = adder_result;
	wire is_equal;
	reg is_greater_equal;
	reg cmp_signed;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd27, 7'd25, 7'd43, 7'd31, 7'd33: cmp_signed = 1'b1;
			default: cmp_signed = 1'b0;
		endcase
	end
	assign is_equal = adder_result == 32'b00000000000000000000000000000000;
	assign is_equal_result_o = is_equal;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((operand_a_i[31] ^ operand_b_i[31]) == 1'b0)
			is_greater_equal = adder_result[31] == 1'b0;
		else
			is_greater_equal = operand_a_i[31] ^ cmp_signed;
	end
	reg cmp_result;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd29: cmp_result = is_equal;
			7'd30: cmp_result = ~is_equal;
			7'd27, 7'd28, 7'd33, 7'd34: cmp_result = is_greater_equal;
			7'd25, 7'd26, 7'd31, 7'd32, 7'd43, 7'd44: cmp_result = ~is_greater_equal;
			default: cmp_result = is_equal;
		endcase
	end
	assign comparison_result_o = cmp_result;
	reg shift_left;
	wire shift_ones;
	wire shift_arith;
	wire shift_funnel;
	wire shift_sbmode;
	reg [5:0] shift_amt;
	wire [5:0] shift_amt_compl;
	reg [31:0] shift_operand;
	reg signed [32:0] shift_result_ext_signed;
	reg [32:0] shift_result_ext;
	reg unused_shift_result_ext;
	reg [31:0] shift_result;
	reg [31:0] shift_result_rev;
	wire bfp_op;
	wire [4:0] bfp_len;
	wire [4:0] bfp_off;
	wire [31:0] bfp_mask;
	wire [31:0] bfp_mask_rev;
	wire [31:0] bfp_result;
	assign bfp_op = (RV32B != 32'sd0 ? operator_i == 7'd55 : 1'b0);
	assign bfp_len = {~(|operand_b_i[27:24]), operand_b_i[27:24]};
	assign bfp_off = operand_b_i[20:16];
	assign bfp_mask = (RV32B != 32'sd0 ? ~(32'hffffffff << bfp_len) : {32 {1'sb0}});
	genvar _gv_i_1;
	generate
		for (_gv_i_1 = 0; _gv_i_1 < 32; _gv_i_1 = _gv_i_1 + 1) begin : gen_rev_bfp_mask
			localparam i = _gv_i_1;
			assign bfp_mask_rev[i] = bfp_mask[31 - i];
		end
	endgenerate
	assign bfp_result = (RV32B != 32'sd0 ? (~shift_result & operand_a_i) | ((operand_b_i & bfp_mask) << bfp_off) : {32 {1'sb0}});
	wire [1:1] sv2v_tmp_BA5F8;
	assign sv2v_tmp_BA5F8 = operand_b_i[5] & shift_funnel;
	always @(*) shift_amt[5] = sv2v_tmp_BA5F8;
	assign shift_amt_compl = 32 - operand_b_i[4:0];
	always @(*) begin
		if (_sv2v_0)
			;
		if (bfp_op)
			shift_amt[4:0] = bfp_off;
		else
			shift_amt[4:0] = (instr_first_cycle_i ? (operand_b_i[5] && shift_funnel ? shift_amt_compl[4:0] : operand_b_i[4:0]) : (operand_b_i[5] && shift_funnel ? operand_b_i[4:0] : shift_amt_compl[4:0]));
	end
	assign shift_sbmode = (RV32B != 32'sd0 ? ((operator_i == 7'd49) | (operator_i == 7'd50)) | (operator_i == 7'd51) : 1'b0);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd10: shift_left = 1'b1;
			7'd12: shift_left = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b1 : 1'b0);
			7'd55: shift_left = (RV32B != 32'sd0 ? 1'b1 : 1'b0);
			7'd14: shift_left = (RV32B != 32'sd0 ? instr_first_cycle_i : 0);
			7'd13: shift_left = (RV32B != 32'sd0 ? ~instr_first_cycle_i : 0);
			7'd47: shift_left = (RV32B != 32'sd0 ? (shift_amt[5] ? ~instr_first_cycle_i : instr_first_cycle_i) : 1'b0);
			7'd48: shift_left = (RV32B != 32'sd0 ? (shift_amt[5] ? instr_first_cycle_i : ~instr_first_cycle_i) : 1'b0);
			default: shift_left = 1'b0;
		endcase
		if (shift_sbmode)
			shift_left = 1'b1;
	end
	assign shift_arith = operator_i == 7'd8;
	assign shift_ones = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? (operator_i == 7'd12) | (operator_i == 7'd11) : 1'b0);
	assign shift_funnel = (RV32B != 32'sd0 ? (operator_i == 7'd47) | (operator_i == 7'd48) : 1'b0);
	always @(*) begin
		if (_sv2v_0)
			;
		if (RV32B == 32'sd0)
			shift_operand = (shift_left ? operand_a_rev : operand_a_i);
		else
			(* full_case, parallel_case *)
			case (1'b1)
				bfp_op: shift_operand = bfp_mask_rev;
				shift_sbmode: shift_operand = 32'h80000000;
				default: shift_operand = (shift_left ? operand_a_rev : operand_a_i);
			endcase
		shift_result_ext_signed = $signed({shift_ones | (shift_arith & shift_operand[31]), shift_operand}) >>> shift_amt[4:0];
		shift_result_ext = $unsigned(shift_result_ext_signed);
		shift_result = shift_result_ext[31:0];
		unused_shift_result_ext = shift_result_ext[32];
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				shift_result_rev[i] = shift_result[31 - i];
		end
		shift_result = (shift_left ? shift_result_rev : shift_result);
	end
	wire bwlogic_or;
	wire bwlogic_and;
	wire [31:0] bwlogic_operand_b;
	wire [31:0] bwlogic_or_result;
	wire [31:0] bwlogic_and_result;
	wire [31:0] bwlogic_xor_result;
	reg [31:0] bwlogic_result;
	reg bwlogic_op_b_negate;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd5, 7'd6, 7'd7: bwlogic_op_b_negate = (RV32B != 32'sd0 ? 1'b1 : 1'b0);
			7'd46: bwlogic_op_b_negate = (RV32B != 32'sd0 ? ~instr_first_cycle_i : 1'b0);
			default: bwlogic_op_b_negate = 1'b0;
		endcase
	end
	assign bwlogic_operand_b = (bwlogic_op_b_negate ? operand_b_neg[32:1] : operand_b_i);
	assign bwlogic_or_result = operand_a_i | bwlogic_operand_b;
	assign bwlogic_and_result = operand_a_i & bwlogic_operand_b;
	assign bwlogic_xor_result = operand_a_i ^ bwlogic_operand_b;
	assign bwlogic_or = (operator_i == 7'd3) | (operator_i == 7'd6);
	assign bwlogic_and = (operator_i == 7'd4) | (operator_i == 7'd7);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (1'b1)
			bwlogic_or: bwlogic_result = bwlogic_or_result;
			bwlogic_and: bwlogic_result = bwlogic_and_result;
			default: bwlogic_result = bwlogic_xor_result;
		endcase
	end
	wire [5:0] bitcnt_result;
	wire [31:0] minmax_result;
	reg [31:0] pack_result;
	wire [31:0] sext_result;
	reg [31:0] singlebit_result;
	reg [31:0] rev_result;
	reg [31:0] shuffle_result;
	wire [31:0] xperm_result;
	reg [31:0] butterfly_result;
	reg [31:0] invbutterfly_result;
	reg [31:0] clmul_result;
	reg [31:0] multicycle_result;
	generate
		if (RV32B != 32'sd0) begin : g_alu_rvb
			wire zbe_op;
			wire bitcnt_ctz;
			wire bitcnt_clz;
			wire bitcnt_cz;
			reg [31:0] bitcnt_bits;
			wire [31:0] bitcnt_mask_op;
			reg [31:0] bitcnt_bit_mask;
			reg [191:0] bitcnt_partial;
			wire [31:0] bitcnt_partial_lsb_d;
			wire [31:0] bitcnt_partial_msb_d;
			assign bitcnt_ctz = operator_i == 7'd41;
			assign bitcnt_clz = operator_i == 7'd40;
			assign bitcnt_cz = bitcnt_ctz | bitcnt_clz;
			assign bitcnt_result = bitcnt_partial[0+:6];
			assign bitcnt_mask_op = (bitcnt_clz ? operand_a_rev : operand_a_i);
			always @(*) begin
				if (_sv2v_0)
					;
				bitcnt_bit_mask = bitcnt_mask_op;
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 1);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 2);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 4);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 8);
				bitcnt_bit_mask = bitcnt_bit_mask | (bitcnt_bit_mask << 16);
				bitcnt_bit_mask = ~bitcnt_bit_mask;
			end
			assign zbe_op = (operator_i == 7'd53) | (operator_i == 7'd54);
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (1'b1)
					zbe_op: bitcnt_bits = operand_b_i;
					bitcnt_cz: bitcnt_bits = bitcnt_bit_mask & ~bitcnt_mask_op;
					default: bitcnt_bits = operand_a_i;
				endcase
			end
			always @(*) begin
				if (_sv2v_0)
					;
				bitcnt_partial = {32 {6'b000000}};
				begin : sv2v_autoblock_2
					reg [31:0] i;
					for (i = 1; i < 32; i = i + 2)
						bitcnt_partial[(31 - i) * 6+:6] = {5'h00, bitcnt_bits[i]} + {5'h00, bitcnt_bits[i - 1]};
				end
				begin : sv2v_autoblock_3
					reg [31:0] i;
					for (i = 3; i < 32; i = i + 4)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(33 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_4
					reg [31:0] i;
					for (i = 7; i < 32; i = i + 8)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(35 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_5
					reg [31:0] i;
					for (i = 15; i < 32; i = i + 16)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(39 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				bitcnt_partial[0+:6] = bitcnt_partial[96+:6] + bitcnt_partial[0+:6];
				bitcnt_partial[48+:6] = bitcnt_partial[96+:6] + bitcnt_partial[48+:6];
				begin : sv2v_autoblock_6
					reg [31:0] i;
					for (i = 11; i < 32; i = i + 8)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(35 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				begin : sv2v_autoblock_7
					reg [31:0] i;
					for (i = 5; i < 32; i = i + 4)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(33 - i) * 6+:6] + bitcnt_partial[(31 - i) * 6+:6];
				end
				bitcnt_partial[186+:6] = {5'h00, bitcnt_bits[0]};
				begin : sv2v_autoblock_8
					reg [31:0] i;
					for (i = 2; i < 32; i = i + 2)
						bitcnt_partial[(31 - i) * 6+:6] = bitcnt_partial[(32 - i) * 6+:6] + {5'h00, bitcnt_bits[i]};
				end
			end
			assign minmax_result = (cmp_result ? operand_a_i : operand_b_i);
			wire packu;
			wire packh;
			assign packu = operator_i == 7'd36;
			assign packh = operator_i == 7'd37;
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (1'b1)
					packu: pack_result = {operand_b_i[31:16], operand_a_i[31:16]};
					packh: pack_result = {16'h0000, operand_b_i[7:0], operand_a_i[7:0]};
					default: pack_result = {operand_b_i[15:0], operand_a_i[15:0]};
				endcase
			end
			assign sext_result = (operator_i == 7'd38 ? {{24 {operand_a_i[7]}}, operand_a_i[7:0]} : {{16 {operand_a_i[15]}}, operand_a_i[15:0]});
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (operator_i)
					7'd49: singlebit_result = operand_a_i | shift_result;
					7'd50: singlebit_result = operand_a_i & ~shift_result;
					7'd51: singlebit_result = operand_a_i ^ shift_result;
					default: singlebit_result = {31'h00000000, shift_result[0]};
				endcase
			end
			wire [4:0] zbp_shift_amt;
			wire gorc_op;
			assign gorc_op = operator_i == 7'd16;
			assign zbp_shift_amt[2:0] = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? shift_amt[2:0] : {3 {shift_amt[0]}});
			assign zbp_shift_amt[4:3] = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? shift_amt[4:3] : {2 {shift_amt[3]}});
			always @(*) begin
				if (_sv2v_0)
					;
				rev_result = operand_a_i;
				if (zbp_shift_amt[0])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h55555555) << 1)) | ((rev_result & 32'haaaaaaaa) >> 1);
				if (zbp_shift_amt[1])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h33333333) << 2)) | ((rev_result & 32'hcccccccc) >> 2);
				if (zbp_shift_amt[2])
					rev_result = ((gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h0f0f0f0f) << 4)) | ((rev_result & 32'hf0f0f0f0) >> 4);
				if (zbp_shift_amt[3])
					rev_result = ((((RV32B == 32'sd2) || (RV32B == 32'sd3)) && gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h00ff00ff) << 8)) | ((rev_result & 32'hff00ff00) >> 8);
				if (zbp_shift_amt[4])
					rev_result = ((((RV32B == 32'sd2) || (RV32B == 32'sd3)) && gorc_op ? rev_result : 32'h00000000) | ((rev_result & 32'h0000ffff) << 16)) | ((rev_result & 32'hffff0000) >> 16);
			end
			wire crc_hmode;
			wire crc_bmode;
			wire [31:0] clmul_result_rev;
			if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin : gen_alu_rvb_otearlgrey_full
				localparam [127:0] SHUFFLE_MASK_L = 128'h00ff00000f000f003030303044444444;
				localparam [127:0] SHUFFLE_MASK_R = 128'h0000ff0000f000f00c0c0c0c22222222;
				localparam [127:0] FLIP_MASK_L = 128'h22001100004400004411000011000000;
				localparam [127:0] FLIP_MASK_R = 128'h00880044000022000000882200000088;
				wire [31:0] SHUFFLE_MASK_NOT [0:3];
				genvar _gv_i_2;
				for (_gv_i_2 = 0; _gv_i_2 < 4; _gv_i_2 = _gv_i_2 + 1) begin : gen_shuffle_mask_not
					localparam i = _gv_i_2;
					assign SHUFFLE_MASK_NOT[i] = ~(SHUFFLE_MASK_L[(3 - i) * 32+:32] | SHUFFLE_MASK_R[(3 - i) * 32+:32]);
				end
				wire shuffle_flip;
				assign shuffle_flip = operator_i == 7'd18;
				reg [3:0] shuffle_mode;
				always @(*) begin
					if (_sv2v_0)
						;
					shuffle_result = operand_a_i;
					if (shuffle_flip) begin
						shuffle_mode[3] = shift_amt[0];
						shuffle_mode[2] = shift_amt[1];
						shuffle_mode[1] = shift_amt[2];
						shuffle_mode[0] = shift_amt[3];
					end
					else
						shuffle_mode = shift_amt[3:0];
					if (shuffle_flip)
						shuffle_result = ((((((((shuffle_result & 32'h88224411) | ((shuffle_result << 6) & FLIP_MASK_L[96+:32])) | ((shuffle_result >> 6) & FLIP_MASK_R[96+:32])) | ((shuffle_result << 9) & FLIP_MASK_L[64+:32])) | ((shuffle_result >> 9) & FLIP_MASK_R[64+:32])) | ((shuffle_result << 15) & FLIP_MASK_L[32+:32])) | ((shuffle_result >> 15) & FLIP_MASK_R[32+:32])) | ((shuffle_result << 21) & FLIP_MASK_L[0+:32])) | ((shuffle_result >> 21) & FLIP_MASK_R[0+:32]);
					if (shuffle_mode[3])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[0]) | (((shuffle_result << 8) & SHUFFLE_MASK_L[96+:32]) | ((shuffle_result >> 8) & SHUFFLE_MASK_R[96+:32]));
					if (shuffle_mode[2])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[1]) | (((shuffle_result << 4) & SHUFFLE_MASK_L[64+:32]) | ((shuffle_result >> 4) & SHUFFLE_MASK_R[64+:32]));
					if (shuffle_mode[1])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[2]) | (((shuffle_result << 2) & SHUFFLE_MASK_L[32+:32]) | ((shuffle_result >> 2) & SHUFFLE_MASK_R[32+:32]));
					if (shuffle_mode[0])
						shuffle_result = (shuffle_result & SHUFFLE_MASK_NOT[3]) | (((shuffle_result << 1) & SHUFFLE_MASK_L[0+:32]) | ((shuffle_result >> 1) & SHUFFLE_MASK_R[0+:32]));
					if (shuffle_flip)
						shuffle_result = ((((((((shuffle_result & 32'h88224411) | ((shuffle_result << 6) & FLIP_MASK_L[96+:32])) | ((shuffle_result >> 6) & FLIP_MASK_R[96+:32])) | ((shuffle_result << 9) & FLIP_MASK_L[64+:32])) | ((shuffle_result >> 9) & FLIP_MASK_R[64+:32])) | ((shuffle_result << 15) & FLIP_MASK_L[32+:32])) | ((shuffle_result >> 15) & FLIP_MASK_R[32+:32])) | ((shuffle_result << 21) & FLIP_MASK_L[0+:32])) | ((shuffle_result >> 21) & FLIP_MASK_R[0+:32]);
				end
				wire [23:0] sel_n;
				wire [7:0] vld_n;
				wire [7:0] sel_b;
				wire [3:0] vld_b;
				wire [1:0] sel_h;
				wire [1:0] vld_h;
				genvar _gv_i_3;
				for (_gv_i_3 = 0; _gv_i_3 < 8; _gv_i_3 = _gv_i_3 + 1) begin : gen_sel_vld_n
					localparam i = _gv_i_3;
					assign sel_n[i * 3+:3] = operand_b_i[i * 4+:3];
					assign vld_n[i] = ~|operand_b_i[(i * 4) + 3+:1];
				end
				genvar _gv_i_4;
				for (_gv_i_4 = 0; _gv_i_4 < 4; _gv_i_4 = _gv_i_4 + 1) begin : gen_sel_vld_b
					localparam i = _gv_i_4;
					assign sel_b[i * 2+:2] = operand_b_i[i * 8+:2];
					assign vld_b[i] = ~|operand_b_i[(i * 8) + 2+:6];
				end
				genvar _gv_i_5;
				for (_gv_i_5 = 0; _gv_i_5 < 2; _gv_i_5 = _gv_i_5 + 1) begin : gen_sel_vld_h
					localparam i = _gv_i_5;
					assign sel_h[i+:1] = operand_b_i[i * 16+:1];
					assign vld_h[i] = ~|operand_b_i[(i * 16) + 1+:15];
				end
				reg [23:0] sel;
				reg [7:0] vld;
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (operator_i)
						7'd19: begin
							sel = sel_n;
							vld = vld_n;
						end
						7'd20: begin : sv2v_autoblock_9
							reg signed [31:0] b;
							for (b = 0; b < 4; b = b + 1)
								begin
									sel[((b * 2) + 0) * 3+:3] = {sel_b[b * 2+:2], 1'b0};
									sel[((b * 2) + 1) * 3+:3] = {sel_b[b * 2+:2], 1'b1};
									vld[b * 2+:2] = {2 {vld_b[b]}};
								end
						end
						7'd21: begin : sv2v_autoblock_10
							reg signed [31:0] h;
							for (h = 0; h < 2; h = h + 1)
								begin
									sel[((h * 4) + 0) * 3+:3] = {sel_h[h+:1], 2'b00};
									sel[((h * 4) + 1) * 3+:3] = {sel_h[h+:1], 2'b01};
									sel[((h * 4) + 2) * 3+:3] = {sel_h[h+:1], 2'b10};
									sel[((h * 4) + 3) * 3+:3] = {sel_h[h+:1], 2'b11};
									vld[h * 4+:4] = {4 {vld_h[h]}};
								end
						end
						default: begin
							sel = sel_n;
							vld = 1'sb0;
						end
					endcase
				end
				wire [31:0] val_n;
				wire [31:0] xperm_n;
				assign val_n = operand_a_i;
				genvar _gv_i_6;
				for (_gv_i_6 = 0; _gv_i_6 < 8; _gv_i_6 = _gv_i_6 + 1) begin : gen_xperm_n
					localparam i = _gv_i_6;
					assign xperm_n[i * 4+:4] = (vld[i] ? val_n[sel[i * 3+:3] * 4+:4] : {4 {1'sb0}});
				end
				assign xperm_result = xperm_n;
				wire clmul_rmode;
				wire clmul_hmode;
				reg [31:0] clmul_op_a;
				reg [31:0] clmul_op_b;
				wire [31:0] operand_b_rev;
				wire [31:0] clmul_and_stage [0:31];
				wire [31:0] clmul_xor_stage1 [0:15];
				wire [31:0] clmul_xor_stage2 [0:7];
				wire [31:0] clmul_xor_stage3 [0:3];
				wire [31:0] clmul_xor_stage4 [0:1];
				wire [31:0] clmul_result_raw;
				genvar _gv_i_7;
				for (_gv_i_7 = 0; _gv_i_7 < 32; _gv_i_7 = _gv_i_7 + 1) begin : gen_rev_operand_b
					localparam i = _gv_i_7;
					assign operand_b_rev[i] = operand_b_i[31 - i];
				end
				assign clmul_rmode = operator_i == 7'd57;
				assign clmul_hmode = operator_i == 7'd58;
				localparam [31:0] CRC32_POLYNOMIAL = 32'h04c11db7;
				localparam [31:0] CRC32_MU_REV = 32'hf7011641;
				localparam [31:0] CRC32C_POLYNOMIAL = 32'h1edc6f41;
				localparam [31:0] CRC32C_MU_REV = 32'hdea713f1;
				wire crc_op;
				wire crc_cpoly;
				reg [31:0] crc_operand;
				wire [31:0] crc_poly;
				wire [31:0] crc_mu_rev;
				assign crc_op = (((((operator_i == 7'd64) | (operator_i == 7'd63)) | (operator_i == 7'd62)) | (operator_i == 7'd61)) | (operator_i == 7'd60)) | (operator_i == 7'd59);
				assign crc_cpoly = ((operator_i == 7'd64) | (operator_i == 7'd62)) | (operator_i == 7'd60);
				assign crc_hmode = (operator_i == 7'd61) | (operator_i == 7'd62);
				assign crc_bmode = (operator_i == 7'd59) | (operator_i == 7'd60);
				assign crc_poly = (crc_cpoly ? CRC32C_POLYNOMIAL : CRC32_POLYNOMIAL);
				assign crc_mu_rev = (crc_cpoly ? CRC32C_MU_REV : CRC32_MU_REV);
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (1'b1)
						crc_bmode: crc_operand = {operand_a_i[7:0], 24'h000000};
						crc_hmode: crc_operand = {operand_a_i[15:0], 16'h0000};
						default: crc_operand = operand_a_i;
					endcase
				end
				always @(*) begin
					if (_sv2v_0)
						;
					if (crc_op) begin
						clmul_op_a = (instr_first_cycle_i ? crc_operand : imd_val_q_i[32+:32]);
						clmul_op_b = (instr_first_cycle_i ? crc_mu_rev : crc_poly);
					end
					else begin
						clmul_op_a = (clmul_rmode | clmul_hmode ? operand_a_rev : operand_a_i);
						clmul_op_b = (clmul_rmode | clmul_hmode ? operand_b_rev : operand_b_i);
					end
				end
				genvar _gv_i_8;
				for (_gv_i_8 = 0; _gv_i_8 < 32; _gv_i_8 = _gv_i_8 + 1) begin : gen_clmul_and_op
					localparam i = _gv_i_8;
					assign clmul_and_stage[i] = (clmul_op_b[i] ? clmul_op_a << i : {32 {1'sb0}});
				end
				genvar _gv_i_9;
				for (_gv_i_9 = 0; _gv_i_9 < 16; _gv_i_9 = _gv_i_9 + 1) begin : gen_clmul_xor_op_l1
					localparam i = _gv_i_9;
					assign clmul_xor_stage1[i] = clmul_and_stage[2 * i] ^ clmul_and_stage[(2 * i) + 1];
				end
				genvar _gv_i_10;
				for (_gv_i_10 = 0; _gv_i_10 < 8; _gv_i_10 = _gv_i_10 + 1) begin : gen_clmul_xor_op_l2
					localparam i = _gv_i_10;
					assign clmul_xor_stage2[i] = clmul_xor_stage1[2 * i] ^ clmul_xor_stage1[(2 * i) + 1];
				end
				genvar _gv_i_11;
				for (_gv_i_11 = 0; _gv_i_11 < 4; _gv_i_11 = _gv_i_11 + 1) begin : gen_clmul_xor_op_l3
					localparam i = _gv_i_11;
					assign clmul_xor_stage3[i] = clmul_xor_stage2[2 * i] ^ clmul_xor_stage2[(2 * i) + 1];
				end
				genvar _gv_i_12;
				for (_gv_i_12 = 0; _gv_i_12 < 2; _gv_i_12 = _gv_i_12 + 1) begin : gen_clmul_xor_op_l4
					localparam i = _gv_i_12;
					assign clmul_xor_stage4[i] = clmul_xor_stage3[2 * i] ^ clmul_xor_stage3[(2 * i) + 1];
				end
				assign clmul_result_raw = clmul_xor_stage4[0] ^ clmul_xor_stage4[1];
				genvar _gv_i_13;
				for (_gv_i_13 = 0; _gv_i_13 < 32; _gv_i_13 = _gv_i_13 + 1) begin : gen_rev_clmul_result
					localparam i = _gv_i_13;
					assign clmul_result_rev[i] = clmul_result_raw[31 - i];
				end
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (1'b1)
						clmul_rmode: clmul_result = clmul_result_rev;
						clmul_hmode: clmul_result = {1'b0, clmul_result_rev[31:1]};
						default: clmul_result = clmul_result_raw;
					endcase
				end
			end
			else begin : gen_alu_rvb_not_otearlgrey_full
				wire [32:1] sv2v_tmp_4A308;
				assign sv2v_tmp_4A308 = 1'sb0;
				always @(*) shuffle_result = sv2v_tmp_4A308;
				assign xperm_result = 1'sb0;
				wire [32:1] sv2v_tmp_31DA6;
				assign sv2v_tmp_31DA6 = 1'sb0;
				always @(*) clmul_result = sv2v_tmp_31DA6;
				assign clmul_result_rev = 1'sb0;
				assign crc_bmode = 1'sb0;
				assign crc_hmode = 1'sb0;
			end
			if (RV32B == 32'sd3) begin : gen_alu_rvb_full
				reg [191:0] bitcnt_partial_q;
				genvar _gv_i_14;
				for (_gv_i_14 = 0; _gv_i_14 < 32; _gv_i_14 = _gv_i_14 + 1) begin : gen_bitcnt_reg_in_lsb
					localparam i = _gv_i_14;
					assign bitcnt_partial_lsb_d[i] = bitcnt_partial[(31 - i) * 6];
				end
				genvar _gv_i_15;
				for (_gv_i_15 = 0; _gv_i_15 < 16; _gv_i_15 = _gv_i_15 + 1) begin : gen_bitcnt_reg_in_b1
					localparam i = _gv_i_15;
					assign bitcnt_partial_msb_d[i] = bitcnt_partial[((31 - ((2 * i) + 1)) * 6) + 1];
				end
				genvar _gv_i_16;
				for (_gv_i_16 = 0; _gv_i_16 < 8; _gv_i_16 = _gv_i_16 + 1) begin : gen_bitcnt_reg_in_b2
					localparam i = _gv_i_16;
					assign bitcnt_partial_msb_d[16 + i] = bitcnt_partial[((31 - ((4 * i) + 3)) * 6) + 2];
				end
				genvar _gv_i_17;
				for (_gv_i_17 = 0; _gv_i_17 < 4; _gv_i_17 = _gv_i_17 + 1) begin : gen_bitcnt_reg_in_b3
					localparam i = _gv_i_17;
					assign bitcnt_partial_msb_d[24 + i] = bitcnt_partial[((31 - ((8 * i) + 7)) * 6) + 3];
				end
				genvar _gv_i_18;
				for (_gv_i_18 = 0; _gv_i_18 < 2; _gv_i_18 = _gv_i_18 + 1) begin : gen_bitcnt_reg_in_b4
					localparam i = _gv_i_18;
					assign bitcnt_partial_msb_d[28 + i] = bitcnt_partial[((31 - ((16 * i) + 15)) * 6) + 4];
				end
				assign bitcnt_partial_msb_d[30] = bitcnt_partial[5];
				assign bitcnt_partial_msb_d[31] = 1'b0;
				always @(*) begin
					if (_sv2v_0)
						;
					bitcnt_partial_q = {32 {6'b000000}};
					begin : sv2v_autoblock_11
						reg [31:0] i;
						for (i = 0; i < 32; i = i + 1)
							begin : gen_bitcnt_reg_out_lsb
								bitcnt_partial_q[(31 - i) * 6] = imd_val_q_i[32 + i];
							end
					end
					begin : sv2v_autoblock_12
						reg [31:0] i;
						for (i = 0; i < 16; i = i + 1)
							begin : gen_bitcnt_reg_out_b1
								bitcnt_partial_q[((31 - ((2 * i) + 1)) * 6) + 1] = imd_val_q_i[0 + i];
							end
					end
					begin : sv2v_autoblock_13
						reg [31:0] i;
						for (i = 0; i < 8; i = i + 1)
							begin : gen_bitcnt_reg_out_b2
								bitcnt_partial_q[((31 - ((4 * i) + 3)) * 6) + 2] = imd_val_q_i[16 + i];
							end
					end
					begin : sv2v_autoblock_14
						reg [31:0] i;
						for (i = 0; i < 4; i = i + 1)
							begin : gen_bitcnt_reg_out_b3
								bitcnt_partial_q[((31 - ((8 * i) + 7)) * 6) + 3] = imd_val_q_i[24 + i];
							end
					end
					begin : sv2v_autoblock_15
						reg [31:0] i;
						for (i = 0; i < 2; i = i + 1)
							begin : gen_bitcnt_reg_out_b4
								bitcnt_partial_q[((31 - ((16 * i) + 15)) * 6) + 4] = imd_val_q_i[28 + i];
							end
					end
					bitcnt_partial_q[5] = imd_val_q_i[30];
				end
				wire [31:0] butterfly_mask_l [0:4];
				wire [31:0] butterfly_mask_r [0:4];
				wire [31:0] butterfly_mask_not [0:4];
				wire [31:0] lrotc_stage [0:4];
				genvar _gv_stg_1;
				for (_gv_stg_1 = 0; _gv_stg_1 < 5; _gv_stg_1 = _gv_stg_1 + 1) begin : gen_butterfly_ctrl_stage
					localparam stg = _gv_stg_1;
					genvar _gv_seg_1;
					for (_gv_seg_1 = 0; _gv_seg_1 < (2 ** stg); _gv_seg_1 = _gv_seg_1 + 1) begin : gen_butterfly_ctrl
						localparam seg = _gv_seg_1;
						assign lrotc_stage[stg][((2 * (16 >> stg)) * (seg + 1)) - 1:(2 * (16 >> stg)) * seg] = {{16 >> stg {1'b0}}, {16 >> stg {1'b1}}} << bitcnt_partial_q[((32 - ((16 >> stg) * ((2 * seg) + 1))) * 6) + ($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) : ($clog2(16 >> stg) + ($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) + 1 : 1 - $clog2(16 >> stg))) - 1)-:($clog2(16 >> stg) >= 0 ? $clog2(16 >> stg) + 1 : 1 - $clog2(16 >> stg))];
						assign butterfly_mask_l[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)] = ~lrotc_stage[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)];
						assign butterfly_mask_r[stg][((16 >> stg) * ((2 * seg) + 1)) - 1:(16 >> stg) * (2 * seg)] = ~lrotc_stage[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)];
						assign butterfly_mask_l[stg][((16 >> stg) * ((2 * seg) + 1)) - 1:(16 >> stg) * (2 * seg)] = 1'sb0;
						assign butterfly_mask_r[stg][((16 >> stg) * ((2 * seg) + 2)) - 1:(16 >> stg) * ((2 * seg) + 1)] = 1'sb0;
					end
				end
				genvar _gv_stg_2;
				for (_gv_stg_2 = 0; _gv_stg_2 < 5; _gv_stg_2 = _gv_stg_2 + 1) begin : gen_butterfly_not
					localparam stg = _gv_stg_2;
					assign butterfly_mask_not[stg] = ~(butterfly_mask_l[stg] | butterfly_mask_r[stg]);
				end
				always @(*) begin
					if (_sv2v_0)
						;
					butterfly_result = operand_a_i;
					butterfly_result = ((butterfly_result & butterfly_mask_not[0]) | ((butterfly_result & butterfly_mask_l[0]) >> 16)) | ((butterfly_result & butterfly_mask_r[0]) << 16);
					butterfly_result = ((butterfly_result & butterfly_mask_not[1]) | ((butterfly_result & butterfly_mask_l[1]) >> 8)) | ((butterfly_result & butterfly_mask_r[1]) << 8);
					butterfly_result = ((butterfly_result & butterfly_mask_not[2]) | ((butterfly_result & butterfly_mask_l[2]) >> 4)) | ((butterfly_result & butterfly_mask_r[2]) << 4);
					butterfly_result = ((butterfly_result & butterfly_mask_not[3]) | ((butterfly_result & butterfly_mask_l[3]) >> 2)) | ((butterfly_result & butterfly_mask_r[3]) << 2);
					butterfly_result = ((butterfly_result & butterfly_mask_not[4]) | ((butterfly_result & butterfly_mask_l[4]) >> 1)) | ((butterfly_result & butterfly_mask_r[4]) << 1);
					butterfly_result = butterfly_result & operand_b_i;
				end
				always @(*) begin
					if (_sv2v_0)
						;
					invbutterfly_result = operand_a_i & operand_b_i;
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[4]) | ((invbutterfly_result & butterfly_mask_l[4]) >> 1)) | ((invbutterfly_result & butterfly_mask_r[4]) << 1);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[3]) | ((invbutterfly_result & butterfly_mask_l[3]) >> 2)) | ((invbutterfly_result & butterfly_mask_r[3]) << 2);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[2]) | ((invbutterfly_result & butterfly_mask_l[2]) >> 4)) | ((invbutterfly_result & butterfly_mask_r[2]) << 4);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[1]) | ((invbutterfly_result & butterfly_mask_l[1]) >> 8)) | ((invbutterfly_result & butterfly_mask_r[1]) << 8);
					invbutterfly_result = ((invbutterfly_result & butterfly_mask_not[0]) | ((invbutterfly_result & butterfly_mask_l[0]) >> 16)) | ((invbutterfly_result & butterfly_mask_r[0]) << 16);
				end
			end
			else begin : gen_alu_rvb_not_full
				wire [31:0] unused_imd_val_q_1;
				assign unused_imd_val_q_1 = imd_val_q_i[0+:32];
				wire [32:1] sv2v_tmp_98122;
				assign sv2v_tmp_98122 = 1'sb0;
				always @(*) butterfly_result = sv2v_tmp_98122;
				wire [32:1] sv2v_tmp_B39E0;
				assign sv2v_tmp_B39E0 = 1'sb0;
				always @(*) invbutterfly_result = sv2v_tmp_B39E0;
				assign bitcnt_partial_lsb_d = 1'sb0;
				assign bitcnt_partial_msb_d = 1'sb0;
			end
			always @(*) begin
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (operator_i)
					7'd45: begin
						multicycle_result = (operand_b_i == 32'h00000000 ? operand_a_i : imd_val_q_i[32+:32]);
						imd_val_d_o = {operand_a_i, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd46: begin
						multicycle_result = imd_val_q_i[32+:32] | bwlogic_and_result;
						imd_val_d_o = {bwlogic_and_result, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd48, 7'd47, 7'd14, 7'd13: begin
						if (shift_amt[4:0] == 5'h00)
							multicycle_result = (shift_amt[5] ? operand_a_i : imd_val_q_i[32+:32]);
						else
							multicycle_result = imd_val_q_i[32+:32] | shift_result;
						imd_val_d_o = {shift_result, 32'h00000000};
						if (instr_first_cycle_i)
							imd_val_we_o = 2'b01;
						else
							imd_val_we_o = 2'b00;
					end
					7'd63, 7'd64, 7'd61, 7'd62, 7'd59, 7'd60:
						if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
							(* full_case, parallel_case *)
							case (1'b1)
								crc_bmode: multicycle_result = clmul_result_rev ^ (operand_a_i >> 8);
								crc_hmode: multicycle_result = clmul_result_rev ^ (operand_a_i >> 16);
								default: multicycle_result = clmul_result_rev;
							endcase
							imd_val_d_o = {clmul_result_rev, 32'h00000000};
							if (instr_first_cycle_i)
								imd_val_we_o = 2'b01;
							else
								imd_val_we_o = 2'b00;
						end
						else begin
							imd_val_d_o = {operand_a_i, 32'h00000000};
							imd_val_we_o = 2'b00;
							multicycle_result = 1'sb0;
						end
					7'd53, 7'd54:
						if (RV32B == 32'sd3) begin
							multicycle_result = (operator_i == 7'd54 ? butterfly_result : invbutterfly_result);
							imd_val_d_o = {bitcnt_partial_lsb_d, bitcnt_partial_msb_d};
							if (instr_first_cycle_i)
								imd_val_we_o = 2'b11;
							else
								imd_val_we_o = 2'b00;
						end
						else begin
							imd_val_d_o = {operand_a_i, 32'h00000000};
							imd_val_we_o = 2'b00;
							multicycle_result = 1'sb0;
						end
					default: begin
						imd_val_d_o = {operand_a_i, 32'h00000000};
						imd_val_we_o = 2'b00;
						multicycle_result = 1'sb0;
					end
				endcase
			end
		end
		else begin : g_no_alu_rvb
			wire [63:0] unused_imd_val_q;
			assign unused_imd_val_q = imd_val_q_i;
			wire [31:0] unused_butterfly_result;
			assign unused_butterfly_result = butterfly_result;
			wire [31:0] unused_invbutterfly_result;
			assign unused_invbutterfly_result = invbutterfly_result;
			assign bitcnt_result = 1'sb0;
			assign minmax_result = 1'sb0;
			wire [32:1] sv2v_tmp_A0513;
			assign sv2v_tmp_A0513 = 1'sb0;
			always @(*) pack_result = sv2v_tmp_A0513;
			assign sext_result = 1'sb0;
			wire [32:1] sv2v_tmp_75CE4;
			assign sv2v_tmp_75CE4 = 1'sb0;
			always @(*) singlebit_result = sv2v_tmp_75CE4;
			wire [32:1] sv2v_tmp_FA09A;
			assign sv2v_tmp_FA09A = 1'sb0;
			always @(*) rev_result = sv2v_tmp_FA09A;
			wire [32:1] sv2v_tmp_4A308;
			assign sv2v_tmp_4A308 = 1'sb0;
			always @(*) shuffle_result = sv2v_tmp_4A308;
			assign xperm_result = 1'sb0;
			wire [32:1] sv2v_tmp_98122;
			assign sv2v_tmp_98122 = 1'sb0;
			always @(*) butterfly_result = sv2v_tmp_98122;
			wire [32:1] sv2v_tmp_B39E0;
			assign sv2v_tmp_B39E0 = 1'sb0;
			always @(*) invbutterfly_result = sv2v_tmp_B39E0;
			wire [32:1] sv2v_tmp_31DA6;
			assign sv2v_tmp_31DA6 = 1'sb0;
			always @(*) clmul_result = sv2v_tmp_31DA6;
			wire [32:1] sv2v_tmp_BC1B9;
			assign sv2v_tmp_BC1B9 = 1'sb0;
			always @(*) multicycle_result = sv2v_tmp_BC1B9;
			wire [64:1] sv2v_tmp_42A49;
			assign sv2v_tmp_42A49 = {2 {32'b00000000000000000000000000000000}};
			always @(*) imd_val_d_o = sv2v_tmp_42A49;
			wire [2:1] sv2v_tmp_0E15E;
			assign sv2v_tmp_0E15E = {2 {1'b0}};
			always @(*) imd_val_we_o = sv2v_tmp_0E15E;
		end
	endgenerate
	always @(*) begin
		if (_sv2v_0)
			;
		result_o = 1'sb0;
		(* full_case, parallel_case *)
		case (operator_i)
			7'd2, 7'd5, 7'd3, 7'd6, 7'd4, 7'd7: result_o = bwlogic_result;
			7'd0, 7'd1, 7'd22, 7'd23, 7'd24: result_o = adder_result;
			7'd10, 7'd9, 7'd8, 7'd12, 7'd11: result_o = shift_result;
			7'd17, 7'd18: result_o = shuffle_result;
			7'd19, 7'd20, 7'd21: result_o = xperm_result;
			7'd29, 7'd30, 7'd27, 7'd28, 7'd25, 7'd26, 7'd43, 7'd44: result_o = {31'h00000000, cmp_result};
			7'd31, 7'd33, 7'd32, 7'd34: result_o = minmax_result;
			7'd40, 7'd41, 7'd42: result_o = {26'h0000000, bitcnt_result};
			7'd35, 7'd37, 7'd36: result_o = pack_result;
			7'd38, 7'd39: result_o = sext_result;
			7'd46, 7'd45, 7'd47, 7'd48, 7'd14, 7'd13, 7'd63, 7'd64, 7'd61, 7'd62, 7'd59, 7'd60, 7'd53, 7'd54: result_o = multicycle_result;
			7'd49, 7'd50, 7'd51, 7'd52: result_o = singlebit_result;
			7'd15, 7'd16: result_o = rev_result;
			7'd55: result_o = bfp_result;
			7'd56, 7'd57, 7'd58: result_o = clmul_result;
			default:
				;
		endcase
	end
	wire unused_shift_amt_compl;
	assign unused_shift_amt_compl = shift_amt_compl[5];
	initial _sv2v_0 = 0;
endmodule
module ibex_compressed_decoder (
	clk_i,
	rst_ni,
	valid_i,
	instr_i,
	instr_o,
	is_compressed_o,
	illegal_instr_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire valid_i;
	input wire [31:0] instr_i;
	output reg [31:0] instr_o;
	output wire is_compressed_o;
	output reg illegal_instr_o;
	wire unused_valid;
	assign unused_valid = valid_i;
	always @(*) begin
		if (_sv2v_0)
			;
		instr_o = instr_i;
		illegal_instr_o = 1'b0;
		(* full_case, parallel_case *)
		case (instr_i[1:0])
			2'b00:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: begin
						instr_o = {2'b00, instr_i[10:7], instr_i[12:11], instr_i[5], instr_i[6], 12'h041, instr_i[4:2], 7'h13};
						if (instr_i[12:5] == 8'b00000000)
							illegal_instr_o = 1'b1;
					end
					3'b010: instr_o = {5'b00000, instr_i[5], instr_i[12:10], instr_i[6], 4'b0001, instr_i[9:7], 5'b01001, instr_i[4:2], 7'h03};
					3'b110: instr_o = {5'b00000, instr_i[5], instr_i[12], 2'b01, instr_i[4:2], 2'b01, instr_i[9:7], 3'b010, instr_i[11:10], instr_i[6], 9'h023};
					3'b001, 3'b011, 3'b100, 3'b101, 3'b111: illegal_instr_o = 1'b1;
					default: illegal_instr_o = 1'b1;
				endcase
			2'b01:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], 7'h13};
					3'b001, 3'b101: instr_o = {instr_i[12], instr_i[8], instr_i[10:9], instr_i[6], instr_i[7], instr_i[2], instr_i[11], instr_i[5:3], {9 {instr_i[12]}}, 4'b0000, ~instr_i[15], 7'h6f};
					3'b010: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 8'b00000000, instr_i[11:7], 7'h13};
					3'b011: begin
						instr_o = {{15 {instr_i[12]}}, instr_i[6:2], instr_i[11:7], 7'h37};
						if (instr_i[11:7] == 5'h02)
							instr_o = {{3 {instr_i[12]}}, instr_i[4:3], instr_i[5], instr_i[2], instr_i[6], 24'h010113};
						if ({instr_i[12], instr_i[6:2]} == 6'b000000)
							illegal_instr_o = 1'b1;
					end
					3'b100:
						(* full_case, parallel_case *)
						case (instr_i[11:10])
							2'b00, 2'b01: begin
								instr_o = {1'b0, instr_i[10], 5'b00000, instr_i[6:2], 2'b01, instr_i[9:7], 5'b10101, instr_i[9:7], 7'h13};
								if (instr_i[12] == 1'b1)
									illegal_instr_o = 1'b1;
							end
							2'b10: instr_o = {{6 {instr_i[12]}}, instr_i[12], instr_i[6:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], 7'h13};
							2'b11:
								(* full_case, parallel_case *)
								case ({instr_i[12], instr_i[6:5]})
									3'b000: instr_o = {9'b010000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b00001, instr_i[9:7], 7'h33};
									3'b001: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b10001, instr_i[9:7], 7'h33};
									3'b010: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11001, instr_i[9:7], 7'h33};
									3'b011: instr_o = {9'b000000001, instr_i[4:2], 2'b01, instr_i[9:7], 5'b11101, instr_i[9:7], 7'h33};
									3'b100, 3'b101, 3'b110, 3'b111: illegal_instr_o = 1'b1;
									default: illegal_instr_o = 1'b1;
								endcase
							default: illegal_instr_o = 1'b1;
						endcase
					3'b110, 3'b111: instr_o = {{4 {instr_i[12]}}, instr_i[6:5], instr_i[2], 7'b0000001, instr_i[9:7], 2'b00, instr_i[13], instr_i[11:10], instr_i[4:3], instr_i[12], 7'h63};
					default: illegal_instr_o = 1'b1;
				endcase
			2'b10:
				(* full_case, parallel_case *)
				case (instr_i[15:13])
					3'b000: begin
						instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b001, instr_i[11:7], 7'h13};
						if (instr_i[12] == 1'b1)
							illegal_instr_o = 1'b1;
					end
					3'b010: begin
						instr_o = {4'b0000, instr_i[3:2], instr_i[12], instr_i[6:4], 10'h012, instr_i[11:7], 7'h03};
						if (instr_i[11:7] == 5'b00000)
							illegal_instr_o = 1'b1;
					end
					3'b100:
						if (instr_i[12] == 1'b0) begin
							if (instr_i[6:2] != 5'b00000)
								instr_o = {7'b0000000, instr_i[6:2], 8'b00000000, instr_i[11:7], 7'h33};
							else begin
								instr_o = {12'b000000000000, instr_i[11:7], 15'h0067};
								if (instr_i[11:7] == 5'b00000)
									illegal_instr_o = 1'b1;
							end
						end
						else if (instr_i[6:2] != 5'b00000)
							instr_o = {7'b0000000, instr_i[6:2], instr_i[11:7], 3'b000, instr_i[11:7], 7'h33};
						else if (instr_i[11:7] == 5'b00000)
							instr_o = 32'h00100073;
						else
							instr_o = {12'b000000000000, instr_i[11:7], 15'h00e7};
					3'b110: instr_o = {4'b0000, instr_i[8:7], instr_i[12], instr_i[6:2], 8'h12, instr_i[11:9], 9'h023};
					3'b001, 3'b011, 3'b101, 3'b111: illegal_instr_o = 1'b1;
					default: illegal_instr_o = 1'b1;
				endcase
			2'b11:
				;
			default: illegal_instr_o = 1'b1;
		endcase
	end
	assign is_compressed_o = instr_i[1:0] != 2'b11;
	initial _sv2v_0 = 0;
endmodule
module ibex_controller (
	clk_i,
	rst_ni,
	ctrl_busy_o,
	illegal_insn_i,
	ecall_insn_i,
	mret_insn_i,
	dret_insn_i,
	wfi_insn_i,
	ebrk_insn_i,
	csr_pipe_flush_i,
	instr_valid_i,
	instr_i,
	instr_compressed_i,
	instr_is_compressed_i,
	instr_bp_taken_i,
	instr_fetch_err_i,
	instr_fetch_err_plus2_i,
	pc_id_i,
	instr_valid_clear_o,
	id_in_ready_o,
	controller_run_o,
	instr_exec_i,
	instr_req_o,
	pc_set_o,
	pc_mux_o,
	nt_branch_mispredict_o,
	exc_pc_mux_o,
	exc_cause_o,
	lsu_addr_last_i,
	load_err_i,
	store_err_i,
	mem_resp_intg_err_i,
	wb_exception_o,
	id_exception_o,
	branch_set_i,
	branch_not_set_i,
	jump_set_i,
	csr_mstatus_mie_i,
	irq_pending_i,
	irqs_i,
	irq_nm_ext_i,
	nmi_mode_o,
	debug_req_i,
	debug_cause_o,
	debug_csr_save_o,
	debug_mode_o,
	debug_mode_entering_o,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_wb_o,
	csr_restore_mret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	csr_mtval_o,
	priv_mode_i,
	stall_id_i,
	stall_wb_i,
	flush_id_o,
	ready_wb_i,
	perf_jump_o,
	perf_tbranch_o
);
	reg _sv2v_0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] MemECC = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	output reg ctrl_busy_o;
	input wire illegal_insn_i;
	input wire ecall_insn_i;
	input wire mret_insn_i;
	input wire dret_insn_i;
	input wire wfi_insn_i;
	input wire ebrk_insn_i;
	input wire csr_pipe_flush_i;
	input wire instr_valid_i;
	input wire [31:0] instr_i;
	input wire [15:0] instr_compressed_i;
	input wire instr_is_compressed_i;
	input wire instr_bp_taken_i;
	input wire instr_fetch_err_i;
	input wire instr_fetch_err_plus2_i;
	input wire [31:0] pc_id_i;
	output wire instr_valid_clear_o;
	output wire id_in_ready_o;
	output reg controller_run_o;
	input wire instr_exec_i;
	output reg instr_req_o;
	output reg pc_set_o;
	output reg [2:0] pc_mux_o;
	output reg nt_branch_mispredict_o;
	output reg [1:0] exc_pc_mux_o;
	output reg [6:0] exc_cause_o;
	input wire [31:0] lsu_addr_last_i;
	input wire load_err_i;
	input wire store_err_i;
	input wire mem_resp_intg_err_i;
	output wire wb_exception_o;
	output wire id_exception_o;
	input wire branch_set_i;
	input wire branch_not_set_i;
	input wire jump_set_i;
	input wire csr_mstatus_mie_i;
	input wire irq_pending_i;
	input wire [17:0] irqs_i;
	input wire irq_nm_ext_i;
	output wire nmi_mode_o;
	input wire debug_req_i;
	output wire [2:0] debug_cause_o;
	output reg debug_csr_save_o;
	output wire debug_mode_o;
	output reg debug_mode_entering_o;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	output reg csr_save_if_o;
	output reg csr_save_id_o;
	output reg csr_save_wb_o;
	output reg csr_restore_mret_id_o;
	output reg csr_restore_dret_id_o;
	output reg csr_save_cause_o;
	output reg [31:0] csr_mtval_o;
	input wire [1:0] priv_mode_i;
	input wire stall_id_i;
	input wire stall_wb_i;
	output wire flush_id_o;
	input wire ready_wb_i;
	output reg perf_jump_o;
	output reg perf_tbranch_o;
	reg [3:0] ctrl_fsm_cs;
	reg [3:0] ctrl_fsm_ns;
	reg nmi_mode_q;
	reg nmi_mode_d;
	reg debug_mode_q;
	reg debug_mode_d;
	wire [2:0] debug_cause_d;
	reg [2:0] debug_cause_q;
	reg load_err_q;
	wire load_err_d;
	reg store_err_q;
	wire store_err_d;
	reg exc_req_q;
	wire exc_req_d;
	reg illegal_insn_q;
	wire illegal_insn_d;
	reg instr_fetch_err_prio;
	reg illegal_insn_prio;
	reg ecall_insn_prio;
	reg ebrk_insn_prio;
	reg store_err_prio;
	reg load_err_prio;
	wire stall;
	reg halt_if;
	reg retain_id;
	reg flush_id;
	wire exc_req_lsu;
	wire special_req;
	wire special_req_pc_change;
	wire special_req_flush_only;
	wire do_single_step_d;
	reg do_single_step_q;
	wire enter_debug_mode_prio_d;
	reg enter_debug_mode_prio_q;
	wire enter_debug_mode;
	wire ebreak_into_debug;
	wire irq_enabled;
	wire handle_irq;
	wire id_wb_pending;
	wire irq_nm;
	wire irq_nm_int;
	wire [31:0] irq_nm_int_mtval;
	wire [4:0] irq_nm_int_cause;
	reg [3:0] mfip_id;
	wire unused_irq_timer;
	wire ecall_insn;
	wire mret_insn;
	wire dret_insn;
	wire wfi_insn;
	wire ebrk_insn;
	wire csr_pipe_flush;
	wire instr_fetch_err;
	assign load_err_d = load_err_i;
	assign store_err_d = store_err_i;
	assign ecall_insn = ecall_insn_i & instr_valid_i;
	assign mret_insn = mret_insn_i & instr_valid_i;
	assign dret_insn = dret_insn_i & instr_valid_i;
	assign wfi_insn = wfi_insn_i & instr_valid_i;
	assign ebrk_insn = ebrk_insn_i & instr_valid_i;
	assign csr_pipe_flush = csr_pipe_flush_i & instr_valid_i;
	assign instr_fetch_err = instr_fetch_err_i & instr_valid_i;
	assign illegal_insn_d = illegal_insn_i & (ctrl_fsm_cs != 4'd6);
	assign exc_req_d = (((ecall_insn | ebrk_insn) | illegal_insn_d) | instr_fetch_err) & (ctrl_fsm_cs != 4'd6);
	assign exc_req_lsu = store_err_i | load_err_i;
	assign id_exception_o = exc_req_d & ~wb_exception_o;
	assign special_req_flush_only = wfi_insn | csr_pipe_flush;
	assign special_req_pc_change = ((mret_insn | dret_insn) | exc_req_d) | exc_req_lsu;
	assign special_req = special_req_pc_change | special_req_flush_only;
	assign id_wb_pending = instr_valid_i | ~ready_wb_i;
	generate
		if (WritebackStage) begin : g_wb_exceptions
			always @(*) begin
				if (_sv2v_0)
					;
				instr_fetch_err_prio = 0;
				illegal_insn_prio = 0;
				ecall_insn_prio = 0;
				ebrk_insn_prio = 0;
				store_err_prio = 0;
				load_err_prio = 0;
				if (store_err_q)
					store_err_prio = 1'b1;
				else if (load_err_q)
					load_err_prio = 1'b1;
				else if (instr_fetch_err)
					instr_fetch_err_prio = 1'b1;
				else if (illegal_insn_q)
					illegal_insn_prio = 1'b1;
				else if (ecall_insn)
					ecall_insn_prio = 1'b1;
				else if (ebrk_insn)
					ebrk_insn_prio = 1'b1;
			end
			assign wb_exception_o = ((load_err_q | store_err_q) | load_err_i) | store_err_i;
		end
		else begin : g_no_wb_exceptions
			always @(*) begin
				if (_sv2v_0)
					;
				instr_fetch_err_prio = 0;
				illegal_insn_prio = 0;
				ecall_insn_prio = 0;
				ebrk_insn_prio = 0;
				store_err_prio = 0;
				load_err_prio = 0;
				if (instr_fetch_err)
					instr_fetch_err_prio = 1'b1;
				else if (illegal_insn_q)
					illegal_insn_prio = 1'b1;
				else if (ecall_insn)
					ecall_insn_prio = 1'b1;
				else if (ebrk_insn)
					ebrk_insn_prio = 1'b1;
				else if (store_err_q)
					store_err_prio = 1'b1;
				else if (load_err_q)
					load_err_prio = 1'b1;
			end
			assign wb_exception_o = 1'b0;
		end
		if (MemECC) begin : g_intg_irq_int
			reg mem_resp_intg_err_irq_pending_q;
			wire mem_resp_intg_err_irq_pending_d;
			reg [31:0] mem_resp_intg_err_addr_q;
			reg [31:0] mem_resp_intg_err_addr_d;
			reg mem_resp_intg_err_irq_set;
			reg mem_resp_intg_err_irq_clear;
			wire entering_nmi;
			assign entering_nmi = nmi_mode_d & ~nmi_mode_q;
			always @(*) begin
				if (_sv2v_0)
					;
				mem_resp_intg_err_addr_d = mem_resp_intg_err_addr_q;
				mem_resp_intg_err_irq_set = 1'b0;
				mem_resp_intg_err_irq_clear = 1'b0;
				if (mem_resp_intg_err_irq_pending_q) begin
					if (entering_nmi & !irq_nm_ext_i)
						mem_resp_intg_err_irq_clear = 1'b1;
				end
				else if (mem_resp_intg_err_i) begin
					mem_resp_intg_err_addr_d = lsu_addr_last_i;
					mem_resp_intg_err_irq_set = 1'b1;
				end
			end
			assign mem_resp_intg_err_irq_pending_d = (mem_resp_intg_err_irq_pending_q & ~mem_resp_intg_err_irq_clear) | mem_resp_intg_err_irq_set;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					mem_resp_intg_err_irq_pending_q <= 1'b0;
					mem_resp_intg_err_addr_q <= 1'sb0;
				end
				else begin
					mem_resp_intg_err_irq_pending_q <= mem_resp_intg_err_irq_pending_d;
					mem_resp_intg_err_addr_q <= mem_resp_intg_err_addr_d;
				end
			assign irq_nm_int = mem_resp_intg_err_irq_pending_q;
			assign irq_nm_int_cause = 5'b00000;
			assign irq_nm_int_mtval = mem_resp_intg_err_addr_q;
		end
		else begin : g_no_intg_irq_int
			wire unused_mem_resp_intg_err_i;
			assign unused_mem_resp_intg_err_i = mem_resp_intg_err_i;
			assign irq_nm_int = 1'b0;
			assign irq_nm_int_cause = 5'd0;
			assign irq_nm_int_mtval = 1'sb0;
		end
	endgenerate
	assign do_single_step_d = (instr_valid_i ? ~debug_mode_q & debug_single_step_i : do_single_step_q);
	assign enter_debug_mode_prio_d = (debug_req_i | do_single_step_d) & ~debug_mode_q;
	assign enter_debug_mode = enter_debug_mode_prio_d | (trigger_match_i & ~debug_mode_q);
	assign ebreak_into_debug = (priv_mode_i == 2'b11 ? debug_ebreakm_i : (priv_mode_i == 2'b00 ? debug_ebreaku_i : 1'b0));
	assign irq_nm = irq_nm_ext_i | irq_nm_int;
	assign irq_enabled = csr_mstatus_mie_i | (priv_mode_i == 2'b00);
	assign handle_irq = ((~debug_mode_q & ~debug_single_step_i) & ~nmi_mode_q) & (irq_nm | (irq_pending_i & irq_enabled));
	always @(*) begin : gen_mfip_id
		if (_sv2v_0)
			;
		mfip_id = 4'd0;
		begin : sv2v_autoblock_1
			reg signed [31:0] i;
			for (i = 14; i >= 0; i = i - 1)
				if (irqs_i[0 + i])
					mfip_id = i[3:0];
		end
	end
	assign unused_irq_timer = irqs_i[16];
	assign debug_cause_d = (trigger_match_i ? 3'h2 : (ebrk_insn_prio & ebreak_into_debug ? 3'h1 : (debug_req_i ? 3'h3 : (do_single_step_d ? 3'h4 : 3'h0))));
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			debug_cause_q <= 3'h0;
		else
			debug_cause_q <= debug_cause_d;
	assign debug_cause_o = debug_cause_q;
	localparam [6:0] ibex_pkg_ExcCauseBreakpoint = 7'h03;
	localparam [6:0] ibex_pkg_ExcCauseEcallMMode = 7'h0b;
	localparam [6:0] ibex_pkg_ExcCauseEcallUMode = 7'h08;
	localparam [6:0] ibex_pkg_ExcCauseIllegalInsn = 7'h02;
	localparam [6:0] ibex_pkg_ExcCauseInsnAddrMisa = 7'h00;
	localparam [6:0] ibex_pkg_ExcCauseInstrAccessFault = 7'h01;
	localparam [6:0] ibex_pkg_ExcCauseIrqExternalM = 7'h2b;
	localparam [6:0] ibex_pkg_ExcCauseIrqNm = 7'h3f;
	localparam [6:0] ibex_pkg_ExcCauseIrqSoftwareM = 7'h23;
	localparam [6:0] ibex_pkg_ExcCauseIrqTimerM = 7'h27;
	localparam [6:0] ibex_pkg_ExcCauseLoadAccessFault = 7'h05;
	localparam [6:0] ibex_pkg_ExcCauseStoreAccessFault = 7'h07;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		instr_req_o = 1'b1;
		csr_save_if_o = 1'b0;
		csr_save_id_o = 1'b0;
		csr_save_wb_o = 1'b0;
		csr_restore_mret_id_o = 1'b0;
		csr_restore_dret_id_o = 1'b0;
		csr_save_cause_o = 1'b0;
		csr_mtval_o = 1'sb0;
		pc_mux_o = 3'd0;
		pc_set_o = 1'b0;
		nt_branch_mispredict_o = 1'b0;
		exc_pc_mux_o = 2'd1;
		exc_cause_o = ibex_pkg_ExcCauseInsnAddrMisa;
		ctrl_fsm_ns = ctrl_fsm_cs;
		ctrl_busy_o = 1'b1;
		halt_if = 1'b0;
		retain_id = 1'b0;
		flush_id = 1'b0;
		debug_csr_save_o = 1'b0;
		debug_mode_d = debug_mode_q;
		debug_mode_entering_o = 1'b0;
		nmi_mode_d = nmi_mode_q;
		perf_tbranch_o = 1'b0;
		perf_jump_o = 1'b0;
		controller_run_o = 1'b0;
		(* full_case, parallel_case *)
		case (ctrl_fsm_cs)
			4'd0: begin
				instr_req_o = 1'b0;
				pc_mux_o = 3'd0;
				pc_set_o = 1'b1;
				ctrl_fsm_ns = 4'd1;
			end
			4'd1: begin
				instr_req_o = 1'b1;
				pc_mux_o = 3'd0;
				pc_set_o = 1'b1;
				ctrl_fsm_ns = 4'd4;
			end
			4'd2: begin
				ctrl_busy_o = 1'b0;
				instr_req_o = 1'b0;
				halt_if = 1'b1;
				flush_id = 1'b1;
				ctrl_fsm_ns = 4'd3;
			end
			4'd3: begin
				instr_req_o = 1'b0;
				halt_if = 1'b1;
				flush_id = 1'b1;
				if ((((irq_nm || irq_pending_i) || debug_req_i) || debug_mode_q) || debug_single_step_i)
					ctrl_fsm_ns = 4'd4;
				else
					ctrl_busy_o = 1'b0;
			end
			4'd4: begin
				if (id_in_ready_o)
					ctrl_fsm_ns = 4'd5;
				if (handle_irq) begin
					ctrl_fsm_ns = 4'd7;
					halt_if = 1'b1;
				end
				if (enter_debug_mode) begin
					ctrl_fsm_ns = 4'd8;
					halt_if = 1'b1;
				end
			end
			4'd5: begin
				controller_run_o = 1'b1;
				pc_mux_o = 3'd1;
				if (special_req) begin
					retain_id = 1'b1;
					if (ready_wb_i | wb_exception_o)
						ctrl_fsm_ns = 4'd6;
				end
				if (branch_set_i || jump_set_i) begin
					pc_set_o = (BranchPredictor ? ~instr_bp_taken_i : 1'b1);
					perf_tbranch_o = branch_set_i;
					perf_jump_o = jump_set_i;
				end
				if (BranchPredictor) begin
					if (instr_bp_taken_i & branch_not_set_i)
						nt_branch_mispredict_o = 1'b1;
				end
				if ((enter_debug_mode || handle_irq) && (stall || id_wb_pending))
					halt_if = 1'b1;
				if ((!stall && !special_req) && !id_wb_pending) begin
					if (enter_debug_mode) begin
						ctrl_fsm_ns = 4'd8;
						halt_if = 1'b1;
					end
					else if (handle_irq) begin
						ctrl_fsm_ns = 4'd7;
						halt_if = 1'b1;
					end
				end
			end
			4'd7: begin
				pc_mux_o = 3'd2;
				exc_pc_mux_o = 2'd1;
				if (handle_irq) begin
					pc_set_o = 1'b1;
					csr_save_if_o = 1'b1;
					csr_save_cause_o = 1'b1;
					if (irq_nm && !nmi_mode_q) begin
						exc_cause_o = (irq_nm_ext_i ? ibex_pkg_ExcCauseIrqNm : {2'b10, irq_nm_int_cause});
						if (irq_nm_int & !irq_nm_ext_i)
							csr_mtval_o = irq_nm_int_mtval;
						nmi_mode_d = 1'b1;
					end
					else if (irqs_i[14-:15] != 15'b000000000000000)
						exc_cause_o = {2'b01, sv2v_cast_5({1'b1, mfip_id})};
					else if (irqs_i[15])
						exc_cause_o = ibex_pkg_ExcCauseIrqExternalM;
					else if (irqs_i[17])
						exc_cause_o = ibex_pkg_ExcCauseIrqSoftwareM;
					else
						exc_cause_o = ibex_pkg_ExcCauseIrqTimerM;
				end
				ctrl_fsm_ns = 4'd5;
			end
			4'd8: begin
				pc_mux_o = 3'd2;
				exc_pc_mux_o = 2'd2;
				flush_id = 1'b1;
				pc_set_o = 1'b1;
				csr_save_if_o = 1'b1;
				debug_csr_save_o = 1'b1;
				csr_save_cause_o = 1'b1;
				debug_mode_d = 1'b1;
				debug_mode_entering_o = 1'b1;
				ctrl_fsm_ns = 4'd5;
			end
			4'd9: begin
				flush_id = 1'b1;
				pc_mux_o = 3'd2;
				pc_set_o = 1'b1;
				exc_pc_mux_o = 2'd2;
				if (ebreak_into_debug && !debug_mode_q) begin
					csr_save_cause_o = 1'b1;
					csr_save_id_o = 1'b1;
					debug_csr_save_o = 1'b1;
				end
				debug_mode_d = 1'b1;
				debug_mode_entering_o = 1'b1;
				ctrl_fsm_ns = 4'd5;
			end
			4'd6: begin
				halt_if = 1'b1;
				flush_id = 1'b1;
				ctrl_fsm_ns = 4'd5;
				if ((exc_req_q || store_err_q) || load_err_q) begin
					pc_set_o = 1'b1;
					pc_mux_o = 3'd2;
					exc_pc_mux_o = (debug_mode_q ? 2'd3 : 2'd0);
					if (WritebackStage) begin : g_writeback_mepc_save
						csr_save_id_o = ~(store_err_q | load_err_q);
						csr_save_wb_o = store_err_q | load_err_q;
					end
					else begin : g_no_writeback_mepc_save
						csr_save_id_o = 1'b0;
					end
					csr_save_cause_o = 1'b1;
					(* full_case, parallel_case *)
					case (1'b1)
						instr_fetch_err_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseInstrAccessFault;
							csr_mtval_o = (instr_fetch_err_plus2_i ? pc_id_i + 32'd2 : pc_id_i);
						end
						illegal_insn_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseIllegalInsn;
							csr_mtval_o = (instr_is_compressed_i ? {16'b0000000000000000, instr_compressed_i} : instr_i);
						end
						ecall_insn_prio: exc_cause_o = (priv_mode_i == 2'b11 ? ibex_pkg_ExcCauseEcallMMode : ibex_pkg_ExcCauseEcallUMode);
						ebrk_insn_prio:
							if (debug_mode_q | ebreak_into_debug) begin
								pc_set_o = 1'b0;
								csr_save_id_o = 1'b0;
								csr_save_cause_o = 1'b0;
								ctrl_fsm_ns = 4'd9;
								flush_id = 1'b0;
							end
							else
								exc_cause_o = ibex_pkg_ExcCauseBreakpoint;
						store_err_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseStoreAccessFault;
							csr_mtval_o = lsu_addr_last_i;
						end
						load_err_prio: begin
							exc_cause_o = ibex_pkg_ExcCauseLoadAccessFault;
							csr_mtval_o = lsu_addr_last_i;
						end
						default:
							;
					endcase
				end
				else if (mret_insn) begin
					pc_mux_o = 3'd3;
					pc_set_o = 1'b1;
					csr_restore_mret_id_o = 1'b1;
					if (nmi_mode_q)
						nmi_mode_d = 1'b0;
				end
				else if (dret_insn) begin
					pc_mux_o = 3'd4;
					pc_set_o = 1'b1;
					debug_mode_d = 1'b0;
					csr_restore_dret_id_o = 1'b1;
				end
				else if (wfi_insn)
					ctrl_fsm_ns = 4'd2;
				if (enter_debug_mode_prio_q && !(ebrk_insn_prio && ebreak_into_debug))
					ctrl_fsm_ns = 4'd8;
			end
			default: begin
				instr_req_o = 1'b0;
				ctrl_fsm_ns = 4'd0;
			end
		endcase
		if (~instr_exec_i)
			halt_if = 1'b1;
	end
	assign flush_id_o = flush_id;
	assign debug_mode_o = debug_mode_q;
	assign nmi_mode_o = nmi_mode_q;
	assign stall = stall_id_i | stall_wb_i;
	assign id_in_ready_o = (~stall & ~halt_if) & ~retain_id;
	assign instr_valid_clear_o = ~(stall | retain_id) | flush_id;
	always @(posedge clk_i or negedge rst_ni) begin : update_regs
		if (!rst_ni) begin
			ctrl_fsm_cs <= 4'd0;
			nmi_mode_q <= 1'b0;
			do_single_step_q <= 1'b0;
			debug_mode_q <= 1'b0;
			enter_debug_mode_prio_q <= 1'b0;
			load_err_q <= 1'b0;
			store_err_q <= 1'b0;
			exc_req_q <= 1'b0;
			illegal_insn_q <= 1'b0;
		end
		else begin
			ctrl_fsm_cs <= ctrl_fsm_ns;
			nmi_mode_q <= nmi_mode_d;
			do_single_step_q <= do_single_step_d;
			debug_mode_q <= debug_mode_d;
			enter_debug_mode_prio_q <= enter_debug_mode_prio_d;
			load_err_q <= load_err_d;
			store_err_q <= store_err_d;
			exc_req_q <= exc_req_d;
			illegal_insn_q <= illegal_insn_d;
		end
	end
	initial _sv2v_0 = 0;
endmodule
module ibex_counter (
	clk_i,
	rst_ni,
	counter_inc_i,
	counterh_we_i,
	counter_we_i,
	counter_val_i,
	counter_val_o,
	counter_val_upd_o
);
	reg _sv2v_0;
	parameter signed [31:0] CounterWidth = 32;
	parameter [0:0] ProvideValUpd = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire counter_inc_i;
	input wire counterh_we_i;
	input wire counter_we_i;
	input wire [31:0] counter_val_i;
	output wire [63:0] counter_val_o;
	output wire [63:0] counter_val_upd_o;
	wire [63:0] counter;
	wire [CounterWidth - 1:0] counter_upd;
	reg [63:0] counter_load;
	reg we;
	reg [CounterWidth - 1:0] counter_d;
	assign counter_upd = counter[CounterWidth - 1:0] + {{CounterWidth - 1 {1'b0}}, 1'b1};
	always @(*) begin
		if (_sv2v_0)
			;
		we = counter_we_i | counterh_we_i;
		counter_load[63:32] = counter[63:32];
		counter_load[31:0] = counter_val_i;
		if (counterh_we_i) begin
			counter_load[63:32] = counter_val_i;
			counter_load[31:0] = counter[31:0];
		end
		if (we)
			counter_d = counter_load[CounterWidth - 1:0];
		else if (counter_inc_i)
			counter_d = counter_upd[CounterWidth - 1:0];
		else
			counter_d = counter[CounterWidth - 1:0];
	end
	localparam signed [31:0] UseDsp = "no";
	reg [CounterWidth - 1:0] counter_q;
	generate
		if (UseDsp == "yes") begin : g_cnt_dsp
			always @(posedge clk_i)
				if (!rst_ni)
					counter_q <= 1'sb0;
				else
					counter_q <= counter_d;
		end
		else begin : g_cnt_no_dsp
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					counter_q <= 1'sb0;
				else
					counter_q <= counter_d;
		end
		if (CounterWidth < 64) begin : g_counter_narrow
			wire [63:CounterWidth] unused_counter_load;
			assign counter[CounterWidth - 1:0] = counter_q;
			assign counter[63:CounterWidth] = 1'sb0;
			if (ProvideValUpd) begin : g_counter_val_upd_o
				assign counter_val_upd_o[CounterWidth - 1:0] = counter_upd;
			end
			else begin : g_no_counter_val_upd_o
				assign counter_val_upd_o[CounterWidth - 1:0] = 1'sb0;
			end
			assign counter_val_upd_o[63:CounterWidth] = 1'sb0;
			assign unused_counter_load = counter_load[63:CounterWidth];
		end
		else begin : g_counter_full
			assign counter = counter_q;
			if (ProvideValUpd) begin : g_counter_val_upd_o
				assign counter_val_upd_o = counter_upd;
			end
			else begin : g_no_counter_val_upd_o
				assign counter_val_upd_o = 1'sb0;
			end
		end
	endgenerate
	assign counter_val_o = counter;
	initial _sv2v_0 = 0;
endmodule
module ibex_cs_registers (
	clk_i,
	rst_ni,
	hart_id_i,
	priv_mode_id_o,
	priv_mode_lsu_o,
	csr_mstatus_tw_o,
	csr_mtvec_o,
	csr_mtvec_init_i,
	boot_addr_i,
	csr_access_i,
	csr_addr_i,
	csr_wdata_i,
	csr_op_i,
	csr_op_en_i,
	csr_rdata_o,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	nmi_mode_i,
	irq_pending_o,
	irqs_o,
	csr_mstatus_mie_o,
	csr_mepc_o,
	csr_mtval_o,
	csr_pmp_cfg_o,
	csr_pmp_addr_o,
	csr_pmp_mseccfg_o,
	debug_mode_i,
	debug_mode_entering_i,
	debug_cause_i,
	debug_csr_save_i,
	csr_depc_o,
	debug_single_step_o,
	debug_ebreakm_o,
	debug_ebreaku_o,
	trigger_match_o,
	pc_if_i,
	pc_id_i,
	pc_wb_i,
	data_ind_timing_o,
	dummy_instr_en_o,
	dummy_instr_mask_o,
	dummy_instr_seed_en_o,
	dummy_instr_seed_o,
	icache_enable_o,
	csr_shadow_err_o,
	ic_scr_key_valid_i,
	csr_save_if_i,
	csr_save_id_i,
	csr_save_wb_i,
	csr_restore_mret_i,
	csr_restore_dret_i,
	csr_save_cause_i,
	csr_mcause_i,
	csr_mtval_i,
	illegal_csr_insn_o,
	double_fault_seen_o,
	instr_ret_i,
	instr_ret_compressed_i,
	instr_ret_spec_i,
	instr_ret_compressed_spec_i,
	iside_wait_i,
	jump_i,
	branch_i,
	branch_taken_i,
	mem_load_i,
	mem_store_i,
	dside_wait_i,
	mul_wait_i,
	div_wait_i
);
	reg _sv2v_0;
	parameter [0:0] DbgTriggerEn = 0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] DataIndTiming = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] ShadowCSR = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [31:0] MHPMCounterNum = 10;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] PMPEnable = 0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] hart_id_i;
	output wire [1:0] priv_mode_id_o;
	output wire [1:0] priv_mode_lsu_o;
	output wire csr_mstatus_tw_o;
	output wire [31:0] csr_mtvec_o;
	input wire csr_mtvec_init_i;
	input wire [31:0] boot_addr_i;
	input wire csr_access_i;
	input wire [11:0] csr_addr_i;
	input wire [31:0] csr_wdata_i;
	input wire [1:0] csr_op_i;
	input csr_op_en_i;
	output wire [31:0] csr_rdata_o;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire nmi_mode_i;
	output wire irq_pending_o;
	output wire [17:0] irqs_o;
	output wire csr_mstatus_mie_o;
	output wire [31:0] csr_mepc_o;
	output wire [31:0] csr_mtval_o;
	output wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg_o;
	output wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr_o;
	output wire [2:0] csr_pmp_mseccfg_o;
	input wire debug_mode_i;
	input wire debug_mode_entering_i;
	input wire [2:0] debug_cause_i;
	input wire debug_csr_save_i;
	output wire [31:0] csr_depc_o;
	output wire debug_single_step_o;
	output wire debug_ebreakm_o;
	output wire debug_ebreaku_o;
	output wire trigger_match_o;
	input wire [31:0] pc_if_i;
	input wire [31:0] pc_id_i;
	input wire [31:0] pc_wb_i;
	output wire data_ind_timing_o;
	output wire dummy_instr_en_o;
	output wire [2:0] dummy_instr_mask_o;
	output wire dummy_instr_seed_en_o;
	output wire [31:0] dummy_instr_seed_o;
	output wire icache_enable_o;
	output wire csr_shadow_err_o;
	input wire ic_scr_key_valid_i;
	input wire csr_save_if_i;
	input wire csr_save_id_i;
	input wire csr_save_wb_i;
	input wire csr_restore_mret_i;
	input wire csr_restore_dret_i;
	input wire csr_save_cause_i;
	input wire [6:0] csr_mcause_i;
	input wire [31:0] csr_mtval_i;
	output wire illegal_csr_insn_o;
	output reg double_fault_seen_o;
	input wire instr_ret_i;
	input wire instr_ret_compressed_i;
	input wire instr_ret_spec_i;
	input wire instr_ret_compressed_spec_i;
	input wire iside_wait_i;
	input wire jump_i;
	input wire branch_i;
	input wire branch_taken_i;
	input wire mem_load_i;
	input wire mem_store_i;
	input wire dside_wait_i;
	input wire mul_wait_i;
	input wire div_wait_i;
	function automatic is_mml_m_exec_cfg;
		input reg [5:0] pmp_cfg;
		reg unused_cfg;
		reg value;
		begin
			unused_cfg = ^{pmp_cfg[4-:2]};
			value = 1'b0;
			if (pmp_cfg[5])
				(* full_case, parallel_case *)
				case ({pmp_cfg[0], pmp_cfg[1], pmp_cfg[2]})
					3'b001, 3'b010, 3'b011, 3'b101: value = 1'b1;
					default: value = 1'b0;
				endcase
			is_mml_m_exec_cfg = value;
		end
	endfunction
	localparam [31:0] RV32BExtra = (RV32B != 32'sd0 ? 1 : 0);
	localparam [31:0] RV32MEnabled = (RV32M == 32'sd0 ? 0 : 1);
	localparam [31:0] PMPAddrWidth = (PMPGranularity > 0 ? 33 - PMPGranularity : 32);
	localparam [1:0] ibex_pkg_CSR_MISA_MXL = 2'd1;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	localparam [31:0] MISA_VALUE = ((((((((4 | (sv2v_cast_32(RV32E) << 4)) | 0) | (sv2v_cast_32(!RV32E) << 8)) | (RV32MEnabled << 12)) | 0) | 0) | 1048576) | (RV32BExtra << 23)) | (sv2v_cast_32(ibex_pkg_CSR_MISA_MXL) << 30);
	reg [31:0] exception_pc;
	reg [1:0] priv_lvl_q;
	reg [1:0] priv_lvl_d;
	wire [5:0] mstatus_q;
	reg [5:0] mstatus_d;
	wire mstatus_err;
	reg mstatus_en;
	wire [17:0] mie_q;
	wire [17:0] mie_d;
	reg mie_en;
	wire [31:0] mscratch_q;
	reg mscratch_en;
	wire [31:0] mepc_q;
	reg [31:0] mepc_d;
	reg mepc_en;
	wire [6:0] mcause_q;
	reg [6:0] mcause_d;
	reg mcause_en;
	wire [31:0] mtval_q;
	reg [31:0] mtval_d;
	reg mtval_en;
	wire [31:0] mtvec_q;
	reg [31:0] mtvec_d;
	wire mtvec_err;
	reg mtvec_en;
	wire [17:0] mip;
	wire [31:0] dcsr_q;
	reg [31:0] dcsr_d;
	reg dcsr_en;
	wire [31:0] depc_q;
	reg [31:0] depc_d;
	reg depc_en;
	wire [31:0] dscratch0_q;
	wire [31:0] dscratch1_q;
	reg dscratch0_en;
	reg dscratch1_en;
	wire [2:0] mstack_q;
	reg [2:0] mstack_d;
	reg mstack_en;
	wire [31:0] mstack_epc_q;
	reg [31:0] mstack_epc_d;
	wire [6:0] mstack_cause_q;
	reg [6:0] mstack_cause_d;
	localparam [31:0] ibex_pkg_PMP_MAX_REGIONS = 16;
	reg [31:0] pmp_addr_rdata [0:15];
	localparam [31:0] ibex_pkg_PMP_CFG_W = 8;
	wire [7:0] pmp_cfg_rdata [0:15];
	wire pmp_csr_err;
	wire [2:0] pmp_mseccfg;
	wire [31:0] mcountinhibit;
	reg [MHPMCounterNum + 2:0] mcountinhibit_d;
	reg [MHPMCounterNum + 2:0] mcountinhibit_q;
	reg mcountinhibit_we;
	wire [63:0] mhpmcounter [0:31];
	reg [31:0] mhpmcounter_we;
	reg [31:0] mhpmcounterh_we;
	reg [31:0] mhpmcounter_incr;
	reg [31:0] mhpmevent [0:31];
	wire [4:0] mhpmcounter_idx;
	wire unused_mhpmcounter_we_1;
	wire unused_mhpmcounterh_we_1;
	wire unused_mhpmcounter_incr_1;
	wire [63:0] minstret_next;
	wire [63:0] minstret_raw;
	wire [31:0] tselect_rdata;
	wire [31:0] tmatch_control_rdata;
	wire [31:0] tmatch_value_rdata;
	wire [7:0] cpuctrlsts_part_q;
	reg [7:0] cpuctrlsts_part_d;
	wire [7:0] cpuctrlsts_part_wdata_raw;
	wire [7:0] cpuctrlsts_part_wdata;
	reg cpuctrlsts_part_we;
	wire cpuctrlsts_part_err;
	wire cpuctrlsts_ic_scr_key_valid_q;
	wire cpuctrlsts_ic_scr_key_err;
	reg [31:0] csr_wdata_int;
	reg [31:0] csr_rdata_int;
	wire csr_we_int;
	wire csr_wr;
	reg dbg_csr;
	reg illegal_csr;
	wire illegal_csr_priv;
	wire illegal_csr_dbg;
	wire illegal_csr_write;
	wire [7:0] unused_boot_addr;
	wire [2:0] unused_csr_addr;
	assign unused_boot_addr = boot_addr_i[7:0];
	wire [11:0] csr_addr;
	assign csr_addr = {csr_addr_i};
	assign unused_csr_addr = csr_addr[7:5];
	assign mhpmcounter_idx = csr_addr[4:0];
	assign illegal_csr_dbg = dbg_csr & ~debug_mode_i;
	assign illegal_csr_priv = csr_addr[9:8] > {priv_lvl_q};
	assign illegal_csr_write = (csr_addr[11:10] == 2'b11) && csr_wr;
	assign illegal_csr_insn_o = csr_access_i & (((illegal_csr | illegal_csr_write) | illegal_csr_priv) | illegal_csr_dbg);
	assign mip[17] = irq_software_i;
	assign mip[16] = irq_timer_i;
	assign mip[15] = irq_external_i;
	assign mip[14-:15] = irq_fast_i;
	localparam [31:0] ibex_pkg_CSR_MARCHID_VALUE = 32'h00000016;
	localparam [31:0] ibex_pkg_CSR_MCONFIGPTR_VALUE = 32'b00000000000000000000000000000000;
	localparam [31:0] ibex_pkg_CSR_MEIX_BIT = 11;
	localparam [31:0] ibex_pkg_CSR_MFIX_BIT_HIGH = 30;
	localparam [31:0] ibex_pkg_CSR_MFIX_BIT_LOW = 16;
	localparam [31:0] ibex_pkg_CSR_MIMPID_VALUE = 32'b00000000000000000000000000000000;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_MML_BIT = 0;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_MMWP_BIT = 1;
	localparam [31:0] ibex_pkg_CSR_MSECCFG_RLB_BIT = 2;
	localparam [31:0] ibex_pkg_CSR_MSIX_BIT = 3;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MIE_BIT = 3;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPIE_BIT = 7;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH = 12;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW = 11;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_MPRV_BIT = 17;
	localparam [31:0] ibex_pkg_CSR_MSTATUS_TW_BIT = 21;
	localparam [31:0] ibex_pkg_CSR_MTIX_BIT = 7;
	localparam [31:0] ibex_pkg_CSR_MVENDORID_VALUE = 32'b00000000000000000000000000000000;
	always @(*) begin
		if (_sv2v_0)
			;
		csr_rdata_int = 1'sb0;
		illegal_csr = 1'b0;
		dbg_csr = 1'b0;
		(* full_case, parallel_case *)
		case (csr_addr_i)
			12'hf11: csr_rdata_int = ibex_pkg_CSR_MVENDORID_VALUE;
			12'hf12: csr_rdata_int = ibex_pkg_CSR_MARCHID_VALUE;
			12'hf13: csr_rdata_int = ibex_pkg_CSR_MIMPID_VALUE;
			12'hf14: csr_rdata_int = hart_id_i;
			12'hf15: csr_rdata_int = ibex_pkg_CSR_MCONFIGPTR_VALUE;
			12'h300: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MIE_BIT] = mstatus_q[5];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPIE_BIT] = mstatus_q[4];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH:ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW] = mstatus_q[3-:2];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_MPRV_BIT] = mstatus_q[1];
				csr_rdata_int[ibex_pkg_CSR_MSTATUS_TW_BIT] = mstatus_q[0];
			end
			12'h310: csr_rdata_int = 1'sb0;
			12'h30a, 12'h31a: csr_rdata_int = 1'sb0;
			12'h301: csr_rdata_int = MISA_VALUE;
			12'h304: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSIX_BIT] = mie_q[17];
				csr_rdata_int[ibex_pkg_CSR_MTIX_BIT] = mie_q[16];
				csr_rdata_int[ibex_pkg_CSR_MEIX_BIT] = mie_q[15];
				csr_rdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW] = mie_q[14-:15];
			end
			12'h306: csr_rdata_int = 1'sb0;
			12'h340: csr_rdata_int = mscratch_q;
			12'h305: csr_rdata_int = mtvec_q;
			12'h341: csr_rdata_int = mepc_q;
			12'h342: csr_rdata_int = {mcause_q[5] | mcause_q[6], (mcause_q[6] ? {26 {1'b1}} : 26'b00000000000000000000000000), mcause_q[4:0]};
			12'h343: csr_rdata_int = mtval_q;
			12'h344: begin
				csr_rdata_int = 1'sb0;
				csr_rdata_int[ibex_pkg_CSR_MSIX_BIT] = mip[17];
				csr_rdata_int[ibex_pkg_CSR_MTIX_BIT] = mip[16];
				csr_rdata_int[ibex_pkg_CSR_MEIX_BIT] = mip[15];
				csr_rdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW] = mip[14-:15];
			end
			12'h747:
				if (PMPEnable) begin
					csr_rdata_int = 1'sb0;
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_MML_BIT] = pmp_mseccfg[0];
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_MMWP_BIT] = pmp_mseccfg[1];
					csr_rdata_int[ibex_pkg_CSR_MSECCFG_RLB_BIT] = pmp_mseccfg[2];
				end
				else
					illegal_csr = 1'b1;
			12'h757:
				if (PMPEnable)
					csr_rdata_int = 1'sb0;
				else
					illegal_csr = 1'b1;
			12'h3a0: csr_rdata_int = {pmp_cfg_rdata[3], pmp_cfg_rdata[2], pmp_cfg_rdata[1], pmp_cfg_rdata[0]};
			12'h3a1: csr_rdata_int = {pmp_cfg_rdata[7], pmp_cfg_rdata[6], pmp_cfg_rdata[5], pmp_cfg_rdata[4]};
			12'h3a2: csr_rdata_int = {pmp_cfg_rdata[11], pmp_cfg_rdata[10], pmp_cfg_rdata[9], pmp_cfg_rdata[8]};
			12'h3a3: csr_rdata_int = {pmp_cfg_rdata[15], pmp_cfg_rdata[14], pmp_cfg_rdata[13], pmp_cfg_rdata[12]};
			12'h3b0: csr_rdata_int = pmp_addr_rdata[0];
			12'h3b1: csr_rdata_int = pmp_addr_rdata[1];
			12'h3b2: csr_rdata_int = pmp_addr_rdata[2];
			12'h3b3: csr_rdata_int = pmp_addr_rdata[3];
			12'h3b4: csr_rdata_int = pmp_addr_rdata[4];
			12'h3b5: csr_rdata_int = pmp_addr_rdata[5];
			12'h3b6: csr_rdata_int = pmp_addr_rdata[6];
			12'h3b7: csr_rdata_int = pmp_addr_rdata[7];
			12'h3b8: csr_rdata_int = pmp_addr_rdata[8];
			12'h3b9: csr_rdata_int = pmp_addr_rdata[9];
			12'h3ba: csr_rdata_int = pmp_addr_rdata[10];
			12'h3bb: csr_rdata_int = pmp_addr_rdata[11];
			12'h3bc: csr_rdata_int = pmp_addr_rdata[12];
			12'h3bd: csr_rdata_int = pmp_addr_rdata[13];
			12'h3be: csr_rdata_int = pmp_addr_rdata[14];
			12'h3bf: csr_rdata_int = pmp_addr_rdata[15];
			12'h7b0: begin
				csr_rdata_int = dcsr_q;
				dbg_csr = 1'b1;
			end
			12'h7b1: begin
				csr_rdata_int = depc_q;
				dbg_csr = 1'b1;
			end
			12'h7b2: begin
				csr_rdata_int = dscratch0_q;
				dbg_csr = 1'b1;
			end
			12'h7b3: begin
				csr_rdata_int = dscratch1_q;
				dbg_csr = 1'b1;
			end
			12'h320: csr_rdata_int = mcountinhibit;
			12'h323, 12'h324, 12'h325, 12'h326, 12'h327, 12'h328, 12'h329, 12'h32a, 12'h32b, 12'h32c, 12'h32d, 12'h32e, 12'h32f, 12'h330, 12'h331, 12'h332, 12'h333, 12'h334, 12'h335, 12'h336, 12'h337, 12'h338, 12'h339, 12'h33a, 12'h33b, 12'h33c, 12'h33d, 12'h33e, 12'h33f: csr_rdata_int = mhpmevent[mhpmcounter_idx];
			12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f: csr_rdata_int = mhpmcounter[mhpmcounter_idx][31:0];
			12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f: csr_rdata_int = mhpmcounter[mhpmcounter_idx][63:32];
			12'h7a0: begin
				csr_rdata_int = tselect_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a1: begin
				csr_rdata_int = tmatch_control_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a2: begin
				csr_rdata_int = tmatch_value_rdata;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a3: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7a8: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h5a8: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7aa: begin
				csr_rdata_int = 1'sb0;
				illegal_csr = ~DbgTriggerEn;
			end
			12'h7c0: csr_rdata_int = {{23 {1'b0}}, cpuctrlsts_ic_scr_key_valid_q, cpuctrlsts_part_q};
			12'h7c1: csr_rdata_int = 1'sb0;
			default: illegal_csr = 1'b1;
		endcase
		if (!PMPEnable) begin
			if (|{csr_addr == 12'h3a0, csr_addr == 12'h3a1, csr_addr == 12'h3a2, csr_addr == 12'h3a3, csr_addr == 12'h3b0, csr_addr == 12'h3b1, csr_addr == 12'h3b2, csr_addr == 12'h3b3, csr_addr == 12'h3b4, csr_addr == 12'h3b5, csr_addr == 12'h3b6, csr_addr == 12'h3b7, csr_addr == 12'h3b8, csr_addr == 12'h3b9, csr_addr == 12'h3ba, csr_addr == 12'h3bb, csr_addr == 12'h3bc, csr_addr == 12'h3bd, csr_addr == 12'h3be, csr_addr == 12'h3bf})
				illegal_csr = 1'b1;
		end
	end
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		exception_pc = pc_id_i;
		priv_lvl_d = priv_lvl_q;
		mstatus_en = 1'b0;
		mstatus_d = mstatus_q;
		mie_en = 1'b0;
		mscratch_en = 1'b0;
		mepc_en = 1'b0;
		mepc_d = {csr_wdata_int[31:1], 1'b0};
		mcause_en = 1'b0;
		mcause_d = {csr_wdata_int[31:30] == 2'b11, csr_wdata_int[31:30] == 2'b10, csr_wdata_int[4:0]};
		mtval_en = 1'b0;
		mtval_d = csr_wdata_int;
		mtvec_en = csr_mtvec_init_i;
		mtvec_d = (csr_mtvec_init_i ? {boot_addr_i[31:8], 8'b00000001} : {csr_wdata_int[31:8], 8'b00000001});
		dcsr_en = 1'b0;
		dcsr_d = dcsr_q;
		depc_d = {csr_wdata_int[31:1], 1'b0};
		depc_en = 1'b0;
		dscratch0_en = 1'b0;
		dscratch1_en = 1'b0;
		mstack_en = 1'b0;
		mstack_d[2] = mstatus_q[4];
		mstack_d[1-:2] = mstatus_q[3-:2];
		mstack_epc_d = mepc_q;
		mstack_cause_d = mcause_q;
		mcountinhibit_we = 1'b0;
		mhpmcounter_we = 1'sb0;
		mhpmcounterh_we = 1'sb0;
		cpuctrlsts_part_we = 1'b0;
		cpuctrlsts_part_d = cpuctrlsts_part_q;
		double_fault_seen_o = 1'b0;
		if (csr_we_int)
			(* full_case, parallel_case *)
			case (csr_addr_i)
				12'h300: begin
					mstatus_en = 1'b1;
					mstatus_d = {csr_wdata_int[ibex_pkg_CSR_MSTATUS_MIE_BIT], csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPIE_BIT], sv2v_cast_2(csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPP_BIT_HIGH:ibex_pkg_CSR_MSTATUS_MPP_BIT_LOW]), csr_wdata_int[ibex_pkg_CSR_MSTATUS_MPRV_BIT], csr_wdata_int[ibex_pkg_CSR_MSTATUS_TW_BIT]};
					if ((mstatus_d[3-:2] != 2'b11) && (mstatus_d[3-:2] != 2'b00))
						mstatus_d[3-:2] = 2'b00;
				end
				12'h304: mie_en = 1'b1;
				12'h340: mscratch_en = 1'b1;
				12'h341: mepc_en = 1'b1;
				12'h342: mcause_en = 1'b1;
				12'h343: mtval_en = 1'b1;
				12'h305: mtvec_en = 1'b1;
				12'h7b0: begin
					dcsr_d = csr_wdata_int;
					dcsr_d[31-:4] = 4'd4;
					if ((dcsr_d[1-:2] != 2'b11) && (dcsr_d[1-:2] != 2'b00))
						dcsr_d[1-:2] = 2'b00;
					dcsr_d[8-:3] = dcsr_q[8-:3];
					dcsr_d[11] = 1'b0;
					dcsr_d[3] = 1'b0;
					dcsr_d[4] = 1'b0;
					dcsr_d[10] = 1'b0;
					dcsr_d[9] = 1'b0;
					dcsr_d[5] = 1'b0;
					dcsr_d[14] = 1'b0;
					dcsr_d[27-:12] = 12'h000;
					dcsr_en = 1'b1;
				end
				12'h7b1: depc_en = 1'b1;
				12'h7b2: dscratch0_en = 1'b1;
				12'h7b3: dscratch1_en = 1'b1;
				12'h320: mcountinhibit_we = 1'b1;
				12'hb00, 12'hb02, 12'hb03, 12'hb04, 12'hb05, 12'hb06, 12'hb07, 12'hb08, 12'hb09, 12'hb0a, 12'hb0b, 12'hb0c, 12'hb0d, 12'hb0e, 12'hb0f, 12'hb10, 12'hb11, 12'hb12, 12'hb13, 12'hb14, 12'hb15, 12'hb16, 12'hb17, 12'hb18, 12'hb19, 12'hb1a, 12'hb1b, 12'hb1c, 12'hb1d, 12'hb1e, 12'hb1f: mhpmcounter_we[mhpmcounter_idx] = 1'b1;
				12'hb80, 12'hb82, 12'hb83, 12'hb84, 12'hb85, 12'hb86, 12'hb87, 12'hb88, 12'hb89, 12'hb8a, 12'hb8b, 12'hb8c, 12'hb8d, 12'hb8e, 12'hb8f, 12'hb90, 12'hb91, 12'hb92, 12'hb93, 12'hb94, 12'hb95, 12'hb96, 12'hb97, 12'hb98, 12'hb99, 12'hb9a, 12'hb9b, 12'hb9c, 12'hb9d, 12'hb9e, 12'hb9f: mhpmcounterh_we[mhpmcounter_idx] = 1'b1;
				12'h7c0: begin
					cpuctrlsts_part_d = cpuctrlsts_part_wdata;
					cpuctrlsts_part_we = 1'b1;
				end
				default:
					;
			endcase
		(* full_case, parallel_case *)
		case (1'b1)
			csr_save_cause_i: begin
				(* full_case, parallel_case *)
				case (1'b1)
					csr_save_if_i: exception_pc = pc_if_i;
					csr_save_id_i: exception_pc = pc_id_i;
					csr_save_wb_i: exception_pc = pc_wb_i;
					default:
						;
				endcase
				priv_lvl_d = 2'b11;
				if (debug_csr_save_i) begin
					dcsr_d[1-:2] = priv_lvl_q;
					dcsr_d[8-:3] = debug_cause_i;
					dcsr_en = 1'b1;
					depc_d = exception_pc;
					depc_en = 1'b1;
				end
				else if (!debug_mode_i) begin
					mtval_en = 1'b1;
					mtval_d = csr_mtval_i;
					mstatus_en = 1'b1;
					mstatus_d[5] = 1'b0;
					mstatus_d[4] = mstatus_q[5];
					mstatus_d[3-:2] = priv_lvl_q;
					mepc_en = 1'b1;
					mepc_d = exception_pc;
					mcause_en = 1'b1;
					mcause_d = csr_mcause_i;
					mstack_en = 1'b1;
					if (!(mcause_d[5] || mcause_d[6])) begin
						cpuctrlsts_part_we = 1'b1;
						cpuctrlsts_part_d[6] = 1'b1;
						if (cpuctrlsts_part_q[6]) begin
							double_fault_seen_o = 1'b1;
							cpuctrlsts_part_d[7] = 1'b1;
						end
					end
				end
			end
			csr_restore_dret_i: priv_lvl_d = dcsr_q[1-:2];
			csr_restore_mret_i: begin
				priv_lvl_d = mstatus_q[3-:2];
				mstatus_en = 1'b1;
				mstatus_d[5] = mstatus_q[4];
				if (mstatus_q[3-:2] != 2'b11)
					mstatus_d[1] = 1'b0;
				cpuctrlsts_part_we = 1'b1;
				cpuctrlsts_part_d[6] = 1'b0;
				if (nmi_mode_i) begin
					mstatus_d[4] = mstack_q[2];
					mstatus_d[3-:2] = mstack_q[1-:2];
					mepc_en = 1'b1;
					mepc_d = mstack_epc_q;
					mcause_en = 1'b1;
					mcause_d = mstack_cause_q;
				end
				else begin
					mstatus_d[4] = 1'b1;
					mstatus_d[3-:2] = 2'b00;
				end
			end
			default:
				;
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			priv_lvl_q <= 2'b11;
		else
			priv_lvl_q <= priv_lvl_d;
	assign priv_mode_id_o = priv_lvl_q;
	assign priv_mode_lsu_o = (mstatus_q[1] ? mstatus_q[3-:2] : priv_lvl_q);
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (csr_op_i)
			2'd1: csr_wdata_int = csr_wdata_i;
			2'd2: csr_wdata_int = csr_wdata_i | csr_rdata_o;
			2'd3: csr_wdata_int = ~csr_wdata_i & csr_rdata_o;
			2'd0: csr_wdata_int = csr_wdata_i;
			default: csr_wdata_int = csr_wdata_i;
		endcase
	end
	assign csr_wr = |{csr_op_i == 2'd1, csr_op_i == 2'd2, csr_op_i == 2'd3};
	assign csr_we_int = (csr_wr & csr_op_en_i) & ~illegal_csr_insn_o;
	assign csr_rdata_o = csr_rdata_int;
	assign csr_mepc_o = mepc_q;
	assign csr_depc_o = depc_q;
	assign csr_mtvec_o = mtvec_q;
	assign csr_mtval_o = mtval_q;
	assign csr_mstatus_mie_o = mstatus_q[5];
	assign csr_mstatus_tw_o = mstatus_q[0];
	assign debug_single_step_o = dcsr_q[2];
	assign debug_ebreakm_o = dcsr_q[15];
	assign debug_ebreaku_o = dcsr_q[12];
	assign irqs_o = mip & mie_q;
	assign irq_pending_o = |irqs_o;
	localparam [5:0] MSTATUS_RST_VAL = 6'b010000;
	ibex_csr #(
		.Width(6),
		.ShadowCopy(ShadowCSR),
		.ResetValue({MSTATUS_RST_VAL})
	) u_mstatus_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mstatus_d}),
		.wr_en_i(mstatus_en),
		.rd_data_o(mstatus_q),
		.rd_error_o(mstatus_err)
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mepc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mepc_d),
		.wr_en_i(mepc_en),
		.rd_data_o(mepc_q),
		.rd_error_o()
	);
	assign mie_d[17] = csr_wdata_int[ibex_pkg_CSR_MSIX_BIT];
	assign mie_d[16] = csr_wdata_int[ibex_pkg_CSR_MTIX_BIT];
	assign mie_d[15] = csr_wdata_int[ibex_pkg_CSR_MEIX_BIT];
	assign mie_d[14-:15] = csr_wdata_int[ibex_pkg_CSR_MFIX_BIT_HIGH:ibex_pkg_CSR_MFIX_BIT_LOW];
	ibex_csr #(
		.Width(18),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mie_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mie_d}),
		.wr_en_i(mie_en),
		.rd_data_o(mie_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mscratch_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(csr_wdata_int),
		.wr_en_i(mscratch_en),
		.rd_data_o(mscratch_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(7),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mcause_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mcause_d}),
		.wr_en_i(mcause_en),
		.rd_data_o(mcause_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mtval_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mtval_d),
		.wr_en_i(mtval_en),
		.rd_data_o(mtval_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(ShadowCSR),
		.ResetValue(32'd1)
	) u_mtvec_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mtvec_d),
		.wr_en_i(mtvec_en),
		.rd_data_o(mtvec_q),
		.rd_error_o(mtvec_err)
	);
	localparam [31:0] DCSR_RESET_VAL = 32'h40000003;
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue({DCSR_RESET_VAL})
	) u_dcsr_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({dcsr_d}),
		.wr_en_i(dcsr_en),
		.rd_data_o(dcsr_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_depc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(depc_d),
		.wr_en_i(depc_en),
		.rd_data_o(depc_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_dscratch0_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(csr_wdata_int),
		.wr_en_i(dscratch0_en),
		.rd_data_o(dscratch0_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_dscratch1_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(csr_wdata_int),
		.wr_en_i(dscratch1_en),
		.rd_data_o(dscratch1_q),
		.rd_error_o()
	);
	localparam [2:0] MSTACK_RESET_VAL = 3'b100;
	ibex_csr #(
		.Width(3),
		.ShadowCopy(1'b0),
		.ResetValue({MSTACK_RESET_VAL})
	) u_mstack_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({mstack_d}),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(32),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mstack_epc_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mstack_epc_d),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_epc_q),
		.rd_error_o()
	);
	ibex_csr #(
		.Width(7),
		.ShadowCopy(1'b0),
		.ResetValue(1'sb0)
	) u_mstack_cause_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i(mstack_cause_d),
		.wr_en_i(mstack_en),
		.rd_data_o(mstack_cause_q),
		.rd_error_o()
	);
	localparam [11:0] ibex_pkg_CSR_OFF_PMP_ADDR = 12'h3b0;
	localparam [11:0] ibex_pkg_CSR_OFF_PMP_CFG = 12'h3a0;
	generate
		if (PMPEnable) begin : g_pmp_registers
			wire [2:0] pmp_mseccfg_q;
			wire [2:0] pmp_mseccfg_d;
			wire pmp_mseccfg_we;
			wire pmp_mseccfg_err;
			wire [5:0] pmp_cfg [0:PMPNumRegions - 1];
			wire [PMPNumRegions - 1:0] pmp_cfg_locked;
			wire [PMPNumRegions - 1:0] pmp_cfg_wr_suppress;
			reg [5:0] pmp_cfg_wdata [0:PMPNumRegions - 1];
			wire [PMPAddrWidth - 1:0] pmp_addr [0:PMPNumRegions - 1];
			wire [PMPNumRegions - 1:0] pmp_cfg_we;
			wire [PMPNumRegions - 1:0] pmp_cfg_err;
			wire [PMPNumRegions - 1:0] pmp_addr_we;
			wire [PMPNumRegions - 1:0] pmp_addr_err;
			wire any_pmp_entry_locked;
			genvar _gv_i_19;
			for (_gv_i_19 = 0; _gv_i_19 < ibex_pkg_PMP_MAX_REGIONS; _gv_i_19 = _gv_i_19 + 1) begin : g_exp_rd_data
				localparam i = _gv_i_19;
				if (i < PMPNumRegions) begin : g_implemented_regions
					assign pmp_cfg_rdata[i] = {pmp_cfg[i][5], 2'b00, pmp_cfg[i][4-:2], pmp_cfg[i][2], pmp_cfg[i][1], pmp_cfg[i][0]};
					if (PMPGranularity == 0) begin : g_pmp_g0
						wire [32:1] sv2v_tmp_2683A;
						assign sv2v_tmp_2683A = pmp_addr[i];
						always @(*) pmp_addr_rdata[i] = sv2v_tmp_2683A;
					end
					else if (PMPGranularity == 1) begin : g_pmp_g1
						always @(*) begin
							if (_sv2v_0)
								;
							pmp_addr_rdata[i] = pmp_addr[i];
							if ((pmp_cfg[i][4-:2] == 2'b00) || (pmp_cfg[i][4-:2] == 2'b01))
								pmp_addr_rdata[i][PMPGranularity - 1:0] = 1'sb0;
						end
					end
					else begin : g_pmp_g2
						always @(*) begin
							if (_sv2v_0)
								;
							pmp_addr_rdata[i] = {pmp_addr[i], {PMPGranularity - 1 {1'b1}}};
							if ((pmp_cfg[i][4-:2] == 2'b00) || (pmp_cfg[i][4-:2] == 2'b01))
								pmp_addr_rdata[i][PMPGranularity - 1:0] = 1'sb0;
						end
					end
				end
				else begin : g_other_regions
					assign pmp_cfg_rdata[i] = 1'sb0;
					wire [32:1] sv2v_tmp_D50E5;
					assign sv2v_tmp_D50E5 = 1'sb0;
					always @(*) pmp_addr_rdata[i] = sv2v_tmp_D50E5;
				end
			end
			genvar _gv_i_20;
			for (_gv_i_20 = 0; _gv_i_20 < PMPNumRegions; _gv_i_20 = _gv_i_20 + 1) begin : g_pmp_csrs
				localparam i = _gv_i_20;
				assign pmp_cfg_we[i] = ((csr_we_int & ~pmp_cfg_locked[i]) & ~pmp_cfg_wr_suppress[i]) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_CFG + (i[11:0] >> 2)));
				wire [1:1] sv2v_tmp_8F287;
				assign sv2v_tmp_8F287 = csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 7];
				always @(*) pmp_cfg_wdata[i][5] = sv2v_tmp_8F287;
				always @(*) begin
					if (_sv2v_0)
						;
					(* full_case, parallel_case *)
					case (csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 3+:2])
						2'b00: pmp_cfg_wdata[i][4-:2] = 2'b00;
						2'b01: pmp_cfg_wdata[i][4-:2] = 2'b01;
						2'b10: pmp_cfg_wdata[i][4-:2] = (PMPGranularity == 0 ? 2'b10 : 2'b00);
						2'b11: pmp_cfg_wdata[i][4-:2] = 2'b11;
						default: pmp_cfg_wdata[i][4-:2] = 2'b00;
					endcase
				end
				wire [1:1] sv2v_tmp_45785;
				assign sv2v_tmp_45785 = csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 2];
				always @(*) pmp_cfg_wdata[i][2] = sv2v_tmp_45785;
				wire [1:1] sv2v_tmp_BB30C;
				assign sv2v_tmp_BB30C = (pmp_mseccfg_q[0] ? csr_wdata_int[((i % 4) * ibex_pkg_PMP_CFG_W) + 1] : &csr_wdata_int[(i % 4) * ibex_pkg_PMP_CFG_W+:2]);
				always @(*) pmp_cfg_wdata[i][1] = sv2v_tmp_BB30C;
				wire [1:1] sv2v_tmp_F1349;
				assign sv2v_tmp_F1349 = csr_wdata_int[(i % 4) * ibex_pkg_PMP_CFG_W];
				always @(*) pmp_cfg_wdata[i][0] = sv2v_tmp_F1349;
				ibex_csr #(
					.Width(6),
					.ShadowCopy(ShadowCSR),
					.ResetValue(PMPRstCfg[(15 - i) * 6+:6])
				) u_pmp_cfg_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i({pmp_cfg_wdata[i]}),
					.wr_en_i(pmp_cfg_we[i]),
					.rd_data_o(pmp_cfg[i]),
					.rd_error_o(pmp_cfg_err[i])
				);
				assign pmp_cfg_locked[i] = pmp_cfg[i][5] & ~pmp_mseccfg_q[2];
				assign pmp_cfg_wr_suppress[i] = (pmp_mseccfg_q[0] & ~pmp_mseccfg[2]) & is_mml_m_exec_cfg(pmp_cfg_wdata[i]);
				if (i < (PMPNumRegions - 1)) begin : g_lower
					assign pmp_addr_we[i] = ((csr_we_int & ~pmp_cfg_locked[i]) & (~pmp_cfg_locked[i + 1] | (pmp_cfg[i + 1][4-:2] != 2'b01))) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_ADDR + i[11:0]));
				end
				else begin : g_upper
					assign pmp_addr_we[i] = (csr_we_int & ~pmp_cfg_locked[i]) & (csr_addr == (ibex_pkg_CSR_OFF_PMP_ADDR + i[11:0]));
				end
				ibex_csr #(
					.Width(PMPAddrWidth),
					.ShadowCopy(ShadowCSR),
					.ResetValue(PMPRstAddr[((15 - i) * 34) + 33-:PMPAddrWidth])
				) u_pmp_addr_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(csr_wdata_int[31-:PMPAddrWidth]),
					.wr_en_i(pmp_addr_we[i]),
					.rd_data_o(pmp_addr[i]),
					.rd_error_o(pmp_addr_err[i])
				);
				assign csr_pmp_cfg_o[((PMPNumRegions - 1) - i) * 6+:6] = pmp_cfg[i];
				assign csr_pmp_addr_o[((PMPNumRegions - 1) - i) * 34+:34] = {pmp_addr_rdata[i], 2'b00};
			end
			assign pmp_mseccfg_we = csr_we_int & (csr_addr == 12'h747);
			assign pmp_mseccfg_d[0] = (pmp_mseccfg_q[0] ? 1'b1 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_MML_BIT]);
			assign pmp_mseccfg_d[1] = (pmp_mseccfg_q[1] ? 1'b1 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_MMWP_BIT]);
			assign any_pmp_entry_locked = |pmp_cfg_locked;
			assign pmp_mseccfg_d[2] = (any_pmp_entry_locked ? 1'b0 : csr_wdata_int[ibex_pkg_CSR_MSECCFG_RLB_BIT]);
			ibex_csr #(
				.Width(3),
				.ShadowCopy(ShadowCSR),
				.ResetValue(PMPRstMsecCfg)
			) u_pmp_mseccfg(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(pmp_mseccfg_d),
				.wr_en_i(pmp_mseccfg_we),
				.rd_data_o(pmp_mseccfg_q),
				.rd_error_o(pmp_mseccfg_err)
			);
			assign pmp_csr_err = (|pmp_cfg_err | (|pmp_addr_err)) | pmp_mseccfg_err;
			assign pmp_mseccfg = pmp_mseccfg_q;
		end
		else begin : g_no_pmp_tieoffs
			genvar _gv_i_21;
			for (_gv_i_21 = 0; _gv_i_21 < ibex_pkg_PMP_MAX_REGIONS; _gv_i_21 = _gv_i_21 + 1) begin : g_rdata
				localparam i = _gv_i_21;
				wire [32:1] sv2v_tmp_D50E5;
				assign sv2v_tmp_D50E5 = 1'sb0;
				always @(*) pmp_addr_rdata[i] = sv2v_tmp_D50E5;
				assign pmp_cfg_rdata[i] = 1'sb0;
			end
			genvar _gv_i_22;
			for (_gv_i_22 = 0; _gv_i_22 < PMPNumRegions; _gv_i_22 = _gv_i_22 + 1) begin : g_outputs
				localparam i = _gv_i_22;
				assign csr_pmp_cfg_o[((PMPNumRegions - 1) - i) * 6+:6] = 6'b000000;
				assign csr_pmp_addr_o[((PMPNumRegions - 1) - i) * 34+:34] = 1'sb0;
			end
			assign pmp_csr_err = 1'b0;
			assign pmp_mseccfg = 1'sb0;
		end
	endgenerate
	assign csr_pmp_mseccfg_o = pmp_mseccfg;
	always @(*) begin : mcountinhibit_update
		if (_sv2v_0)
			;
		if (mcountinhibit_we == 1'b1)
			mcountinhibit_d = {csr_wdata_int[MHPMCounterNum + 2:2], 1'b0, csr_wdata_int[0]};
		else
			mcountinhibit_d = mcountinhibit_q;
	end
	always @(*) begin : gen_mhpmcounter_incr
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				begin : gen_mhpmcounter_incr_inactive
					mhpmcounter_incr[i] = 1'b0;
				end
		end
		mhpmcounter_incr[0] = 1'b1;
		mhpmcounter_incr[1] = 1'b0;
		mhpmcounter_incr[2] = instr_ret_i;
		mhpmcounter_incr[3] = dside_wait_i;
		mhpmcounter_incr[4] = iside_wait_i;
		mhpmcounter_incr[5] = mem_load_i;
		mhpmcounter_incr[6] = mem_store_i;
		mhpmcounter_incr[7] = jump_i;
		mhpmcounter_incr[8] = branch_i;
		mhpmcounter_incr[9] = branch_taken_i;
		mhpmcounter_incr[10] = instr_ret_compressed_i;
		mhpmcounter_incr[11] = mul_wait_i;
		mhpmcounter_incr[12] = div_wait_i;
	end
	always @(*) begin : gen_mhpmevent
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_2
			reg signed [31:0] i;
			for (i = 0; i < 32; i = i + 1)
				begin : gen_mhpmevent_active
					mhpmevent[i] = 1'sb0;
					if (i >= 3)
						mhpmevent[i][i - 3] = 1'b1;
				end
		end
		mhpmevent[1] = 1'sb0;
		begin : sv2v_autoblock_3
			reg [31:0] i;
			for (i = 3 + MHPMCounterNum; i < 32; i = i + 1)
				begin : gen_mhpmevent_inactive
					mhpmevent[i] = 1'sb0;
				end
		end
	end
	ibex_counter #(.CounterWidth(64)) mcycle_counter_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.counter_inc_i(mhpmcounter_incr[0] & ~mcountinhibit[0]),
		.counterh_we_i(mhpmcounterh_we[0]),
		.counter_we_i(mhpmcounter_we[0]),
		.counter_val_i(csr_wdata_int),
		.counter_val_o(mhpmcounter[0]),
		.counter_val_upd_o()
	);
	ibex_counter #(
		.CounterWidth(64),
		.ProvideValUpd(1)
	) minstret_counter_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.counter_inc_i(mhpmcounter_incr[2] & ~mcountinhibit[2]),
		.counterh_we_i(mhpmcounterh_we[2]),
		.counter_we_i(mhpmcounter_we[2]),
		.counter_val_i(csr_wdata_int),
		.counter_val_o(minstret_raw),
		.counter_val_upd_o(minstret_next)
	);
	assign mhpmcounter[2] = (instr_ret_spec_i & ~mcountinhibit[2] ? minstret_next : minstret_raw);
	assign mhpmcounter[1] = 1'sb0;
	assign unused_mhpmcounter_we_1 = mhpmcounter_we[1];
	assign unused_mhpmcounterh_we_1 = mhpmcounterh_we[1];
	assign unused_mhpmcounter_incr_1 = mhpmcounter_incr[1];
	genvar _gv_i_23;
	generate
		for (_gv_i_23 = 0; _gv_i_23 < 29; _gv_i_23 = _gv_i_23 + 1) begin : gen_cntrs
			localparam i = _gv_i_23;
			localparam signed [31:0] Cnt = i + 3;
			if (i < MHPMCounterNum) begin : gen_imp
				wire [63:0] mhpmcounter_raw;
				wire [63:0] mhpmcounter_next;
				ibex_counter #(
					.CounterWidth(MHPMCounterWidth),
					.ProvideValUpd(Cnt == 10)
				) mcounters_variable_i(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.counter_inc_i(mhpmcounter_incr[Cnt] & ~mcountinhibit[Cnt]),
					.counterh_we_i(mhpmcounterh_we[Cnt]),
					.counter_we_i(mhpmcounter_we[Cnt]),
					.counter_val_i(csr_wdata_int),
					.counter_val_o(mhpmcounter_raw),
					.counter_val_upd_o(mhpmcounter_next)
				);
				if (Cnt == 10) begin : gen_compressed_instr_cnt
					assign mhpmcounter[Cnt] = (instr_ret_compressed_spec_i & ~mcountinhibit[Cnt] ? mhpmcounter_next : mhpmcounter_raw);
				end
				else begin : gen_other_cnts
					wire [63:0] unused_mhpmcounter_next;
					assign mhpmcounter[Cnt] = mhpmcounter_raw;
					assign unused_mhpmcounter_next = mhpmcounter_next;
				end
			end
			else begin : gen_unimp
				assign mhpmcounter[Cnt] = 1'sb0;
				if (Cnt == 10) begin : gen_no_compressed_instr_cnt
					wire unused_instr_ret_compressed_spec_i;
					assign unused_instr_ret_compressed_spec_i = instr_ret_compressed_spec_i;
				end
			end
		end
		if (MHPMCounterNum < 29) begin : g_mcountinhibit_reduced
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounter_we;
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounterh_we;
			wire [(29 - MHPMCounterNum) - 1:0] unused_mhphcounter_incr;
			assign mcountinhibit = {{29 - MHPMCounterNum {1'b0}}, mcountinhibit_q};
			assign unused_mhphcounter_we = mhpmcounter_we[31:MHPMCounterNum + 3];
			assign unused_mhphcounterh_we = mhpmcounterh_we[31:MHPMCounterNum + 3];
			assign unused_mhphcounter_incr = mhpmcounter_incr[31:MHPMCounterNum + 3];
		end
		else begin : g_mcountinhibit_full
			assign mcountinhibit = mcountinhibit_q;
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			mcountinhibit_q <= 1'sb0;
		else
			mcountinhibit_q <= mcountinhibit_d;
	generate
		if (DbgTriggerEn) begin : gen_trigger_regs
			localparam [31:0] DbgHwNumLen = (DbgHwBreakNum > 1 ? $clog2(DbgHwBreakNum) : 1);
			localparam [31:0] MaxTselect = DbgHwBreakNum - 1;
			wire [DbgHwNumLen - 1:0] tselect_d;
			wire [DbgHwNumLen - 1:0] tselect_q;
			wire tmatch_control_d;
			wire [DbgHwBreakNum - 1:0] tmatch_control_q;
			wire [31:0] tmatch_value_d;
			wire [31:0] tmatch_value_q [0:DbgHwBreakNum - 1];
			wire selected_tmatch_control;
			wire [31:0] selected_tmatch_value;
			wire tselect_we;
			wire [DbgHwBreakNum - 1:0] tmatch_control_we;
			wire [DbgHwBreakNum - 1:0] tmatch_value_we;
			wire [DbgHwBreakNum - 1:0] trigger_match;
			assign tselect_we = (csr_we_int & debug_mode_i) & (csr_addr_i == 12'h7a0);
			genvar _gv_i_24;
			for (_gv_i_24 = 0; _gv_i_24 < DbgHwBreakNum; _gv_i_24 = _gv_i_24 + 1) begin : g_dbg_tmatch_we
				localparam i = _gv_i_24;
				assign tmatch_control_we[i] = (((i[DbgHwNumLen - 1:0] == tselect_q) & csr_we_int) & debug_mode_i) & (csr_addr_i == 12'h7a1);
				assign tmatch_value_we[i] = (((i[DbgHwNumLen - 1:0] == tselect_q) & csr_we_int) & debug_mode_i) & (csr_addr_i == 12'h7a2);
			end
			assign tselect_d = (csr_wdata_int < DbgHwBreakNum ? csr_wdata_int[DbgHwNumLen - 1:0] : MaxTselect[DbgHwNumLen - 1:0]);
			assign tmatch_control_d = csr_wdata_int[2];
			assign tmatch_value_d = csr_wdata_int[31:0];
			ibex_csr #(
				.Width(DbgHwNumLen),
				.ShadowCopy(1'b0),
				.ResetValue(1'sb0)
			) u_tselect_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(tselect_d),
				.wr_en_i(tselect_we),
				.rd_data_o(tselect_q),
				.rd_error_o()
			);
			genvar _gv_i_25;
			for (_gv_i_25 = 0; _gv_i_25 < DbgHwBreakNum; _gv_i_25 = _gv_i_25 + 1) begin : g_dbg_tmatch_reg
				localparam i = _gv_i_25;
				ibex_csr #(
					.Width(1),
					.ShadowCopy(1'b0),
					.ResetValue(1'sb0)
				) u_tmatch_control_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(tmatch_control_d),
					.wr_en_i(tmatch_control_we[i]),
					.rd_data_o(tmatch_control_q[i]),
					.rd_error_o()
				);
				ibex_csr #(
					.Width(32),
					.ShadowCopy(1'b0),
					.ResetValue(1'sb0)
				) u_tmatch_value_csr(
					.clk_i(clk_i),
					.rst_ni(rst_ni),
					.wr_data_i(tmatch_value_d),
					.wr_en_i(tmatch_value_we[i]),
					.rd_data_o(tmatch_value_q[i]),
					.rd_error_o()
				);
			end
			localparam [31:0] TSelectRdataPadlen = (DbgHwNumLen >= 32 ? 0 : 32 - DbgHwNumLen);
			assign tselect_rdata = {{TSelectRdataPadlen {1'b0}}, tselect_q};
			if (DbgHwBreakNum > 1) begin : g_dbg_tmatch_multiple_select
				assign selected_tmatch_control = tmatch_control_q[tselect_q];
				assign selected_tmatch_value = tmatch_value_q[tselect_q];
			end
			else begin : g_dbg_tmatch_single_select
				assign selected_tmatch_control = tmatch_control_q[0];
				assign selected_tmatch_value = tmatch_value_q[0];
			end
			assign tmatch_control_rdata = {29'h05000209, selected_tmatch_control, 2'b00};
			assign tmatch_value_rdata = selected_tmatch_value;
			genvar _gv_i_26;
			for (_gv_i_26 = 0; _gv_i_26 < DbgHwBreakNum; _gv_i_26 = _gv_i_26 + 1) begin : g_dbg_trigger_match
				localparam i = _gv_i_26;
				assign trigger_match[i] = tmatch_control_q[i] & (pc_if_i[31:0] == tmatch_value_q[i]);
			end
			assign trigger_match_o = |trigger_match;
		end
		else begin : gen_no_trigger_regs
			assign tselect_rdata = 'b0;
			assign tmatch_control_rdata = 'b0;
			assign tmatch_value_rdata = 'b0;
			assign trigger_match_o = 'b0;
		end
	endgenerate
	assign cpuctrlsts_part_wdata_raw = csr_wdata_int[7:0];
	generate
		if (DataIndTiming) begin : gen_dit
			assign cpuctrlsts_part_wdata[1] = cpuctrlsts_part_wdata_raw[1];
		end
		else begin : gen_no_dit
			wire unused_dit;
			assign unused_dit = cpuctrlsts_part_wdata_raw[1];
			assign cpuctrlsts_part_wdata[1] = 1'b0;
		end
	endgenerate
	assign data_ind_timing_o = cpuctrlsts_part_q[1];
	generate
		if (DummyInstructions) begin : gen_dummy
			assign cpuctrlsts_part_wdata[2] = cpuctrlsts_part_wdata_raw[2];
			assign cpuctrlsts_part_wdata[5-:3] = cpuctrlsts_part_wdata_raw[5-:3];
			assign dummy_instr_seed_en_o = csr_we_int && (csr_addr == 12'h7c1);
			assign dummy_instr_seed_o = csr_wdata_int;
		end
		else begin : gen_no_dummy
			wire unused_dummy_en;
			wire [2:0] unused_dummy_mask;
			assign unused_dummy_en = cpuctrlsts_part_wdata_raw[2];
			assign unused_dummy_mask = cpuctrlsts_part_wdata_raw[5-:3];
			assign cpuctrlsts_part_wdata[2] = 1'b0;
			assign cpuctrlsts_part_wdata[5-:3] = 3'b000;
			assign dummy_instr_seed_en_o = 1'b0;
			assign dummy_instr_seed_o = 1'sb0;
		end
	endgenerate
	assign dummy_instr_en_o = cpuctrlsts_part_q[2];
	assign dummy_instr_mask_o = cpuctrlsts_part_q[5-:3];
	generate
		if (ICache) begin : gen_icache_enable
			assign cpuctrlsts_part_wdata[0] = cpuctrlsts_part_wdata_raw[0];
			ibex_csr #(
				.Width(1),
				.ShadowCopy(ShadowCSR),
				.ResetValue(1'b0)
			) u_cpuctrlsts_ic_scr_key_valid_q_csr(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.wr_data_i(ic_scr_key_valid_i),
				.wr_en_i(1'b1),
				.rd_data_o(cpuctrlsts_ic_scr_key_valid_q),
				.rd_error_o(cpuctrlsts_ic_scr_key_err)
			);
		end
		else begin : gen_no_icache
			wire unused_icen;
			assign unused_icen = cpuctrlsts_part_wdata_raw[0];
			assign cpuctrlsts_part_wdata[0] = 1'b0;
			wire unused_ic_scr_key_valid;
			assign unused_ic_scr_key_valid = ic_scr_key_valid_i;
			assign cpuctrlsts_ic_scr_key_valid_q = 1'b0;
			assign cpuctrlsts_ic_scr_key_err = 1'b0;
		end
	endgenerate
	assign cpuctrlsts_part_wdata[7] = cpuctrlsts_part_wdata_raw[7];
	assign cpuctrlsts_part_wdata[6] = cpuctrlsts_part_wdata_raw[6];
	assign icache_enable_o = cpuctrlsts_part_q[0] & ~(debug_mode_i | debug_mode_entering_i);
	ibex_csr #(
		.Width(8),
		.ShadowCopy(ShadowCSR),
		.ResetValue(1'sb0)
	) u_cpuctrlsts_part_csr(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wr_data_i({cpuctrlsts_part_d}),
		.wr_en_i(cpuctrlsts_part_we),
		.rd_data_o(cpuctrlsts_part_q),
		.rd_error_o(cpuctrlsts_part_err)
	);
	assign csr_shadow_err_o = (((mstatus_err | mtvec_err) | pmp_csr_err) | cpuctrlsts_part_err) | cpuctrlsts_ic_scr_key_err;
	initial _sv2v_0 = 0;
endmodule
module ibex_csr (
	clk_i,
	rst_ni,
	wr_data_i,
	wr_en_i,
	rd_data_o,
	rd_error_o
);
	parameter [31:0] Width = 32;
	parameter [0:0] ShadowCopy = 1'b0;
	parameter [Width - 1:0] ResetValue = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	input wire [Width - 1:0] wr_data_i;
	input wire wr_en_i;
	output wire [Width - 1:0] rd_data_o;
	output wire rd_error_o;
	reg [Width - 1:0] rdata_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rdata_q <= ResetValue;
		else if (wr_en_i)
			rdata_q <= wr_data_i;
	assign rd_data_o = rdata_q;
	generate
		if (ShadowCopy) begin : gen_shadow
			reg [Width - 1:0] shadow_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					shadow_q <= ~ResetValue;
				else if (wr_en_i)
					shadow_q <= ~wr_data_i;
			assign rd_error_o = rdata_q != ~shadow_q;
		end
		else begin : gen_no_shadow
			assign rd_error_o = 1'b0;
		end
	endgenerate
endmodule
module ibex_decoder (
	clk_i,
	rst_ni,
	illegal_insn_o,
	ebrk_insn_o,
	mret_insn_o,
	dret_insn_o,
	ecall_insn_o,
	wfi_insn_o,
	jump_set_o,
	branch_taken_i,
	icache_inval_o,
	instr_first_cycle_i,
	instr_rdata_i,
	instr_rdata_alu_i,
	illegal_c_insn_i,
	imm_a_mux_sel_o,
	imm_b_mux_sel_o,
	bt_a_mux_sel_o,
	bt_b_mux_sel_o,
	imm_i_type_o,
	imm_s_type_o,
	imm_b_type_o,
	imm_u_type_o,
	imm_j_type_o,
	zimm_rs1_type_o,
	rf_wdata_sel_o,
	rf_we_o,
	rf_raddr_a_o,
	rf_raddr_b_o,
	rf_waddr_o,
	rf_ren_a_o,
	rf_ren_b_o,
	alu_operator_o,
	alu_op_a_mux_sel_o,
	alu_op_b_mux_sel_o,
	alu_multicycle_o,
	mult_en_o,
	div_en_o,
	mult_sel_o,
	div_sel_o,
	multdiv_operator_o,
	multdiv_signed_mode_o,
	csr_access_o,
	csr_op_o,
	csr_addr_o,
	data_req_o,
	data_we_o,
	data_type_o,
	data_sign_extension_o,
	jump_in_dec_o,
	branch_in_dec_o
);
	reg _sv2v_0;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 0;
	input wire clk_i;
	input wire rst_ni;
	output wire illegal_insn_o;
	output reg ebrk_insn_o;
	output reg mret_insn_o;
	output reg dret_insn_o;
	output reg ecall_insn_o;
	output reg wfi_insn_o;
	output reg jump_set_o;
	input wire branch_taken_i;
	output reg icache_inval_o;
	input wire instr_first_cycle_i;
	input wire [31:0] instr_rdata_i;
	input wire [31:0] instr_rdata_alu_i;
	input wire illegal_c_insn_i;
	output reg imm_a_mux_sel_o;
	output reg [2:0] imm_b_mux_sel_o;
	output reg [1:0] bt_a_mux_sel_o;
	output reg [2:0] bt_b_mux_sel_o;
	output wire [31:0] imm_i_type_o;
	output wire [31:0] imm_s_type_o;
	output wire [31:0] imm_b_type_o;
	output wire [31:0] imm_u_type_o;
	output wire [31:0] imm_j_type_o;
	output wire [31:0] zimm_rs1_type_o;
	output reg rf_wdata_sel_o;
	output wire rf_we_o;
	output wire [4:0] rf_raddr_a_o;
	output wire [4:0] rf_raddr_b_o;
	output wire [4:0] rf_waddr_o;
	output reg rf_ren_a_o;
	output reg rf_ren_b_o;
	output reg [6:0] alu_operator_o;
	output reg [1:0] alu_op_a_mux_sel_o;
	output reg alu_op_b_mux_sel_o;
	output reg alu_multicycle_o;
	output wire mult_en_o;
	output wire div_en_o;
	output reg mult_sel_o;
	output reg div_sel_o;
	output reg [1:0] multdiv_operator_o;
	output reg [1:0] multdiv_signed_mode_o;
	output reg csr_access_o;
	output reg [1:0] csr_op_o;
	output wire [11:0] csr_addr_o;
	output reg data_req_o;
	output reg data_we_o;
	output reg [1:0] data_type_o;
	output reg data_sign_extension_o;
	output reg jump_in_dec_o;
	output reg branch_in_dec_o;
	reg illegal_insn;
	wire illegal_reg_rv32e;
	reg csr_illegal;
	reg rf_we;
	wire [31:0] instr;
	wire [31:0] instr_alu;
	wire [9:0] unused_instr_alu;
	wire [4:0] instr_rs1;
	wire [4:0] instr_rs2;
	wire [4:0] instr_rs3;
	wire [4:0] instr_rd;
	reg use_rs3_d;
	reg use_rs3_q;
	reg [1:0] csr_op;
	reg [6:0] opcode;
	reg [6:0] opcode_alu;
	assign instr = instr_rdata_i;
	assign instr_alu = instr_rdata_alu_i;
	assign imm_i_type_o = {{20 {instr[31]}}, instr[31:20]};
	assign imm_s_type_o = {{20 {instr[31]}}, instr[31:25], instr[11:7]};
	assign imm_b_type_o = {{19 {instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
	assign imm_u_type_o = {instr[31:12], 12'b000000000000};
	assign imm_j_type_o = {{12 {instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
	assign csr_addr_o = instr[31:20];
	assign zimm_rs1_type_o = {27'b000000000000000000000000000, instr_rs1};
	generate
		if (RV32B != 32'sd0) begin : gen_rs3_flop
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					use_rs3_q <= 1'b0;
				else
					use_rs3_q <= use_rs3_d;
		end
		else begin : gen_no_rs3_flop
			wire unused_clk;
			wire unused_rst_n;
			assign unused_clk = clk_i;
			assign unused_rst_n = rst_ni;
			wire [1:1] sv2v_tmp_12378;
			assign sv2v_tmp_12378 = use_rs3_d;
			always @(*) use_rs3_q = sv2v_tmp_12378;
		end
	endgenerate
	assign instr_rs1 = instr[19:15];
	assign instr_rs2 = instr[24:20];
	assign instr_rs3 = instr[31:27];
	assign rf_raddr_a_o = (use_rs3_q & ~instr_first_cycle_i ? instr_rs3 : instr_rs1);
	assign rf_raddr_b_o = instr_rs2;
	assign instr_rd = instr[11:7];
	assign rf_waddr_o = instr_rd;
	generate
		if (RV32E) begin : gen_rv32e_reg_check_active
			assign illegal_reg_rv32e = ((rf_raddr_a_o[4] & (alu_op_a_mux_sel_o == 2'd0)) | (rf_raddr_b_o[4] & (alu_op_b_mux_sel_o == 1'd0))) | (rf_waddr_o[4] & rf_we);
		end
		else begin : gen_rv32e_reg_check_inactive
			assign illegal_reg_rv32e = 1'b0;
		end
	endgenerate
	always @(*) begin : csr_operand_check
		if (_sv2v_0)
			;
		csr_op_o = csr_op;
		if (((csr_op == 2'd2) || (csr_op == 2'd3)) && (instr_rs1 == {5 {1'sb0}}))
			csr_op_o = 2'd0;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		jump_in_dec_o = 1'b0;
		jump_set_o = 1'b0;
		branch_in_dec_o = 1'b0;
		icache_inval_o = 1'b0;
		multdiv_operator_o = 2'd0;
		multdiv_signed_mode_o = 2'b00;
		rf_wdata_sel_o = 1'd0;
		rf_we = 1'b0;
		rf_ren_a_o = 1'b0;
		rf_ren_b_o = 1'b0;
		csr_access_o = 1'b0;
		csr_illegal = 1'b0;
		csr_op = 2'd0;
		data_we_o = 1'b0;
		data_type_o = 2'b00;
		data_sign_extension_o = 1'b0;
		data_req_o = 1'b0;
		illegal_insn = 1'b0;
		ebrk_insn_o = 1'b0;
		mret_insn_o = 1'b0;
		dret_insn_o = 1'b0;
		ecall_insn_o = 1'b0;
		wfi_insn_o = 1'b0;
		opcode = instr[6:0];
		(* full_case, parallel_case *)
		case (opcode)
			7'h6f: begin
				jump_in_dec_o = 1'b1;
				if (instr_first_cycle_i) begin
					rf_we = BranchTargetALU;
					jump_set_o = 1'b1;
				end
				else
					rf_we = 1'b1;
			end
			7'h67: begin
				jump_in_dec_o = 1'b1;
				if (instr_first_cycle_i) begin
					rf_we = BranchTargetALU;
					jump_set_o = 1'b1;
				end
				else
					rf_we = 1'b1;
				if (instr[14:12] != 3'b000)
					illegal_insn = 1'b1;
				rf_ren_a_o = 1'b1;
			end
			7'h63: begin
				branch_in_dec_o = 1'b1;
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000, 3'b001, 3'b100, 3'b101, 3'b110, 3'b111: illegal_insn = 1'b0;
					default: illegal_insn = 1'b1;
				endcase
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
			end
			7'h23: begin
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
				data_req_o = 1'b1;
				data_we_o = 1'b1;
				if (instr[14])
					illegal_insn = 1'b1;
				(* full_case, parallel_case *)
				case (instr[13:12])
					2'b00: data_type_o = 2'b10;
					2'b01: data_type_o = 2'b01;
					2'b10: data_type_o = 2'b00;
					default: illegal_insn = 1'b1;
				endcase
			end
			7'h03: begin
				rf_ren_a_o = 1'b1;
				data_req_o = 1'b1;
				data_type_o = 2'b00;
				data_sign_extension_o = ~instr[14];
				(* full_case, parallel_case *)
				case (instr[13:12])
					2'b00: data_type_o = 2'b10;
					2'b01: data_type_o = 2'b01;
					2'b10: begin
						data_type_o = 2'b00;
						if (instr[14])
							illegal_insn = 1'b1;
					end
					default: illegal_insn = 1'b1;
				endcase
			end
			7'h37: rf_we = 1'b1;
			7'h17: rf_we = 1'b1;
			7'h13: begin
				rf_ren_a_o = 1'b1;
				rf_we = 1'b1;
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000, 3'b010, 3'b011, 3'b100, 3'b110, 3'b111: illegal_insn = 1'b0;
					3'b001:
						(* full_case, parallel_case *)
						case (instr[31:27])
							5'b00000: illegal_insn = (instr[26:25] == 2'b00 ? 1'b0 : 1'b1);
							5'b00100: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
							5'b01001, 5'b00101, 5'b01101: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
							5'b00001:
								if (instr[26] == 1'b0)
									illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
								else
									illegal_insn = 1'b1;
							5'b01100:
								(* full_case, parallel_case *)
								case (instr[26:20])
									7'b0000000, 7'b0000001, 7'b0000010, 7'b0000100, 7'b0000101: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
									7'b0010000, 7'b0010001, 7'b0010010, 7'b0011000, 7'b0011001, 7'b0011010: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
									default: illegal_insn = 1'b1;
								endcase
							default: illegal_insn = 1'b1;
						endcase
					3'b101:
						if (instr[26])
							illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
						else
							(* full_case, parallel_case *)
							case (instr[31:27])
								5'b00000, 5'b01000: illegal_insn = (instr[26:25] == 2'b00 ? 1'b0 : 1'b1);
								5'b00100: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
								5'b01100, 5'b01001: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
								5'b01101:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										illegal_insn = 1'b0;
									else if (RV32B == 32'sd1)
										illegal_insn = (instr[24:20] == 5'b11000 ? 1'b0 : 1'b1);
									else
										illegal_insn = 1'b1;
								5'b00101:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										illegal_insn = 1'b0;
									else if (instr[24:20] == 5'b00111)
										illegal_insn = (RV32B == 32'sd1 ? 1'b0 : 1'b1);
									else
										illegal_insn = 1'b1;
								5'b00001:
									if (instr[26] == 1'b0)
										illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
									else
										illegal_insn = 1'b1;
								default: illegal_insn = 1'b1;
							endcase
					default: illegal_insn = 1'b1;
				endcase
			end
			7'h33: begin
				rf_ren_a_o = 1'b1;
				rf_ren_b_o = 1'b1;
				rf_we = 1'b1;
				if ({instr[26], instr[13:12]} == 3'b101)
					illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
				else
					(* full_case, parallel_case *)
					case ({instr[31:25], instr[14:12]})
						10'b0000000000, 10'b0100000000, 10'b0000000010, 10'b0000000011, 10'b0000000100, 10'b0000000110, 10'b0000000111, 10'b0000000001, 10'b0000000101, 10'b0100000101: illegal_insn = 1'b0;
						10'b0010000010, 10'b0010000100, 10'b0010000110, 10'b0100000111, 10'b0100000110, 10'b0100000100, 10'b0110000001, 10'b0110000101, 10'b0000101100, 10'b0000101110, 10'b0000101101, 10'b0000101111, 10'b0000100100, 10'b0100100100, 10'b0000100111, 10'b0100100001, 10'b0010100001, 10'b0110100001, 10'b0100100101, 10'b0100100111: illegal_insn = (RV32B != 32'sd0 ? 1'b0 : 1'b1);
						10'b0110100101, 10'b0010100101, 10'b0000100001, 10'b0000100101, 10'b0010100010, 10'b0010100100, 10'b0010100110, 10'b0010000001, 10'b0010000101, 10'b0000101001, 10'b0000101010, 10'b0000101011: illegal_insn = ((RV32B == 32'sd2) || (RV32B == 32'sd3) ? 1'b0 : 1'b1);
						10'b0100100110, 10'b0000100110: illegal_insn = (RV32B == 32'sd3 ? 1'b0 : 1'b1);
						10'b0000001000: begin
							multdiv_operator_o = 2'd0;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001001: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001010: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b01;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001011: begin
							multdiv_operator_o = 2'd1;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001100: begin
							multdiv_operator_o = 2'd2;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001101: begin
							multdiv_operator_o = 2'd2;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001110: begin
							multdiv_operator_o = 2'd3;
							multdiv_signed_mode_o = 2'b11;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						10'b0000001111: begin
							multdiv_operator_o = 2'd3;
							multdiv_signed_mode_o = 2'b00;
							illegal_insn = (RV32M == 32'sd0 ? 1'b1 : 1'b0);
						end
						default: illegal_insn = 1'b1;
					endcase
			end
			7'h0f:
				(* full_case, parallel_case *)
				case (instr[14:12])
					3'b000: rf_we = 1'b0;
					3'b001: begin
						jump_in_dec_o = 1'b1;
						rf_we = 1'b0;
						if (instr_first_cycle_i) begin
							jump_set_o = 1'b1;
							icache_inval_o = 1'b1;
						end
					end
					default: illegal_insn = 1'b1;
				endcase
			7'h73:
				if (instr[14:12] == 3'b000) begin
					(* full_case, parallel_case *)
					case (instr[31:20])
						12'h000: ecall_insn_o = 1'b1;
						12'h001: ebrk_insn_o = 1'b1;
						12'h302: mret_insn_o = 1'b1;
						12'h7b2: dret_insn_o = 1'b1;
						12'h105: wfi_insn_o = 1'b1;
						default: illegal_insn = 1'b1;
					endcase
					if ((instr_rs1 != 5'b00000) || (instr_rd != 5'b00000))
						illegal_insn = 1'b1;
				end
				else begin
					csr_access_o = 1'b1;
					rf_wdata_sel_o = 1'd1;
					rf_we = 1'b1;
					if (~instr[14])
						rf_ren_a_o = 1'b1;
					(* full_case, parallel_case *)
					case (instr[13:12])
						2'b01: csr_op = 2'd1;
						2'b10: csr_op = 2'd2;
						2'b11: csr_op = 2'd3;
						default: csr_illegal = 1'b1;
					endcase
					illegal_insn = csr_illegal;
				end
			default: illegal_insn = 1'b1;
		endcase
		if (illegal_c_insn_i)
			illegal_insn = 1'b1;
		if (illegal_insn) begin
			rf_we = 1'b0;
			data_req_o = 1'b0;
			data_we_o = 1'b0;
			jump_in_dec_o = 1'b0;
			jump_set_o = 1'b0;
			branch_in_dec_o = 1'b0;
			csr_access_o = 1'b0;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		alu_operator_o = 7'd44;
		alu_op_a_mux_sel_o = 2'd3;
		alu_op_b_mux_sel_o = 1'd1;
		imm_a_mux_sel_o = 1'd1;
		imm_b_mux_sel_o = 3'd0;
		bt_a_mux_sel_o = 2'd2;
		bt_b_mux_sel_o = 3'd0;
		opcode_alu = instr_alu[6:0];
		use_rs3_d = 1'b0;
		alu_multicycle_o = 1'b0;
		mult_sel_o = 1'b0;
		div_sel_o = 1'b0;
		(* full_case, parallel_case *)
		case (opcode_alu)
			7'h6f: begin
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd2;
					bt_b_mux_sel_o = 3'd4;
				end
				if (instr_first_cycle_i && !BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd4;
					alu_operator_o = 7'd0;
				end
				else begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd5;
					alu_operator_o = 7'd0;
				end
			end
			7'h67: begin
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd0;
					bt_b_mux_sel_o = 3'd0;
				end
				if (instr_first_cycle_i && !BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd0;
					alu_operator_o = 7'd0;
				end
				else begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = 3'd5;
					alu_operator_o = 7'd0;
				end
			end
			7'h63: begin
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: alu_operator_o = 7'd29;
					3'b001: alu_operator_o = 7'd30;
					3'b100: alu_operator_o = 7'd25;
					3'b101: alu_operator_o = 7'd27;
					3'b110: alu_operator_o = 7'd26;
					3'b111: alu_operator_o = 7'd28;
					default:
						;
				endcase
				if (BranchTargetALU) begin
					bt_a_mux_sel_o = 2'd2;
					bt_b_mux_sel_o = (branch_taken_i ? 3'd2 : 3'd5);
				end
				if (instr_first_cycle_i) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd0;
				end
				else if (!BranchTargetALU) begin
					alu_op_a_mux_sel_o = 2'd2;
					alu_op_b_mux_sel_o = 1'd1;
					imm_b_mux_sel_o = (branch_taken_i ? 3'd2 : 3'd5);
					alu_operator_o = 7'd0;
				end
			end
			7'h23: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd0;
				alu_operator_o = 7'd0;
				if (!instr_alu[14]) begin
					imm_b_mux_sel_o = 3'd1;
					alu_op_b_mux_sel_o = 1'd1;
				end
			end
			7'h03: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_operator_o = 7'd0;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd0;
			end
			7'h37: begin
				alu_op_a_mux_sel_o = 2'd3;
				alu_op_b_mux_sel_o = 1'd1;
				imm_a_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd3;
				alu_operator_o = 7'd0;
			end
			7'h17: begin
				alu_op_a_mux_sel_o = 2'd2;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd3;
				alu_operator_o = 7'd0;
			end
			7'h13: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd1;
				imm_b_mux_sel_o = 3'd0;
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: alu_operator_o = 7'd0;
					3'b010: alu_operator_o = 7'd43;
					3'b011: alu_operator_o = 7'd44;
					3'b100: alu_operator_o = 7'd2;
					3'b110: alu_operator_o = 7'd3;
					3'b111: alu_operator_o = 7'd4;
					3'b001:
						if (RV32B != 32'sd0)
							(* full_case, parallel_case *)
							case (instr_alu[31:27])
								5'b00000: alu_operator_o = 7'd10;
								5'b00100:
									if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
										alu_operator_o = 7'd12;
								5'b01001: alu_operator_o = 7'd50;
								5'b00101: alu_operator_o = 7'd49;
								5'b01101: alu_operator_o = 7'd51;
								5'b00001:
									if (instr_alu[26] == 0)
										alu_operator_o = 7'd17;
								5'b01100:
									(* full_case, parallel_case *)
									case (instr_alu[26:20])
										7'b0000000: alu_operator_o = 7'd40;
										7'b0000001: alu_operator_o = 7'd41;
										7'b0000010: alu_operator_o = 7'd42;
										7'b0000100: alu_operator_o = 7'd38;
										7'b0000101: alu_operator_o = 7'd39;
										7'b0010000:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd59;
												alu_multicycle_o = 1'b1;
											end
										7'b0010001:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd61;
												alu_multicycle_o = 1'b1;
											end
										7'b0010010:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd63;
												alu_multicycle_o = 1'b1;
											end
										7'b0011000:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd60;
												alu_multicycle_o = 1'b1;
											end
										7'b0011001:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd62;
												alu_multicycle_o = 1'b1;
											end
										7'b0011010:
											if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
												alu_operator_o = 7'd64;
												alu_multicycle_o = 1'b1;
											end
										default:
											;
									endcase
								default:
									;
							endcase
						else
							alu_operator_o = 7'd10;
					3'b101:
						if (RV32B != 32'sd0) begin
							if (instr_alu[26] == 1'b1) begin
								alu_operator_o = 7'd48;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							else
								(* full_case, parallel_case *)
								case (instr_alu[31:27])
									5'b00000: alu_operator_o = 7'd9;
									5'b01000: alu_operator_o = 7'd8;
									5'b00100:
										if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
											alu_operator_o = 7'd11;
									5'b01001: alu_operator_o = 7'd52;
									5'b01100: begin
										alu_operator_o = 7'd13;
										alu_multicycle_o = 1'b1;
									end
									5'b01101: alu_operator_o = 7'd15;
									5'b00101: alu_operator_o = 7'd16;
									5'b00001:
										if ((RV32B == 32'sd2) || (RV32B == 32'sd3)) begin
											if (instr_alu[26] == 1'b0)
												alu_operator_o = 7'd18;
										end
									default:
										;
								endcase
						end
						else if (instr_alu[31:27] == 5'b00000)
							alu_operator_o = 7'd9;
						else if (instr_alu[31:27] == 5'b01000)
							alu_operator_o = 7'd8;
					default:
						;
				endcase
			end
			7'h33: begin
				alu_op_a_mux_sel_o = 2'd0;
				alu_op_b_mux_sel_o = 1'd0;
				if (instr_alu[26]) begin
					if (RV32B != 32'sd0)
						(* full_case, parallel_case *)
						case ({instr_alu[26:25], instr_alu[14:12]})
							5'b11001: begin
								alu_operator_o = 7'd46;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b11101: begin
								alu_operator_o = 7'd45;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b10001: begin
								alu_operator_o = 7'd47;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							5'b10101: begin
								alu_operator_o = 7'd48;
								alu_multicycle_o = 1'b1;
								if (instr_first_cycle_i)
									use_rs3_d = 1'b1;
								else
									use_rs3_d = 1'b0;
							end
							default:
								;
						endcase
				end
				else
					(* full_case, parallel_case *)
					case ({instr_alu[31:25], instr_alu[14:12]})
						10'b0000000000: alu_operator_o = 7'd0;
						10'b0100000000: alu_operator_o = 7'd1;
						10'b0000000010: alu_operator_o = 7'd43;
						10'b0000000011: alu_operator_o = 7'd44;
						10'b0000000100: alu_operator_o = 7'd2;
						10'b0000000110: alu_operator_o = 7'd3;
						10'b0000000111: alu_operator_o = 7'd4;
						10'b0000000001: alu_operator_o = 7'd10;
						10'b0000000101: alu_operator_o = 7'd9;
						10'b0100000101: alu_operator_o = 7'd8;
						10'b0110000001:
							if (RV32B != 32'sd0) begin
								alu_operator_o = 7'd14;
								alu_multicycle_o = 1'b1;
							end
						10'b0110000101:
							if (RV32B != 32'sd0) begin
								alu_operator_o = 7'd13;
								alu_multicycle_o = 1'b1;
							end
						10'b0000101100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd31;
						10'b0000101110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd33;
						10'b0000101101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd32;
						10'b0000101111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd34;
						10'b0000100100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd35;
						10'b0100100100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd36;
						10'b0000100111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd37;
						10'b0100000100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd5;
						10'b0100000110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd6;
						10'b0100000111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd7;
						10'b0010000010:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd22;
						10'b0010000100:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd23;
						10'b0010000110:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd24;
						10'b0100100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd50;
						10'b0010100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd49;
						10'b0110100001:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd51;
						10'b0100100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd52;
						10'b0100100111:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd55;
						10'b0110100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd15;
						10'b0010100101:
							if (RV32B != 32'sd0)
								alu_operator_o = 7'd16;
						10'b0000100001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd17;
						10'b0000100101:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd18;
						10'b0010100010:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd19;
						10'b0010100100:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd20;
						10'b0010100110:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd21;
						10'b0010000001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd12;
						10'b0010000101:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd11;
						10'b0000101001:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd56;
						10'b0000101010:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd57;
						10'b0000101011:
							if ((RV32B == 32'sd2) || (RV32B == 32'sd3))
								alu_operator_o = 7'd58;
						10'b0100100110:
							if (RV32B == 32'sd3) begin
								alu_operator_o = 7'd54;
								alu_multicycle_o = 1'b1;
							end
						10'b0000100110:
							if (RV32B == 32'sd3) begin
								alu_operator_o = 7'd53;
								alu_multicycle_o = 1'b1;
							end
						10'b0000001000: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001001: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001010: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001011: begin
							alu_operator_o = 7'd0;
							mult_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001100: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001101: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001110: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						10'b0000001111: begin
							alu_operator_o = 7'd0;
							div_sel_o = (RV32M == 32'sd0 ? 1'b0 : 1'b1);
						end
						default:
							;
					endcase
			end
			7'h0f:
				(* full_case, parallel_case *)
				case (instr_alu[14:12])
					3'b000: begin
						alu_operator_o = 7'd0;
						alu_op_a_mux_sel_o = 2'd0;
						alu_op_b_mux_sel_o = 1'd1;
					end
					3'b001:
						if (BranchTargetALU) begin
							bt_a_mux_sel_o = 2'd2;
							bt_b_mux_sel_o = 3'd5;
						end
						else begin
							alu_op_a_mux_sel_o = 2'd2;
							alu_op_b_mux_sel_o = 1'd1;
							imm_b_mux_sel_o = 3'd5;
							alu_operator_o = 7'd0;
						end
					default:
						;
				endcase
			7'h73:
				if (instr_alu[14:12] == 3'b000) begin
					alu_op_a_mux_sel_o = 2'd0;
					alu_op_b_mux_sel_o = 1'd1;
				end
				else begin
					imm_a_mux_sel_o = 1'd0;
					if (instr_alu[14])
						alu_op_a_mux_sel_o = 2'd3;
					else
						alu_op_a_mux_sel_o = 2'd0;
				end
			default:
				;
		endcase
	end
	assign mult_en_o = (illegal_insn ? 1'b0 : mult_sel_o);
	assign div_en_o = (illegal_insn ? 1'b0 : div_sel_o);
	assign illegal_insn_o = illegal_insn | illegal_reg_rv32e;
	assign rf_we_o = rf_we & ~illegal_reg_rv32e;
	assign unused_instr_alu = {instr_alu[19:15], instr_alu[11:7]};
	initial _sv2v_0 = 0;
endmodule
module ibex_ex_block (
	clk_i,
	rst_ni,
	alu_operator_i,
	alu_operand_a_i,
	alu_operand_b_i,
	alu_instr_first_cycle_i,
	bt_a_operand_i,
	bt_b_operand_i,
	multdiv_operator_i,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	multdiv_signed_mode_i,
	multdiv_operand_a_i,
	multdiv_operand_b_i,
	multdiv_ready_id_i,
	data_ind_timing_i,
	imd_val_we_o,
	imd_val_d_o,
	imd_val_q_i,
	alu_adder_result_ex_o,
	result_ex_o,
	branch_target_o,
	branch_decision_o,
	ex_valid_o
);
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 0;
	input wire clk_i;
	input wire rst_ni;
	input wire [6:0] alu_operator_i;
	input wire [31:0] alu_operand_a_i;
	input wire [31:0] alu_operand_b_i;
	input wire alu_instr_first_cycle_i;
	input wire [31:0] bt_a_operand_i;
	input wire [31:0] bt_b_operand_i;
	input wire [1:0] multdiv_operator_i;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] multdiv_signed_mode_i;
	input wire [31:0] multdiv_operand_a_i;
	input wire [31:0] multdiv_operand_b_i;
	input wire multdiv_ready_id_i;
	input wire data_ind_timing_i;
	output wire [1:0] imd_val_we_o;
	output wire [67:0] imd_val_d_o;
	input wire [67:0] imd_val_q_i;
	output wire [31:0] alu_adder_result_ex_o;
	output wire [31:0] result_ex_o;
	output wire [31:0] branch_target_o;
	output wire branch_decision_o;
	output wire ex_valid_o;
	wire [31:0] alu_result;
	wire [31:0] multdiv_result;
	wire [32:0] multdiv_alu_operand_b;
	wire [32:0] multdiv_alu_operand_a;
	wire [33:0] alu_adder_result_ext;
	wire alu_cmp_result;
	wire alu_is_equal_result;
	wire multdiv_valid;
	wire multdiv_sel;
	wire [63:0] alu_imd_val_q;
	wire [63:0] alu_imd_val_d;
	wire [1:0] alu_imd_val_we;
	wire [67:0] multdiv_imd_val_d;
	wire [1:0] multdiv_imd_val_we;
	generate
		if (RV32M != 32'sd0) begin : gen_multdiv_m
			assign multdiv_sel = mult_sel_i | div_sel_i;
		end
		else begin : gen_multdiv_no_m
			assign multdiv_sel = 1'b0;
		end
	endgenerate
	assign imd_val_d_o[34+:34] = (multdiv_sel ? multdiv_imd_val_d[34+:34] : {2'b00, alu_imd_val_d[32+:32]});
	assign imd_val_d_o[0+:34] = (multdiv_sel ? multdiv_imd_val_d[0+:34] : {2'b00, alu_imd_val_d[0+:32]});
	assign imd_val_we_o = (multdiv_sel ? multdiv_imd_val_we : alu_imd_val_we);
	assign alu_imd_val_q = {imd_val_q_i[65-:32], imd_val_q_i[31-:32]};
	assign result_ex_o = (multdiv_sel ? multdiv_result : alu_result);
	assign branch_decision_o = alu_cmp_result;
	generate
		if (BranchTargetALU) begin : g_branch_target_alu
			wire [32:0] bt_alu_result;
			wire unused_bt_carry;
			assign bt_alu_result = bt_a_operand_i + bt_b_operand_i;
			assign unused_bt_carry = bt_alu_result[32];
			assign branch_target_o = bt_alu_result[31:0];
		end
		else begin : g_no_branch_target_alu
			wire [31:0] unused_bt_a_operand;
			wire [31:0] unused_bt_b_operand;
			assign unused_bt_a_operand = bt_a_operand_i;
			assign unused_bt_b_operand = bt_b_operand_i;
			assign branch_target_o = alu_adder_result_ex_o;
		end
	endgenerate
	ibex_alu #(.RV32B(RV32B)) alu_i(
		.operator_i(alu_operator_i),
		.operand_a_i(alu_operand_a_i),
		.operand_b_i(alu_operand_b_i),
		.instr_first_cycle_i(alu_instr_first_cycle_i),
		.imd_val_q_i(alu_imd_val_q),
		.imd_val_we_o(alu_imd_val_we),
		.imd_val_d_o(alu_imd_val_d),
		.multdiv_operand_a_i(multdiv_alu_operand_a),
		.multdiv_operand_b_i(multdiv_alu_operand_b),
		.multdiv_sel_i(multdiv_sel),
		.adder_result_o(alu_adder_result_ex_o),
		.adder_result_ext_o(alu_adder_result_ext),
		.result_o(alu_result),
		.comparison_result_o(alu_cmp_result),
		.is_equal_result_o(alu_is_equal_result)
	);
	generate
		if (RV32M == 32'sd1) begin : gen_multdiv_slow
			ibex_multdiv_slow multdiv_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.mult_en_i(mult_en_i),
				.div_en_i(div_en_i),
				.mult_sel_i(mult_sel_i),
				.div_sel_i(div_sel_i),
				.operator_i(multdiv_operator_i),
				.signed_mode_i(multdiv_signed_mode_i),
				.op_a_i(multdiv_operand_a_i),
				.op_b_i(multdiv_operand_b_i),
				.alu_adder_ext_i(alu_adder_result_ext),
				.alu_adder_i(alu_adder_result_ex_o),
				.equal_to_zero_i(alu_is_equal_result),
				.data_ind_timing_i(data_ind_timing_i),
				.valid_o(multdiv_valid),
				.alu_operand_a_o(multdiv_alu_operand_a),
				.alu_operand_b_o(multdiv_alu_operand_b),
				.imd_val_q_i(imd_val_q_i),
				.imd_val_d_o(multdiv_imd_val_d),
				.imd_val_we_o(multdiv_imd_val_we),
				.multdiv_ready_id_i(multdiv_ready_id_i),
				.multdiv_result_o(multdiv_result)
			);
		end
		else if ((RV32M == 32'sd2) || (RV32M == 32'sd3)) begin : gen_multdiv_fast
			ibex_multdiv_fast #(.RV32M(RV32M)) multdiv_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.mult_en_i(mult_en_i),
				.div_en_i(div_en_i),
				.mult_sel_i(mult_sel_i),
				.div_sel_i(div_sel_i),
				.operator_i(multdiv_operator_i),
				.signed_mode_i(multdiv_signed_mode_i),
				.op_a_i(multdiv_operand_a_i),
				.op_b_i(multdiv_operand_b_i),
				.alu_operand_a_o(multdiv_alu_operand_a),
				.alu_operand_b_o(multdiv_alu_operand_b),
				.alu_adder_ext_i(alu_adder_result_ext),
				.alu_adder_i(alu_adder_result_ex_o),
				.equal_to_zero_i(alu_is_equal_result),
				.data_ind_timing_i(data_ind_timing_i),
				.imd_val_q_i(imd_val_q_i),
				.imd_val_d_o(multdiv_imd_val_d),
				.imd_val_we_o(multdiv_imd_val_we),
				.multdiv_ready_id_i(multdiv_ready_id_i),
				.valid_o(multdiv_valid),
				.multdiv_result_o(multdiv_result)
			);
		end
	endgenerate
	assign ex_valid_o = (multdiv_sel ? multdiv_valid : ~(|alu_imd_val_we));
endmodule
module ibex_fetch_fifo (
	clk_i,
	rst_ni,
	clear_i,
	busy_o,
	in_valid_i,
	in_addr_i,
	in_rdata_i,
	in_err_i,
	out_valid_o,
	out_ready_i,
	out_addr_o,
	out_rdata_o,
	out_err_o,
	out_err_plus2_o
);
	reg _sv2v_0;
	parameter [31:0] NUM_REQS = 2;
	parameter [0:0] ResetAll = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire clear_i;
	output wire [NUM_REQS - 1:0] busy_o;
	input wire in_valid_i;
	input wire [31:0] in_addr_i;
	input wire [31:0] in_rdata_i;
	input wire in_err_i;
	output reg out_valid_o;
	input wire out_ready_i;
	output wire [31:0] out_addr_o;
	output reg [31:0] out_rdata_o;
	output reg out_err_o;
	output reg out_err_plus2_o;
	localparam [31:0] DEPTH = NUM_REQS + 1;
	wire [(DEPTH * 32) - 1:0] rdata_d;
	reg [(DEPTH * 32) - 1:0] rdata_q;
	wire [DEPTH - 1:0] err_d;
	reg [DEPTH - 1:0] err_q;
	wire [DEPTH - 1:0] valid_d;
	reg [DEPTH - 1:0] valid_q;
	wire [DEPTH - 1:0] lowest_free_entry;
	wire [DEPTH - 1:0] valid_pushed;
	wire [DEPTH - 1:0] valid_popped;
	wire [DEPTH - 1:0] entry_en;
	wire pop_fifo;
	wire [31:0] rdata;
	wire [31:0] rdata_unaligned;
	wire err;
	wire err_unaligned;
	wire err_plus2;
	wire valid;
	wire valid_unaligned;
	wire aligned_is_compressed;
	wire unaligned_is_compressed;
	wire addr_incr_two;
	wire [31:1] instr_addr_next;
	wire [31:1] instr_addr_d;
	reg [31:1] instr_addr_q;
	wire instr_addr_en;
	wire unused_addr_in;
	assign rdata = (valid_q[0] ? rdata_q[0+:32] : in_rdata_i);
	assign err = (valid_q[0] ? err_q[0] : in_err_i);
	assign valid = valid_q[0] | in_valid_i;
	assign rdata_unaligned = (valid_q[1] ? {rdata_q[47-:16], rdata[31:16]} : {in_rdata_i[15:0], rdata[31:16]});
	assign err_unaligned = (valid_q[1] ? (err_q[1] & ~unaligned_is_compressed) | err_q[0] : (valid_q[0] & err_q[0]) | (in_err_i & (~valid_q[0] | ~unaligned_is_compressed)));
	assign err_plus2 = (valid_q[1] ? err_q[1] & ~err_q[0] : (in_err_i & valid_q[0]) & ~err_q[0]);
	assign valid_unaligned = (valid_q[1] ? 1'b1 : valid_q[0] & in_valid_i);
	assign unaligned_is_compressed = (rdata[17:16] != 2'b11) & ~err;
	assign aligned_is_compressed = (rdata[1:0] != 2'b11) & ~err;
	always @(*) begin
		if (_sv2v_0)
			;
		if (out_addr_o[1]) begin
			out_rdata_o = rdata_unaligned;
			out_err_o = err_unaligned;
			out_err_plus2_o = err_plus2;
			if (unaligned_is_compressed)
				out_valid_o = valid;
			else
				out_valid_o = valid_unaligned;
		end
		else begin
			out_rdata_o = rdata;
			out_err_o = err;
			out_err_plus2_o = 1'b0;
			out_valid_o = valid;
		end
	end
	assign instr_addr_en = clear_i | (out_ready_i & out_valid_o);
	assign addr_incr_two = (instr_addr_q[1] ? unaligned_is_compressed : aligned_is_compressed);
	assign instr_addr_next = instr_addr_q[31:1] + {29'd0, ~addr_incr_two, addr_incr_two};
	assign instr_addr_d = (clear_i ? in_addr_i[31:1] : instr_addr_next);
	generate
		if (ResetAll) begin : g_instr_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					instr_addr_q <= 1'sb0;
				else if (instr_addr_en)
					instr_addr_q <= instr_addr_d;
		end
		else begin : g_instr_addr_nr
			always @(posedge clk_i)
				if (instr_addr_en)
					instr_addr_q <= instr_addr_d;
		end
	endgenerate
	assign out_addr_o = {instr_addr_q, 1'b0};
	assign unused_addr_in = in_addr_i[0];
	assign busy_o = valid_q[DEPTH - 1:DEPTH - NUM_REQS];
	assign pop_fifo = (out_ready_i & out_valid_o) & (~aligned_is_compressed | out_addr_o[1]);
	genvar _gv_i_27;
	generate
		for (_gv_i_27 = 0; _gv_i_27 < (DEPTH - 1); _gv_i_27 = _gv_i_27 + 1) begin : g_fifo_next
			localparam i = _gv_i_27;
			if (i == 0) begin : g_ent0
				assign lowest_free_entry[i] = ~valid_q[i];
			end
			else begin : g_ent_others
				assign lowest_free_entry[i] = ~valid_q[i] & valid_q[i - 1];
			end
			assign valid_pushed[i] = (in_valid_i & lowest_free_entry[i]) | valid_q[i];
			assign valid_popped[i] = (pop_fifo ? valid_pushed[i + 1] : valid_pushed[i]);
			assign valid_d[i] = valid_popped[i] & ~clear_i;
			assign entry_en[i] = (valid_pushed[i + 1] & pop_fifo) | ((in_valid_i & lowest_free_entry[i]) & ~pop_fifo);
			assign rdata_d[i * 32+:32] = (valid_q[i + 1] ? rdata_q[(i + 1) * 32+:32] : in_rdata_i);
			assign err_d[i] = (valid_q[i + 1] ? err_q[i + 1] : in_err_i);
		end
	endgenerate
	assign lowest_free_entry[DEPTH - 1] = ~valid_q[DEPTH - 1] & valid_q[DEPTH - 2];
	assign valid_pushed[DEPTH - 1] = valid_q[DEPTH - 1] | (in_valid_i & lowest_free_entry[DEPTH - 1]);
	assign valid_popped[DEPTH - 1] = (pop_fifo ? 1'b0 : valid_pushed[DEPTH - 1]);
	assign valid_d[DEPTH - 1] = valid_popped[DEPTH - 1] & ~clear_i;
	assign entry_en[DEPTH - 1] = in_valid_i & lowest_free_entry[DEPTH - 1];
	assign rdata_d[(DEPTH - 1) * 32+:32] = in_rdata_i;
	assign err_d[DEPTH - 1] = in_err_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			valid_q <= 1'sb0;
		else
			valid_q <= valid_d;
	genvar _gv_i_28;
	generate
		for (_gv_i_28 = 0; _gv_i_28 < DEPTH; _gv_i_28 = _gv_i_28 + 1) begin : g_fifo_regs
			localparam i = _gv_i_28;
			if (ResetAll) begin : g_rdata_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						rdata_q[i * 32+:32] <= 1'sb0;
						err_q[i] <= 1'sb0;
					end
					else if (entry_en[i]) begin
						rdata_q[i * 32+:32] <= rdata_d[i * 32+:32];
						err_q[i] <= err_d[i];
					end
			end
			else begin : g_rdata_nr
				always @(posedge clk_i)
					if (entry_en[i]) begin
						rdata_q[i * 32+:32] <= rdata_d[i * 32+:32];
						err_q[i] <= err_d[i];
					end
			end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_id_stage (
	clk_i,
	rst_ni,
	ctrl_busy_o,
	illegal_insn_o,
	instr_valid_i,
	instr_rdata_i,
	instr_rdata_alu_i,
	instr_rdata_c_i,
	instr_is_compressed_i,
	instr_bp_taken_i,
	instr_req_o,
	instr_first_cycle_id_o,
	instr_valid_clear_o,
	id_in_ready_o,
	instr_exec_i,
	icache_inval_o,
	branch_decision_i,
	pc_set_o,
	pc_mux_o,
	nt_branch_mispredict_o,
	nt_branch_addr_o,
	exc_pc_mux_o,
	exc_cause_o,
	illegal_c_insn_i,
	instr_fetch_err_i,
	instr_fetch_err_plus2_i,
	pc_id_i,
	ex_valid_i,
	lsu_resp_valid_i,
	alu_operator_ex_o,
	alu_operand_a_ex_o,
	alu_operand_b_ex_o,
	imd_val_we_ex_i,
	imd_val_d_ex_i,
	imd_val_q_ex_o,
	bt_a_operand_o,
	bt_b_operand_o,
	mult_en_ex_o,
	div_en_ex_o,
	mult_sel_ex_o,
	div_sel_ex_o,
	multdiv_operator_ex_o,
	multdiv_signed_mode_ex_o,
	multdiv_operand_a_ex_o,
	multdiv_operand_b_ex_o,
	multdiv_ready_id_o,
	csr_access_o,
	csr_op_o,
	csr_addr_o,
	csr_op_en_o,
	csr_save_if_o,
	csr_save_id_o,
	csr_save_wb_o,
	csr_restore_mret_id_o,
	csr_restore_dret_id_o,
	csr_save_cause_o,
	csr_mtval_o,
	priv_mode_i,
	csr_mstatus_tw_i,
	illegal_csr_insn_i,
	data_ind_timing_i,
	lsu_req_o,
	lsu_we_o,
	lsu_type_o,
	lsu_sign_ext_o,
	lsu_wdata_o,
	lsu_req_done_i,
	lsu_addr_incr_req_i,
	lsu_addr_last_i,
	csr_mstatus_mie_i,
	irq_pending_i,
	irqs_i,
	irq_nm_i,
	nmi_mode_o,
	lsu_load_err_i,
	lsu_load_resp_intg_err_i,
	lsu_store_err_i,
	lsu_store_resp_intg_err_i,
	expecting_load_resp_o,
	expecting_store_resp_o,
	debug_mode_o,
	debug_mode_entering_o,
	debug_cause_o,
	debug_csr_save_o,
	debug_req_i,
	debug_single_step_i,
	debug_ebreakm_i,
	debug_ebreaku_i,
	trigger_match_i,
	result_ex_i,
	csr_rdata_i,
	rf_raddr_a_o,
	rf_rdata_a_i,
	rf_raddr_b_o,
	rf_rdata_b_i,
	rf_ren_a_o,
	rf_ren_b_o,
	rf_waddr_id_o,
	rf_wdata_id_o,
	rf_we_id_o,
	rf_rd_a_wb_match_o,
	rf_rd_b_wb_match_o,
	rf_waddr_wb_i,
	rf_wdata_fwd_wb_i,
	rf_write_wb_i,
	en_wb_o,
	instr_type_wb_o,
	instr_perf_count_id_o,
	ready_wb_i,
	outstanding_load_wb_i,
	outstanding_store_wb_i,
	perf_jump_o,
	perf_branch_o,
	perf_tbranch_o,
	perf_dside_wait_o,
	perf_mul_wait_o,
	perf_div_wait_o,
	instr_id_done_o
);
	reg _sv2v_0;
	parameter [0:0] RV32E = 0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] DataIndTiming = 1'b0;
	parameter [0:0] BranchTargetALU = 0;
	parameter [0:0] WritebackStage = 0;
	parameter [0:0] BranchPredictor = 0;
	parameter [0:0] MemECC = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	output wire ctrl_busy_o;
	output wire illegal_insn_o;
	input wire instr_valid_i;
	input wire [31:0] instr_rdata_i;
	input wire [31:0] instr_rdata_alu_i;
	input wire [15:0] instr_rdata_c_i;
	input wire instr_is_compressed_i;
	input wire instr_bp_taken_i;
	output wire instr_req_o;
	output wire instr_first_cycle_id_o;
	output wire instr_valid_clear_o;
	output wire id_in_ready_o;
	input wire instr_exec_i;
	output wire icache_inval_o;
	input wire branch_decision_i;
	output wire pc_set_o;
	output wire [2:0] pc_mux_o;
	output wire nt_branch_mispredict_o;
	output wire [31:0] nt_branch_addr_o;
	output wire [1:0] exc_pc_mux_o;
	output wire [6:0] exc_cause_o;
	input wire illegal_c_insn_i;
	input wire instr_fetch_err_i;
	input wire instr_fetch_err_plus2_i;
	input wire [31:0] pc_id_i;
	input wire ex_valid_i;
	input wire lsu_resp_valid_i;
	output wire [6:0] alu_operator_ex_o;
	output wire [31:0] alu_operand_a_ex_o;
	output wire [31:0] alu_operand_b_ex_o;
	input wire [1:0] imd_val_we_ex_i;
	input wire [67:0] imd_val_d_ex_i;
	output wire [67:0] imd_val_q_ex_o;
	output reg [31:0] bt_a_operand_o;
	output reg [31:0] bt_b_operand_o;
	output wire mult_en_ex_o;
	output wire div_en_ex_o;
	output wire mult_sel_ex_o;
	output wire div_sel_ex_o;
	output wire [1:0] multdiv_operator_ex_o;
	output wire [1:0] multdiv_signed_mode_ex_o;
	output wire [31:0] multdiv_operand_a_ex_o;
	output wire [31:0] multdiv_operand_b_ex_o;
	output wire multdiv_ready_id_o;
	output wire csr_access_o;
	output wire [1:0] csr_op_o;
	output wire [11:0] csr_addr_o;
	output wire csr_op_en_o;
	output wire csr_save_if_o;
	output wire csr_save_id_o;
	output wire csr_save_wb_o;
	output wire csr_restore_mret_id_o;
	output wire csr_restore_dret_id_o;
	output wire csr_save_cause_o;
	output wire [31:0] csr_mtval_o;
	input wire [1:0] priv_mode_i;
	input wire csr_mstatus_tw_i;
	input wire illegal_csr_insn_i;
	input wire data_ind_timing_i;
	output wire lsu_req_o;
	output wire lsu_we_o;
	output wire [1:0] lsu_type_o;
	output wire lsu_sign_ext_o;
	output wire [31:0] lsu_wdata_o;
	input wire lsu_req_done_i;
	input wire lsu_addr_incr_req_i;
	input wire [31:0] lsu_addr_last_i;
	input wire csr_mstatus_mie_i;
	input wire irq_pending_i;
	input wire [17:0] irqs_i;
	input wire irq_nm_i;
	output wire nmi_mode_o;
	input wire lsu_load_err_i;
	input wire lsu_load_resp_intg_err_i;
	input wire lsu_store_err_i;
	input wire lsu_store_resp_intg_err_i;
	output wire expecting_load_resp_o;
	output wire expecting_store_resp_o;
	output wire debug_mode_o;
	output wire debug_mode_entering_o;
	output wire [2:0] debug_cause_o;
	output wire debug_csr_save_o;
	input wire debug_req_i;
	input wire debug_single_step_i;
	input wire debug_ebreakm_i;
	input wire debug_ebreaku_i;
	input wire trigger_match_i;
	input wire [31:0] result_ex_i;
	input wire [31:0] csr_rdata_i;
	output wire [4:0] rf_raddr_a_o;
	input wire [31:0] rf_rdata_a_i;
	output wire [4:0] rf_raddr_b_o;
	input wire [31:0] rf_rdata_b_i;
	output wire rf_ren_a_o;
	output wire rf_ren_b_o;
	output wire [4:0] rf_waddr_id_o;
	output reg [31:0] rf_wdata_id_o;
	output wire rf_we_id_o;
	output wire rf_rd_a_wb_match_o;
	output wire rf_rd_b_wb_match_o;
	input wire [4:0] rf_waddr_wb_i;
	input wire [31:0] rf_wdata_fwd_wb_i;
	input wire rf_write_wb_i;
	output wire en_wb_o;
	output wire [1:0] instr_type_wb_o;
	output wire instr_perf_count_id_o;
	input wire ready_wb_i;
	input wire outstanding_load_wb_i;
	input wire outstanding_store_wb_i;
	output wire perf_jump_o;
	output reg perf_branch_o;
	output wire perf_tbranch_o;
	output wire perf_dside_wait_o;
	output wire perf_mul_wait_o;
	output wire perf_div_wait_o;
	output wire instr_id_done_o;
	wire illegal_insn_dec;
	wire illegal_dret_insn;
	wire illegal_umode_insn;
	wire ebrk_insn;
	wire mret_insn_dec;
	wire dret_insn_dec;
	wire ecall_insn_dec;
	wire wfi_insn_dec;
	wire wb_exception;
	wire id_exception;
	wire branch_in_dec;
	wire branch_set;
	wire branch_set_raw;
	reg branch_set_raw_d;
	reg branch_jump_set_done_q;
	wire branch_jump_set_done_d;
	reg branch_not_set;
	wire branch_taken;
	wire jump_in_dec;
	wire jump_set_dec;
	wire jump_set;
	reg jump_set_raw;
	wire instr_first_cycle;
	wire instr_executing_spec;
	wire instr_executing;
	wire instr_done;
	wire controller_run;
	wire stall_ld_hz;
	wire stall_mem;
	reg stall_multdiv;
	reg stall_branch;
	reg stall_jump;
	wire stall_id;
	wire stall_wb;
	wire flush_id;
	wire multicycle_done;
	wire mem_resp_intg_err;
	wire [31:0] imm_i_type;
	wire [31:0] imm_s_type;
	wire [31:0] imm_b_type;
	wire [31:0] imm_u_type;
	wire [31:0] imm_j_type;
	wire [31:0] zimm_rs1_type;
	wire [31:0] imm_a;
	reg [31:0] imm_b;
	wire rf_wdata_sel;
	wire rf_we_dec;
	reg rf_we_raw;
	wire rf_ren_a;
	wire rf_ren_b;
	wire rf_ren_a_dec;
	wire rf_ren_b_dec;
	assign rf_ren_a = ((instr_valid_i & ~instr_fetch_err_i) & ~illegal_insn_o) & rf_ren_a_dec;
	assign rf_ren_b = ((instr_valid_i & ~instr_fetch_err_i) & ~illegal_insn_o) & rf_ren_b_dec;
	assign rf_ren_a_o = rf_ren_a;
	assign rf_ren_b_o = rf_ren_b;
	wire [31:0] rf_rdata_a_fwd;
	wire [31:0] rf_rdata_b_fwd;
	wire [6:0] alu_operator;
	wire [1:0] alu_op_a_mux_sel;
	wire [1:0] alu_op_a_mux_sel_dec;
	wire alu_op_b_mux_sel;
	wire alu_op_b_mux_sel_dec;
	wire alu_multicycle_dec;
	reg stall_alu;
	reg [67:0] imd_val_q;
	wire [1:0] bt_a_mux_sel;
	wire [2:0] bt_b_mux_sel;
	wire imm_a_mux_sel;
	wire [2:0] imm_b_mux_sel;
	wire [2:0] imm_b_mux_sel_dec;
	wire mult_en_id;
	wire mult_en_dec;
	wire div_en_id;
	wire div_en_dec;
	wire multdiv_en_dec;
	wire [1:0] multdiv_operator;
	wire [1:0] multdiv_signed_mode;
	wire lsu_we;
	wire [1:0] lsu_type;
	wire lsu_sign_ext;
	wire lsu_req;
	wire lsu_req_dec;
	wire data_req_allowed;
	wire no_flush_csr_addr;
	wire csr_pipe_flush;
	reg [31:0] alu_operand_a;
	wire [31:0] alu_operand_b;
	assign alu_op_a_mux_sel = (lsu_addr_incr_req_i ? 2'd1 : alu_op_a_mux_sel_dec);
	assign alu_op_b_mux_sel = (lsu_addr_incr_req_i ? 1'd1 : alu_op_b_mux_sel_dec);
	assign imm_b_mux_sel = (lsu_addr_incr_req_i ? 3'd6 : imm_b_mux_sel_dec);
	assign imm_a = (imm_a_mux_sel == 1'd0 ? zimm_rs1_type : {32 {1'sb0}});
	always @(*) begin : alu_operand_a_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (alu_op_a_mux_sel)
			2'd0: alu_operand_a = rf_rdata_a_fwd;
			2'd1: alu_operand_a = lsu_addr_last_i;
			2'd2: alu_operand_a = pc_id_i;
			2'd3: alu_operand_a = imm_a;
			default: alu_operand_a = pc_id_i;
		endcase
	end
	generate
		if (BranchTargetALU) begin : g_btalu_muxes
			always @(*) begin : bt_operand_a_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (bt_a_mux_sel)
					2'd0: bt_a_operand_o = rf_rdata_a_fwd;
					2'd2: bt_a_operand_o = pc_id_i;
					default: bt_a_operand_o = pc_id_i;
				endcase
			end
			always @(*) begin : bt_immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (bt_b_mux_sel)
					3'd0: bt_b_operand_o = imm_i_type;
					3'd2: bt_b_operand_o = imm_b_type;
					3'd4: bt_b_operand_o = imm_j_type;
					3'd5: bt_b_operand_o = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					default: bt_b_operand_o = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
				endcase
			end
			always @(*) begin : immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (imm_b_mux_sel)
					3'd0: imm_b = imm_i_type;
					3'd1: imm_b = imm_s_type;
					3'd3: imm_b = imm_u_type;
					3'd5: imm_b = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					3'd6: imm_b = 32'h00000004;
					default: imm_b = 32'h00000004;
				endcase
			end
		end
		else begin : g_nobtalu
			wire [1:0] unused_a_mux_sel;
			wire [2:0] unused_b_mux_sel;
			assign unused_a_mux_sel = bt_a_mux_sel;
			assign unused_b_mux_sel = bt_b_mux_sel;
			wire [32:1] sv2v_tmp_1FCCD;
			assign sv2v_tmp_1FCCD = 1'sb0;
			always @(*) bt_a_operand_o = sv2v_tmp_1FCCD;
			wire [32:1] sv2v_tmp_B876E;
			assign sv2v_tmp_B876E = 1'sb0;
			always @(*) bt_b_operand_o = sv2v_tmp_B876E;
			always @(*) begin : immediate_b_mux
				if (_sv2v_0)
					;
				(* full_case, parallel_case *)
				case (imm_b_mux_sel)
					3'd0: imm_b = imm_i_type;
					3'd1: imm_b = imm_s_type;
					3'd2: imm_b = imm_b_type;
					3'd3: imm_b = imm_u_type;
					3'd4: imm_b = imm_j_type;
					3'd5: imm_b = (instr_is_compressed_i ? 32'h00000002 : 32'h00000004);
					3'd6: imm_b = 32'h00000004;
					default: imm_b = 32'h00000004;
				endcase
			end
		end
	endgenerate
	assign alu_operand_b = (alu_op_b_mux_sel == 1'd1 ? imm_b : rf_rdata_b_fwd);
	genvar _gv_i_29;
	generate
		for (_gv_i_29 = 0; _gv_i_29 < 2; _gv_i_29 = _gv_i_29 + 1) begin : gen_intermediate_val_reg
			localparam i = _gv_i_29;
			always @(posedge clk_i or negedge rst_ni) begin : intermediate_val_reg
				if (!rst_ni)
					imd_val_q[(1 - i) * 34+:34] <= 1'sb0;
				else if (imd_val_we_ex_i[i])
					imd_val_q[(1 - i) * 34+:34] <= imd_val_d_ex_i[(1 - i) * 34+:34];
			end
		end
	endgenerate
	assign imd_val_q_ex_o = imd_val_q;
	assign rf_we_id_o = (rf_we_raw & instr_executing) & ~illegal_csr_insn_i;
	always @(*) begin : rf_wdata_id_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rf_wdata_sel)
			1'd0: rf_wdata_id_o = result_ex_i;
			1'd1: rf_wdata_id_o = csr_rdata_i;
			default: rf_wdata_id_o = result_ex_i;
		endcase
	end
	ibex_decoder #(
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU)
	) decoder_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.illegal_insn_o(illegal_insn_dec),
		.ebrk_insn_o(ebrk_insn),
		.mret_insn_o(mret_insn_dec),
		.dret_insn_o(dret_insn_dec),
		.ecall_insn_o(ecall_insn_dec),
		.wfi_insn_o(wfi_insn_dec),
		.jump_set_o(jump_set_dec),
		.branch_taken_i(branch_taken),
		.icache_inval_o(icache_inval_o),
		.instr_first_cycle_i(instr_first_cycle),
		.instr_rdata_i(instr_rdata_i),
		.instr_rdata_alu_i(instr_rdata_alu_i),
		.illegal_c_insn_i(illegal_c_insn_i),
		.imm_a_mux_sel_o(imm_a_mux_sel),
		.imm_b_mux_sel_o(imm_b_mux_sel_dec),
		.bt_a_mux_sel_o(bt_a_mux_sel),
		.bt_b_mux_sel_o(bt_b_mux_sel),
		.imm_i_type_o(imm_i_type),
		.imm_s_type_o(imm_s_type),
		.imm_b_type_o(imm_b_type),
		.imm_u_type_o(imm_u_type),
		.imm_j_type_o(imm_j_type),
		.zimm_rs1_type_o(zimm_rs1_type),
		.rf_wdata_sel_o(rf_wdata_sel),
		.rf_we_o(rf_we_dec),
		.rf_raddr_a_o(rf_raddr_a_o),
		.rf_raddr_b_o(rf_raddr_b_o),
		.rf_waddr_o(rf_waddr_id_o),
		.rf_ren_a_o(rf_ren_a_dec),
		.rf_ren_b_o(rf_ren_b_dec),
		.alu_operator_o(alu_operator),
		.alu_op_a_mux_sel_o(alu_op_a_mux_sel_dec),
		.alu_op_b_mux_sel_o(alu_op_b_mux_sel_dec),
		.alu_multicycle_o(alu_multicycle_dec),
		.mult_en_o(mult_en_dec),
		.div_en_o(div_en_dec),
		.mult_sel_o(mult_sel_ex_o),
		.div_sel_o(div_sel_ex_o),
		.multdiv_operator_o(multdiv_operator),
		.multdiv_signed_mode_o(multdiv_signed_mode),
		.csr_access_o(csr_access_o),
		.csr_op_o(csr_op_o),
		.csr_addr_o(csr_addr_o),
		.data_req_o(lsu_req_dec),
		.data_we_o(lsu_we),
		.data_type_o(lsu_type),
		.data_sign_extension_o(lsu_sign_ext),
		.jump_in_dec_o(jump_in_dec),
		.branch_in_dec_o(branch_in_dec)
	);
	assign no_flush_csr_addr = |{csr_addr_o == 12'h340, csr_addr_o == 12'h341};
	assign csr_pipe_flush = ((csr_op_en_o == 1) && |{csr_op_o == 2'd1, csr_op_o == 2'd2, csr_op_o == 2'd3}) && !no_flush_csr_addr;
	assign illegal_dret_insn = dret_insn_dec & ~debug_mode_o;
	assign illegal_umode_insn = (priv_mode_i != 2'b11) & (mret_insn_dec | (csr_mstatus_tw_i & wfi_insn_dec));
	assign illegal_insn_o = instr_valid_i & (((illegal_insn_dec | illegal_csr_insn_i) | illegal_dret_insn) | illegal_umode_insn);
	assign mem_resp_intg_err = lsu_load_resp_intg_err_i | lsu_store_resp_intg_err_i;
	ibex_controller #(
		.WritebackStage(WritebackStage),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC)
	) controller_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.ctrl_busy_o(ctrl_busy_o),
		.illegal_insn_i(illegal_insn_o),
		.ecall_insn_i(ecall_insn_dec),
		.mret_insn_i(mret_insn_dec),
		.dret_insn_i(dret_insn_dec),
		.wfi_insn_i(wfi_insn_dec),
		.ebrk_insn_i(ebrk_insn),
		.csr_pipe_flush_i(csr_pipe_flush),
		.instr_valid_i(instr_valid_i),
		.instr_i(instr_rdata_i),
		.instr_compressed_i(instr_rdata_c_i),
		.instr_is_compressed_i(instr_is_compressed_i),
		.instr_bp_taken_i(instr_bp_taken_i),
		.instr_fetch_err_i(instr_fetch_err_i),
		.instr_fetch_err_plus2_i(instr_fetch_err_plus2_i),
		.pc_id_i(pc_id_i),
		.instr_valid_clear_o(instr_valid_clear_o),
		.id_in_ready_o(id_in_ready_o),
		.controller_run_o(controller_run),
		.instr_exec_i(instr_exec_i),
		.instr_req_o(instr_req_o),
		.pc_set_o(pc_set_o),
		.pc_mux_o(pc_mux_o),
		.nt_branch_mispredict_o(nt_branch_mispredict_o),
		.exc_pc_mux_o(exc_pc_mux_o),
		.exc_cause_o(exc_cause_o),
		.lsu_addr_last_i(lsu_addr_last_i),
		.load_err_i(lsu_load_err_i),
		.mem_resp_intg_err_i(mem_resp_intg_err),
		.store_err_i(lsu_store_err_i),
		.wb_exception_o(wb_exception),
		.id_exception_o(id_exception),
		.branch_set_i(branch_set),
		.branch_not_set_i(branch_not_set),
		.jump_set_i(jump_set),
		.csr_mstatus_mie_i(csr_mstatus_mie_i),
		.irq_pending_i(irq_pending_i),
		.irqs_i(irqs_i),
		.irq_nm_ext_i(irq_nm_i),
		.nmi_mode_o(nmi_mode_o),
		.csr_save_if_o(csr_save_if_o),
		.csr_save_id_o(csr_save_id_o),
		.csr_save_wb_o(csr_save_wb_o),
		.csr_restore_mret_id_o(csr_restore_mret_id_o),
		.csr_restore_dret_id_o(csr_restore_dret_id_o),
		.csr_save_cause_o(csr_save_cause_o),
		.csr_mtval_o(csr_mtval_o),
		.priv_mode_i(priv_mode_i),
		.debug_mode_o(debug_mode_o),
		.debug_mode_entering_o(debug_mode_entering_o),
		.debug_cause_o(debug_cause_o),
		.debug_csr_save_o(debug_csr_save_o),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step_i),
		.debug_ebreakm_i(debug_ebreakm_i),
		.debug_ebreaku_i(debug_ebreaku_i),
		.trigger_match_i(trigger_match_i),
		.stall_id_i(stall_id),
		.stall_wb_i(stall_wb),
		.flush_id_o(flush_id),
		.ready_wb_i(ready_wb_i),
		.perf_jump_o(perf_jump_o),
		.perf_tbranch_o(perf_tbranch_o)
	);
	assign multdiv_en_dec = mult_en_dec | div_en_dec;
	assign lsu_req = (instr_executing ? data_req_allowed & lsu_req_dec : 1'b0);
	assign mult_en_id = (instr_executing ? mult_en_dec : 1'b0);
	assign div_en_id = (instr_executing ? div_en_dec : 1'b0);
	assign lsu_req_o = lsu_req;
	assign lsu_we_o = lsu_we;
	assign lsu_type_o = lsu_type;
	assign lsu_sign_ext_o = lsu_sign_ext;
	assign lsu_wdata_o = rf_rdata_b_fwd;
	assign csr_op_en_o = (csr_access_o & instr_executing) & instr_id_done_o;
	assign alu_operator_ex_o = alu_operator;
	assign alu_operand_a_ex_o = alu_operand_a;
	assign alu_operand_b_ex_o = alu_operand_b;
	assign mult_en_ex_o = mult_en_id;
	assign div_en_ex_o = div_en_id;
	assign multdiv_operator_ex_o = multdiv_operator;
	assign multdiv_signed_mode_ex_o = multdiv_signed_mode;
	assign multdiv_operand_a_ex_o = rf_rdata_a_fwd;
	assign multdiv_operand_b_ex_o = rf_rdata_b_fwd;
	generate
		if (BranchTargetALU && !DataIndTiming) begin : g_branch_set_direct
			assign branch_set_raw = branch_set_raw_d;
		end
		else begin : g_branch_set_flop
			reg branch_set_raw_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					branch_set_raw_q <= 1'b0;
				else
					branch_set_raw_q <= branch_set_raw_d;
			assign branch_set_raw = (BranchTargetALU && !data_ind_timing_i ? branch_set_raw_d : branch_set_raw_q);
		end
	endgenerate
	assign branch_jump_set_done_d = ((branch_set_raw | jump_set_raw) | branch_jump_set_done_q) & ~instr_valid_clear_o;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			branch_jump_set_done_q <= 1'b0;
		else
			branch_jump_set_done_q <= branch_jump_set_done_d;
	assign jump_set = jump_set_raw & ~branch_jump_set_done_q;
	assign branch_set = branch_set_raw & ~branch_jump_set_done_q;
	generate
		if (DataIndTiming) begin : g_sec_branch_taken
			reg branch_taken_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					branch_taken_q <= 1'b0;
				else
					branch_taken_q <= branch_decision_i;
			assign branch_taken = ~data_ind_timing_i | branch_taken_q;
		end
		else begin : g_nosec_branch_taken
			assign branch_taken = 1'b1;
		end
		if (BranchPredictor) begin : g_calc_nt_addr
			assign nt_branch_addr_o = pc_id_i + (instr_is_compressed_i ? 32'd2 : 32'd4);
		end
		else begin : g_n_calc_nt_addr
			assign nt_branch_addr_o = 32'd0;
		end
	endgenerate
	reg id_fsm_q;
	reg id_fsm_d;
	always @(posedge clk_i or negedge rst_ni) begin : id_pipeline_reg
		if (!rst_ni)
			id_fsm_q <= 1'd0;
		else if (instr_executing)
			id_fsm_q <= id_fsm_d;
	end
	always @(*) begin
		if (_sv2v_0)
			;
		id_fsm_d = id_fsm_q;
		rf_we_raw = rf_we_dec;
		stall_multdiv = 1'b0;
		stall_jump = 1'b0;
		stall_branch = 1'b0;
		stall_alu = 1'b0;
		branch_set_raw_d = 1'b0;
		branch_not_set = 1'b0;
		jump_set_raw = 1'b0;
		perf_branch_o = 1'b0;
		if (instr_executing_spec)
			(* full_case, parallel_case *)
			case (id_fsm_q)
				1'd0:
					(* full_case, parallel_case *)
					case (1'b1)
						lsu_req_dec:
							if (!WritebackStage)
								id_fsm_d = 1'd1;
							else if (~lsu_req_done_i)
								id_fsm_d = 1'd1;
						multdiv_en_dec:
							if (~ex_valid_i) begin
								id_fsm_d = 1'd1;
								rf_we_raw = 1'b0;
								stall_multdiv = 1'b1;
							end
						branch_in_dec: begin
							id_fsm_d = (data_ind_timing_i || (!BranchTargetALU && branch_decision_i) ? 1'd1 : 1'd0);
							stall_branch = (~BranchTargetALU & branch_decision_i) | data_ind_timing_i;
							branch_set_raw_d = branch_decision_i | data_ind_timing_i;
							if (BranchPredictor)
								branch_not_set = ~branch_decision_i;
							perf_branch_o = 1'b1;
						end
						jump_in_dec: begin
							id_fsm_d = (BranchTargetALU ? 1'd0 : 1'd1);
							stall_jump = ~BranchTargetALU;
							jump_set_raw = jump_set_dec;
						end
						alu_multicycle_dec: begin
							stall_alu = 1'b1;
							id_fsm_d = 1'd1;
							rf_we_raw = 1'b0;
						end
						default: id_fsm_d = 1'd0;
					endcase
				1'd1: begin
					if (multdiv_en_dec)
						rf_we_raw = rf_we_dec & ex_valid_i;
					if (multicycle_done & ready_wb_i)
						id_fsm_d = 1'd0;
					else begin
						stall_multdiv = multdiv_en_dec;
						stall_branch = branch_in_dec;
						stall_jump = jump_in_dec;
					end
				end
				default: id_fsm_d = 1'd0;
			endcase
	end
	assign multdiv_ready_id_o = ready_wb_i;
	assign stall_id = ((((stall_ld_hz | stall_mem) | stall_multdiv) | stall_jump) | stall_branch) | stall_alu;
	assign instr_done = (~stall_id & ~flush_id) & instr_executing;
	assign instr_first_cycle = instr_valid_i & (id_fsm_q == 1'd0);
	assign instr_first_cycle_id_o = instr_first_cycle;
	generate
		if (WritebackStage) begin : gen_stall_mem
			wire rf_rd_a_wb_match;
			wire rf_rd_b_wb_match;
			wire rf_rd_a_hz;
			wire rf_rd_b_hz;
			wire outstanding_memory_access;
			wire instr_kill;
			assign multicycle_done = (lsu_req_dec ? ~stall_mem : ex_valid_i);
			assign outstanding_memory_access = (outstanding_load_wb_i | outstanding_store_wb_i) & ~lsu_resp_valid_i;
			assign data_req_allowed = ~outstanding_memory_access;
			assign instr_kill = ((instr_fetch_err_i | wb_exception) | id_exception) | ~controller_run;
			assign instr_executing_spec = ((instr_valid_i & ~instr_fetch_err_i) & controller_run) & ~stall_ld_hz;
			assign instr_executing = ((instr_valid_i & ~instr_kill) & ~stall_ld_hz) & ~outstanding_memory_access;
			assign stall_mem = instr_valid_i & (outstanding_memory_access | (lsu_req_dec & ~lsu_req_done_i));
			assign rf_rd_a_wb_match = (rf_waddr_wb_i == rf_raddr_a_o) & |rf_raddr_a_o;
			assign rf_rd_b_wb_match = (rf_waddr_wb_i == rf_raddr_b_o) & |rf_raddr_b_o;
			assign rf_rd_a_wb_match_o = rf_rd_a_wb_match;
			assign rf_rd_b_wb_match_o = rf_rd_b_wb_match;
			assign rf_rd_a_hz = rf_rd_a_wb_match & rf_ren_a;
			assign rf_rd_b_hz = rf_rd_b_wb_match & rf_ren_b;
			assign rf_rdata_a_fwd = (rf_rd_a_wb_match & rf_write_wb_i ? rf_wdata_fwd_wb_i : rf_rdata_a_i);
			assign rf_rdata_b_fwd = (rf_rd_b_wb_match & rf_write_wb_i ? rf_wdata_fwd_wb_i : rf_rdata_b_i);
			assign stall_ld_hz = outstanding_load_wb_i & (rf_rd_a_hz | rf_rd_b_hz);
			assign instr_type_wb_o = (~lsu_req_dec ? 2'd2 : (lsu_we ? 2'd1 : 2'd0));
			assign instr_id_done_o = en_wb_o & ready_wb_i;
			assign stall_wb = en_wb_o & ~ready_wb_i;
			assign perf_dside_wait_o = (instr_valid_i & ~instr_kill) & (outstanding_memory_access | stall_ld_hz);
			assign expecting_load_resp_o = 1'b0;
			assign expecting_store_resp_o = 1'b0;
		end
		else begin : gen_no_stall_mem
			assign multicycle_done = (lsu_req_dec ? lsu_resp_valid_i : ex_valid_i);
			assign data_req_allowed = instr_first_cycle;
			assign stall_mem = instr_valid_i & (lsu_req_dec & (~lsu_resp_valid_i | instr_first_cycle));
			assign stall_ld_hz = 1'b0;
			assign instr_executing_spec = (instr_valid_i & ~instr_fetch_err_i) & controller_run;
			assign instr_executing = instr_executing_spec;
			assign rf_rdata_a_fwd = rf_rdata_a_i;
			assign rf_rdata_b_fwd = rf_rdata_b_i;
			assign rf_rd_a_wb_match_o = 1'b0;
			assign rf_rd_b_wb_match_o = 1'b0;
			assign expecting_load_resp_o = ((instr_valid_i & lsu_req_dec) & ~instr_first_cycle) & ~lsu_we;
			assign expecting_store_resp_o = ((instr_valid_i & lsu_req_dec) & ~instr_first_cycle) & lsu_we;
			wire unused_data_req_done_ex;
			wire [4:0] unused_rf_waddr_wb;
			wire unused_rf_write_wb;
			wire unused_outstanding_load_wb;
			wire unused_outstanding_store_wb;
			wire unused_wb_exception;
			wire [31:0] unused_rf_wdata_fwd_wb;
			wire unused_id_exception;
			assign unused_data_req_done_ex = lsu_req_done_i;
			assign unused_rf_waddr_wb = rf_waddr_wb_i;
			assign unused_rf_write_wb = rf_write_wb_i;
			assign unused_outstanding_load_wb = outstanding_load_wb_i;
			assign unused_outstanding_store_wb = outstanding_store_wb_i;
			assign unused_wb_exception = wb_exception;
			assign unused_rf_wdata_fwd_wb = rf_wdata_fwd_wb_i;
			assign unused_id_exception = id_exception;
			assign instr_type_wb_o = 2'd2;
			assign stall_wb = 1'b0;
			assign perf_dside_wait_o = (instr_executing & lsu_req_dec) & ~lsu_resp_valid_i;
			assign instr_id_done_o = instr_done;
		end
	endgenerate
	assign instr_perf_count_id_o = (((~ebrk_insn & ~ecall_insn_dec) & ~illegal_insn_dec) & ~illegal_csr_insn_i) & ~instr_fetch_err_i;
	assign en_wb_o = instr_done;
	assign perf_mul_wait_o = stall_multdiv & mult_en_dec;
	assign perf_div_wait_o = stall_multdiv & div_en_dec;
	initial _sv2v_0 = 0;
endmodule
module ibex_if_stage (
	clk_i,
	rst_ni,
	boot_addr_i,
	req_i,
	instr_req_o,
	instr_addr_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_rdata_i,
	instr_bus_err_i,
	instr_intg_err_o,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	instr_valid_id_o,
	instr_new_id_o,
	instr_rdata_id_o,
	instr_rdata_alu_id_o,
	instr_rdata_c_id_o,
	instr_is_compressed_id_o,
	instr_bp_taken_o,
	instr_fetch_err_o,
	instr_fetch_err_plus2_o,
	illegal_c_insn_id_o,
	dummy_instr_id_o,
	pc_if_o,
	pc_id_o,
	pmp_err_if_i,
	pmp_err_if_plus2_i,
	instr_valid_clear_i,
	pc_set_i,
	pc_mux_i,
	nt_branch_mispredict_i,
	nt_branch_addr_i,
	exc_pc_mux_i,
	exc_cause,
	dummy_instr_en_i,
	dummy_instr_mask_i,
	dummy_instr_seed_en_i,
	dummy_instr_seed_i,
	icache_enable_i,
	icache_inval_i,
	icache_ecc_error_o,
	branch_target_ex_i,
	csr_mepc_i,
	csr_depc_i,
	csr_mtvec_i,
	csr_mtvec_init_o,
	id_in_ready_i,
	pc_mismatch_alert_o,
	if_busy_o
);
	reg _sv2v_0;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] PCIncrCheck = 1'b0;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] boot_addr_i;
	input wire req_i;
	output wire instr_req_o;
	output wire [31:0] instr_addr_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_bus_err_i;
	output wire instr_intg_err_o;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output wire ic_scr_key_req_o;
	output wire instr_valid_id_o;
	output wire instr_new_id_o;
	output reg [31:0] instr_rdata_id_o;
	output reg [31:0] instr_rdata_alu_id_o;
	output reg [15:0] instr_rdata_c_id_o;
	output reg instr_is_compressed_id_o;
	output wire instr_bp_taken_o;
	output reg instr_fetch_err_o;
	output reg instr_fetch_err_plus2_o;
	output reg illegal_c_insn_id_o;
	output reg dummy_instr_id_o;
	output wire [31:0] pc_if_o;
	output reg [31:0] pc_id_o;
	input wire pmp_err_if_i;
	input wire pmp_err_if_plus2_i;
	input wire instr_valid_clear_i;
	input wire pc_set_i;
	input wire [2:0] pc_mux_i;
	input wire nt_branch_mispredict_i;
	input wire [31:0] nt_branch_addr_i;
	input wire [1:0] exc_pc_mux_i;
	input wire [6:0] exc_cause;
	input wire dummy_instr_en_i;
	input wire [2:0] dummy_instr_mask_i;
	input wire dummy_instr_seed_en_i;
	input wire [31:0] dummy_instr_seed_i;
	input wire icache_enable_i;
	input wire icache_inval_i;
	output wire icache_ecc_error_o;
	input wire [31:0] branch_target_ex_i;
	input wire [31:0] csr_mepc_i;
	input wire [31:0] csr_depc_i;
	input wire [31:0] csr_mtvec_i;
	output wire csr_mtvec_init_o;
	input wire id_in_ready_i;
	output wire pc_mismatch_alert_o;
	output wire if_busy_o;
	wire instr_valid_id_d;
	reg instr_valid_id_q;
	wire instr_new_id_d;
	reg instr_new_id_q;
	wire instr_err;
	wire instr_intg_err;
	wire prefetch_busy;
	wire branch_req;
	reg [31:0] fetch_addr_n;
	wire unused_fetch_addr_n0;
	wire prefetch_branch;
	wire [31:0] prefetch_addr;
	wire fetch_valid_raw;
	wire fetch_valid;
	wire fetch_ready;
	wire [31:0] fetch_rdata;
	wire [31:0] fetch_addr;
	wire fetch_err;
	wire fetch_err_plus2;
	wire [31:0] instr_decompressed;
	wire illegal_c_insn;
	wire instr_is_compressed;
	wire if_instr_valid;
	wire [31:0] if_instr_rdata;
	wire [31:0] if_instr_addr;
	wire if_instr_bus_err;
	wire if_instr_pmp_err;
	wire if_instr_err;
	wire if_instr_err_plus2;
	reg [31:0] exc_pc;
	wire if_id_pipe_reg_we;
	wire stall_dummy_instr;
	wire [31:0] instr_out;
	wire instr_is_compressed_out;
	wire illegal_c_instr_out;
	wire instr_err_out;
	wire predict_branch_taken;
	wire [31:0] predict_branch_pc;
	reg [4:0] irq_vec;
	wire [2:0] pc_mux_internal;
	wire [7:0] unused_boot_addr;
	wire [7:0] unused_csr_mtvec;
	wire unused_exc_cause;
	assign unused_boot_addr = boot_addr_i[7:0];
	assign unused_csr_mtvec = csr_mtvec_i[7:0];
	assign unused_exc_cause = |{exc_cause[5], exc_cause[6]};
	localparam [6:0] ibex_pkg_ExcCauseIrqNm = 7'h3f;
	always @(*) begin : exc_pc_mux
		if (_sv2v_0)
			;
		irq_vec = exc_cause[4-:5];
		if (exc_cause[6])
			irq_vec = ibex_pkg_ExcCauseIrqNm[4-:5];
		(* full_case, parallel_case *)
		case (exc_pc_mux_i)
			2'd0: exc_pc = {csr_mtvec_i[31:8], 8'h00};
			2'd1: exc_pc = {csr_mtvec_i[31:8], 1'b0, irq_vec, 2'b00};
			2'd2: exc_pc = DmHaltAddr;
			2'd3: exc_pc = DmExceptionAddr;
			default: exc_pc = {csr_mtvec_i[31:8], 8'h00};
		endcase
	end
	assign pc_mux_internal = ((BranchPredictor && predict_branch_taken) && !pc_set_i ? 3'd5 : pc_mux_i);
	always @(*) begin : fetch_addr_mux
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (pc_mux_internal)
			3'd0: fetch_addr_n = {boot_addr_i[31:8], 8'h80};
			3'd1: fetch_addr_n = branch_target_ex_i;
			3'd2: fetch_addr_n = exc_pc;
			3'd3: fetch_addr_n = csr_mepc_i;
			3'd4: fetch_addr_n = csr_depc_i;
			3'd5: fetch_addr_n = (BranchPredictor ? predict_branch_pc : {boot_addr_i[31:8], 8'h80});
			default: fetch_addr_n = {boot_addr_i[31:8], 8'h80};
		endcase
	end
	assign csr_mtvec_init_o = (pc_mux_i == 3'd0) & pc_set_i;
	generate
		if (MemECC) begin : g_mem_ecc
			wire [1:0] ecc_err;
			wire [MemDataWidth - 1:0] instr_rdata_buf;
			prim_buf #(.Width(MemDataWidth)) u_prim_buf_instr_rdata(
				.in_i(instr_rdata_i),
				.out_o(instr_rdata_buf)
			);
			prim_secded_inv_39_32_dec u_instr_intg_dec(
				.data_i(instr_rdata_buf),
				.data_o(),
				.syndrome_o(),
				.err_o(ecc_err)
			);
			assign instr_intg_err = |ecc_err;
		end
		else begin : g_no_mem_ecc
			assign instr_intg_err = 1'b0;
		end
	endgenerate
	assign instr_err = instr_intg_err | instr_bus_err_i;
	assign instr_intg_err_o = instr_intg_err & instr_rvalid_i;
	assign prefetch_branch = branch_req | nt_branch_mispredict_i;
	assign prefetch_addr = (branch_req ? {fetch_addr_n[31:1], 1'b0} : nt_branch_addr_i);
	assign fetch_valid = fetch_valid_raw & ~nt_branch_mispredict_i;
	generate
		if (ICache) begin : gen_icache
			ibex_icache #(
				.ICacheECC(ICacheECC),
				.ResetAll(ResetAll),
				.BusSizeECC(BusSizeECC),
				.TagSizeECC(TagSizeECC),
				.LineSizeECC(LineSizeECC)
			) icache_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req_i),
				.branch_i(prefetch_branch),
				.addr_i(prefetch_addr),
				.ready_i(fetch_ready),
				.valid_o(fetch_valid_raw),
				.rdata_o(fetch_rdata),
				.addr_o(fetch_addr),
				.err_o(fetch_err),
				.err_plus2_o(fetch_err_plus2),
				.instr_req_o(instr_req_o),
				.instr_addr_o(instr_addr_o),
				.instr_gnt_i(instr_gnt_i),
				.instr_rvalid_i(instr_rvalid_i),
				.instr_rdata_i(instr_rdata_i[31:0]),
				.instr_err_i(instr_err),
				.ic_tag_req_o(ic_tag_req_o),
				.ic_tag_write_o(ic_tag_write_o),
				.ic_tag_addr_o(ic_tag_addr_o),
				.ic_tag_wdata_o(ic_tag_wdata_o),
				.ic_tag_rdata_i(ic_tag_rdata_i),
				.ic_data_req_o(ic_data_req_o),
				.ic_data_write_o(ic_data_write_o),
				.ic_data_addr_o(ic_data_addr_o),
				.ic_data_wdata_o(ic_data_wdata_o),
				.ic_data_rdata_i(ic_data_rdata_i),
				.ic_scr_key_valid_i(ic_scr_key_valid_i),
				.ic_scr_key_req_o(ic_scr_key_req_o),
				.icache_enable_i(icache_enable_i),
				.icache_inval_i(icache_inval_i),
				.busy_o(prefetch_busy),
				.ecc_error_o(icache_ecc_error_o)
			);
		end
		else begin : gen_prefetch_buffer
			ibex_prefetch_buffer #(.ResetAll(ResetAll)) prefetch_buffer_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.req_i(req_i),
				.branch_i(prefetch_branch),
				.addr_i(prefetch_addr),
				.ready_i(fetch_ready),
				.valid_o(fetch_valid_raw),
				.rdata_o(fetch_rdata),
				.addr_o(fetch_addr),
				.err_o(fetch_err),
				.err_plus2_o(fetch_err_plus2),
				.instr_req_o(instr_req_o),
				.instr_addr_o(instr_addr_o),
				.instr_gnt_i(instr_gnt_i),
				.instr_rvalid_i(instr_rvalid_i),
				.instr_rdata_i(instr_rdata_i[31:0]),
				.instr_err_i(instr_err),
				.busy_o(prefetch_busy)
			);
			wire unused_icen;
			wire unused_icinv;
			wire unused_scr_key_valid;
			wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] unused_tag_ram_input;
			wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] unused_data_ram_input;
			assign unused_icen = icache_enable_i;
			assign unused_icinv = icache_inval_i;
			assign unused_tag_ram_input = ic_tag_rdata_i;
			assign unused_data_ram_input = ic_data_rdata_i;
			assign unused_scr_key_valid = ic_scr_key_valid_i;
			assign ic_tag_req_o = 'b0;
			assign ic_tag_write_o = 'b0;
			assign ic_tag_addr_o = 'b0;
			assign ic_tag_wdata_o = 'b0;
			assign ic_data_req_o = 'b0;
			assign ic_data_write_o = 'b0;
			assign ic_data_addr_o = 'b0;
			assign ic_data_wdata_o = 'b0;
			assign ic_scr_key_req_o = 'b0;
			assign icache_ecc_error_o = 'b0;
		end
	endgenerate
	assign unused_fetch_addr_n0 = fetch_addr_n[0];
	assign branch_req = pc_set_i | predict_branch_taken;
	assign pc_if_o = if_instr_addr;
	assign if_busy_o = prefetch_busy;
	assign if_instr_pmp_err = pmp_err_if_i | ((if_instr_addr[1] & ~instr_is_compressed) & pmp_err_if_plus2_i);
	assign if_instr_err = if_instr_bus_err | if_instr_pmp_err;
	assign if_instr_err_plus2 = (((if_instr_addr[1] & ~instr_is_compressed) & pmp_err_if_plus2_i) | fetch_err_plus2) & ~pmp_err_if_i;
	ibex_compressed_decoder compressed_decoder_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.valid_i(fetch_valid & ~fetch_err),
		.instr_i(if_instr_rdata),
		.instr_o(instr_decompressed),
		.is_compressed_o(instr_is_compressed),
		.illegal_instr_o(illegal_c_insn)
	);
	generate
		if (DummyInstructions) begin : gen_dummy_instr
			wire insert_dummy_instr;
			wire [31:0] dummy_instr_data;
			ibex_dummy_instr #(
				.RndCnstLfsrSeed(RndCnstLfsrSeed),
				.RndCnstLfsrPerm(RndCnstLfsrPerm)
			) dummy_instr_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.dummy_instr_en_i(dummy_instr_en_i),
				.dummy_instr_mask_i(dummy_instr_mask_i),
				.dummy_instr_seed_en_i(dummy_instr_seed_en_i),
				.dummy_instr_seed_i(dummy_instr_seed_i),
				.fetch_valid_i(fetch_valid),
				.id_in_ready_i(id_in_ready_i),
				.insert_dummy_instr_o(insert_dummy_instr),
				.dummy_instr_data_o(dummy_instr_data)
			);
			assign instr_out = (insert_dummy_instr ? dummy_instr_data : instr_decompressed);
			assign instr_is_compressed_out = (insert_dummy_instr ? 1'b0 : instr_is_compressed);
			assign illegal_c_instr_out = (insert_dummy_instr ? 1'b0 : illegal_c_insn);
			assign instr_err_out = (insert_dummy_instr ? 1'b0 : if_instr_err);
			assign stall_dummy_instr = insert_dummy_instr;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					dummy_instr_id_o <= 1'b0;
				else if (if_id_pipe_reg_we)
					dummy_instr_id_o <= insert_dummy_instr;
		end
		else begin : gen_no_dummy_instr
			wire unused_dummy_en;
			wire [2:0] unused_dummy_mask;
			wire unused_dummy_seed_en;
			wire [31:0] unused_dummy_seed;
			assign unused_dummy_en = dummy_instr_en_i;
			assign unused_dummy_mask = dummy_instr_mask_i;
			assign unused_dummy_seed_en = dummy_instr_seed_en_i;
			assign unused_dummy_seed = dummy_instr_seed_i;
			assign instr_out = instr_decompressed;
			assign instr_is_compressed_out = instr_is_compressed;
			assign illegal_c_instr_out = illegal_c_insn;
			assign instr_err_out = if_instr_err;
			assign stall_dummy_instr = 1'b0;
			wire [1:1] sv2v_tmp_C8A0C;
			assign sv2v_tmp_C8A0C = 1'b0;
			always @(*) dummy_instr_id_o = sv2v_tmp_C8A0C;
		end
	endgenerate
	assign instr_valid_id_d = ((if_instr_valid & id_in_ready_i) & ~pc_set_i) | (instr_valid_id_q & ~instr_valid_clear_i);
	assign instr_new_id_d = if_instr_valid & id_in_ready_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			instr_valid_id_q <= 1'b0;
			instr_new_id_q <= 1'b0;
		end
		else begin
			instr_valid_id_q <= instr_valid_id_d;
			instr_new_id_q <= instr_new_id_d;
		end
	assign instr_valid_id_o = instr_valid_id_q;
	assign instr_new_id_o = instr_new_id_q;
	assign if_id_pipe_reg_we = instr_new_id_d;
	generate
		if (ResetAll) begin : g_instr_rdata_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					instr_rdata_id_o <= 1'sb0;
					instr_rdata_alu_id_o <= 1'sb0;
					instr_fetch_err_o <= 1'sb0;
					instr_fetch_err_plus2_o <= 1'sb0;
					instr_rdata_c_id_o <= 1'sb0;
					instr_is_compressed_id_o <= 1'sb0;
					illegal_c_insn_id_o <= 1'sb0;
					pc_id_o <= 1'sb0;
				end
				else if (if_id_pipe_reg_we) begin
					instr_rdata_id_o <= instr_out;
					instr_rdata_alu_id_o <= instr_out;
					instr_fetch_err_o <= instr_err_out;
					instr_fetch_err_plus2_o <= if_instr_err_plus2;
					instr_rdata_c_id_o <= if_instr_rdata[15:0];
					instr_is_compressed_id_o <= instr_is_compressed_out;
					illegal_c_insn_id_o <= illegal_c_instr_out;
					pc_id_o <= pc_if_o;
				end
		end
		else begin : g_instr_rdata_nr
			always @(posedge clk_i)
				if (if_id_pipe_reg_we) begin
					instr_rdata_id_o <= instr_out;
					instr_rdata_alu_id_o <= instr_out;
					instr_fetch_err_o <= instr_err_out;
					instr_fetch_err_plus2_o <= if_instr_err_plus2;
					instr_rdata_c_id_o <= if_instr_rdata[15:0];
					instr_is_compressed_id_o <= instr_is_compressed_out;
					illegal_c_insn_id_o <= illegal_c_instr_out;
					pc_id_o <= pc_if_o;
				end
		end
		if (PCIncrCheck) begin : g_secure_pc
			wire [31:0] prev_instr_addr_incr;
			wire [31:0] prev_instr_addr_incr_buf;
			reg prev_instr_seq_q;
			wire prev_instr_seq_d;
			assign prev_instr_seq_d = (((prev_instr_seq_q | instr_new_id_d) & ~branch_req) & ~if_instr_err) & ~stall_dummy_instr;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					prev_instr_seq_q <= 1'b0;
				else
					prev_instr_seq_q <= prev_instr_seq_d;
			assign prev_instr_addr_incr = pc_id_o + (instr_is_compressed_id_o ? 32'd2 : 32'd4);
			prim_buf #(.Width(32)) u_prev_instr_addr_incr_buf(
				.in_i(prev_instr_addr_incr),
				.out_o(prev_instr_addr_incr_buf)
			);
			assign pc_mismatch_alert_o = prev_instr_seq_q & (pc_if_o != prev_instr_addr_incr_buf);
		end
		else begin : g_no_secure_pc
			assign pc_mismatch_alert_o = 1'b0;
		end
		if (BranchPredictor) begin : g_branch_predictor
			reg [31:0] instr_skid_data_q;
			reg [31:0] instr_skid_addr_q;
			reg instr_skid_bp_taken_q;
			reg instr_skid_valid_q;
			wire instr_skid_valid_d;
			wire instr_skid_en;
			reg instr_bp_taken_q;
			wire instr_bp_taken_d;
			wire predict_branch_taken_raw;
			if (ResetAll) begin : g_bp_taken_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni)
						instr_bp_taken_q <= 1'sb0;
					else if (if_id_pipe_reg_we)
						instr_bp_taken_q <= instr_bp_taken_d;
			end
			else begin : g_bp_taken_nr
				always @(posedge clk_i)
					if (if_id_pipe_reg_we)
						instr_bp_taken_q <= instr_bp_taken_d;
			end
			assign instr_skid_en = ((predict_branch_taken & ~pc_set_i) & ~id_in_ready_i) & ~instr_skid_valid_q;
			assign instr_skid_valid_d = ((instr_skid_valid_q & ~id_in_ready_i) & ~stall_dummy_instr) | instr_skid_en;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					instr_skid_valid_q <= 1'b0;
				else
					instr_skid_valid_q <= instr_skid_valid_d;
			if (ResetAll) begin : g_instr_skid_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						instr_skid_bp_taken_q <= 1'sb0;
						instr_skid_data_q <= 1'sb0;
						instr_skid_addr_q <= 1'sb0;
					end
					else if (instr_skid_en) begin
						instr_skid_bp_taken_q <= predict_branch_taken;
						instr_skid_data_q <= fetch_rdata;
						instr_skid_addr_q <= fetch_addr;
					end
			end
			else begin : g_instr_skid_nr
				always @(posedge clk_i)
					if (instr_skid_en) begin
						instr_skid_bp_taken_q <= predict_branch_taken;
						instr_skid_data_q <= fetch_rdata;
						instr_skid_addr_q <= fetch_addr;
					end
			end
			ibex_branch_predict branch_predict_i(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.fetch_rdata_i(fetch_rdata),
				.fetch_pc_i(fetch_addr),
				.fetch_valid_i(fetch_valid),
				.predict_branch_taken_o(predict_branch_taken_raw),
				.predict_branch_pc_o(predict_branch_pc)
			);
			assign predict_branch_taken = (predict_branch_taken_raw & ~instr_skid_valid_q) & ~fetch_err;
			assign if_instr_valid = fetch_valid | (instr_skid_valid_q & ~nt_branch_mispredict_i);
			assign if_instr_rdata = (instr_skid_valid_q ? instr_skid_data_q : fetch_rdata);
			assign if_instr_addr = (instr_skid_valid_q ? instr_skid_addr_q : fetch_addr);
			assign if_instr_bus_err = ~instr_skid_valid_q & fetch_err;
			assign instr_bp_taken_d = (instr_skid_valid_q ? instr_skid_bp_taken_q : predict_branch_taken);
			assign fetch_ready = (id_in_ready_i & ~stall_dummy_instr) & ~instr_skid_valid_q;
			assign instr_bp_taken_o = instr_bp_taken_q;
		end
		else begin : g_no_branch_predictor
			assign instr_bp_taken_o = 1'b0;
			assign predict_branch_taken = 1'b0;
			assign predict_branch_pc = 32'b00000000000000000000000000000000;
			assign if_instr_valid = fetch_valid;
			assign if_instr_rdata = fetch_rdata;
			assign if_instr_addr = fetch_addr;
			assign if_instr_bus_err = fetch_err;
			assign fetch_ready = id_in_ready_i & ~stall_dummy_instr;
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module ibex_load_store_unit (
	clk_i,
	rst_ni,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_bus_err_i,
	data_pmp_err_i,
	data_addr_o,
	data_we_o,
	data_be_o,
	data_wdata_o,
	data_rdata_i,
	lsu_we_i,
	lsu_type_i,
	lsu_wdata_i,
	lsu_sign_ext_i,
	lsu_rdata_o,
	lsu_rdata_valid_o,
	lsu_req_i,
	adder_result_ex_i,
	addr_incr_req_o,
	addr_last_o,
	lsu_req_done_o,
	lsu_resp_valid_o,
	load_err_o,
	load_resp_intg_err_o,
	store_err_o,
	store_resp_intg_err_o,
	busy_o,
	perf_load_o,
	perf_store_o
);
	reg _sv2v_0;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	input wire clk_i;
	input wire rst_ni;
	output reg data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	input wire data_bus_err_i;
	input wire data_pmp_err_i;
	output wire [31:0] data_addr_o;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [MemDataWidth - 1:0] data_wdata_o;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire lsu_we_i;
	input wire [1:0] lsu_type_i;
	input wire [31:0] lsu_wdata_i;
	input wire lsu_sign_ext_i;
	output wire [31:0] lsu_rdata_o;
	output wire lsu_rdata_valid_o;
	input wire lsu_req_i;
	input wire [31:0] adder_result_ex_i;
	output reg addr_incr_req_o;
	output wire [31:0] addr_last_o;
	output wire lsu_req_done_o;
	output wire lsu_resp_valid_o;
	output wire load_err_o;
	output wire load_resp_intg_err_o;
	output wire store_err_o;
	output wire store_resp_intg_err_o;
	output wire busy_o;
	output reg perf_load_o;
	output reg perf_store_o;
	wire [31:0] data_addr;
	wire [31:0] data_addr_w_aligned;
	reg [31:0] addr_last_q;
	wire [31:0] addr_last_d;
	reg addr_update;
	reg ctrl_update;
	reg rdata_update;
	reg [31:8] rdata_q;
	reg [1:0] rdata_offset_q;
	reg [1:0] data_type_q;
	reg data_sign_ext_q;
	reg data_we_q;
	wire [1:0] data_offset;
	reg [3:0] data_be;
	reg [31:0] data_wdata;
	reg [31:0] data_rdata_ext;
	reg [31:0] rdata_w_ext;
	reg [31:0] rdata_h_ext;
	reg [31:0] rdata_b_ext;
	wire split_misaligned_access;
	reg handle_misaligned_q;
	reg handle_misaligned_d;
	reg pmp_err_q;
	reg pmp_err_d;
	reg lsu_err_q;
	reg lsu_err_d;
	wire data_intg_err;
	wire data_or_pmp_err;
	reg [2:0] ls_fsm_cs;
	reg [2:0] ls_fsm_ns;
	assign data_addr = adder_result_ex_i;
	assign data_offset = data_addr[1:0];
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (lsu_type_i)
			2'b00:
				if (!handle_misaligned_q)
					(* full_case, parallel_case *)
					case (data_offset)
						2'b00: data_be = 4'b1111;
						2'b01: data_be = 4'b1110;
						2'b10: data_be = 4'b1100;
						2'b11: data_be = 4'b1000;
						default: data_be = 4'b1111;
					endcase
				else
					(* full_case, parallel_case *)
					case (data_offset)
						2'b00: data_be = 4'b0000;
						2'b01: data_be = 4'b0001;
						2'b10: data_be = 4'b0011;
						2'b11: data_be = 4'b0111;
						default: data_be = 4'b1111;
					endcase
			2'b01:
				if (!handle_misaligned_q)
					(* full_case, parallel_case *)
					case (data_offset)
						2'b00: data_be = 4'b0011;
						2'b01: data_be = 4'b0110;
						2'b10: data_be = 4'b1100;
						2'b11: data_be = 4'b1000;
						default: data_be = 4'b1111;
					endcase
				else
					data_be = 4'b0001;
			2'b10, 2'b11:
				(* full_case, parallel_case *)
				case (data_offset)
					2'b00: data_be = 4'b0001;
					2'b01: data_be = 4'b0010;
					2'b10: data_be = 4'b0100;
					2'b11: data_be = 4'b1000;
					default: data_be = 4'b1111;
				endcase
			default: data_be = 4'b1111;
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (data_offset)
			2'b00: data_wdata = lsu_wdata_i[31:0];
			2'b01: data_wdata = {lsu_wdata_i[23:0], lsu_wdata_i[31:24]};
			2'b10: data_wdata = {lsu_wdata_i[15:0], lsu_wdata_i[31:16]};
			2'b11: data_wdata = {lsu_wdata_i[7:0], lsu_wdata_i[31:8]};
			default: data_wdata = lsu_wdata_i[31:0];
		endcase
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rdata_q <= 1'sb0;
		else if (rdata_update)
			rdata_q <= data_rdata_i[31:8];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			rdata_offset_q <= 2'h0;
			data_type_q <= 2'h0;
			data_sign_ext_q <= 1'b0;
			data_we_q <= 1'b0;
		end
		else if (ctrl_update) begin
			rdata_offset_q <= data_offset;
			data_type_q <= lsu_type_i;
			data_sign_ext_q <= lsu_sign_ext_i;
			data_we_q <= lsu_we_i;
		end
	assign addr_last_d = (addr_incr_req_o ? data_addr_w_aligned : data_addr);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			addr_last_q <= 1'sb0;
		else if (addr_update)
			addr_last_q <= addr_last_d;
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00: rdata_w_ext = data_rdata_i[31:0];
			2'b01: rdata_w_ext = {data_rdata_i[7:0], rdata_q[31:8]};
			2'b10: rdata_w_ext = {data_rdata_i[15:0], rdata_q[31:16]};
			2'b11: rdata_w_ext = {data_rdata_i[23:0], rdata_q[31:24]};
			default: rdata_w_ext = data_rdata_i[31:0];
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
				else
					rdata_h_ext = {{16 {data_rdata_i[15]}}, data_rdata_i[15:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[23:8]};
				else
					rdata_h_ext = {{16 {data_rdata_i[23]}}, data_rdata_i[23:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[31:16]};
				else
					rdata_h_ext = {{16 {data_rdata_i[31]}}, data_rdata_i[31:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_h_ext = {16'h0000, data_rdata_i[7:0], rdata_q[31:24]};
				else
					rdata_h_ext = {{16 {data_rdata_i[7]}}, data_rdata_i[7:0], rdata_q[31:24]};
			default: rdata_h_ext = {16'h0000, data_rdata_i[15:0]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (rdata_offset_q)
			2'b00:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
				else
					rdata_b_ext = {{24 {data_rdata_i[7]}}, data_rdata_i[7:0]};
			2'b01:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[15:8]};
				else
					rdata_b_ext = {{24 {data_rdata_i[15]}}, data_rdata_i[15:8]};
			2'b10:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[23:16]};
				else
					rdata_b_ext = {{24 {data_rdata_i[23]}}, data_rdata_i[23:16]};
			2'b11:
				if (!data_sign_ext_q)
					rdata_b_ext = {24'h000000, data_rdata_i[31:24]};
				else
					rdata_b_ext = {{24 {data_rdata_i[31]}}, data_rdata_i[31:24]};
			default: rdata_b_ext = {24'h000000, data_rdata_i[7:0]};
		endcase
	end
	always @(*) begin
		if (_sv2v_0)
			;
		(* full_case, parallel_case *)
		case (data_type_q)
			2'b00: data_rdata_ext = rdata_w_ext;
			2'b01: data_rdata_ext = rdata_h_ext;
			2'b10, 2'b11: data_rdata_ext = rdata_b_ext;
			default: data_rdata_ext = rdata_w_ext;
		endcase
	end
	generate
		if (MemECC) begin : g_mem_rdata_ecc
			wire [1:0] ecc_err;
			wire [MemDataWidth - 1:0] data_rdata_buf;
			prim_buf #(.Width(MemDataWidth)) u_prim_buf_instr_rdata(
				.in_i(data_rdata_i),
				.out_o(data_rdata_buf)
			);
			prim_secded_inv_39_32_dec u_data_intg_dec(
				.data_i(data_rdata_buf),
				.data_o(),
				.syndrome_o(),
				.err_o(ecc_err)
			);
			assign data_intg_err = |ecc_err;
		end
		else begin : g_no_mem_data_ecc
			assign data_intg_err = 1'b0;
		end
	endgenerate
	assign split_misaligned_access = ((lsu_type_i == 2'b00) && (data_offset != 2'b00)) || ((lsu_type_i == 2'b01) && (data_offset == 2'b11));
	always @(*) begin
		if (_sv2v_0)
			;
		ls_fsm_ns = ls_fsm_cs;
		data_req_o = 1'b0;
		addr_incr_req_o = 1'b0;
		handle_misaligned_d = handle_misaligned_q;
		pmp_err_d = pmp_err_q;
		lsu_err_d = lsu_err_q;
		addr_update = 1'b0;
		ctrl_update = 1'b0;
		rdata_update = 1'b0;
		perf_load_o = 1'b0;
		perf_store_o = 1'b0;
		(* full_case, parallel_case *)
		case (ls_fsm_cs)
			3'd0: begin
				pmp_err_d = 1'b0;
				if (lsu_req_i) begin
					data_req_o = 1'b1;
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = 1'b0;
					perf_load_o = ~lsu_we_i;
					perf_store_o = lsu_we_i;
					if (data_gnt_i) begin
						ctrl_update = 1'b1;
						addr_update = 1'b1;
						handle_misaligned_d = split_misaligned_access;
						ls_fsm_ns = (split_misaligned_access ? 3'd2 : 3'd0);
					end
					else
						ls_fsm_ns = (split_misaligned_access ? 3'd1 : 3'd3);
				end
			end
			3'd1: begin
				data_req_o = 1'b1;
				if (data_gnt_i || pmp_err_q) begin
					addr_update = 1'b1;
					ctrl_update = 1'b1;
					handle_misaligned_d = 1'b1;
					ls_fsm_ns = 3'd2;
				end
			end
			3'd2: begin
				data_req_o = 1'b1;
				addr_incr_req_o = 1'b1;
				if (data_rvalid_i || pmp_err_q) begin
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = data_bus_err_i | pmp_err_q;
					rdata_update = ~data_we_q;
					ls_fsm_ns = (data_gnt_i ? 3'd0 : 3'd3);
					addr_update = data_gnt_i & ~(data_bus_err_i | pmp_err_q);
					handle_misaligned_d = ~data_gnt_i;
				end
				else if (data_gnt_i) begin
					ls_fsm_ns = 3'd4;
					handle_misaligned_d = 1'b0;
				end
			end
			3'd3: begin
				addr_incr_req_o = handle_misaligned_q;
				data_req_o = 1'b1;
				if (data_gnt_i || pmp_err_q) begin
					ctrl_update = 1'b1;
					addr_update = ~lsu_err_q;
					ls_fsm_ns = 3'd0;
					handle_misaligned_d = 1'b0;
				end
			end
			3'd4: begin
				addr_incr_req_o = 1'b1;
				if (data_rvalid_i) begin
					pmp_err_d = data_pmp_err_i;
					lsu_err_d = data_bus_err_i;
					addr_update = ~data_bus_err_i;
					rdata_update = ~data_we_q;
					ls_fsm_ns = 3'd0;
				end
			end
			default: ls_fsm_ns = 3'd0;
		endcase
	end
	assign lsu_req_done_o = (lsu_req_i | (ls_fsm_cs != 3'd0)) & (ls_fsm_ns == 3'd0);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			ls_fsm_cs <= 3'd0;
			handle_misaligned_q <= 1'sb0;
			pmp_err_q <= 1'sb0;
			lsu_err_q <= 1'sb0;
		end
		else begin
			ls_fsm_cs <= ls_fsm_ns;
			handle_misaligned_q <= handle_misaligned_d;
			pmp_err_q <= pmp_err_d;
			lsu_err_q <= lsu_err_d;
		end
	assign data_or_pmp_err = (lsu_err_q | data_bus_err_i) | pmp_err_q;
	assign lsu_resp_valid_o = (data_rvalid_i | pmp_err_q) & (ls_fsm_cs == 3'd0);
	assign lsu_rdata_valid_o = ((((ls_fsm_cs == 3'd0) & data_rvalid_i) & ~data_or_pmp_err) & ~data_we_q) & ~data_intg_err;
	assign lsu_rdata_o = data_rdata_ext;
	assign data_addr_w_aligned = {data_addr[31:2], 2'b00};
	assign data_addr_o = data_addr_w_aligned;
	assign data_we_o = lsu_we_i;
	assign data_be_o = data_be;
	generate
		if (MemECC) begin : g_mem_wdata_ecc
			prim_secded_inv_39_32_enc u_data_gen(
				.data_i(data_wdata),
				.data_o(data_wdata_o)
			);
		end
		else begin : g_no_mem_wdata_ecc
			assign data_wdata_o = data_wdata;
		end
	endgenerate
	assign addr_last_o = addr_last_q;
	assign load_err_o = (data_or_pmp_err & ~data_we_q) & lsu_resp_valid_o;
	assign store_err_o = (data_or_pmp_err & data_we_q) & lsu_resp_valid_o;
	assign load_resp_intg_err_o = (data_intg_err & data_rvalid_i) & ~data_we_q;
	assign store_resp_intg_err_o = (data_intg_err & data_rvalid_i) & data_we_q;
	assign busy_o = ls_fsm_cs != 3'd0;
	initial _sv2v_0 = 0;
endmodule
module ibex_multdiv_fast (
	clk_i,
	rst_ni,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero_i,
	data_ind_timing_i,
	alu_operand_a_o,
	alu_operand_b_o,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	multdiv_ready_id_i,
	multdiv_result_o,
	valid_o
);
	reg _sv2v_0;
	parameter integer RV32M = 32'sd2;
	input wire clk_i;
	input wire rst_ni;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero_i;
	input wire data_ind_timing_i;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	input wire [67:0] imd_val_q_i;
	output wire [67:0] imd_val_d_o;
	output wire [1:0] imd_val_we_o;
	input wire multdiv_ready_id_i;
	output wire [31:0] multdiv_result_o;
	output wire valid_o;
	wire signed [34:0] mac_res_signed;
	wire [34:0] mac_res_ext;
	reg [33:0] accum;
	reg sign_a;
	reg sign_b;
	reg mult_valid;
	wire signed_mult;
	reg [33:0] mac_res_d;
	reg [33:0] op_remainder_d;
	wire [33:0] mac_res;
	wire div_sign_a;
	wire div_sign_b;
	reg is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	wire [31:0] one_shift;
	wire [31:0] op_denominator_q;
	reg [31:0] op_numerator_q;
	reg [31:0] op_quotient_q;
	reg [31:0] op_denominator_d;
	reg [31:0] op_numerator_d;
	reg [31:0] op_quotient_d;
	wire [31:0] next_remainder;
	wire [32:0] next_quotient;
	wire [31:0] res_adder_h;
	reg div_valid;
	reg [4:0] div_counter_q;
	reg [4:0] div_counter_d;
	wire multdiv_en;
	reg mult_hold;
	reg div_hold;
	reg div_by_zero_d;
	reg div_by_zero_q;
	wire mult_en_internal;
	wire div_en_internal;
	wire sva_mul_fsm_idle;
	reg [2:0] md_state_q;
	reg [2:0] md_state_d;
	wire unused_mult_sel_i;
	assign unused_mult_sel_i = mult_sel_i;
	assign mult_en_internal = mult_en_i & ~mult_hold;
	assign div_en_internal = div_en_i & ~div_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			div_counter_q <= 1'sb0;
			md_state_q <= 3'd0;
			op_numerator_q <= 1'sb0;
			op_quotient_q <= 1'sb0;
			div_by_zero_q <= 1'sb0;
		end
		else if (div_en_internal) begin
			div_counter_q <= div_counter_d;
			op_numerator_q <= op_numerator_d;
			op_quotient_q <= op_quotient_d;
			md_state_q <= md_state_d;
			div_by_zero_q <= div_by_zero_d;
		end
	assign multdiv_en = mult_en_internal | div_en_internal;
	assign imd_val_d_o[34+:34] = (div_sel_i ? op_remainder_d : mac_res_d);
	assign imd_val_we_o[0] = multdiv_en;
	assign imd_val_d_o[0+:34] = {2'b00, op_denominator_d};
	assign imd_val_we_o[1] = div_en_internal;
	assign op_denominator_q = imd_val_q_i[31-:32];
	wire [1:0] unused_imd_val;
	assign unused_imd_val = imd_val_q_i[33-:2];
	wire unused_mac_res_ext;
	assign unused_mac_res_ext = mac_res_ext[34];
	assign signed_mult = signed_mode_i != 2'b00;
	assign multdiv_result_o = (div_sel_i ? imd_val_q_i[65-:32] : mac_res_d[31:0]);
	generate
		if (RV32M == 32'sd3) begin : gen_mult_single_cycle
			reg mult_state_q;
			reg mult_state_d;
			wire signed [33:0] mult1_res;
			wire signed [33:0] mult2_res;
			wire signed [33:0] mult3_res;
			wire [33:0] mult1_res_uns;
			wire [33:32] unused_mult1_res_uns;
			wire [15:0] mult1_op_a;
			wire [15:0] mult1_op_b;
			wire [15:0] mult2_op_a;
			wire [15:0] mult2_op_b;
			reg [15:0] mult3_op_a;
			reg [15:0] mult3_op_b;
			wire mult1_sign_a;
			wire mult1_sign_b;
			wire mult2_sign_a;
			wire mult2_sign_b;
			reg mult3_sign_a;
			reg mult3_sign_b;
			reg [33:0] summand1;
			reg [33:0] summand2;
			reg [33:0] summand3;
			assign mult1_res = $signed({mult1_sign_a, mult1_op_a}) * $signed({mult1_sign_b, mult1_op_b});
			assign mult2_res = $signed({mult2_sign_a, mult2_op_a}) * $signed({mult2_sign_b, mult2_op_b});
			assign mult3_res = $signed({mult3_sign_a, mult3_op_a}) * $signed({mult3_sign_b, mult3_op_b});
			assign mac_res_signed = ($signed(summand1) + $signed(summand2)) + $signed(summand3);
			assign mult1_res_uns = $unsigned(mult1_res);
			assign mac_res_ext = $unsigned(mac_res_signed);
			assign mac_res = mac_res_ext[33:0];
			wire [1:1] sv2v_tmp_5ADA8;
			assign sv2v_tmp_5ADA8 = signed_mode_i[0] & op_a_i[31];
			always @(*) sign_a = sv2v_tmp_5ADA8;
			wire [1:1] sv2v_tmp_C5449;
			assign sv2v_tmp_C5449 = signed_mode_i[1] & op_b_i[31];
			always @(*) sign_b = sv2v_tmp_C5449;
			assign mult1_sign_a = 1'b0;
			assign mult1_sign_b = 1'b0;
			assign mult1_op_a = op_a_i[15:0];
			assign mult1_op_b = op_b_i[15:0];
			assign mult2_sign_a = 1'b0;
			assign mult2_sign_b = sign_b;
			assign mult2_op_a = op_a_i[15:0];
			assign mult2_op_b = op_b_i[31:16];
			wire [18:1] sv2v_tmp_6FF3F;
			assign sv2v_tmp_6FF3F = imd_val_q_i[67-:18];
			always @(*) accum[17:0] = sv2v_tmp_6FF3F;
			wire [16:1] sv2v_tmp_A7770;
			assign sv2v_tmp_A7770 = {16 {signed_mult & imd_val_q_i[67]}};
			always @(*) accum[33:18] = sv2v_tmp_A7770;
			always @(*) begin
				if (_sv2v_0)
					;
				mult3_sign_a = sign_a;
				mult3_sign_b = 1'b0;
				mult3_op_a = op_a_i[31:16];
				mult3_op_b = op_b_i[15:0];
				summand1 = {18'h00000, mult1_res_uns[31:16]};
				summand2 = $unsigned(mult2_res);
				summand3 = $unsigned(mult3_res);
				mac_res_d = {2'b00, mac_res[15:0], mult1_res_uns[15:0]};
				mult_valid = mult_en_i;
				mult_state_d = 1'd0;
				mult_hold = 1'b0;
				(* full_case, parallel_case *)
				case (mult_state_q)
					1'd0:
						if (operator_i != 2'd0) begin
							mac_res_d = mac_res;
							mult_valid = 1'b0;
							mult_state_d = 1'd1;
						end
						else
							mult_hold = ~multdiv_ready_id_i;
					1'd1: begin
						mult3_sign_a = sign_a;
						mult3_sign_b = sign_b;
						mult3_op_a = op_a_i[31:16];
						mult3_op_b = op_b_i[31:16];
						mac_res_d = mac_res;
						summand1 = 1'sb0;
						summand2 = accum;
						summand3 = $unsigned(mult3_res);
						mult_state_d = 1'd0;
						mult_valid = 1'b1;
						mult_hold = ~multdiv_ready_id_i;
					end
					default: mult_state_d = 1'd0;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mult_state_q <= 1'd0;
				else if (mult_en_internal)
					mult_state_q <= mult_state_d;
			assign unused_mult1_res_uns = mult1_res_uns[33:32];
			assign sva_mul_fsm_idle = mult_state_q == 1'd0;
		end
		else begin : gen_mult_fast
			reg [15:0] mult_op_a;
			reg [15:0] mult_op_b;
			reg [1:0] mult_state_q;
			reg [1:0] mult_state_d;
			assign mac_res_signed = ($signed({sign_a, mult_op_a}) * $signed({sign_b, mult_op_b})) + $signed(accum);
			assign mac_res_ext = $unsigned(mac_res_signed);
			assign mac_res = mac_res_ext[33:0];
			always @(*) begin
				if (_sv2v_0)
					;
				mult_op_a = op_a_i[15:0];
				mult_op_b = op_b_i[15:0];
				sign_a = 1'b0;
				sign_b = 1'b0;
				accum = imd_val_q_i[34+:34];
				mac_res_d = mac_res;
				mult_state_d = mult_state_q;
				mult_valid = 1'b0;
				mult_hold = 1'b0;
				(* full_case, parallel_case *)
				case (mult_state_q)
					2'd0: begin
						mult_op_a = op_a_i[15:0];
						mult_op_b = op_b_i[15:0];
						sign_a = 1'b0;
						sign_b = 1'b0;
						accum = 1'sb0;
						mac_res_d = mac_res;
						mult_state_d = 2'd1;
					end
					2'd1: begin
						mult_op_a = op_a_i[15:0];
						mult_op_b = op_b_i[31:16];
						sign_a = 1'b0;
						sign_b = signed_mode_i[1] & op_b_i[31];
						accum = {18'b000000000000000000, imd_val_q_i[65-:16]};
						if (operator_i == 2'd0)
							mac_res_d = {2'b00, mac_res[15:0], imd_val_q_i[49-:16]};
						else
							mac_res_d = mac_res;
						mult_state_d = 2'd2;
					end
					2'd2: begin
						mult_op_a = op_a_i[31:16];
						mult_op_b = op_b_i[15:0];
						sign_a = signed_mode_i[0] & op_a_i[31];
						sign_b = 1'b0;
						if (operator_i == 2'd0) begin
							accum = {18'b000000000000000000, imd_val_q_i[65-:16]};
							mac_res_d = {2'b00, mac_res[15:0], imd_val_q_i[49-:16]};
							mult_valid = 1'b1;
							mult_state_d = 2'd0;
							mult_hold = ~multdiv_ready_id_i;
						end
						else begin
							accum = imd_val_q_i[34+:34];
							mac_res_d = mac_res;
							mult_state_d = 2'd3;
						end
					end
					2'd3: begin
						mult_op_a = op_a_i[31:16];
						mult_op_b = op_b_i[31:16];
						sign_a = signed_mode_i[0] & op_a_i[31];
						sign_b = signed_mode_i[1] & op_b_i[31];
						accum[17:0] = imd_val_q_i[67-:18];
						accum[33:18] = {16 {signed_mult & imd_val_q_i[67]}};
						mac_res_d = mac_res;
						mult_valid = 1'b1;
						mult_state_d = 2'd0;
						mult_hold = ~multdiv_ready_id_i;
					end
					default: mult_state_d = 2'd0;
				endcase
			end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					mult_state_q <= 2'd0;
				else if (mult_en_internal)
					mult_state_q <= mult_state_d;
			assign sva_mul_fsm_idle = mult_state_q == 2'd0;
		end
	endgenerate
	assign res_adder_h = alu_adder_ext_i[32:1];
	wire [1:0] unused_alu_adder_ext;
	assign unused_alu_adder_ext = {alu_adder_ext_i[33], alu_adder_ext_i[0]};
	assign next_remainder = (is_greater_equal ? res_adder_h[31:0] : imd_val_q_i[65-:32]);
	assign next_quotient = (is_greater_equal ? {1'b0, op_quotient_q} | {1'b0, one_shift} : {1'b0, op_quotient_q});
	assign one_shift = 32'b00000000000000000000000000000001 << div_counter_q;
	always @(*) begin
		if (_sv2v_0)
			;
		if ((imd_val_q_i[65] ^ op_denominator_q[31]) == 1'b0)
			is_greater_equal = res_adder_h[31] == 1'b0;
		else
			is_greater_equal = imd_val_q_i[65];
	end
	assign div_sign_a = op_a_i[31] & signed_mode_i[0];
	assign div_sign_b = op_b_i[31] & signed_mode_i[1];
	assign div_change_sign = (div_sign_a ^ div_sign_b) & ~div_by_zero_q;
	assign rem_change_sign = div_sign_a;
	always @(*) begin
		if (_sv2v_0)
			;
		div_counter_d = div_counter_q - 5'h01;
		op_remainder_d = imd_val_q_i[34+:34];
		op_quotient_d = op_quotient_q;
		md_state_d = md_state_q;
		op_numerator_d = op_numerator_q;
		op_denominator_d = op_denominator_q;
		alu_operand_a_o = 33'h000000001;
		alu_operand_b_o = {~op_b_i, 1'b1};
		div_valid = 1'b0;
		div_hold = 1'b0;
		div_by_zero_d = div_by_zero_q;
		(* full_case, parallel_case *)
		case (md_state_q)
			3'd0: begin
				if (operator_i == 2'd2) begin
					op_remainder_d = 1'sb1;
					md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
					div_by_zero_d = equal_to_zero_i;
				end
				else begin
					op_remainder_d = {2'b00, op_a_i};
					md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
				end
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_b_i, 1'b1};
				div_counter_d = 5'd31;
			end
			3'd1: begin
				op_quotient_d = 1'sb0;
				op_numerator_d = (div_sign_a ? alu_adder_i : op_a_i);
				md_state_d = 3'd2;
				div_counter_d = 5'd31;
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_a_i, 1'b1};
			end
			3'd2: begin
				op_remainder_d = {33'h000000000, op_numerator_q[31]};
				op_denominator_d = (div_sign_b ? alu_adder_i : op_b_i);
				md_state_d = 3'd3;
				div_counter_d = 5'd31;
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~op_b_i, 1'b1};
			end
			3'd3: begin
				op_remainder_d = {1'b0, next_remainder[31:0], op_numerator_q[div_counter_d]};
				op_quotient_d = next_quotient[31:0];
				md_state_d = (div_counter_q == 5'd1 ? 3'd4 : 3'd3);
				alu_operand_a_o = {imd_val_q_i[65-:32], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
			end
			3'd4: begin
				if (operator_i == 2'd2)
					op_remainder_d = {1'b0, next_quotient};
				else
					op_remainder_d = {2'b00, next_remainder[31:0]};
				alu_operand_a_o = {imd_val_q_i[65-:32], 1'b1};
				alu_operand_b_o = {~op_denominator_q[31:0], 1'b1};
				md_state_d = 3'd5;
			end
			3'd5: begin
				md_state_d = 3'd6;
				if (operator_i == 2'd2)
					op_remainder_d = (div_change_sign ? {2'h0, alu_adder_i} : imd_val_q_i[34+:34]);
				else
					op_remainder_d = (rem_change_sign ? {2'h0, alu_adder_i} : imd_val_q_i[34+:34]);
				alu_operand_a_o = 33'h000000001;
				alu_operand_b_o = {~imd_val_q_i[65-:32], 1'b1};
			end
			3'd6: begin
				md_state_d = 3'd0;
				div_hold = ~multdiv_ready_id_i;
				div_valid = 1'b1;
			end
			default: md_state_d = 3'd0;
		endcase
	end
	assign valid_o = mult_valid | div_valid;
	wire unused_sva_mul_fsm_idle;
	assign unused_sva_mul_fsm_idle = sva_mul_fsm_idle;
	initial _sv2v_0 = 0;
endmodule
module ibex_multdiv_slow (
	clk_i,
	rst_ni,
	mult_en_i,
	div_en_i,
	mult_sel_i,
	div_sel_i,
	operator_i,
	signed_mode_i,
	op_a_i,
	op_b_i,
	alu_adder_ext_i,
	alu_adder_i,
	equal_to_zero_i,
	data_ind_timing_i,
	alu_operand_a_o,
	alu_operand_b_o,
	imd_val_q_i,
	imd_val_d_o,
	imd_val_we_o,
	multdiv_ready_id_i,
	multdiv_result_o,
	valid_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire rst_ni;
	input wire mult_en_i;
	input wire div_en_i;
	input wire mult_sel_i;
	input wire div_sel_i;
	input wire [1:0] operator_i;
	input wire [1:0] signed_mode_i;
	input wire [31:0] op_a_i;
	input wire [31:0] op_b_i;
	input wire [33:0] alu_adder_ext_i;
	input wire [31:0] alu_adder_i;
	input wire equal_to_zero_i;
	input wire data_ind_timing_i;
	output reg [32:0] alu_operand_a_o;
	output reg [32:0] alu_operand_b_o;
	input wire [67:0] imd_val_q_i;
	output wire [67:0] imd_val_d_o;
	output wire [1:0] imd_val_we_o;
	input wire multdiv_ready_id_i;
	output wire [31:0] multdiv_result_o;
	output wire valid_o;
	reg [2:0] md_state_q;
	reg [2:0] md_state_d;
	wire [32:0] accum_window_q;
	reg [32:0] accum_window_d;
	wire unused_imd_val0;
	wire [1:0] unused_imd_val1;
	wire [32:0] res_adder_l;
	wire [32:0] res_adder_h;
	reg [4:0] multdiv_count_q;
	reg [4:0] multdiv_count_d;
	reg [32:0] op_b_shift_q;
	reg [32:0] op_b_shift_d;
	reg [32:0] op_a_shift_q;
	reg [32:0] op_a_shift_d;
	wire [32:0] op_a_ext;
	wire [32:0] op_b_ext;
	wire [32:0] one_shift;
	wire [32:0] op_a_bw_pp;
	wire [32:0] op_a_bw_last_pp;
	wire [31:0] b_0;
	wire sign_a;
	wire sign_b;
	wire [32:0] next_quotient;
	wire [31:0] next_remainder;
	wire [31:0] op_numerator_q;
	reg [31:0] op_numerator_d;
	wire is_greater_equal;
	wire div_change_sign;
	wire rem_change_sign;
	reg div_by_zero_d;
	reg div_by_zero_q;
	reg multdiv_hold;
	wire multdiv_en;
	assign res_adder_l = alu_adder_ext_i[32:0];
	assign res_adder_h = alu_adder_ext_i[33:1];
	assign imd_val_d_o[34+:34] = {1'b0, accum_window_d};
	assign imd_val_we_o[0] = ~multdiv_hold;
	assign accum_window_q = imd_val_q_i[66-:33];
	assign unused_imd_val0 = imd_val_q_i[67];
	assign imd_val_d_o[0+:34] = {2'b00, op_numerator_d};
	assign imd_val_we_o[1] = multdiv_en;
	assign op_numerator_q = imd_val_q_i[31-:32];
	assign unused_imd_val1 = imd_val_q_i[33-:2];
	always @(*) begin
		if (_sv2v_0)
			;
		alu_operand_a_o = accum_window_q;
		(* full_case, parallel_case *)
		case (operator_i)
			2'd0: alu_operand_b_o = op_a_bw_pp;
			2'd1: alu_operand_b_o = (md_state_q == 3'd4 ? op_a_bw_last_pp : op_a_bw_pp);
			2'd2, 2'd3:
				(* full_case, parallel_case *)
				case (md_state_q)
					3'd0: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_b_i, 1'b1};
					end
					3'd1: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_a_i, 1'b1};
					end
					3'd2: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~op_b_i, 1'b1};
					end
					3'd5: begin
						alu_operand_a_o = 33'h000000001;
						alu_operand_b_o = {~accum_window_q[31:0], 1'b1};
					end
					default: begin
						alu_operand_a_o = {accum_window_q[31:0], 1'b1};
						alu_operand_b_o = {~op_b_shift_q[31:0], 1'b1};
					end
				endcase
			default: begin
				alu_operand_a_o = accum_window_q;
				alu_operand_b_o = {~op_b_shift_q[31:0], 1'b1};
			end
		endcase
	end
	assign b_0 = {32 {op_b_shift_q[0]}};
	assign op_a_bw_pp = {~(op_a_shift_q[32] & op_b_shift_q[0]), op_a_shift_q[31:0] & b_0};
	assign op_a_bw_last_pp = {op_a_shift_q[32] & op_b_shift_q[0], ~(op_a_shift_q[31:0] & b_0)};
	assign sign_a = op_a_i[31] & signed_mode_i[0];
	assign sign_b = op_b_i[31] & signed_mode_i[1];
	assign op_a_ext = {sign_a, op_a_i};
	assign op_b_ext = {sign_b, op_b_i};
	assign is_greater_equal = (accum_window_q[31] == op_b_shift_q[31] ? ~res_adder_h[31] : accum_window_q[31]);
	assign one_shift = 33'b000000000000000000000000000000001 << multdiv_count_q;
	assign next_remainder = (is_greater_equal ? res_adder_h[31:0] : accum_window_q[31:0]);
	assign next_quotient = (is_greater_equal ? op_a_shift_q | one_shift : op_a_shift_q);
	assign div_change_sign = (sign_a ^ sign_b) & ~div_by_zero_q;
	assign rem_change_sign = sign_a;
	always @(*) begin
		if (_sv2v_0)
			;
		multdiv_count_d = multdiv_count_q;
		accum_window_d = accum_window_q;
		op_b_shift_d = op_b_shift_q;
		op_a_shift_d = op_a_shift_q;
		op_numerator_d = op_numerator_q;
		md_state_d = md_state_q;
		multdiv_hold = 1'b0;
		div_by_zero_d = div_by_zero_q;
		if (mult_sel_i || div_sel_i)
			(* full_case, parallel_case *)
			case (md_state_q)
				3'd0: begin
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							op_a_shift_d = op_a_ext << 1;
							accum_window_d = {~(op_a_ext[32] & op_b_i[0]), op_a_ext[31:0] & {32 {op_b_i[0]}}};
							op_b_shift_d = op_b_ext >> 1;
							md_state_d = (!data_ind_timing_i && ((op_b_ext >> 1) == 0) ? 3'd4 : 3'd3);
						end
						2'd1: begin
							op_a_shift_d = op_a_ext;
							accum_window_d = {1'b1, ~(op_a_ext[32] & op_b_i[0]), op_a_ext[31:1] & {31 {op_b_i[0]}}};
							op_b_shift_d = op_b_ext >> 1;
							md_state_d = 3'd3;
						end
						2'd2: begin
							accum_window_d = {33 {1'b1}};
							md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
							div_by_zero_d = equal_to_zero_i;
						end
						2'd3: begin
							accum_window_d = op_a_ext;
							md_state_d = (!data_ind_timing_i && equal_to_zero_i ? 3'd6 : 3'd1);
						end
						default:
							;
					endcase
					multdiv_count_d = 5'd31;
				end
				3'd1: begin
					op_a_shift_d = 1'sb0;
					op_numerator_d = (sign_a ? alu_adder_i : op_a_i);
					md_state_d = 3'd2;
				end
				3'd2: begin
					accum_window_d = {32'h00000000, op_numerator_q[31]};
					op_b_shift_d = (sign_b ? {1'b0, alu_adder_i} : {1'b0, op_b_i});
					md_state_d = 3'd3;
				end
				3'd3: begin
					multdiv_count_d = multdiv_count_q - 5'h01;
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							accum_window_d = res_adder_l;
							op_a_shift_d = op_a_shift_q << 1;
							op_b_shift_d = op_b_shift_q >> 1;
							md_state_d = ((!data_ind_timing_i && (op_b_shift_d == 0)) || (multdiv_count_q == 5'd1) ? 3'd4 : 3'd3);
						end
						2'd1: begin
							accum_window_d = res_adder_h;
							op_a_shift_d = op_a_shift_q;
							op_b_shift_d = op_b_shift_q >> 1;
							md_state_d = (multdiv_count_q == 5'd1 ? 3'd4 : 3'd3);
						end
						2'd2, 2'd3: begin
							accum_window_d = {next_remainder[31:0], op_numerator_q[multdiv_count_d]};
							op_a_shift_d = next_quotient;
							md_state_d = (multdiv_count_q == 5'd1 ? 3'd4 : 3'd3);
						end
						default:
							;
					endcase
				end
				3'd4:
					(* full_case, parallel_case *)
					case (operator_i)
						2'd0: begin
							accum_window_d = res_adder_l;
							md_state_d = 3'd0;
							multdiv_hold = ~multdiv_ready_id_i;
						end
						2'd1: begin
							accum_window_d = res_adder_l;
							md_state_d = 3'd0;
							md_state_d = 3'd0;
							multdiv_hold = ~multdiv_ready_id_i;
						end
						2'd2: begin
							accum_window_d = next_quotient;
							md_state_d = 3'd5;
						end
						2'd3: begin
							accum_window_d = {1'b0, next_remainder[31:0]};
							md_state_d = 3'd5;
						end
						default:
							;
					endcase
				3'd5: begin
					md_state_d = 3'd6;
					(* full_case, parallel_case *)
					case (operator_i)
						2'd2: accum_window_d = (div_change_sign ? {1'b0, alu_adder_i} : accum_window_q);
						2'd3: accum_window_d = (rem_change_sign ? {1'b0, alu_adder_i} : accum_window_q);
						default:
							;
					endcase
				end
				3'd6: begin
					md_state_d = 3'd0;
					multdiv_hold = ~multdiv_ready_id_i;
				end
				default: md_state_d = 3'd0;
			endcase
	end
	assign multdiv_en = (mult_en_i | div_en_i) & ~multdiv_hold;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			multdiv_count_q <= 5'h00;
			op_b_shift_q <= 33'h000000000;
			op_a_shift_q <= 33'h000000000;
			md_state_q <= 3'd0;
			div_by_zero_q <= 1'b0;
		end
		else if (multdiv_en) begin
			multdiv_count_q <= multdiv_count_d;
			op_b_shift_q <= op_b_shift_d;
			op_a_shift_q <= op_a_shift_d;
			md_state_q <= md_state_d;
			div_by_zero_q <= div_by_zero_d;
		end
	assign valid_o = (md_state_q == 3'd6) | ((md_state_q == 3'd4) & ((operator_i == 2'd0) | (operator_i == 2'd1)));
	assign multdiv_result_o = (div_en_i ? accum_window_q[31:0] : res_adder_l[31:0]);
	initial _sv2v_0 = 0;
endmodule
module ibex_prefetch_buffer (
	clk_i,
	rst_ni,
	req_i,
	branch_i,
	addr_i,
	ready_i,
	valid_o,
	rdata_o,
	addr_o,
	err_o,
	err_plus2_o,
	instr_req_o,
	instr_gnt_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	instr_rvalid_i,
	busy_o
);
	parameter [0:0] ResetAll = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire req_i;
	input wire branch_i;
	input wire [31:0] addr_i;
	input wire ready_i;
	output wire valid_o;
	output wire [31:0] rdata_o;
	output wire [31:0] addr_o;
	output wire err_o;
	output wire err_plus2_o;
	output wire instr_req_o;
	input wire instr_gnt_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire instr_err_i;
	input wire instr_rvalid_i;
	output wire busy_o;
	localparam [31:0] NUM_REQS = 2;
	wire valid_new_req;
	wire valid_req;
	wire valid_req_d;
	reg valid_req_q;
	wire discard_req_d;
	reg discard_req_q;
	wire [1:0] rdata_outstanding_n;
	wire [1:0] rdata_outstanding_s;
	reg [1:0] rdata_outstanding_q;
	wire [1:0] branch_discard_n;
	wire [1:0] branch_discard_s;
	reg [1:0] branch_discard_q;
	wire [1:0] rdata_outstanding_rev;
	wire [31:0] stored_addr_d;
	reg [31:0] stored_addr_q;
	wire stored_addr_en;
	wire [31:0] fetch_addr_d;
	reg [31:0] fetch_addr_q;
	wire fetch_addr_en;
	wire [31:0] instr_addr;
	wire [31:0] instr_addr_w_aligned;
	wire fifo_valid;
	wire [31:0] fifo_addr;
	wire fifo_ready;
	wire fifo_clear;
	wire [1:0] fifo_busy;
	assign busy_o = |rdata_outstanding_q | instr_req_o;
	assign fifo_clear = branch_i;
	genvar _gv_i_30;
	generate
		for (_gv_i_30 = 0; _gv_i_30 < NUM_REQS; _gv_i_30 = _gv_i_30 + 1) begin : gen_rd_rev
			localparam i = _gv_i_30;
			assign rdata_outstanding_rev[i] = rdata_outstanding_q[1 - i];
		end
	endgenerate
	assign fifo_ready = ~&(fifo_busy | rdata_outstanding_rev);
	ibex_fetch_fifo #(
		.NUM_REQS(NUM_REQS),
		.ResetAll(ResetAll)
	) fifo_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clear_i(fifo_clear),
		.busy_o(fifo_busy),
		.in_valid_i(fifo_valid),
		.in_addr_i(fifo_addr),
		.in_rdata_i(instr_rdata_i),
		.in_err_i(instr_err_i),
		.out_valid_o(valid_o),
		.out_ready_i(ready_i),
		.out_rdata_o(rdata_o),
		.out_addr_o(addr_o),
		.out_err_o(err_o),
		.out_err_plus2_o(err_plus2_o)
	);
	assign valid_new_req = (req_i & (fifo_ready | branch_i)) & ~rdata_outstanding_q[1];
	assign valid_req = valid_req_q | valid_new_req;
	assign valid_req_d = valid_req & ~instr_gnt_i;
	assign discard_req_d = valid_req_q & (branch_i | discard_req_q);
	assign stored_addr_en = (valid_new_req & ~valid_req_q) & ~instr_gnt_i;
	assign stored_addr_d = instr_addr;
	generate
		if (ResetAll) begin : g_stored_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					stored_addr_q <= 1'sb0;
				else if (stored_addr_en)
					stored_addr_q <= stored_addr_d;
		end
		else begin : g_stored_addr_nr
			always @(posedge clk_i)
				if (stored_addr_en)
					stored_addr_q <= stored_addr_d;
		end
	endgenerate
	assign fetch_addr_en = branch_i | (valid_new_req & ~valid_req_q);
	assign fetch_addr_d = (branch_i ? addr_i : {fetch_addr_q[31:2], 2'b00}) + {{29 {1'b0}}, valid_new_req & ~valid_req_q, 2'b00};
	generate
		if (ResetAll) begin : g_fetch_addr_ra
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					fetch_addr_q <= 1'sb0;
				else if (fetch_addr_en)
					fetch_addr_q <= fetch_addr_d;
		end
		else begin : g_fetch_addr_nr
			always @(posedge clk_i)
				if (fetch_addr_en)
					fetch_addr_q <= fetch_addr_d;
		end
	endgenerate
	assign instr_addr = (valid_req_q ? stored_addr_q : (branch_i ? addr_i : fetch_addr_q));
	assign instr_addr_w_aligned = {instr_addr[31:2], 2'b00};
	genvar _gv_i_31;
	generate
		for (_gv_i_31 = 0; _gv_i_31 < NUM_REQS; _gv_i_31 = _gv_i_31 + 1) begin : g_outstanding_reqs
			localparam i = _gv_i_31;
			if (i == 0) begin : g_req0
				assign rdata_outstanding_n[i] = (valid_req & instr_gnt_i) | rdata_outstanding_q[i];
				assign branch_discard_n[i] = (((valid_req & instr_gnt_i) & discard_req_d) | (branch_i & rdata_outstanding_q[i])) | branch_discard_q[i];
			end
			else begin : g_reqtop
				assign rdata_outstanding_n[i] = ((valid_req & instr_gnt_i) & rdata_outstanding_q[i - 1]) | rdata_outstanding_q[i];
				assign branch_discard_n[i] = ((((valid_req & instr_gnt_i) & discard_req_d) & rdata_outstanding_q[i - 1]) | (branch_i & rdata_outstanding_q[i])) | branch_discard_q[i];
			end
		end
	endgenerate
	assign rdata_outstanding_s = (instr_rvalid_i ? {1'b0, rdata_outstanding_n[1:1]} : rdata_outstanding_n);
	assign branch_discard_s = (instr_rvalid_i ? {1'b0, branch_discard_n[1:1]} : branch_discard_n);
	assign fifo_valid = instr_rvalid_i & ~branch_discard_q[0];
	assign fifo_addr = addr_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			valid_req_q <= 1'b0;
			discard_req_q <= 1'b0;
			rdata_outstanding_q <= 'b0;
			branch_discard_q <= 'b0;
		end
		else begin
			valid_req_q <= valid_req_d;
			discard_req_q <= discard_req_d;
			rdata_outstanding_q <= rdata_outstanding_s;
			branch_discard_q <= branch_discard_s;
		end
	assign instr_req_o = valid_req;
	assign instr_addr_o = instr_addr_w_aligned;
endmodule
module ibex_register_file_ff (
	clk_i,
	rst_ni,
	test_en_i,
	dummy_instr_id_i,
	dummy_instr_wb_i,
	raddr_a_i,
	rdata_a_o,
	raddr_b_i,
	rdata_b_o,
	waddr_a_i,
	wdata_a_i,
	we_a_i,
	err_o
);
	reg _sv2v_0;
	parameter [0:0] RV32E = 0;
	parameter [31:0] DataWidth = 32;
	parameter [0:0] DummyInstructions = 0;
	parameter [0:0] WrenCheck = 0;
	parameter [0:0] RdataMuxCheck = 0;
	parameter [DataWidth - 1:0] WordZeroVal = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	input wire dummy_instr_id_i;
	input wire dummy_instr_wb_i;
	input wire [4:0] raddr_a_i;
	output wire [DataWidth - 1:0] rdata_a_o;
	input wire [4:0] raddr_b_i;
	output wire [DataWidth - 1:0] rdata_b_o;
	input wire [4:0] waddr_a_i;
	input wire [DataWidth - 1:0] wdata_a_i;
	input wire we_a_i;
	output wire err_o;
	localparam [31:0] ADDR_WIDTH = (RV32E ? 4 : 5);
	localparam [31:0] NUM_WORDS = 2 ** ADDR_WIDTH;
	wire [(NUM_WORDS * DataWidth) - 1:0] rf_reg;
	reg [NUM_WORDS - 1:0] we_a_dec;
	wire oh_raddr_a_err;
	wire oh_raddr_b_err;
	wire oh_we_err;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(*) begin : we_a_decoder
		if (_sv2v_0)
			;
		begin : sv2v_autoblock_1
			reg [31:0] i;
			for (i = 0; i < NUM_WORDS; i = i + 1)
				we_a_dec[i] = (waddr_a_i == sv2v_cast_5(i) ? we_a_i : 1'b0);
		end
	end
	generate
		if (WrenCheck) begin : gen_wren_check
			wire [NUM_WORDS - 1:0] we_a_dec_buf;
			prim_buf #(.Width(NUM_WORDS)) u_prim_buf(
				.in_i(we_a_dec),
				.out_o(we_a_dec_buf)
			);
			prim_onehot_check #(
				.AddrWidth(ADDR_WIDTH),
				.AddrCheck(1),
				.EnableCheck(1)
			) u_prim_onehot_check(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.oh_i(we_a_dec_buf),
				.addr_i(waddr_a_i),
				.en_i(we_a_i),
				.err_o(oh_we_err)
			);
		end
		else begin : gen_no_wren_check
			wire unused_strobe;
			assign unused_strobe = we_a_dec[0];
			assign oh_we_err = 1'b0;
		end
	endgenerate
	genvar _gv_i_32;
	generate
		for (_gv_i_32 = 1; _gv_i_32 < NUM_WORDS; _gv_i_32 = _gv_i_32 + 1) begin : g_rf_flops
			localparam i = _gv_i_32;
			reg [DataWidth - 1:0] rf_reg_q;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					rf_reg_q <= WordZeroVal;
				else if (we_a_dec[i])
					rf_reg_q <= wdata_a_i;
			assign rf_reg[((NUM_WORDS - 1) - i) * DataWidth+:DataWidth] = rf_reg_q;
		end
		if (DummyInstructions) begin : g_dummy_r0
			wire we_r0_dummy;
			reg [DataWidth - 1:0] rf_r0_q;
			assign we_r0_dummy = we_a_i & dummy_instr_wb_i;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					rf_r0_q <= WordZeroVal;
				else if (we_r0_dummy)
					rf_r0_q <= wdata_a_i;
			assign rf_reg[(NUM_WORDS - 1) * DataWidth+:DataWidth] = (dummy_instr_id_i ? rf_r0_q : WordZeroVal);
		end
		else begin : g_normal_r0
			wire unused_dummy_instr;
			assign unused_dummy_instr = dummy_instr_id_i ^ dummy_instr_wb_i;
			assign rf_reg[(NUM_WORDS - 1) * DataWidth+:DataWidth] = WordZeroVal;
		end
		if (RdataMuxCheck) begin : gen_rdata_mux_check
			wire [NUM_WORDS - 1:0] raddr_onehot_a;
			wire [NUM_WORDS - 1:0] raddr_onehot_b;
			wire [NUM_WORDS - 1:0] raddr_onehot_a_buf;
			wire [NUM_WORDS - 1:0] raddr_onehot_b_buf;
			prim_onehot_enc #(.OneHotWidth(NUM_WORDS)) u_prim_onehot_enc_raddr_a(
				.in_i(raddr_a_i),
				.en_i(1'b1),
				.out_o(raddr_onehot_a)
			);
			prim_onehot_enc #(.OneHotWidth(NUM_WORDS)) u_prim_onehot_enc_raddr_b(
				.in_i(raddr_b_i),
				.en_i(1'b1),
				.out_o(raddr_onehot_b)
			);
			prim_buf #(.Width(NUM_WORDS)) u_prim_buf_raddr_a(
				.in_i(raddr_onehot_a),
				.out_o(raddr_onehot_a_buf)
			);
			prim_buf #(.Width(NUM_WORDS)) u_prim_buf_raddr_b(
				.in_i(raddr_onehot_b),
				.out_o(raddr_onehot_b_buf)
			);
			prim_onehot_check #(
				.AddrWidth(ADDR_WIDTH),
				.OneHotWidth(NUM_WORDS),
				.AddrCheck(1),
				.EnableCheck(1)
			) u_prim_onehot_check_raddr_a(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.oh_i(raddr_onehot_a_buf),
				.addr_i(raddr_a_i),
				.en_i(1'b1),
				.err_o(oh_raddr_a_err)
			);
			prim_onehot_check #(
				.AddrWidth(ADDR_WIDTH),
				.OneHotWidth(NUM_WORDS),
				.AddrCheck(1),
				.EnableCheck(1)
			) u_prim_onehot_check_raddr_b(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.oh_i(raddr_onehot_b_buf),
				.addr_i(raddr_b_i),
				.en_i(1'b1),
				.err_o(oh_raddr_b_err)
			);
			prim_onehot_mux #(
				.Width(DataWidth),
				.Inputs(NUM_WORDS)
			) u_rdata_a_mux(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.in_i(rf_reg),
				.sel_i(raddr_onehot_a),
				.out_o(rdata_a_o)
			);
			prim_onehot_mux #(
				.Width(DataWidth),
				.Inputs(NUM_WORDS)
			) u_rdata_b_mux(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.in_i(rf_reg),
				.sel_i(raddr_onehot_b),
				.out_o(rdata_b_o)
			);
		end
		else begin : gen_no_rdata_mux_check
			assign rdata_a_o = rf_reg[((NUM_WORDS - 1) - raddr_a_i) * DataWidth+:DataWidth];
			assign rdata_b_o = rf_reg[((NUM_WORDS - 1) - raddr_b_i) * DataWidth+:DataWidth];
			assign oh_raddr_a_err = 1'b0;
			assign oh_raddr_b_err = 1'b0;
		end
	endgenerate
	assign err_o = (oh_raddr_a_err || oh_raddr_b_err) || oh_we_err;
	wire unused_test_en;
	assign unused_test_en = test_en_i;
	initial _sv2v_0 = 0;
endmodule
module ibex_wb_stage (
	clk_i,
	rst_ni,
	en_wb_i,
	instr_type_wb_i,
	pc_id_i,
	instr_is_compressed_id_i,
	instr_perf_count_id_i,
	ready_wb_o,
	rf_write_wb_o,
	outstanding_load_wb_o,
	outstanding_store_wb_o,
	pc_wb_o,
	perf_instr_ret_wb_o,
	perf_instr_ret_compressed_wb_o,
	perf_instr_ret_wb_spec_o,
	perf_instr_ret_compressed_wb_spec_o,
	rf_waddr_id_i,
	rf_wdata_id_i,
	rf_we_id_i,
	dummy_instr_id_i,
	rf_wdata_lsu_i,
	rf_we_lsu_i,
	rf_wdata_fwd_wb_o,
	rf_waddr_wb_o,
	rf_wdata_wb_o,
	rf_we_wb_o,
	dummy_instr_wb_o,
	lsu_resp_valid_i,
	lsu_resp_err_i,
	instr_done_wb_o
);
	parameter [0:0] ResetAll = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	input wire clk_i;
	input wire rst_ni;
	input wire en_wb_i;
	input wire [1:0] instr_type_wb_i;
	input wire [31:0] pc_id_i;
	input wire instr_is_compressed_id_i;
	input wire instr_perf_count_id_i;
	output wire ready_wb_o;
	output wire rf_write_wb_o;
	output wire outstanding_load_wb_o;
	output wire outstanding_store_wb_o;
	output wire [31:0] pc_wb_o;
	output wire perf_instr_ret_wb_o;
	output wire perf_instr_ret_compressed_wb_o;
	output wire perf_instr_ret_wb_spec_o;
	output wire perf_instr_ret_compressed_wb_spec_o;
	input wire [4:0] rf_waddr_id_i;
	input wire [31:0] rf_wdata_id_i;
	input wire rf_we_id_i;
	input wire dummy_instr_id_i;
	input wire [31:0] rf_wdata_lsu_i;
	input wire rf_we_lsu_i;
	output wire [31:0] rf_wdata_fwd_wb_o;
	output wire [4:0] rf_waddr_wb_o;
	output wire [31:0] rf_wdata_wb_o;
	output wire rf_we_wb_o;
	output wire dummy_instr_wb_o;
	input wire lsu_resp_valid_i;
	input wire lsu_resp_err_i;
	output wire instr_done_wb_o;
	wire [31:0] rf_wdata_wb_mux [0:1];
	wire [1:0] rf_wdata_wb_mux_we;
	generate
		if (WritebackStage) begin : g_writeback_stage
			reg [31:0] rf_wdata_wb_q;
			reg rf_we_wb_q;
			reg [4:0] rf_waddr_wb_q;
			wire wb_done;
			reg wb_valid_q;
			reg [31:0] wb_pc_q;
			reg wb_compressed_q;
			reg wb_count_q;
			reg [1:0] wb_instr_type_q;
			wire wb_valid_d;
			assign wb_valid_d = (en_wb_i & ready_wb_o) | (wb_valid_q & ~wb_done);
			assign wb_done = (wb_instr_type_q == 2'd2) | lsu_resp_valid_i;
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					wb_valid_q <= 1'b0;
				else
					wb_valid_q <= wb_valid_d;
			if (ResetAll) begin : g_wb_regs_ra
				always @(posedge clk_i or negedge rst_ni)
					if (!rst_ni) begin
						rf_we_wb_q <= 1'sb0;
						rf_waddr_wb_q <= 1'sb0;
						rf_wdata_wb_q <= 1'sb0;
						wb_instr_type_q <= 2'd0;
						wb_pc_q <= 1'sb0;
						wb_compressed_q <= 1'sb0;
						wb_count_q <= 1'sb0;
					end
					else if (en_wb_i) begin
						rf_we_wb_q <= rf_we_id_i;
						rf_waddr_wb_q <= rf_waddr_id_i;
						rf_wdata_wb_q <= rf_wdata_id_i;
						wb_instr_type_q <= instr_type_wb_i;
						wb_pc_q <= pc_id_i;
						wb_compressed_q <= instr_is_compressed_id_i;
						wb_count_q <= instr_perf_count_id_i;
					end
			end
			else begin : g_wb_regs_nr
				always @(posedge clk_i)
					if (en_wb_i) begin
						rf_we_wb_q <= rf_we_id_i;
						rf_waddr_wb_q <= rf_waddr_id_i;
						rf_wdata_wb_q <= rf_wdata_id_i;
						wb_instr_type_q <= instr_type_wb_i;
						wb_pc_q <= pc_id_i;
						wb_compressed_q <= instr_is_compressed_id_i;
						wb_count_q <= instr_perf_count_id_i;
					end
			end
			assign rf_waddr_wb_o = rf_waddr_wb_q;
			assign rf_wdata_wb_mux[0] = rf_wdata_wb_q;
			assign rf_wdata_wb_mux_we[0] = rf_we_wb_q & wb_valid_q;
			assign ready_wb_o = ~wb_valid_q | wb_done;
			assign rf_write_wb_o = wb_valid_q & (rf_we_wb_q | (wb_instr_type_q == 2'd0));
			assign outstanding_load_wb_o = wb_valid_q & (wb_instr_type_q == 2'd0);
			assign outstanding_store_wb_o = wb_valid_q & (wb_instr_type_q == 2'd1);
			assign pc_wb_o = wb_pc_q;
			assign instr_done_wb_o = wb_valid_q & wb_done;
			assign perf_instr_ret_wb_spec_o = wb_count_q;
			assign perf_instr_ret_compressed_wb_spec_o = perf_instr_ret_wb_spec_o & wb_compressed_q;
			assign perf_instr_ret_wb_o = (instr_done_wb_o & wb_count_q) & ~(lsu_resp_valid_i & lsu_resp_err_i);
			assign perf_instr_ret_compressed_wb_o = perf_instr_ret_wb_o & wb_compressed_q;
			assign rf_wdata_fwd_wb_o = rf_wdata_wb_q;
			assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
			if (DummyInstructions) begin : g_dummy_instr_wb
				reg dummy_instr_wb_q;
				if (ResetAll) begin : g_dummy_instr_wb_regs_ra
					always @(posedge clk_i or negedge rst_ni)
						if (!rst_ni)
							dummy_instr_wb_q <= 1'b0;
						else if (en_wb_i)
							dummy_instr_wb_q <= dummy_instr_id_i;
				end
				else begin : g_dummy_instr_wb_regs_nr
					always @(posedge clk_i)
						if (en_wb_i)
							dummy_instr_wb_q <= dummy_instr_id_i;
				end
				assign dummy_instr_wb_o = dummy_instr_wb_q;
			end
			else begin : g_no_dummy_instr_wb
				wire unused_dummy_instr_id;
				assign unused_dummy_instr_id = dummy_instr_id_i;
				assign dummy_instr_wb_o = 1'b0;
			end
		end
		else begin : g_bypass_wb
			assign rf_waddr_wb_o = rf_waddr_id_i;
			assign rf_wdata_wb_mux[0] = rf_wdata_id_i;
			assign rf_wdata_wb_mux_we[0] = rf_we_id_i;
			assign rf_wdata_wb_mux_we[1] = rf_we_lsu_i;
			assign dummy_instr_wb_o = dummy_instr_id_i;
			assign perf_instr_ret_wb_spec_o = 1'b0;
			assign perf_instr_ret_compressed_wb_spec_o = 1'b0;
			assign perf_instr_ret_wb_o = (instr_perf_count_id_i & en_wb_i) & ~(lsu_resp_valid_i & lsu_resp_err_i);
			assign perf_instr_ret_compressed_wb_o = perf_instr_ret_wb_o & instr_is_compressed_id_i;
			assign ready_wb_o = 1'b1;
			wire unused_clk;
			wire unused_rst;
			wire [1:0] unused_instr_type_wb;
			wire [31:0] unused_pc_id;
			wire unused_dummy_instr_id;
			assign unused_clk = clk_i;
			assign unused_rst = rst_ni;
			assign unused_instr_type_wb = instr_type_wb_i;
			assign unused_pc_id = pc_id_i;
			assign unused_dummy_instr_id = dummy_instr_id_i;
			assign outstanding_load_wb_o = 1'b0;
			assign outstanding_store_wb_o = 1'b0;
			assign pc_wb_o = 1'sb0;
			assign rf_write_wb_o = 1'b0;
			assign rf_wdata_fwd_wb_o = 32'b00000000000000000000000000000000;
			assign instr_done_wb_o = 1'b0;
		end
	endgenerate
	assign rf_wdata_wb_mux[1] = rf_wdata_lsu_i;
	assign rf_wdata_wb_o = ({32 {rf_wdata_wb_mux_we[0]}} & rf_wdata_wb_mux[0]) | ({32 {rf_wdata_wb_mux_we[1]}} & rf_wdata_wb_mux[1]);
	assign rf_we_wb_o = |rf_wdata_wb_mux_we;
endmodule
module ibex_core (
	clk_i,
	rst_ni,
	hart_id_i,
	boot_addr_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	instr_err_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_rdata_i,
	data_err_i,
	dummy_instr_id_o,
	dummy_instr_wb_o,
	rf_raddr_a_o,
	rf_raddr_b_o,
	rf_waddr_wb_o,
	rf_we_wb_o,
	rf_wdata_wb_ecc_o,
	rf_rdata_a_ecc_i,
	rf_rdata_b_ecc_i,
	ic_tag_req_o,
	ic_tag_write_o,
	ic_tag_addr_o,
	ic_tag_wdata_o,
	ic_tag_rdata_i,
	ic_data_req_o,
	ic_data_write_o,
	ic_data_addr_o,
	ic_data_wdata_o,
	ic_data_rdata_i,
	ic_scr_key_valid_i,
	ic_scr_key_req_o,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	irq_pending_o,
	debug_req_i,
	crash_dump_o,
	double_fault_seen_o,
	fetch_enable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_busy_o
);
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	parameter [31:0] BusSizeECC = ibex_pkg_BUS_SIZE;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	parameter [31:0] TagSizeECC = ibex_pkg_IC_TAG_SIZE;
	parameter [31:0] LineSizeECC = ibex_pkg_IC_LINE_SIZE;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] ResetAll = 1'b0;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [0:0] DummyInstructions = 1'b0;
	parameter [0:0] RegFileECC = 1'b0;
	parameter [31:0] RegFileDataWidth = 32;
	parameter [0:0] MemECC = 1'b0;
	parameter [31:0] MemDataWidth = (MemECC ? 39 : 32);
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	input wire clk_i;
	input wire rst_ni;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [MemDataWidth - 1:0] instr_rdata_i;
	input wire instr_err_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [MemDataWidth - 1:0] data_wdata_o;
	input wire [MemDataWidth - 1:0] data_rdata_i;
	input wire data_err_i;
	output wire dummy_instr_id_o;
	output wire dummy_instr_wb_o;
	output wire [4:0] rf_raddr_a_o;
	output wire [4:0] rf_raddr_b_o;
	output wire [4:0] rf_waddr_wb_o;
	output wire rf_we_wb_o;
	output wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc_o;
	input wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_i;
	input wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_i;
	output wire [1:0] ic_tag_req_o;
	output wire ic_tag_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_o;
	output wire [TagSizeECC - 1:0] ic_tag_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_i;
	output wire [1:0] ic_data_req_o;
	output wire ic_data_write_o;
	output wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_o;
	output wire [LineSizeECC - 1:0] ic_data_wdata_o;
	input wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_i;
	input wire ic_scr_key_valid_i;
	output wire ic_scr_key_req_o;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	output wire irq_pending_o;
	input wire debug_req_i;
	output wire [159:0] crash_dump_o;
	output wire double_fault_seen_o;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] fetch_enable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	output wire [3:0] core_busy_o;
	localparam [31:0] PMPNumChan = 3;
	localparam [0:0] DataIndTiming = SecureIbex;
	localparam [0:0] PCIncrCheck = SecureIbex;
	localparam [0:0] ShadowCSR = 1'b0;
	wire dummy_instr_id;
	wire instr_valid_id;
	wire instr_new_id;
	wire [31:0] instr_rdata_id;
	wire [31:0] instr_rdata_alu_id;
	wire [15:0] instr_rdata_c_id;
	wire instr_is_compressed_id;
	wire instr_perf_count_id;
	wire instr_bp_taken_id;
	wire instr_fetch_err;
	wire instr_fetch_err_plus2;
	wire illegal_c_insn_id;
	wire [31:0] pc_if;
	wire [31:0] pc_id;
	wire [31:0] pc_wb;
	wire [67:0] imd_val_d_ex;
	wire [67:0] imd_val_q_ex;
	wire [1:0] imd_val_we_ex;
	wire data_ind_timing;
	wire dummy_instr_en;
	wire [2:0] dummy_instr_mask;
	wire dummy_instr_seed_en;
	wire [31:0] dummy_instr_seed;
	wire icache_enable;
	wire icache_inval;
	wire icache_ecc_error;
	wire pc_mismatch_alert;
	wire csr_shadow_err;
	wire instr_first_cycle_id;
	wire instr_valid_clear;
	wire pc_set;
	wire nt_branch_mispredict;
	wire [31:0] nt_branch_addr;
	wire [2:0] pc_mux_id;
	wire [1:0] exc_pc_mux_id;
	wire [6:0] exc_cause;
	wire instr_intg_err;
	wire lsu_load_err;
	wire lsu_load_err_raw;
	wire lsu_store_err;
	wire lsu_store_err_raw;
	wire lsu_load_resp_intg_err;
	wire lsu_store_resp_intg_err;
	wire expecting_load_resp_id;
	wire expecting_store_resp_id;
	wire lsu_addr_incr_req;
	wire [31:0] lsu_addr_last;
	wire [31:0] branch_target_ex;
	wire branch_decision;
	wire ctrl_busy;
	wire if_busy;
	wire lsu_busy;
	wire [4:0] rf_raddr_a;
	wire [31:0] rf_rdata_a;
	wire [4:0] rf_raddr_b;
	wire [31:0] rf_rdata_b;
	wire rf_ren_a;
	wire rf_ren_b;
	wire [4:0] rf_waddr_wb;
	wire [31:0] rf_wdata_wb;
	wire [31:0] rf_wdata_fwd_wb;
	wire [31:0] rf_wdata_lsu;
	wire rf_we_wb;
	wire rf_we_lsu;
	wire rf_ecc_err_comb;
	wire [4:0] rf_waddr_id;
	wire [31:0] rf_wdata_id;
	wire rf_we_id;
	wire rf_rd_a_wb_match;
	wire rf_rd_b_wb_match;
	wire [6:0] alu_operator_ex;
	wire [31:0] alu_operand_a_ex;
	wire [31:0] alu_operand_b_ex;
	wire [31:0] bt_a_operand;
	wire [31:0] bt_b_operand;
	wire [31:0] alu_adder_result_ex;
	wire [31:0] result_ex;
	wire mult_en_ex;
	wire div_en_ex;
	wire mult_sel_ex;
	wire div_sel_ex;
	wire [1:0] multdiv_operator_ex;
	wire [1:0] multdiv_signed_mode_ex;
	wire [31:0] multdiv_operand_a_ex;
	wire [31:0] multdiv_operand_b_ex;
	wire multdiv_ready_id;
	wire csr_access;
	wire [1:0] csr_op;
	wire csr_op_en;
	wire [11:0] csr_addr;
	wire [31:0] csr_rdata;
	wire [31:0] csr_wdata;
	wire illegal_csr_insn_id;
	wire lsu_we;
	wire [1:0] lsu_type;
	wire lsu_sign_ext;
	wire lsu_req;
	wire lsu_rdata_valid;
	wire [31:0] lsu_wdata;
	wire lsu_req_done;
	wire id_in_ready;
	wire ex_valid;
	wire lsu_resp_valid;
	wire lsu_resp_err;
	wire instr_req_int;
	wire instr_req_gated;
	wire instr_exec;
	wire en_wb;
	wire [1:0] instr_type_wb;
	wire ready_wb;
	wire rf_write_wb;
	wire outstanding_load_wb;
	wire outstanding_store_wb;
	wire dummy_instr_wb;
	wire nmi_mode;
	wire [17:0] irqs;
	wire csr_mstatus_mie;
	wire [31:0] csr_mepc;
	wire [31:0] csr_depc;
	wire [(PMPNumRegions * 34) - 1:0] csr_pmp_addr;
	wire [(PMPNumRegions * 6) - 1:0] csr_pmp_cfg;
	wire [2:0] csr_pmp_mseccfg;
	wire [0:2] pmp_req_err;
	wire data_req_out;
	wire csr_save_if;
	wire csr_save_id;
	wire csr_save_wb;
	wire csr_restore_mret_id;
	wire csr_restore_dret_id;
	wire csr_save_cause;
	wire csr_mtvec_init;
	wire [31:0] csr_mtvec;
	wire [31:0] csr_mtval;
	wire csr_mstatus_tw;
	wire [1:0] priv_mode_id;
	wire [1:0] priv_mode_lsu;
	wire debug_mode;
	wire debug_mode_entering;
	wire [2:0] debug_cause;
	wire debug_csr_save;
	wire debug_single_step;
	wire debug_ebreakm;
	wire debug_ebreaku;
	wire trigger_match;
	wire instr_id_done;
	wire instr_done_wb;
	wire perf_instr_ret_wb;
	wire perf_instr_ret_compressed_wb;
	wire perf_instr_ret_wb_spec;
	wire perf_instr_ret_compressed_wb_spec;
	wire perf_iside_wait;
	wire perf_dside_wait;
	wire perf_mul_wait;
	wire perf_div_wait;
	wire perf_jump;
	wire perf_branch;
	wire perf_tbranch;
	wire perf_load;
	wire perf_store;
	wire illegal_insn_id;
	wire unused_illegal_insn_id;
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	localparam [3:0] ibex_pkg_IbexMuBiOn = 4'b0101;
	generate
		if (SecureIbex) begin : g_core_busy_secure
			localparam [31:0] NumBusySignals = 3;
			localparam [31:0] NumBusyBits = ibex_pkg_IbexMuBiWidth * NumBusySignals;
			wire [NumBusyBits - 1:0] busy_bits_buf;
			prim_buf #(.Width(NumBusyBits)) u_fetch_enable_buf(
				.in_i({ibex_pkg_IbexMuBiWidth {ctrl_busy, if_busy, lsu_busy}}),
				.out_o(busy_bits_buf)
			);
			genvar _gv_i_33;
			for (_gv_i_33 = 0; _gv_i_33 < ibex_pkg_IbexMuBiWidth; _gv_i_33 = _gv_i_33 + 1) begin : g_core_busy_bits
				localparam i = _gv_i_33;
				if (ibex_pkg_IbexMuBiOn[i] == 1'b1) begin : g_pos
					assign core_busy_o[i] = |busy_bits_buf[i * NumBusySignals+:NumBusySignals];
				end
				else begin : g_neg
					assign core_busy_o[i] = ~|busy_bits_buf[i * NumBusySignals+:NumBusySignals];
				end
			end
		end
		else begin : g_core_busy_non_secure
			assign core_busy_o = ((ctrl_busy || if_busy) || lsu_busy ? ibex_pkg_IbexMuBiOn : ibex_pkg_IbexMuBiOff);
		end
	endgenerate
	localparam [31:0] ibex_pkg_PMP_I = 0;
	localparam [31:0] ibex_pkg_PMP_I2 = 1;
	ibex_if_stage #(
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr),
		.DummyInstructions(DummyInstructions),
		.ICache(ICache),
		.ICacheECC(ICacheECC),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.PCIncrCheck(PCIncrCheck),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth)
	) if_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.boot_addr_i(boot_addr_i),
		.req_i(instr_req_gated),
		.instr_req_o(instr_req_o),
		.instr_addr_o(instr_addr_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_rdata_i(instr_rdata_i),
		.instr_bus_err_i(instr_err_i),
		.instr_intg_err_o(instr_intg_err),
		.ic_tag_req_o(ic_tag_req_o),
		.ic_tag_write_o(ic_tag_write_o),
		.ic_tag_addr_o(ic_tag_addr_o),
		.ic_tag_wdata_o(ic_tag_wdata_o),
		.ic_tag_rdata_i(ic_tag_rdata_i),
		.ic_data_req_o(ic_data_req_o),
		.ic_data_write_o(ic_data_write_o),
		.ic_data_addr_o(ic_data_addr_o),
		.ic_data_wdata_o(ic_data_wdata_o),
		.ic_data_rdata_i(ic_data_rdata_i),
		.ic_scr_key_valid_i(ic_scr_key_valid_i),
		.ic_scr_key_req_o(ic_scr_key_req_o),
		.instr_valid_id_o(instr_valid_id),
		.instr_new_id_o(instr_new_id),
		.instr_rdata_id_o(instr_rdata_id),
		.instr_rdata_alu_id_o(instr_rdata_alu_id),
		.instr_rdata_c_id_o(instr_rdata_c_id),
		.instr_is_compressed_id_o(instr_is_compressed_id),
		.instr_bp_taken_o(instr_bp_taken_id),
		.instr_fetch_err_o(instr_fetch_err),
		.instr_fetch_err_plus2_o(instr_fetch_err_plus2),
		.illegal_c_insn_id_o(illegal_c_insn_id),
		.dummy_instr_id_o(dummy_instr_id),
		.pc_if_o(pc_if),
		.pc_id_o(pc_id),
		.pmp_err_if_i(pmp_req_err[ibex_pkg_PMP_I]),
		.pmp_err_if_plus2_i(pmp_req_err[ibex_pkg_PMP_I2]),
		.instr_valid_clear_i(instr_valid_clear),
		.pc_set_i(pc_set),
		.pc_mux_i(pc_mux_id),
		.nt_branch_mispredict_i(nt_branch_mispredict),
		.exc_pc_mux_i(exc_pc_mux_id),
		.exc_cause(exc_cause),
		.dummy_instr_en_i(dummy_instr_en),
		.dummy_instr_mask_i(dummy_instr_mask),
		.dummy_instr_seed_en_i(dummy_instr_seed_en),
		.dummy_instr_seed_i(dummy_instr_seed),
		.icache_enable_i(icache_enable),
		.icache_inval_i(icache_inval),
		.icache_ecc_error_o(icache_ecc_error),
		.branch_target_ex_i(branch_target_ex),
		.nt_branch_addr_i(nt_branch_addr),
		.csr_mepc_i(csr_mepc),
		.csr_depc_i(csr_depc),
		.csr_mtvec_i(csr_mtvec),
		.csr_mtvec_init_o(csr_mtvec_init),
		.id_in_ready_i(id_in_ready),
		.pc_mismatch_alert_o(pc_mismatch_alert),
		.if_busy_o(if_busy)
	);
	assign perf_iside_wait = id_in_ready & ~instr_valid_id;
	generate
		if (SecureIbex) begin : g_instr_req_gated_secure
			assign instr_req_gated = instr_req_int & (fetch_enable_i == ibex_pkg_IbexMuBiOn);
			assign instr_exec = fetch_enable_i == ibex_pkg_IbexMuBiOn;
		end
		else begin : g_instr_req_gated_non_secure
			wire unused_fetch_enable;
			assign unused_fetch_enable = ^fetch_enable_i[3:1];
			assign instr_req_gated = instr_req_int & fetch_enable_i[0];
			assign instr_exec = fetch_enable_i[0];
		end
	endgenerate
	ibex_id_stage #(
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU),
		.DataIndTiming(DataIndTiming),
		.WritebackStage(WritebackStage),
		.BranchPredictor(BranchPredictor),
		.MemECC(MemECC)
	) id_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.ctrl_busy_o(ctrl_busy),
		.illegal_insn_o(illegal_insn_id),
		.instr_valid_i(instr_valid_id),
		.instr_rdata_i(instr_rdata_id),
		.instr_rdata_alu_i(instr_rdata_alu_id),
		.instr_rdata_c_i(instr_rdata_c_id),
		.instr_is_compressed_i(instr_is_compressed_id),
		.instr_bp_taken_i(instr_bp_taken_id),
		.branch_decision_i(branch_decision),
		.instr_first_cycle_id_o(instr_first_cycle_id),
		.instr_valid_clear_o(instr_valid_clear),
		.id_in_ready_o(id_in_ready),
		.instr_exec_i(instr_exec),
		.instr_req_o(instr_req_int),
		.pc_set_o(pc_set),
		.pc_mux_o(pc_mux_id),
		.nt_branch_mispredict_o(nt_branch_mispredict),
		.nt_branch_addr_o(nt_branch_addr),
		.exc_pc_mux_o(exc_pc_mux_id),
		.exc_cause_o(exc_cause),
		.icache_inval_o(icache_inval),
		.instr_fetch_err_i(instr_fetch_err),
		.instr_fetch_err_plus2_i(instr_fetch_err_plus2),
		.illegal_c_insn_i(illegal_c_insn_id),
		.pc_id_i(pc_id),
		.ex_valid_i(ex_valid),
		.lsu_resp_valid_i(lsu_resp_valid),
		.alu_operator_ex_o(alu_operator_ex),
		.alu_operand_a_ex_o(alu_operand_a_ex),
		.alu_operand_b_ex_o(alu_operand_b_ex),
		.imd_val_q_ex_o(imd_val_q_ex),
		.imd_val_d_ex_i(imd_val_d_ex),
		.imd_val_we_ex_i(imd_val_we_ex),
		.bt_a_operand_o(bt_a_operand),
		.bt_b_operand_o(bt_b_operand),
		.mult_en_ex_o(mult_en_ex),
		.div_en_ex_o(div_en_ex),
		.mult_sel_ex_o(mult_sel_ex),
		.div_sel_ex_o(div_sel_ex),
		.multdiv_operator_ex_o(multdiv_operator_ex),
		.multdiv_signed_mode_ex_o(multdiv_signed_mode_ex),
		.multdiv_operand_a_ex_o(multdiv_operand_a_ex),
		.multdiv_operand_b_ex_o(multdiv_operand_b_ex),
		.multdiv_ready_id_o(multdiv_ready_id),
		.csr_access_o(csr_access),
		.csr_op_o(csr_op),
		.csr_addr_o(csr_addr),
		.csr_op_en_o(csr_op_en),
		.csr_save_if_o(csr_save_if),
		.csr_save_id_o(csr_save_id),
		.csr_save_wb_o(csr_save_wb),
		.csr_restore_mret_id_o(csr_restore_mret_id),
		.csr_restore_dret_id_o(csr_restore_dret_id),
		.csr_save_cause_o(csr_save_cause),
		.csr_mtval_o(csr_mtval),
		.priv_mode_i(priv_mode_id),
		.csr_mstatus_tw_i(csr_mstatus_tw),
		.illegal_csr_insn_i(illegal_csr_insn_id),
		.data_ind_timing_i(data_ind_timing),
		.lsu_req_o(lsu_req),
		.lsu_we_o(lsu_we),
		.lsu_type_o(lsu_type),
		.lsu_sign_ext_o(lsu_sign_ext),
		.lsu_wdata_o(lsu_wdata),
		.lsu_req_done_i(lsu_req_done),
		.lsu_addr_incr_req_i(lsu_addr_incr_req),
		.lsu_addr_last_i(lsu_addr_last),
		.lsu_load_err_i(lsu_load_err),
		.lsu_load_resp_intg_err_i(lsu_load_resp_intg_err),
		.lsu_store_err_i(lsu_store_err),
		.lsu_store_resp_intg_err_i(lsu_store_resp_intg_err),
		.expecting_load_resp_o(expecting_load_resp_id),
		.expecting_store_resp_o(expecting_store_resp_id),
		.csr_mstatus_mie_i(csr_mstatus_mie),
		.irq_pending_i(irq_pending_o),
		.irqs_i(irqs),
		.irq_nm_i(irq_nm_i),
		.nmi_mode_o(nmi_mode),
		.debug_mode_o(debug_mode),
		.debug_mode_entering_o(debug_mode_entering),
		.debug_cause_o(debug_cause),
		.debug_csr_save_o(debug_csr_save),
		.debug_req_i(debug_req_i),
		.debug_single_step_i(debug_single_step),
		.debug_ebreakm_i(debug_ebreakm),
		.debug_ebreaku_i(debug_ebreaku),
		.trigger_match_i(trigger_match),
		.result_ex_i(result_ex),
		.csr_rdata_i(csr_rdata),
		.rf_raddr_a_o(rf_raddr_a),
		.rf_rdata_a_i(rf_rdata_a),
		.rf_raddr_b_o(rf_raddr_b),
		.rf_rdata_b_i(rf_rdata_b),
		.rf_ren_a_o(rf_ren_a),
		.rf_ren_b_o(rf_ren_b),
		.rf_waddr_id_o(rf_waddr_id),
		.rf_wdata_id_o(rf_wdata_id),
		.rf_we_id_o(rf_we_id),
		.rf_rd_a_wb_match_o(rf_rd_a_wb_match),
		.rf_rd_b_wb_match_o(rf_rd_b_wb_match),
		.rf_waddr_wb_i(rf_waddr_wb),
		.rf_wdata_fwd_wb_i(rf_wdata_fwd_wb),
		.rf_write_wb_i(rf_write_wb),
		.en_wb_o(en_wb),
		.instr_type_wb_o(instr_type_wb),
		.instr_perf_count_id_o(instr_perf_count_id),
		.ready_wb_i(ready_wb),
		.outstanding_load_wb_i(outstanding_load_wb),
		.outstanding_store_wb_i(outstanding_store_wb),
		.perf_jump_o(perf_jump),
		.perf_branch_o(perf_branch),
		.perf_tbranch_o(perf_tbranch),
		.perf_dside_wait_o(perf_dside_wait),
		.perf_mul_wait_o(perf_mul_wait),
		.perf_div_wait_o(perf_div_wait),
		.instr_id_done_o(instr_id_done)
	);
	assign unused_illegal_insn_id = illegal_insn_id;
	ibex_ex_block #(
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU)
	) ex_block_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.alu_operator_i(alu_operator_ex),
		.alu_operand_a_i(alu_operand_a_ex),
		.alu_operand_b_i(alu_operand_b_ex),
		.alu_instr_first_cycle_i(instr_first_cycle_id),
		.bt_a_operand_i(bt_a_operand),
		.bt_b_operand_i(bt_b_operand),
		.multdiv_operator_i(multdiv_operator_ex),
		.mult_en_i(mult_en_ex),
		.div_en_i(div_en_ex),
		.mult_sel_i(mult_sel_ex),
		.div_sel_i(div_sel_ex),
		.multdiv_signed_mode_i(multdiv_signed_mode_ex),
		.multdiv_operand_a_i(multdiv_operand_a_ex),
		.multdiv_operand_b_i(multdiv_operand_b_ex),
		.multdiv_ready_id_i(multdiv_ready_id),
		.data_ind_timing_i(data_ind_timing),
		.imd_val_we_o(imd_val_we_ex),
		.imd_val_d_o(imd_val_d_ex),
		.imd_val_q_i(imd_val_q_ex),
		.alu_adder_result_ex_o(alu_adder_result_ex),
		.result_ex_o(result_ex),
		.branch_target_o(branch_target_ex),
		.branch_decision_o(branch_decision),
		.ex_valid_o(ex_valid)
	);
	localparam [31:0] ibex_pkg_PMP_D = 2;
	assign data_req_o = data_req_out & ~pmp_req_err[ibex_pkg_PMP_D];
	assign lsu_resp_err = lsu_load_err | lsu_store_err;
	ibex_load_store_unit #(
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth)
	) load_store_unit_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.data_req_o(data_req_out),
		.data_gnt_i(data_gnt_i),
		.data_rvalid_i(data_rvalid_i),
		.data_bus_err_i(data_err_i),
		.data_pmp_err_i(pmp_req_err[ibex_pkg_PMP_D]),
		.data_addr_o(data_addr_o),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_wdata_o(data_wdata_o),
		.data_rdata_i(data_rdata_i),
		.lsu_we_i(lsu_we),
		.lsu_type_i(lsu_type),
		.lsu_wdata_i(lsu_wdata),
		.lsu_sign_ext_i(lsu_sign_ext),
		.lsu_rdata_o(rf_wdata_lsu),
		.lsu_rdata_valid_o(lsu_rdata_valid),
		.lsu_req_i(lsu_req),
		.lsu_req_done_o(lsu_req_done),
		.adder_result_ex_i(alu_adder_result_ex),
		.addr_incr_req_o(lsu_addr_incr_req),
		.addr_last_o(lsu_addr_last),
		.lsu_resp_valid_o(lsu_resp_valid),
		.load_err_o(lsu_load_err_raw),
		.load_resp_intg_err_o(lsu_load_resp_intg_err),
		.store_err_o(lsu_store_err_raw),
		.store_resp_intg_err_o(lsu_store_resp_intg_err),
		.busy_o(lsu_busy),
		.perf_load_o(perf_load),
		.perf_store_o(perf_store)
	);
	ibex_wb_stage #(
		.ResetAll(ResetAll),
		.WritebackStage(WritebackStage),
		.DummyInstructions(DummyInstructions)
	) wb_stage_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.en_wb_i(en_wb),
		.instr_type_wb_i(instr_type_wb),
		.pc_id_i(pc_id),
		.instr_is_compressed_id_i(instr_is_compressed_id),
		.instr_perf_count_id_i(instr_perf_count_id),
		.ready_wb_o(ready_wb),
		.rf_write_wb_o(rf_write_wb),
		.outstanding_load_wb_o(outstanding_load_wb),
		.outstanding_store_wb_o(outstanding_store_wb),
		.pc_wb_o(pc_wb),
		.perf_instr_ret_wb_o(perf_instr_ret_wb),
		.perf_instr_ret_compressed_wb_o(perf_instr_ret_compressed_wb),
		.perf_instr_ret_wb_spec_o(perf_instr_ret_wb_spec),
		.perf_instr_ret_compressed_wb_spec_o(perf_instr_ret_compressed_wb_spec),
		.rf_waddr_id_i(rf_waddr_id),
		.rf_wdata_id_i(rf_wdata_id),
		.rf_we_id_i(rf_we_id),
		.dummy_instr_id_i(dummy_instr_id),
		.rf_wdata_lsu_i(rf_wdata_lsu),
		.rf_we_lsu_i(rf_we_lsu),
		.rf_wdata_fwd_wb_o(rf_wdata_fwd_wb),
		.rf_waddr_wb_o(rf_waddr_wb),
		.rf_wdata_wb_o(rf_wdata_wb),
		.rf_we_wb_o(rf_we_wb),
		.dummy_instr_wb_o(dummy_instr_wb),
		.lsu_resp_valid_i(lsu_resp_valid),
		.lsu_resp_err_i(lsu_resp_err),
		.instr_done_wb_o(instr_done_wb)
	);
	generate
		if (SecureIbex) begin : g_check_mem_response
			assign lsu_load_err = lsu_load_err_raw & (outstanding_load_wb | expecting_load_resp_id);
			assign lsu_store_err = lsu_store_err_raw & (outstanding_store_wb | expecting_store_resp_id);
			assign rf_we_lsu = lsu_rdata_valid & (outstanding_load_wb | expecting_load_resp_id);
		end
		else begin : g_no_check_mem_response
			assign lsu_load_err = lsu_load_err_raw;
			assign lsu_store_err = lsu_store_err_raw;
			assign rf_we_lsu = lsu_rdata_valid;
			wire unused_expecting_load_resp_id;
			wire unused_expecting_store_resp_id;
			assign unused_expecting_load_resp_id = expecting_load_resp_id;
			assign unused_expecting_store_resp_id = expecting_store_resp_id;
		end
	endgenerate
	assign dummy_instr_id_o = dummy_instr_id;
	assign dummy_instr_wb_o = dummy_instr_wb;
	assign rf_raddr_a_o = rf_raddr_a;
	assign rf_waddr_wb_o = rf_waddr_wb;
	assign rf_we_wb_o = rf_we_wb;
	assign rf_raddr_b_o = rf_raddr_b;
	generate
		if (RegFileECC) begin : gen_regfile_ecc
			wire [1:0] rf_ecc_err_a;
			wire [1:0] rf_ecc_err_b;
			wire rf_ecc_err_a_id;
			wire rf_ecc_err_b_id;
			prim_secded_inv_39_32_enc regfile_ecc_enc(
				.data_i(rf_wdata_wb),
				.data_o(rf_wdata_wb_ecc_o)
			);
			prim_secded_inv_39_32_dec regfile_ecc_dec_a(
				.data_i(rf_rdata_a_ecc_i),
				.data_o(),
				.syndrome_o(),
				.err_o(rf_ecc_err_a)
			);
			prim_secded_inv_39_32_dec regfile_ecc_dec_b(
				.data_i(rf_rdata_b_ecc_i),
				.data_o(),
				.syndrome_o(),
				.err_o(rf_ecc_err_b)
			);
			assign rf_rdata_a = rf_rdata_a_ecc_i[31:0];
			assign rf_rdata_b = rf_rdata_b_ecc_i[31:0];
			assign rf_ecc_err_a_id = (|rf_ecc_err_a & rf_ren_a) & ~(rf_rd_a_wb_match & rf_write_wb);
			assign rf_ecc_err_b_id = (|rf_ecc_err_b & rf_ren_b) & ~(rf_rd_b_wb_match & rf_write_wb);
			assign rf_ecc_err_comb = instr_valid_id & (rf_ecc_err_a_id | rf_ecc_err_b_id);
		end
		else begin : gen_no_regfile_ecc
			wire unused_rf_ren_a;
			wire unused_rf_ren_b;
			wire unused_rf_rd_a_wb_match;
			wire unused_rf_rd_b_wb_match;
			assign unused_rf_ren_a = rf_ren_a;
			assign unused_rf_ren_b = rf_ren_b;
			assign unused_rf_rd_a_wb_match = rf_rd_a_wb_match;
			assign unused_rf_rd_b_wb_match = rf_rd_b_wb_match;
			assign rf_wdata_wb_ecc_o = rf_wdata_wb;
			assign rf_rdata_a = rf_rdata_a_ecc_i;
			assign rf_rdata_b = rf_rdata_b_ecc_i;
			assign rf_ecc_err_comb = 1'b0;
		end
	endgenerate
	wire [31:0] crash_dump_mtval;
	assign crash_dump_o[159-:32] = pc_id;
	assign crash_dump_o[127-:32] = pc_if;
	assign crash_dump_o[95-:32] = lsu_addr_last;
	assign crash_dump_o[63-:32] = csr_mepc;
	assign crash_dump_o[31-:32] = crash_dump_mtval;
	assign alert_minor_o = icache_ecc_error;
	assign alert_major_internal_o = (rf_ecc_err_comb | pc_mismatch_alert) | csr_shadow_err;
	assign alert_major_bus_o = (lsu_load_resp_intg_err | lsu_store_resp_intg_err) | instr_intg_err;
	assign csr_wdata = alu_operand_a_ex;
	ibex_cs_registers #(
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.DataIndTiming(DataIndTiming),
		.DummyInstructions(DummyInstructions),
		.ShadowCSR(ShadowCSR),
		.ICache(ICache),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B)
	) cs_registers_i(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.hart_id_i(hart_id_i),
		.priv_mode_id_o(priv_mode_id),
		.priv_mode_lsu_o(priv_mode_lsu),
		.csr_mtvec_o(csr_mtvec),
		.csr_mtvec_init_i(csr_mtvec_init),
		.boot_addr_i(boot_addr_i),
		.csr_access_i(csr_access),
		.csr_addr_i(csr_addr),
		.csr_wdata_i(csr_wdata),
		.csr_op_i(csr_op),
		.csr_op_en_i(csr_op_en),
		.csr_rdata_o(csr_rdata),
		.irq_software_i(irq_software_i),
		.irq_timer_i(irq_timer_i),
		.irq_external_i(irq_external_i),
		.irq_fast_i(irq_fast_i),
		.nmi_mode_i(nmi_mode),
		.irq_pending_o(irq_pending_o),
		.irqs_o(irqs),
		.csr_mstatus_mie_o(csr_mstatus_mie),
		.csr_mstatus_tw_o(csr_mstatus_tw),
		.csr_mepc_o(csr_mepc),
		.csr_mtval_o(crash_dump_mtval),
		.csr_pmp_cfg_o(csr_pmp_cfg),
		.csr_pmp_addr_o(csr_pmp_addr),
		.csr_pmp_mseccfg_o(csr_pmp_mseccfg),
		.csr_depc_o(csr_depc),
		.debug_mode_i(debug_mode),
		.debug_mode_entering_i(debug_mode_entering),
		.debug_cause_i(debug_cause),
		.debug_csr_save_i(debug_csr_save),
		.debug_single_step_o(debug_single_step),
		.debug_ebreakm_o(debug_ebreakm),
		.debug_ebreaku_o(debug_ebreaku),
		.trigger_match_o(trigger_match),
		.pc_if_i(pc_if),
		.pc_id_i(pc_id),
		.pc_wb_i(pc_wb),
		.data_ind_timing_o(data_ind_timing),
		.dummy_instr_en_o(dummy_instr_en),
		.dummy_instr_mask_o(dummy_instr_mask),
		.dummy_instr_seed_en_o(dummy_instr_seed_en),
		.dummy_instr_seed_o(dummy_instr_seed),
		.icache_enable_o(icache_enable),
		.csr_shadow_err_o(csr_shadow_err),
		.ic_scr_key_valid_i(ic_scr_key_valid_i),
		.csr_save_if_i(csr_save_if),
		.csr_save_id_i(csr_save_id),
		.csr_save_wb_i(csr_save_wb),
		.csr_restore_mret_i(csr_restore_mret_id),
		.csr_restore_dret_i(csr_restore_dret_id),
		.csr_save_cause_i(csr_save_cause),
		.csr_mcause_i(exc_cause),
		.csr_mtval_i(csr_mtval),
		.illegal_csr_insn_o(illegal_csr_insn_id),
		.double_fault_seen_o(double_fault_seen_o),
		.instr_ret_i(perf_instr_ret_wb),
		.instr_ret_compressed_i(perf_instr_ret_compressed_wb),
		.instr_ret_spec_i(perf_instr_ret_wb_spec),
		.instr_ret_compressed_spec_i(perf_instr_ret_compressed_wb_spec),
		.iside_wait_i(perf_iside_wait),
		.jump_i(perf_jump),
		.branch_i(perf_branch),
		.branch_taken_i(perf_tbranch),
		.mem_load_i(perf_load),
		.mem_store_i(perf_store),
		.dside_wait_i(perf_dside_wait),
		.mul_wait_i(perf_mul_wait),
		.div_wait_i(perf_div_wait)
	);
	generate
		if (PMPEnable) begin : g_pmp
			wire [31:0] pc_if_inc;
			wire [101:0] pmp_req_addr;
			wire [5:0] pmp_req_type;
			wire [5:0] pmp_priv_lvl;
			assign pc_if_inc = pc_if + 32'd2;
			assign pmp_req_addr[68+:34] = {2'b00, pc_if};
			assign pmp_req_type[4+:2] = 2'b00;
			assign pmp_priv_lvl[4+:2] = priv_mode_id;
			assign pmp_req_addr[34+:34] = {2'b00, pc_if_inc};
			assign pmp_req_type[2+:2] = 2'b00;
			assign pmp_priv_lvl[2+:2] = priv_mode_id;
			assign pmp_req_addr[0+:34] = {2'b00, data_addr_o[31:0]};
			assign pmp_req_type[0+:2] = (data_we_o ? 2'b01 : 2'b10);
			assign pmp_priv_lvl[0+:2] = priv_mode_lsu;
			ibex_pmp #(
				.DmBaseAddr(DmBaseAddr),
				.DmAddrMask(DmAddrMask),
				.PMPGranularity(PMPGranularity),
				.PMPNumChan(PMPNumChan),
				.PMPNumRegions(PMPNumRegions)
			) pmp_i(
				.csr_pmp_cfg_i(csr_pmp_cfg),
				.csr_pmp_addr_i(csr_pmp_addr),
				.csr_pmp_mseccfg_i(csr_pmp_mseccfg),
				.debug_mode_i(debug_mode),
				.priv_mode_i(pmp_priv_lvl),
				.pmp_req_addr_i(pmp_req_addr),
				.pmp_req_type_i(pmp_req_type),
				.pmp_req_err_o(pmp_req_err)
			);
		end
		else begin : g_no_pmp
			wire [1:0] unused_priv_lvl_ls;
			wire [(PMPNumRegions * 34) - 1:0] unused_csr_pmp_addr;
			wire [(PMPNumRegions * 6) - 1:0] unused_csr_pmp_cfg;
			wire [2:0] unused_csr_pmp_mseccfg;
			assign unused_priv_lvl_ls = priv_mode_lsu;
			assign unused_csr_pmp_addr = csr_pmp_addr;
			assign unused_csr_pmp_cfg = csr_pmp_cfg;
			assign unused_csr_pmp_mseccfg = csr_pmp_mseccfg;
			assign pmp_req_err[ibex_pkg_PMP_I] = 1'b0;
			assign pmp_req_err[ibex_pkg_PMP_I2] = 1'b0;
			assign pmp_req_err[ibex_pkg_PMP_D] = 1'b0;
		end
	endgenerate
	wire unused_instr_new_id;
	wire unused_instr_id_done;
	wire unused_instr_done_wb;
	assign unused_instr_id_done = instr_id_done;
	assign unused_instr_new_id = instr_new_id;
	assign unused_instr_done_wb = instr_done_wb;
endmodule
module ibex_top (
	clk_i,
	rst_ni,
	test_en_i,
	ram_cfg_i,
	hart_id_i,
	boot_addr_i,
	instr_req_o,
	instr_gnt_i,
	instr_rvalid_i,
	instr_addr_o,
	instr_rdata_i,
	instr_rdata_intg_i,
	instr_err_i,
	data_req_o,
	data_gnt_i,
	data_rvalid_i,
	data_we_o,
	data_be_o,
	data_addr_o,
	data_wdata_o,
	data_wdata_intg_o,
	data_rdata_i,
	data_rdata_intg_i,
	data_err_i,
	irq_software_i,
	irq_timer_i,
	irq_external_i,
	irq_fast_i,
	irq_nm_i,
	scramble_key_valid_i,
	scramble_key_i,
	scramble_nonce_i,
	scramble_req_o,
	debug_req_i,
	crash_dump_o,
	double_fault_seen_o,
	fetch_enable_i,
	alert_minor_o,
	alert_major_internal_o,
	alert_major_bus_o,
	core_sleep_o,
	scan_rst_ni
);
	parameter [0:0] PMPEnable = 1'b0;
	parameter [31:0] PMPGranularity = 0;
	parameter [31:0] PMPNumRegions = 4;
	parameter [31:0] MHPMCounterNum = 0;
	parameter [31:0] MHPMCounterWidth = 40;
	localparam [95:0] ibex_pkg_PmpCfgRst = 96'b000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000;
	parameter [95:0] PMPRstCfg = ibex_pkg_PmpCfgRst;
	localparam [543:0] ibex_pkg_PmpAddrRst = 544'h0;
	parameter [543:0] PMPRstAddr = ibex_pkg_PmpAddrRst;
	localparam [2:0] ibex_pkg_PmpMseccfgRst = 3'b000;
	parameter [2:0] PMPRstMsecCfg = ibex_pkg_PmpMseccfgRst;
	parameter [0:0] RV32E = 1'b0;
	parameter integer RV32M = 32'sd2;
	parameter integer RV32B = 32'sd0;
	parameter integer RegFile = 32'sd0;
	parameter [0:0] BranchTargetALU = 1'b0;
	parameter [0:0] WritebackStage = 1'b0;
	parameter [0:0] ICache = 1'b0;
	parameter [0:0] ICacheECC = 1'b0;
	parameter [0:0] BranchPredictor = 1'b0;
	parameter [0:0] DbgTriggerEn = 1'b0;
	parameter [31:0] DbgHwBreakNum = 1;
	parameter [0:0] SecureIbex = 1'b0;
	parameter [0:0] ICacheScramble = 1'b0;
	parameter [31:0] ICacheScrNumPrinceRoundsHalf = 2;
	localparam signed [31:0] ibex_pkg_LfsrWidth = 32;
	localparam [31:0] ibex_pkg_RndCnstLfsrSeedDefault = 32'hac533bf4;
	parameter [31:0] RndCnstLfsrSeed = ibex_pkg_RndCnstLfsrSeedDefault;
	localparam [159:0] ibex_pkg_RndCnstLfsrPermDefault = 160'h1e35ecba467fd1b12e958152c04fa43878a8daed;
	parameter [159:0] RndCnstLfsrPerm = ibex_pkg_RndCnstLfsrPermDefault;
	parameter [31:0] DmBaseAddr = 32'h1a110000;
	parameter [31:0] DmAddrMask = 32'h00000fff;
	parameter [31:0] DmHaltAddr = 32'h1a110800;
	parameter [31:0] DmExceptionAddr = 32'h1a110808;
	localparam [31:0] ibex_pkg_SCRAMBLE_KEY_W = 128;
	localparam [127:0] ibex_pkg_RndCnstIbexKeyDefault = 128'h14e8cecae3040d5e12286bb3cc113298;
	parameter [127:0] RndCnstIbexKey = ibex_pkg_RndCnstIbexKeyDefault;
	localparam [31:0] ibex_pkg_SCRAMBLE_NONCE_W = 64;
	localparam [63:0] ibex_pkg_RndCnstIbexNonceDefault = 64'hf79780bc735f3843;
	parameter [63:0] RndCnstIbexNonce = ibex_pkg_RndCnstIbexNonceDefault;
	input wire clk_i;
	input wire rst_ni;
	input wire test_en_i;
	input wire [9:0] ram_cfg_i;
	input wire [31:0] hart_id_i;
	input wire [31:0] boot_addr_i;
	output wire instr_req_o;
	input wire instr_gnt_i;
	input wire instr_rvalid_i;
	output wire [31:0] instr_addr_o;
	input wire [31:0] instr_rdata_i;
	input wire [6:0] instr_rdata_intg_i;
	input wire instr_err_i;
	output wire data_req_o;
	input wire data_gnt_i;
	input wire data_rvalid_i;
	output wire data_we_o;
	output wire [3:0] data_be_o;
	output wire [31:0] data_addr_o;
	output wire [31:0] data_wdata_o;
	output wire [6:0] data_wdata_intg_o;
	input wire [31:0] data_rdata_i;
	input wire [6:0] data_rdata_intg_i;
	input wire data_err_i;
	input wire irq_software_i;
	input wire irq_timer_i;
	input wire irq_external_i;
	input wire [14:0] irq_fast_i;
	input wire irq_nm_i;
	input wire scramble_key_valid_i;
	input wire [127:0] scramble_key_i;
	input wire [63:0] scramble_nonce_i;
	output wire scramble_req_o;
	input wire debug_req_i;
	output wire [159:0] crash_dump_o;
	output wire double_fault_seen_o;
	localparam signed [31:0] ibex_pkg_IbexMuBiWidth = 4;
	input wire [3:0] fetch_enable_i;
	output wire alert_minor_o;
	output wire alert_major_internal_o;
	output wire alert_major_bus_o;
	output wire core_sleep_o;
	input wire scan_rst_ni;
	localparam [0:0] Lockstep = SecureIbex;
	localparam [0:0] ResetAll = Lockstep;
	localparam [0:0] DummyInstructions = SecureIbex;
	localparam [0:0] RegFileECC = SecureIbex;
	localparam [0:0] RegFileWrenCheck = SecureIbex;
	localparam [0:0] RegFileRdataMuxCheck = SecureIbex;
	localparam [31:0] RegFileDataWidth = (RegFileECC ? 39 : 32);
	localparam [0:0] MemECC = SecureIbex;
	localparam [31:0] MemDataWidth = (MemECC ? 39 : 32);
	localparam [31:0] ibex_pkg_BUS_SIZE = 32;
	localparam [31:0] BusSizeECC = (ICacheECC ? 39 : ibex_pkg_BUS_SIZE);
	localparam [31:0] ibex_pkg_BUS_BYTES = 4;
	localparam [31:0] ibex_pkg_IC_LINE_SIZE = 64;
	localparam [31:0] ibex_pkg_IC_LINE_BYTES = 8;
	localparam [31:0] ibex_pkg_IC_LINE_BEATS = ibex_pkg_IC_LINE_BYTES / ibex_pkg_BUS_BYTES;
	localparam [31:0] LineSizeECC = BusSizeECC * ibex_pkg_IC_LINE_BEATS;
	localparam [31:0] ibex_pkg_ADDR_W = 32;
	localparam [31:0] ibex_pkg_IC_NUM_WAYS = 2;
	localparam [31:0] ibex_pkg_IC_SIZE_BYTES = 4096;
	localparam [31:0] ibex_pkg_IC_NUM_LINES = (ibex_pkg_IC_SIZE_BYTES / ibex_pkg_IC_NUM_WAYS) / ibex_pkg_IC_LINE_BYTES;
	localparam [31:0] ibex_pkg_IC_INDEX_W = $clog2(ibex_pkg_IC_NUM_LINES);
	localparam [31:0] ibex_pkg_IC_LINE_W = 3;
	localparam [31:0] ibex_pkg_IC_TAG_SIZE = ((ibex_pkg_ADDR_W - ibex_pkg_IC_INDEX_W) - ibex_pkg_IC_LINE_W) + 1;
	localparam [31:0] TagSizeECC = (ICacheECC ? ibex_pkg_IC_TAG_SIZE + 6 : ibex_pkg_IC_TAG_SIZE);
	localparam [31:0] NumAddrScrRounds = (ICacheScramble ? 2 : 0);
	wire clk;
	wire [3:0] core_busy_d;
	reg [3:0] core_busy_q;
	wire clock_en;
	wire irq_pending;
	wire dummy_instr_id;
	wire dummy_instr_wb;
	wire [4:0] rf_raddr_a;
	wire [4:0] rf_raddr_b;
	wire [4:0] rf_waddr_wb;
	wire rf_we_wb;
	wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc;
	wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc;
	wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_buf;
	wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc;
	wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_buf;
	wire [MemDataWidth - 1:0] data_wdata_core;
	wire [MemDataWidth - 1:0] data_rdata_core;
	wire [MemDataWidth - 1:0] instr_rdata_core;
	wire [1:0] ic_tag_req;
	wire ic_tag_write;
	wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr;
	wire [TagSizeECC - 1:0] ic_tag_wdata;
	wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata;
	wire [1:0] ic_data_req;
	wire ic_data_write;
	wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr;
	wire [LineSizeECC - 1:0] ic_data_wdata;
	wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata;
	wire ic_scr_key_req;
	wire core_alert_major_internal;
	wire core_alert_major_bus;
	wire core_alert_minor;
	wire lockstep_alert_major_internal;
	wire lockstep_alert_major_bus;
	wire lockstep_alert_minor;
	reg [127:0] scramble_key_q;
	reg [63:0] scramble_nonce_q;
	wire scramble_key_valid_d;
	reg scramble_key_valid_q;
	wire scramble_req_d;
	reg scramble_req_q;
	wire [3:0] fetch_enable_buf;
	localparam [3:0] ibex_pkg_IbexMuBiOff = 4'b1010;
	generate
		if (SecureIbex) begin : g_clock_en_secure
			wire [4:1] sv2v_tmp_u_prim_core_busy_flop_q_o;
			always @(*) core_busy_q = sv2v_tmp_u_prim_core_busy_flop_q_o;
			prim_flop #(
				.Width(ibex_pkg_IbexMuBiWidth),
				.ResetValue(ibex_pkg_IbexMuBiOff)
			) u_prim_core_busy_flop(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.d_i(core_busy_d),
				.q_o(sv2v_tmp_u_prim_core_busy_flop_q_o)
			);
			assign clock_en = (((core_busy_q != ibex_pkg_IbexMuBiOff) | debug_req_i) | irq_pending) | irq_nm_i;
		end
		else begin : g_clock_en_non_secure
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni)
					core_busy_q <= ibex_pkg_IbexMuBiOff;
				else
					core_busy_q <= core_busy_d;
			assign clock_en = ((core_busy_q[0] | debug_req_i) | irq_pending) | irq_nm_i;
			wire unused_core_busy;
			assign unused_core_busy = ^core_busy_q[3:1];
		end
	endgenerate
	assign core_sleep_o = ~clock_en;
	prim_clock_gating core_clock_gate_i(
		.clk_i(clk_i),
		.en_i(clock_en),
		.test_en_i(test_en_i),
		.clk_o(clk)
	);
	prim_buf #(.Width(ibex_pkg_IbexMuBiWidth)) u_fetch_enable_buf(
		.in_i(fetch_enable_i),
		.out_o(fetch_enable_buf)
	);
	prim_buf #(.Width(RegFileDataWidth)) u_rf_rdata_a_ecc_buf(
		.in_i(rf_rdata_a_ecc),
		.out_o(rf_rdata_a_ecc_buf)
	);
	prim_buf #(.Width(RegFileDataWidth)) u_rf_rdata_b_ecc_buf(
		.in_i(rf_rdata_b_ecc),
		.out_o(rf_rdata_b_ecc_buf)
	);
	assign data_rdata_core[31:0] = data_rdata_i;
	assign instr_rdata_core[31:0] = instr_rdata_i;
	generate
		if (MemECC) begin : gen_mem_rdata_ecc
			assign data_rdata_core[38:32] = data_rdata_intg_i;
			assign instr_rdata_core[38:32] = instr_rdata_intg_i;
		end
		else begin : gen_non_mem_rdata_ecc
			wire unused_intg;
			assign unused_intg = ^{instr_rdata_intg_i, data_rdata_intg_i};
		end
	endgenerate
	ibex_core #(
		.PMPEnable(PMPEnable),
		.PMPGranularity(PMPGranularity),
		.PMPNumRegions(PMPNumRegions),
		.PMPRstCfg(PMPRstCfg),
		.PMPRstAddr(PMPRstAddr),
		.PMPRstMsecCfg(PMPRstMsecCfg),
		.MHPMCounterNum(MHPMCounterNum),
		.MHPMCounterWidth(MHPMCounterWidth),
		.RV32E(RV32E),
		.RV32M(RV32M),
		.RV32B(RV32B),
		.BranchTargetALU(BranchTargetALU),
		.ICache(ICache),
		.ICacheECC(ICacheECC),
		.BusSizeECC(BusSizeECC),
		.TagSizeECC(TagSizeECC),
		.LineSizeECC(LineSizeECC),
		.BranchPredictor(BranchPredictor),
		.DbgTriggerEn(DbgTriggerEn),
		.DbgHwBreakNum(DbgHwBreakNum),
		.WritebackStage(WritebackStage),
		.ResetAll(ResetAll),
		.RndCnstLfsrSeed(RndCnstLfsrSeed),
		.RndCnstLfsrPerm(RndCnstLfsrPerm),
		.SecureIbex(SecureIbex),
		.DummyInstructions(DummyInstructions),
		.RegFileECC(RegFileECC),
		.RegFileDataWidth(RegFileDataWidth),
		.MemECC(MemECC),
		.MemDataWidth(MemDataWidth),
		.DmBaseAddr(DmBaseAddr),
		.DmAddrMask(DmAddrMask),
		.DmHaltAddr(DmHaltAddr),
		.DmExceptionAddr(DmExceptionAddr)
	) u_ibex_core(
		.clk_i(clk),
		.rst_ni(rst_ni),
		.hart_id_i(hart_id_i),
		.boot_addr_i(boot_addr_i),
		.instr_req_o(instr_req_o),
		.instr_gnt_i(instr_gnt_i),
		.instr_rvalid_i(instr_rvalid_i),
		.instr_addr_o(instr_addr_o),
		.instr_rdata_i(instr_rdata_core),
		.instr_err_i(instr_err_i),
		.data_req_o(data_req_o),
		.data_gnt_i(data_gnt_i),
		.data_rvalid_i(data_rvalid_i),
		.data_we_o(data_we_o),
		.data_be_o(data_be_o),
		.data_addr_o(data_addr_o),
		.data_wdata_o(data_wdata_core),
		.data_rdata_i(data_rdata_core),
		.data_err_i(data_err_i),
		.dummy_instr_id_o(dummy_instr_id),
		.dummy_instr_wb_o(dummy_instr_wb),
		.rf_raddr_a_o(rf_raddr_a),
		.rf_raddr_b_o(rf_raddr_b),
		.rf_waddr_wb_o(rf_waddr_wb),
		.rf_we_wb_o(rf_we_wb),
		.rf_wdata_wb_ecc_o(rf_wdata_wb_ecc),
		.rf_rdata_a_ecc_i(rf_rdata_a_ecc_buf),
		.rf_rdata_b_ecc_i(rf_rdata_b_ecc_buf),
		.ic_tag_req_o(ic_tag_req),
		.ic_tag_write_o(ic_tag_write),
		.ic_tag_addr_o(ic_tag_addr),
		.ic_tag_wdata_o(ic_tag_wdata),
		.ic_tag_rdata_i(ic_tag_rdata),
		.ic_data_req_o(ic_data_req),
		.ic_data_write_o(ic_data_write),
		.ic_data_addr_o(ic_data_addr),
		.ic_data_wdata_o(ic_data_wdata),
		.ic_data_rdata_i(ic_data_rdata),
		.ic_scr_key_valid_i(scramble_key_valid_q),
		.ic_scr_key_req_o(ic_scr_key_req),
		.irq_software_i(irq_software_i),
		.irq_timer_i(irq_timer_i),
		.irq_external_i(irq_external_i),
		.irq_fast_i(irq_fast_i),
		.irq_nm_i(irq_nm_i),
		.irq_pending_o(irq_pending),
		.debug_req_i(debug_req_i),
		.crash_dump_o(crash_dump_o),
		.double_fault_seen_o(double_fault_seen_o),
		.fetch_enable_i(fetch_enable_buf),
		.alert_minor_o(core_alert_minor),
		.alert_major_internal_o(core_alert_major_internal),
		.alert_major_bus_o(core_alert_major_bus),
		.core_busy_o(core_busy_d)
	);
	wire rf_alert_major_internal;
	localparam [38:0] prim_secded_pkg_SecdedInv3932ZeroWord = 39'h2a00000000;
	function automatic [RegFileDataWidth - 1:0] sv2v_cast_0BB25;
		input reg [RegFileDataWidth - 1:0] inp;
		sv2v_cast_0BB25 = inp;
	endfunction
	generate
		if (RegFile == 32'sd0) begin : gen_regfile_ff
			ibex_register_file_ff #(
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WrenCheck(RegFileWrenCheck),
				.RdataMuxCheck(RegFileRdataMuxCheck),
				.WordZeroVal(sv2v_cast_0BB25(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a_ecc),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b_ecc),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb_ecc),
				.we_a_i(rf_we_wb),
				.err_o(rf_alert_major_internal)
			);
		end
		else if (RegFile == 32'sd1) begin : gen_regfile_fpga
			ibex_register_file_fpga #(
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WrenCheck(RegFileWrenCheck),
				.RdataMuxCheck(RegFileRdataMuxCheck),
				.WordZeroVal(sv2v_cast_0BB25(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a_ecc),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b_ecc),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb_ecc),
				.we_a_i(rf_we_wb),
				.err_o(rf_alert_major_internal)
			);
		end
		else if (RegFile == 32'sd2) begin : gen_regfile_latch
			ibex_register_file_latch #(
				.RV32E(RV32E),
				.DataWidth(RegFileDataWidth),
				.DummyInstructions(DummyInstructions),
				.WrenCheck(RegFileWrenCheck),
				.RdataMuxCheck(RegFileRdataMuxCheck),
				.WordZeroVal(sv2v_cast_0BB25(prim_secded_pkg_SecdedInv3932ZeroWord))
			) register_file_i(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.test_en_i(test_en_i),
				.dummy_instr_id_i(dummy_instr_id),
				.dummy_instr_wb_i(dummy_instr_wb),
				.raddr_a_i(rf_raddr_a),
				.rdata_a_o(rf_rdata_a_ecc),
				.raddr_b_i(rf_raddr_b),
				.rdata_b_o(rf_rdata_b_ecc),
				.waddr_a_i(rf_waddr_wb),
				.wdata_a_i(rf_wdata_wb_ecc),
				.we_a_i(rf_we_wb),
				.err_o(rf_alert_major_internal)
			);
		end
		if (ICacheScramble) begin : gen_scramble
			assign scramble_key_valid_d = (scramble_req_q ? scramble_key_valid_i : (ic_scr_key_req ? 1'b0 : scramble_key_valid_q));
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					scramble_key_q <= RndCnstIbexKey;
					scramble_nonce_q <= RndCnstIbexNonce;
				end
				else if (scramble_key_valid_i) begin
					scramble_key_q <= scramble_key_i;
					scramble_nonce_q <= scramble_nonce_i;
				end
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					scramble_key_valid_q <= 1'b1;
					scramble_req_q <= 1'sb0;
				end
				else begin
					scramble_key_valid_q <= scramble_key_valid_d;
					scramble_req_q <= scramble_req_d;
				end
			assign scramble_req_d = (scramble_req_q ? ~scramble_key_valid_i : ic_scr_key_req);
			assign scramble_req_o = scramble_req_q;
		end
		else begin : gen_noscramble
			wire unused_scramble_inputs;
			assign unused_scramble_inputs = (((((((scramble_key_valid_i & |scramble_key_i) & |RndCnstIbexKey) & |scramble_nonce_i) & |RndCnstIbexNonce) & scramble_req_q) & ic_scr_key_req) & scramble_key_valid_d) & scramble_req_d;
			assign scramble_req_d = 1'b0;
			wire [1:1] sv2v_tmp_2E9FB;
			assign sv2v_tmp_2E9FB = 1'b0;
			always @(*) scramble_req_q = sv2v_tmp_2E9FB;
			assign scramble_req_o = 1'b0;
			wire [128:1] sv2v_tmp_E270A;
			assign sv2v_tmp_E270A = 1'sb0;
			always @(*) scramble_key_q = sv2v_tmp_E270A;
			wire [64:1] sv2v_tmp_F758A;
			assign sv2v_tmp_F758A = 1'sb0;
			always @(*) scramble_nonce_q = sv2v_tmp_F758A;
			wire [1:1] sv2v_tmp_604FC;
			assign sv2v_tmp_604FC = 1'b1;
			always @(*) scramble_key_valid_q = sv2v_tmp_604FC;
			assign scramble_key_valid_d = 1'b1;
		end
	endgenerate
	wire [1:0] icache_tag_alert;
	wire [1:0] icache_data_alert;
	function automatic [TagSizeECC - 1:0] sv2v_cast_0CBAD;
		input reg [TagSizeECC - 1:0] inp;
		sv2v_cast_0CBAD = inp;
	endfunction
	function automatic [LineSizeECC - 1:0] sv2v_cast_033B0;
		input reg [LineSizeECC - 1:0] inp;
		sv2v_cast_033B0 = inp;
	endfunction
	generate
		if (ICache) begin : gen_rams
			genvar _gv_way_1;
			for (_gv_way_1 = 0; _gv_way_1 < ibex_pkg_IC_NUM_WAYS; _gv_way_1 = _gv_way_1 + 1) begin : gen_rams_inner
				localparam way = _gv_way_1;
				if (ICacheScramble) begin : gen_scramble_rams
					prim_ram_1p_scr #(
						.Width(TagSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(TagSizeECC),
						.EnableParity(0),
						.NumPrinceRoundsHalf(ICacheScrNumPrinceRoundsHalf),
						.NumAddrScrRounds(NumAddrScrRounds)
					) tag_bank(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.key_valid_i(scramble_key_valid_q),
						.key_i(scramble_key_q),
						.nonce_i(scramble_nonce_q),
						.req_i(ic_tag_req[way]),
						.gnt_o(),
						.write_i(ic_tag_write),
						.addr_i(ic_tag_addr),
						.wdata_i(ic_tag_wdata),
						.wmask_i({TagSizeECC {1'b1}}),
						.intg_error_i(1'b0),
						.rdata_o(ic_tag_rdata[(1 - way) * TagSizeECC+:TagSizeECC]),
						.rvalid_o(),
						.raddr_o(),
						.rerror_o(),
						.cfg_i(ram_cfg_i),
						.wr_collision_o(),
						.write_pending_o(),
						.alert_o(icache_tag_alert[way])
					);
					prim_ram_1p_scr #(
						.Width(LineSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(LineSizeECC),
						.ReplicateKeyStream(1),
						.EnableParity(0),
						.NumPrinceRoundsHalf(ICacheScrNumPrinceRoundsHalf),
						.NumAddrScrRounds(NumAddrScrRounds)
					) data_bank(
						.clk_i(clk_i),
						.rst_ni(rst_ni),
						.key_valid_i(scramble_key_valid_q),
						.key_i(scramble_key_q),
						.nonce_i(scramble_nonce_q),
						.req_i(ic_data_req[way]),
						.gnt_o(),
						.write_i(ic_data_write),
						.addr_i(ic_data_addr),
						.wdata_i(ic_data_wdata),
						.wmask_i({LineSizeECC {1'b1}}),
						.intg_error_i(1'b0),
						.rdata_o(ic_data_rdata[(1 - way) * LineSizeECC+:LineSizeECC]),
						.rvalid_o(),
						.raddr_o(),
						.rerror_o(),
						.cfg_i(ram_cfg_i),
						.wr_collision_o(),
						.write_pending_o(),
						.alert_o(icache_data_alert[way])
					);
				end
				else begin : gen_noscramble_rams
					prim_ram_1p #(
						.Width(TagSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(TagSizeECC)
					) tag_bank(
						.clk_i(clk_i),
						.req_i(ic_tag_req[way]),
						.write_i(ic_tag_write),
						.addr_i(ic_tag_addr),
						.wdata_i(ic_tag_wdata),
						.wmask_i({TagSizeECC {1'b1}}),
						.rdata_o(ic_tag_rdata[(1 - way) * TagSizeECC+:TagSizeECC]),
						.cfg_i(ram_cfg_i)
					);
					prim_ram_1p #(
						.Width(LineSizeECC),
						.Depth(ibex_pkg_IC_NUM_LINES),
						.DataBitsPerMask(LineSizeECC)
					) data_bank(
						.clk_i(clk_i),
						.req_i(ic_data_req[way]),
						.write_i(ic_data_write),
						.addr_i(ic_data_addr),
						.wdata_i(ic_data_wdata),
						.wmask_i({LineSizeECC {1'b1}}),
						.rdata_o(ic_data_rdata[(1 - way) * LineSizeECC+:LineSizeECC]),
						.cfg_i(ram_cfg_i)
					);
					assign icache_tag_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
					assign icache_data_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
				end
			end
		end
		else begin : gen_norams
			wire [9:0] unused_ram_cfg;
			wire unused_ram_inputs;
			assign unused_ram_cfg = ram_cfg_i;
			assign unused_ram_inputs = ((((((((((((|ic_tag_req & ic_tag_write) & |ic_tag_addr) & |ic_tag_wdata) & |ic_data_req) & ic_data_write) & |ic_data_addr) & |ic_data_wdata) & |scramble_key_q) & |scramble_nonce_q) & scramble_key_valid_q) & scramble_key_valid_d) & |scramble_nonce_q) & |NumAddrScrRounds;
			assign ic_tag_rdata = {ibex_pkg_IC_NUM_WAYS {sv2v_cast_0CBAD('b0)}};
			assign ic_data_rdata = {ibex_pkg_IC_NUM_WAYS {sv2v_cast_033B0('b0)}};
			assign icache_tag_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
			assign icache_data_alert = {ibex_pkg_IC_NUM_WAYS {1'b0}};
		end
	endgenerate
	assign data_wdata_o = data_wdata_core[31:0];
	generate
		if (MemECC) begin : gen_mem_wdata_ecc
			prim_buf #(.Width(7)) u_prim_buf_data_wdata_intg(
				.in_i(data_wdata_core[38:32]),
				.out_o(data_wdata_intg_o)
			);
		end
		else begin : gen_no_mem_ecc
			assign data_wdata_intg_o = 1'sb0;
		end
		if (Lockstep) begin : gen_lockstep
			localparam signed [31:0] NumBufferBits = ((((((((((((((((((99 + MemDataWidth) + 41) + MemDataWidth) + MemDataWidth) + 19) + RegFileDataWidth) + RegFileDataWidth) + RegFileDataWidth) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + TagSizeECC) + ibex_pkg_IC_NUM_WAYS) + 1) + ibex_pkg_IC_INDEX_W) + LineSizeECC) + 184) + ibex_pkg_IbexMuBiWidth) + ibex_pkg_IbexMuBiWidth;
			wire [NumBufferBits - 1:0] buf_in;
			wire [NumBufferBits - 1:0] buf_out;
			wire [31:0] hart_id_local;
			wire [31:0] boot_addr_local;
			wire instr_req_local;
			wire instr_gnt_local;
			wire instr_rvalid_local;
			wire [31:0] instr_addr_local;
			wire [MemDataWidth - 1:0] instr_rdata_local;
			wire instr_err_local;
			wire data_req_local;
			wire data_gnt_local;
			wire data_rvalid_local;
			wire data_we_local;
			wire [3:0] data_be_local;
			wire [31:0] data_addr_local;
			wire [MemDataWidth - 1:0] data_wdata_local;
			wire [MemDataWidth - 1:0] data_rdata_local;
			wire data_err_local;
			wire dummy_instr_id_local;
			wire dummy_instr_wb_local;
			wire [4:0] rf_raddr_a_local;
			wire [4:0] rf_raddr_b_local;
			wire [4:0] rf_waddr_wb_local;
			wire rf_we_wb_local;
			wire [RegFileDataWidth - 1:0] rf_wdata_wb_ecc_local;
			wire [RegFileDataWidth - 1:0] rf_rdata_a_ecc_local;
			wire [RegFileDataWidth - 1:0] rf_rdata_b_ecc_local;
			wire [1:0] ic_tag_req_local;
			wire ic_tag_write_local;
			wire [ibex_pkg_IC_INDEX_W - 1:0] ic_tag_addr_local;
			wire [TagSizeECC - 1:0] ic_tag_wdata_local;
			wire [1:0] ic_data_req_local;
			wire ic_data_write_local;
			wire [ibex_pkg_IC_INDEX_W - 1:0] ic_data_addr_local;
			wire [LineSizeECC - 1:0] ic_data_wdata_local;
			wire scramble_key_valid_local;
			wire ic_scr_key_req_local;
			wire irq_software_local;
			wire irq_timer_local;
			wire irq_external_local;
			wire [14:0] irq_fast_local;
			wire irq_nm_local;
			wire irq_pending_local;
			wire debug_req_local;
			wire [159:0] crash_dump_local;
			wire double_fault_seen_local;
			wire [3:0] fetch_enable_local;
			wire [3:0] core_busy_local;
			assign buf_in = {hart_id_i, boot_addr_i, instr_req_o, instr_gnt_i, instr_rvalid_i, instr_addr_o, instr_rdata_core, instr_err_i, data_req_o, data_gnt_i, data_rvalid_i, data_we_o, data_be_o, data_addr_o, data_wdata_core, data_rdata_core, data_err_i, dummy_instr_id, dummy_instr_wb, rf_raddr_a, rf_raddr_b, rf_waddr_wb, rf_we_wb, rf_wdata_wb_ecc, rf_rdata_a_ecc, rf_rdata_b_ecc, ic_tag_req, ic_tag_write, ic_tag_addr, ic_tag_wdata, ic_data_req, ic_data_write, ic_data_addr, ic_data_wdata, scramble_key_valid_q, ic_scr_key_req, irq_software_i, irq_timer_i, irq_external_i, irq_fast_i, irq_nm_i, irq_pending, debug_req_i, crash_dump_o, double_fault_seen_o, fetch_enable_i, core_busy_d};
			assign {hart_id_local, boot_addr_local, instr_req_local, instr_gnt_local, instr_rvalid_local, instr_addr_local, instr_rdata_local, instr_err_local, data_req_local, data_gnt_local, data_rvalid_local, data_we_local, data_be_local, data_addr_local, data_wdata_local, data_rdata_local, data_err_local, dummy_instr_id_local, dummy_instr_wb_local, rf_raddr_a_local, rf_raddr_b_local, rf_waddr_wb_local, rf_we_wb_local, rf_wdata_wb_ecc_local, rf_rdata_a_ecc_local, rf_rdata_b_ecc_local, ic_tag_req_local, ic_tag_write_local, ic_tag_addr_local, ic_tag_wdata_local, ic_data_req_local, ic_data_write_local, ic_data_addr_local, ic_data_wdata_local, scramble_key_valid_local, ic_scr_key_req_local, irq_software_local, irq_timer_local, irq_external_local, irq_fast_local, irq_nm_local, irq_pending_local, debug_req_local, crash_dump_local, double_fault_seen_local, fetch_enable_local, core_busy_local} = buf_out;
			prim_buf #(.Width(NumBufferBits)) u_signals_prim_buf(
				.in_i(buf_in),
				.out_o(buf_out)
			);
			wire [(ibex_pkg_IC_NUM_WAYS * TagSizeECC) - 1:0] ic_tag_rdata_local;
			wire [(ibex_pkg_IC_NUM_WAYS * LineSizeECC) - 1:0] ic_data_rdata_local;
			genvar _gv_k_2;
			for (_gv_k_2 = 0; _gv_k_2 < ibex_pkg_IC_NUM_WAYS; _gv_k_2 = _gv_k_2 + 1) begin : gen_ways
				localparam k = _gv_k_2;
				prim_buf #(.Width(TagSizeECC)) u_tag_prim_buf(
					.in_i(ic_tag_rdata[(1 - k) * TagSizeECC+:TagSizeECC]),
					.out_o(ic_tag_rdata_local[(1 - k) * TagSizeECC+:TagSizeECC])
				);
				prim_buf #(.Width(LineSizeECC)) u_data_prim_buf(
					.in_i(ic_data_rdata[(1 - k) * LineSizeECC+:LineSizeECC]),
					.out_o(ic_data_rdata_local[(1 - k) * LineSizeECC+:LineSizeECC])
				);
			end
			wire lockstep_alert_minor_local;
			wire lockstep_alert_major_internal_local;
			wire lockstep_alert_major_bus_local;
			ibex_lockstep #(
				.PMPEnable(PMPEnable),
				.PMPGranularity(PMPGranularity),
				.PMPNumRegions(PMPNumRegions),
				.PMPRstCfg(PMPRstCfg),
				.PMPRstAddr(PMPRstAddr),
				.PMPRstMsecCfg(PMPRstMsecCfg),
				.MHPMCounterNum(MHPMCounterNum),
				.MHPMCounterWidth(MHPMCounterWidth),
				.RV32E(RV32E),
				.RV32M(RV32M),
				.RV32B(RV32B),
				.BranchTargetALU(BranchTargetALU),
				.ICache(ICache),
				.ICacheECC(ICacheECC),
				.BusSizeECC(BusSizeECC),
				.TagSizeECC(TagSizeECC),
				.LineSizeECC(LineSizeECC),
				.BranchPredictor(BranchPredictor),
				.DbgTriggerEn(DbgTriggerEn),
				.DbgHwBreakNum(DbgHwBreakNum),
				.WritebackStage(WritebackStage),
				.ResetAll(ResetAll),
				.RndCnstLfsrSeed(RndCnstLfsrSeed),
				.RndCnstLfsrPerm(RndCnstLfsrPerm),
				.SecureIbex(SecureIbex),
				.DummyInstructions(DummyInstructions),
				.RegFileECC(RegFileECC),
				.RegFileDataWidth(RegFileDataWidth),
				.MemECC(MemECC),
				.DmBaseAddr(DmBaseAddr),
				.DmAddrMask(DmAddrMask),
				.DmHaltAddr(DmHaltAddr),
				.DmExceptionAddr(DmExceptionAddr)
			) u_ibex_lockstep(
				.clk_i(clk),
				.rst_ni(rst_ni),
				.hart_id_i(hart_id_local),
				.boot_addr_i(boot_addr_local),
				.instr_req_i(instr_req_local),
				.instr_gnt_i(instr_gnt_local),
				.instr_rvalid_i(instr_rvalid_local),
				.instr_addr_i(instr_addr_local),
				.instr_rdata_i(instr_rdata_local),
				.instr_err_i(instr_err_local),
				.data_req_i(data_req_local),
				.data_gnt_i(data_gnt_local),
				.data_rvalid_i(data_rvalid_local),
				.data_we_i(data_we_local),
				.data_be_i(data_be_local),
				.data_addr_i(data_addr_local),
				.data_wdata_i(data_wdata_local),
				.data_rdata_i(data_rdata_local),
				.data_err_i(data_err_local),
				.dummy_instr_id_i(dummy_instr_id_local),
				.dummy_instr_wb_i(dummy_instr_wb_local),
				.rf_raddr_a_i(rf_raddr_a_local),
				.rf_raddr_b_i(rf_raddr_b_local),
				.rf_waddr_wb_i(rf_waddr_wb_local),
				.rf_we_wb_i(rf_we_wb_local),
				.rf_wdata_wb_ecc_i(rf_wdata_wb_ecc_local),
				.rf_rdata_a_ecc_i(rf_rdata_a_ecc_local),
				.rf_rdata_b_ecc_i(rf_rdata_b_ecc_local),
				.ic_tag_req_i(ic_tag_req_local),
				.ic_tag_write_i(ic_tag_write_local),
				.ic_tag_addr_i(ic_tag_addr_local),
				.ic_tag_wdata_i(ic_tag_wdata_local),
				.ic_tag_rdata_i(ic_tag_rdata_local),
				.ic_data_req_i(ic_data_req_local),
				.ic_data_write_i(ic_data_write_local),
				.ic_data_addr_i(ic_data_addr_local),
				.ic_data_wdata_i(ic_data_wdata_local),
				.ic_data_rdata_i(ic_data_rdata_local),
				.ic_scr_key_valid_i(scramble_key_valid_local),
				.ic_scr_key_req_i(ic_scr_key_req_local),
				.irq_software_i(irq_software_local),
				.irq_timer_i(irq_timer_local),
				.irq_external_i(irq_external_local),
				.irq_fast_i(irq_fast_local),
				.irq_nm_i(irq_nm_local),
				.irq_pending_i(irq_pending_local),
				.debug_req_i(debug_req_local),
				.crash_dump_i(crash_dump_local),
				.double_fault_seen_i(double_fault_seen_local),
				.fetch_enable_i(fetch_enable_local),
				.alert_minor_o(lockstep_alert_minor_local),
				.alert_major_internal_o(lockstep_alert_major_internal_local),
				.alert_major_bus_o(lockstep_alert_major_bus_local),
				.core_busy_i(core_busy_local),
				.test_en_i(test_en_i),
				.scan_rst_ni(scan_rst_ni)
			);
			prim_buf u_prim_buf_alert_minor(
				.in_i(lockstep_alert_minor_local),
				.out_o(lockstep_alert_minor)
			);
			prim_buf u_prim_buf_alert_major_internal(
				.in_i(lockstep_alert_major_internal_local),
				.out_o(lockstep_alert_major_internal)
			);
			prim_buf u_prim_buf_alert_major_bus(
				.in_i(lockstep_alert_major_bus_local),
				.out_o(lockstep_alert_major_bus)
			);
		end
		else begin : gen_no_lockstep
			assign lockstep_alert_major_internal = 1'b0;
			assign lockstep_alert_major_bus = 1'b0;
			assign lockstep_alert_minor = 1'b0;
			wire unused_scan;
			assign unused_scan = scan_rst_ni;
		end
	endgenerate
	wire icache_alert_major_internal;
	assign icache_alert_major_internal = |icache_tag_alert | (|icache_data_alert);
	assign alert_major_internal_o = ((core_alert_major_internal | lockstep_alert_major_internal) | rf_alert_major_internal) | icache_alert_major_internal;
	assign alert_major_bus_o = core_alert_major_bus | lockstep_alert_major_bus;
	assign alert_minor_o = core_alert_minor | lockstep_alert_minor;
endmodule
module dm_csrs (
	clk_i,
	rst_ni,
	testmode_i,
	dmi_rst_ni,
	dmi_req_valid_i,
	dmi_req_ready_o,
	dmi_req_i,
	dmi_resp_valid_o,
	dmi_resp_ready_i,
	dmi_resp_o,
	ndmreset_o,
	dmactive_o,
	hartinfo_i,
	halted_i,
	unavailable_i,
	resumeack_i,
	hartsel_o,
	haltreq_o,
	resumereq_o,
	clear_resumeack_o,
	cmd_valid_o,
	cmd_o,
	cmderror_valid_i,
	cmderror_i,
	cmdbusy_i,
	progbuf_o,
	data_o,
	data_i,
	data_valid_i,
	sbaddress_o,
	sbaddress_i,
	sbaddress_write_valid_o,
	sbreadonaddr_o,
	sbautoincrement_o,
	sbaccess_o,
	sbreadondata_o,
	sbdata_o,
	sbdata_read_valid_o,
	sbdata_write_valid_o,
	sbdata_i,
	sbdata_valid_i,
	sbbusy_i,
	sberror_valid_i,
	sberror_i
);
	reg _sv2v_0;
	parameter [31:0] NrHarts = 1;
	parameter [31:0] BusWidth = 32;
	parameter [NrHarts - 1:0] SelectableHarts = {NrHarts {1'b1}};
	input wire clk_i;
	input wire rst_ni;
	input wire testmode_i;
	input wire dmi_rst_ni;
	input wire dmi_req_valid_i;
	output wire dmi_req_ready_o;
	input wire [40:0] dmi_req_i;
	output wire dmi_resp_valid_o;
	input wire dmi_resp_ready_i;
	output wire [33:0] dmi_resp_o;
	output wire ndmreset_o;
	output wire dmactive_o;
	input wire [(NrHarts * 32) - 1:0] hartinfo_i;
	input wire [NrHarts - 1:0] halted_i;
	input wire [NrHarts - 1:0] unavailable_i;
	input wire [NrHarts - 1:0] resumeack_i;
	output wire [19:0] hartsel_o;
	output reg [NrHarts - 1:0] haltreq_o;
	output reg [NrHarts - 1:0] resumereq_o;
	output reg clear_resumeack_o;
	output wire cmd_valid_o;
	output wire [31:0] cmd_o;
	input wire cmderror_valid_i;
	input wire [2:0] cmderror_i;
	input wire cmdbusy_i;
	localparam [4:0] dm_ProgBufSize = 5'h08;
	output wire [255:0] progbuf_o;
	localparam [3:0] dm_DataCount = 4'h2;
	output wire [63:0] data_o;
	input wire [63:0] data_i;
	input wire data_valid_i;
	output wire [BusWidth - 1:0] sbaddress_o;
	input wire [BusWidth - 1:0] sbaddress_i;
	output reg sbaddress_write_valid_o;
	output wire sbreadonaddr_o;
	output wire sbautoincrement_o;
	output wire [2:0] sbaccess_o;
	output wire sbreadondata_o;
	output wire [BusWidth - 1:0] sbdata_o;
	output reg sbdata_read_valid_o;
	output reg sbdata_write_valid_o;
	input wire [BusWidth - 1:0] sbdata_i;
	input wire sbdata_valid_i;
	input wire sbbusy_i;
	input wire sberror_valid_i;
	input wire [2:0] sberror_i;
	localparam [31:0] HartSelLen = (NrHarts == 1 ? 1 : $clog2(NrHarts));
	localparam [31:0] NrHartsAligned = 2 ** HartSelLen;
	wire [1:0] dtm_op;
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	assign dtm_op = sv2v_cast_2(dmi_req_i[33-:2]);
	function automatic [7:0] sv2v_cast_8;
		input reg [7:0] inp;
		sv2v_cast_8 = inp;
	endfunction
	localparam [7:0] DataEnd = sv2v_cast_8((8'h04 + {4'h0, dm_DataCount}) - 8'h01);
	localparam [7:0] ProgBufEnd = sv2v_cast_8((8'h20 + {4'h0, dm_ProgBufSize}) - 8'h01);
	reg [31:0] haltsum0;
	reg [31:0] haltsum1;
	reg [31:0] haltsum2;
	reg [31:0] haltsum3;
	reg [((((NrHarts - 1) / 32) + 1) * 32) - 1:0] halted;
	reg [(((NrHarts - 1) / 32) >= 0 ? ((((NrHarts - 1) / 32) + 1) * 32) - 1 : ((1 - ((NrHarts - 1) / 32)) * 32) + ((((NrHarts - 1) / 32) * 32) - 1)):(((NrHarts - 1) / 32) >= 0 ? 0 : ((NrHarts - 1) / 32) * 32)] halted_reshaped0;
	reg [(((NrHarts - 1) / 1024) >= 0 ? ((((NrHarts - 1) / 1024) + 1) * 32) - 1 : ((1 - ((NrHarts - 1) / 1024)) * 32) + ((((NrHarts - 1) / 1024) * 32) - 1)):(((NrHarts - 1) / 1024) >= 0 ? 0 : ((NrHarts - 1) / 1024) * 32)] halted_reshaped1;
	reg [(((NrHarts - 1) / 32768) >= 0 ? ((((NrHarts - 1) / 32768) + 1) * 32) - 1 : ((1 - ((NrHarts - 1) / 32768)) * 32) + ((((NrHarts - 1) / 32768) * 32) - 1)):(((NrHarts - 1) / 32768) >= 0 ? 0 : ((NrHarts - 1) / 32768) * 32)] halted_reshaped2;
	reg [((((NrHarts - 1) / 1024) + 1) * 32) - 1:0] halted_flat1;
	reg [((((NrHarts - 1) / 32768) + 1) * 32) - 1:0] halted_flat2;
	reg [31:0] halted_flat3;
	reg [14:0] hartsel_idx0;
	function automatic [14:0] sv2v_cast_15;
		input reg [14:0] inp;
		sv2v_cast_15 = inp;
	endfunction
	always @(*) begin : p_haltsum0
		if (_sv2v_0)
			;
		halted = 1'sb0;
		haltsum0 = 1'sb0;
		hartsel_idx0 = hartsel_o[19:5];
		halted[NrHarts - 1:0] = halted_i;
		halted_reshaped0 = halted;
		if (hartsel_idx0 < sv2v_cast_15(((NrHarts - 1) / 32) + 1))
			haltsum0 = halted_reshaped0[(((NrHarts - 1) / 32) >= 0 ? hartsel_idx0 : ((NrHarts - 1) / 32) - hartsel_idx0) * 32+:32];
	end
	reg [9:0] hartsel_idx1;
	function automatic [9:0] sv2v_cast_10;
		input reg [9:0] inp;
		sv2v_cast_10 = inp;
	endfunction
	always @(*) begin : p_reduction1
		if (_sv2v_0)
			;
		halted_flat1 = 1'sb0;
		haltsum1 = 1'sb0;
		hartsel_idx1 = hartsel_o[19:10];
		begin : sv2v_autoblock_1
			reg [31:0] k;
			for (k = 0; k < (((NrHarts - 1) / 32) + 1); k = k + 1)
				halted_flat1[k] = |halted_reshaped0[(((NrHarts - 1) / 32) >= 0 ? k : ((NrHarts - 1) / 32) - k) * 32+:32];
		end
		halted_reshaped1 = halted_flat1;
		if (hartsel_idx1 < sv2v_cast_10(((NrHarts - 1) / 1024) + 1))
			haltsum1 = halted_reshaped1[(((NrHarts - 1) / 1024) >= 0 ? hartsel_idx1 : ((NrHarts - 1) / 1024) - hartsel_idx1) * 32+:32];
	end
	reg [4:0] hartsel_idx2;
	function automatic [4:0] sv2v_cast_5;
		input reg [4:0] inp;
		sv2v_cast_5 = inp;
	endfunction
	always @(*) begin : p_reduction2
		if (_sv2v_0)
			;
		halted_flat2 = 1'sb0;
		haltsum2 = 1'sb0;
		hartsel_idx2 = hartsel_o[19:15];
		begin : sv2v_autoblock_2
			reg [31:0] k;
			for (k = 0; k < (((NrHarts - 1) / 1024) + 1); k = k + 1)
				halted_flat2[k] = |halted_reshaped1[(((NrHarts - 1) / 1024) >= 0 ? k : ((NrHarts - 1) / 1024) - k) * 32+:32];
		end
		halted_reshaped2 = halted_flat2;
		if (hartsel_idx2 < sv2v_cast_5(((NrHarts - 1) / 32768) + 1))
			haltsum2 = halted_reshaped2[(((NrHarts - 1) / 32768) >= 0 ? hartsel_idx2 : ((NrHarts - 1) / 32768) - hartsel_idx2) * 32+:32];
	end
	always @(*) begin : p_reduction3
		if (_sv2v_0)
			;
		halted_flat3 = 1'sb0;
		begin : sv2v_autoblock_3
			reg [31:0] k;
			for (k = 0; k < ((NrHarts / 32768) + 1); k = k + 1)
				halted_flat3[k] = |halted_reshaped2[(((NrHarts - 1) / 32768) >= 0 ? k : ((NrHarts - 1) / 32768) - k) * 32+:32];
		end
		haltsum3 = halted_flat3;
	end
	reg [31:0] dmstatus;
	reg [31:0] dmcontrol_d;
	reg [31:0] dmcontrol_q;
	reg [31:0] abstractcs;
	reg [2:0] cmderr_d;
	reg [2:0] cmderr_q;
	reg [31:0] command_d;
	reg [31:0] command_q;
	reg cmd_valid_d;
	reg cmd_valid_q;
	reg [31:0] abstractauto_d;
	reg [31:0] abstractauto_q;
	reg [31:0] sbcs_d;
	reg [31:0] sbcs_q;
	reg [63:0] sbaddr_d;
	reg [63:0] sbaddr_q;
	reg [63:0] sbdata_d;
	reg [63:0] sbdata_q;
	wire [NrHarts - 1:0] havereset_d;
	reg [NrHarts - 1:0] havereset_q;
	reg [255:0] progbuf_d;
	reg [255:0] progbuf_q;
	reg [63:0] data_d;
	reg [63:0] data_q;
	reg [HartSelLen - 1:0] selected_hart;
	reg [33:0] resp_queue_inp;
	assign sbautoincrement_o = sbcs_q[16];
	assign sbreadonaddr_o = sbcs_q[20];
	assign sbreadondata_o = sbcs_q[15];
	assign sbaccess_o = sbcs_q[19-:3];
	assign sbdata_o = sbdata_q[BusWidth - 1:0];
	assign sbaddress_o = sbaddr_q[BusWidth - 1:0];
	assign hartsel_o = {dmcontrol_q[15-:10], dmcontrol_q[25-:10]};
	reg [NrHartsAligned - 1:0] havereset_d_aligned;
	wire [NrHartsAligned - 1:0] havereset_q_aligned;
	wire [NrHartsAligned - 1:0] resumeack_aligned;
	wire [NrHartsAligned - 1:0] unavailable_aligned;
	wire [NrHartsAligned - 1:0] halted_aligned;
	function automatic [NrHartsAligned - 1:0] sv2v_cast_DFF07;
		input reg [NrHartsAligned - 1:0] inp;
		sv2v_cast_DFF07 = inp;
	endfunction
	assign resumeack_aligned = sv2v_cast_DFF07(resumeack_i);
	assign unavailable_aligned = sv2v_cast_DFF07(unavailable_i);
	assign halted_aligned = sv2v_cast_DFF07(halted_i);
	function automatic [NrHarts - 1:0] sv2v_cast_178F2;
		input reg [NrHarts - 1:0] inp;
		sv2v_cast_178F2 = inp;
	endfunction
	assign havereset_d = sv2v_cast_178F2(havereset_d_aligned);
	assign havereset_q_aligned = sv2v_cast_DFF07(havereset_q);
	reg [(NrHartsAligned * 32) - 1:0] hartinfo_aligned;
	always @(*) begin : p_hartinfo_align
		if (_sv2v_0)
			;
		hartinfo_aligned = 1'sb0;
		hartinfo_aligned[32 * ((NrHarts - 1) - (NrHarts - 1))+:32 * NrHarts] = hartinfo_i;
	end
	wire [7:0] dm_csr_addr;
	reg [31:0] sbcs;
	reg [31:0] a_abstractcs;
	wire [3:0] autoexecdata_idx;
	assign dm_csr_addr = sv2v_cast_8({1'b0, dmi_req_i[40-:7]});
	function automatic [3:0] sv2v_cast_4;
		input reg [3:0] inp;
		sv2v_cast_4 = inp;
	endfunction
	assign autoexecdata_idx = sv2v_cast_4({dm_csr_addr} - 8'h04);
	localparam [3:0] dm_DbgVersion013 = 4'h2;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	function automatic [63:0] sv2v_cast_64;
		input reg [63:0] inp;
		sv2v_cast_64 = inp;
	endfunction
	function automatic [$clog2(4'h2) - 1:0] sv2v_cast_68FD0;
		input reg [$clog2(4'h2) - 1:0] inp;
		sv2v_cast_68FD0 = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	function automatic [11:0] sv2v_cast_12;
		input reg [11:0] inp;
		sv2v_cast_12 = inp;
	endfunction
	function automatic [15:0] sv2v_cast_16;
		input reg [15:0] inp;
		sv2v_cast_16 = inp;
	endfunction
	function automatic [6:0] sv2v_cast_1B50F;
		input reg [6:0] inp;
		sv2v_cast_1B50F = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		(* xprop_off *)
		begin : csr_read_write
			dmstatus = 1'sb0;
			dmstatus[3-:4] = dm_DbgVersion013;
			dmstatus[7] = 1'b1;
			dmstatus[5] = 1'b0;
			dmstatus[19] = havereset_q_aligned[selected_hart];
			dmstatus[18] = havereset_q_aligned[selected_hart];
			dmstatus[17] = resumeack_aligned[selected_hart];
			dmstatus[16] = resumeack_aligned[selected_hart];
			dmstatus[13] = unavailable_aligned[selected_hart];
			dmstatus[12] = unavailable_aligned[selected_hart];
			dmstatus[15] = sv2v_cast_32(hartsel_o) > (NrHarts - 32'sd1);
			dmstatus[14] = sv2v_cast_32(hartsel_o) > (NrHarts - 32'sd1);
			dmstatus[9] = halted_aligned[selected_hart] & ~unavailable_aligned[selected_hart];
			dmstatus[8] = halted_aligned[selected_hart] & ~unavailable_aligned[selected_hart];
			dmstatus[11] = ~halted_aligned[selected_hart] & ~unavailable_aligned[selected_hart];
			dmstatus[10] = ~halted_aligned[selected_hart] & ~unavailable_aligned[selected_hart];
			abstractcs = 1'sb0;
			abstractcs[3-:4] = dm_DataCount;
			abstractcs[28-:5] = dm_ProgBufSize;
			abstractcs[12] = cmdbusy_i;
			abstractcs[10-:3] = cmderr_q;
			abstractauto_d = abstractauto_q;
			abstractauto_d[15-:4] = 1'sb0;
			havereset_d_aligned = sv2v_cast_DFF07(havereset_q);
			dmcontrol_d = dmcontrol_q;
			cmderr_d = cmderr_q;
			command_d = command_q;
			progbuf_d = progbuf_q;
			data_d = data_q;
			sbcs_d = sbcs_q;
			sbaddr_d = sv2v_cast_64(sbaddress_i);
			sbdata_d = sbdata_q;
			resp_queue_inp[33-:32] = 32'h00000000;
			resp_queue_inp[1-:2] = 2'h0;
			cmd_valid_d = 1'b0;
			sbaddress_write_valid_o = 1'b0;
			sbdata_read_valid_o = 1'b0;
			sbdata_write_valid_o = 1'b0;
			clear_resumeack_o = 1'b0;
			sbcs = 1'sb0;
			a_abstractcs = 1'sb0;
			if ((dmi_req_ready_o && dmi_req_valid_i) && (dtm_op == 2'h1)) begin
				(* full_case, parallel_case *)
				if ((8'h04 <= dm_csr_addr) && (DataEnd >= dm_csr_addr)) begin
					resp_queue_inp[33-:32] = data_q[sv2v_cast_68FD0(autoexecdata_idx) * 32+:32];
					if (!cmdbusy_i)
						cmd_valid_d = abstractauto_q[0 + autoexecdata_idx];
					else begin
						resp_queue_inp[1-:2] = 2'h3;
						if (cmderr_q == 3'd0)
							cmderr_d = 3'd1;
					end
				end
				else if (dm_csr_addr == 8'h10)
					resp_queue_inp[33-:32] = dmcontrol_q;
				else if (dm_csr_addr == 8'h11)
					resp_queue_inp[33-:32] = dmstatus;
				else if (dm_csr_addr == 8'h12)
					resp_queue_inp[33-:32] = hartinfo_aligned[selected_hart * 32+:32];
				else if (dm_csr_addr == 8'h16)
					resp_queue_inp[33-:32] = abstractcs;
				else if (dm_csr_addr == 8'h18)
					resp_queue_inp[33-:32] = abstractauto_q;
				else if (dm_csr_addr == 8'h17)
					resp_queue_inp[33-:32] = 1'sb0;
				else if ((8'h20 <= dm_csr_addr) && (ProgBufEnd >= dm_csr_addr)) begin
					resp_queue_inp[33-:32] = progbuf_q[dmi_req_i[$clog2(5'h08) + 33:34] * 32+:32];
					if (!cmdbusy_i)
						cmd_valid_d = abstractauto_q[0 + {1'b1, dmi_req_i[37:34]}];
					else begin
						resp_queue_inp[1-:2] = 2'h3;
						if (cmderr_q == 3'd0)
							cmderr_d = 3'd1;
					end
				end
				else if (dm_csr_addr == 8'h40)
					resp_queue_inp[33-:32] = haltsum0;
				else if (dm_csr_addr == 8'h13)
					resp_queue_inp[33-:32] = haltsum1;
				else if (dm_csr_addr == 8'h34)
					resp_queue_inp[33-:32] = haltsum2;
				else if (dm_csr_addr == 8'h35)
					resp_queue_inp[33-:32] = haltsum3;
				else if (dm_csr_addr == 8'h38)
					resp_queue_inp[33-:32] = sbcs_q;
				else if (dm_csr_addr == 8'h39)
					resp_queue_inp[33-:32] = sbaddr_q[31:0];
				else if (dm_csr_addr == 8'h3a)
					resp_queue_inp[33-:32] = sbaddr_q[63:32];
				else if (dm_csr_addr == 8'h3c) begin
					if (sbbusy_i || sbcs_q[22]) begin
						sbcs_d[22] = 1'b1;
						resp_queue_inp[1-:2] = 2'h3;
					end
					else begin
						sbdata_read_valid_o = sbcs_q[14-:3] == {3 {1'sb0}};
						resp_queue_inp[33-:32] = sbdata_q[31:0];
					end
				end
				else if (dm_csr_addr == 8'h3d) begin
					if (sbbusy_i || sbcs_q[22]) begin
						sbcs_d[22] = 1'b1;
						resp_queue_inp[1-:2] = 2'h3;
					end
					else
						resp_queue_inp[33-:32] = sbdata_q[63:32];
				end
			end
			if ((dmi_req_ready_o && dmi_req_valid_i) && (dtm_op == 2'h2)) begin
				(* full_case, parallel_case *)
				if ((8'h04 <= dm_csr_addr) && (DataEnd >= dm_csr_addr)) begin
					if (!cmdbusy_i) begin
						data_d[dmi_req_i[$clog2(4'h2) + 33:34] * 32+:32] = dmi_req_i[31-:32];
						cmd_valid_d = abstractauto_q[0 + autoexecdata_idx];
					end
					else begin
						resp_queue_inp[1-:2] = 2'h3;
						if (cmderr_q == 3'd0)
							cmderr_d = 3'd1;
					end
				end
				else if (dm_csr_addr == 8'h10) begin
					dmcontrol_d = dmi_req_i[31-:32];
					if (dmcontrol_d[28])
						havereset_d_aligned[selected_hart] = 1'b0;
				end
				else if (dm_csr_addr == 8'h11)
					;
				else if (dm_csr_addr == 8'h12)
					;
				else if (dm_csr_addr == 8'h16) begin
					a_abstractcs = sv2v_cast_32(dmi_req_i[31-:32]);
					if (!cmdbusy_i)
						cmderr_d = sv2v_cast_3(~a_abstractcs[10-:3] & cmderr_q);
					else begin
						resp_queue_inp[1-:2] = 2'h3;
						if (cmderr_q == 3'd0)
							cmderr_d = 3'd1;
					end
				end
				else if (dm_csr_addr == 8'h17) begin
					if (!cmdbusy_i) begin
						cmd_valid_d = 1'b1;
						command_d = sv2v_cast_32(dmi_req_i[31-:32]);
					end
					else begin
						resp_queue_inp[1-:2] = 2'h3;
						if (cmderr_q == 3'd0)
							cmderr_d = 3'd1;
					end
				end
				else if (dm_csr_addr == 8'h18) begin
					if (!cmdbusy_i) begin
						abstractauto_d = 32'h00000000;
						abstractauto_d[11-:12] = sv2v_cast_12(dmi_req_i[1:0]);
						abstractauto_d[31-:16] = sv2v_cast_16(dmi_req_i[23:16]);
					end
					else begin
						resp_queue_inp[1-:2] = 2'h3;
						if (cmderr_q == 3'd0)
							cmderr_d = 3'd1;
					end
				end
				else if ((8'h20 <= dm_csr_addr) && (ProgBufEnd >= dm_csr_addr)) begin
					if (!cmdbusy_i) begin
						progbuf_d[dmi_req_i[$clog2(5'h08) + 33:34] * 32+:32] = dmi_req_i[31-:32];
						cmd_valid_d = abstractauto_q[0 + {1'b1, dmi_req_i[37:34]}];
					end
					else begin
						resp_queue_inp[1-:2] = 2'h3;
						if (cmderr_q == 3'd0)
							cmderr_d = 3'd1;
					end
				end
				else if (dm_csr_addr == 8'h38) begin
					if (sbbusy_i) begin
						sbcs_d[22] = 1'b1;
						resp_queue_inp[1-:2] = 2'h3;
					end
					else begin
						sbcs = sv2v_cast_32(dmi_req_i[31-:32]);
						sbcs_d = sbcs;
						sbcs_d[22] = sbcs_q[22] & ~sbcs[22];
						sbcs_d[14-:3] = (|sbcs[14-:3] ? 3'b000 : sbcs_q[14-:3]);
					end
				end
				else if (dm_csr_addr == 8'h39) begin
					if (sbbusy_i || sbcs_q[22]) begin
						sbcs_d[22] = 1'b1;
						resp_queue_inp[1-:2] = 2'h3;
					end
					else begin
						sbaddr_d[31:0] = dmi_req_i[31-:32];
						sbaddress_write_valid_o = sbcs_q[14-:3] == {3 {1'sb0}};
					end
				end
				else if (dm_csr_addr == 8'h3a) begin
					if (sbbusy_i || sbcs_q[22]) begin
						sbcs_d[22] = 1'b1;
						resp_queue_inp[1-:2] = 2'h3;
					end
					else
						sbaddr_d[63:32] = dmi_req_i[31-:32];
				end
				else if (dm_csr_addr == 8'h3c) begin
					if (sbbusy_i || sbcs_q[22]) begin
						sbcs_d[22] = 1'b1;
						resp_queue_inp[1-:2] = 2'h3;
					end
					else begin
						sbdata_d[31:0] = dmi_req_i[31-:32];
						sbdata_write_valid_o = sbcs_q[14-:3] == {3 {1'sb0}};
					end
				end
				else if (dm_csr_addr == 8'h3d) begin
					if (sbbusy_i || sbcs_q[22]) begin
						sbcs_d[22] = 1'b1;
						resp_queue_inp[1-:2] = 2'h3;
					end
					else
						sbdata_d[63:32] = dmi_req_i[31-:32];
				end
			end
			if (cmderror_valid_i)
				cmderr_d = cmderror_i;
			if (data_valid_i)
				data_d = data_i;
			if (ndmreset_o)
				havereset_d_aligned[NrHarts - 1:0] = 1'sb1;
			if (sberror_valid_i)
				sbcs_d[14-:3] = sberror_i;
			if (sbdata_valid_i)
				sbdata_d = sv2v_cast_64(sbdata_i);
			dmcontrol_d[26] = 1'b0;
			dmcontrol_d[29] = 1'b0;
			dmcontrol_d[3] = 1'b0;
			dmcontrol_d[2] = 1'b0;
			dmcontrol_d[27] = 1'sb0;
			dmcontrol_d[5-:2] = 1'sb0;
			dmcontrol_d[28] = 1'b0;
			if (!dmcontrol_q[30] && dmcontrol_d[30])
				clear_resumeack_o = 1'b1;
			if (dmcontrol_q[30] && resumeack_i)
				dmcontrol_d[30] = 1'b0;
			sbcs_d[31-:3] = 3'd1;
			sbcs_d[21] = sbbusy_i;
			sbcs_d[11-:7] = sv2v_cast_1B50F(BusWidth);
			sbcs_d[4] = BusWidth >= 32'd128;
			sbcs_d[3] = BusWidth >= 32'd64;
			sbcs_d[2] = BusWidth >= 32'd32;
			sbcs_d[1] = BusWidth >= 32'd16;
			sbcs_d[0] = BusWidth >= 32'd8;
		end
	end
	function automatic [HartSelLen - 1:0] sv2v_cast_FFD0D;
		input reg [HartSelLen - 1:0] inp;
		sv2v_cast_FFD0D = inp;
	endfunction
	always @(*) begin : p_outmux
		if (_sv2v_0)
			;
		selected_hart = hartsel_o[HartSelLen - 1:0];
		haltreq_o = 1'sb0;
		resumereq_o = 1'sb0;
		if (selected_hart <= sv2v_cast_FFD0D(NrHarts - 1)) begin
			haltreq_o[selected_hart] = dmcontrol_q[31];
			resumereq_o[selected_hart] = dmcontrol_q[30];
		end
	end
	assign dmactive_o = dmcontrol_q[0];
	assign cmd_o = command_q;
	assign cmd_valid_o = cmd_valid_q;
	assign progbuf_o = progbuf_q;
	assign data_o = data_q;
	assign ndmreset_o = dmcontrol_q[1];
	wire unused_testmode;
	assign unused_testmode = testmode_i;
	prim_fifo_sync #(
		.Width(34),
		.Pass(1'b0),
		.Depth(2)
	) i_fifo(
		.clk_i(clk_i),
		.rst_ni(dmi_rst_ni),
		.clr_i(1'b0),
		.wdata_i(resp_queue_inp),
		.wvalid_i(dmi_req_valid_i),
		.wready_o(dmi_req_ready_o),
		.rdata_o(dmi_resp_o),
		.rvalid_o(dmi_resp_valid_o),
		.rready_i(dmi_resp_ready_i),
		.full_o(),
		.depth_o(),
		.err_o()
	);
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			dmcontrol_q <= 1'sb0;
			cmderr_q <= 3'd0;
			command_q <= 1'sb0;
			cmd_valid_q <= 1'sb0;
			abstractauto_q <= 1'sb0;
			progbuf_q <= 1'sb0;
			data_q <= 1'sb0;
			sbcs_q <= 32'h00040000;
			sbaddr_q <= 1'sb0;
			sbdata_q <= 1'sb0;
			havereset_q <= 1'sb1;
		end
		else begin
			havereset_q <= SelectableHarts & havereset_d;
			if (!dmcontrol_q[0]) begin
				dmcontrol_q[31] <= 1'sb0;
				dmcontrol_q[30] <= 1'sb0;
				dmcontrol_q[29] <= 1'sb0;
				dmcontrol_q[28] <= 1'sb0;
				dmcontrol_q[27] <= 1'sb0;
				dmcontrol_q[26] <= 1'sb0;
				dmcontrol_q[25-:10] <= 1'sb0;
				dmcontrol_q[15-:10] <= 1'sb0;
				dmcontrol_q[5-:2] <= 1'sb0;
				dmcontrol_q[3] <= 1'sb0;
				dmcontrol_q[2] <= 1'sb0;
				dmcontrol_q[1] <= 1'sb0;
				dmcontrol_q[0] <= dmcontrol_d[0];
				cmderr_q <= 3'd0;
				command_q <= 1'sb0;
				cmd_valid_q <= 1'sb0;
				abstractauto_q <= 1'sb0;
				progbuf_q <= 1'sb0;
				data_q <= 1'sb0;
				sbcs_q <= 32'h00040000;
				sbaddr_q <= 1'sb0;
				sbdata_q <= 1'sb0;
			end
			else begin
				dmcontrol_q <= dmcontrol_d;
				cmderr_q <= cmderr_d;
				command_q <= command_d;
				cmd_valid_q <= cmd_valid_d;
				abstractauto_q <= abstractauto_d;
				progbuf_q <= progbuf_d;
				data_q <= data_d;
				sbcs_q <= sbcs_d;
				sbaddr_q <= sbaddr_d;
				sbdata_q <= sbdata_d;
			end
		end
	end
	initial _sv2v_0 = 0;
endmodule
module dm_mem (
	clk_i,
	rst_ni,
	debug_req_o,
	ndmreset_i,
	hartsel_i,
	haltreq_i,
	resumereq_i,
	clear_resumeack_i,
	halted_o,
	resuming_o,
	progbuf_i,
	data_i,
	data_o,
	data_valid_o,
	cmd_valid_i,
	cmd_i,
	cmderror_valid_o,
	cmderror_o,
	cmdbusy_o,
	req_i,
	we_i,
	addr_i,
	wdata_i,
	be_i,
	rdata_o
);
	reg _sv2v_0;
	parameter [31:0] NrHarts = 1;
	parameter [31:0] BusWidth = 32;
	parameter [NrHarts - 1:0] SelectableHarts = {NrHarts {1'b1}};
	parameter [31:0] DmBaseAddress = 1'sb0;
	input wire clk_i;
	input wire rst_ni;
	output wire [NrHarts - 1:0] debug_req_o;
	input wire ndmreset_i;
	input wire [19:0] hartsel_i;
	input wire [NrHarts - 1:0] haltreq_i;
	input wire [NrHarts - 1:0] resumereq_i;
	input wire clear_resumeack_i;
	output wire [NrHarts - 1:0] halted_o;
	output wire [NrHarts - 1:0] resuming_o;
	localparam [4:0] dm_ProgBufSize = 5'h08;
	input wire [255:0] progbuf_i;
	localparam [3:0] dm_DataCount = 4'h2;
	input wire [63:0] data_i;
	output reg [63:0] data_o;
	output reg data_valid_o;
	input wire cmd_valid_i;
	input wire [31:0] cmd_i;
	output reg cmderror_valid_o;
	output reg [2:0] cmderror_o;
	output reg cmdbusy_o;
	input wire req_i;
	input wire we_i;
	input wire [BusWidth - 1:0] addr_i;
	input wire [BusWidth - 1:0] wdata_i;
	input wire [(BusWidth / 8) - 1:0] be_i;
	output wire [BusWidth - 1:0] rdata_o;
	localparam [31:0] DbgAddressBits = 12;
	localparam [31:0] HartSelLen = (NrHarts == 1 ? 1 : $clog2(NrHarts));
	localparam [31:0] NrHartsAligned = 2 ** HartSelLen;
	localparam [31:0] MaxAar = (BusWidth == 64 ? 4 : 3);
	localparam [0:0] HasSndScratch = DmBaseAddress != 0;
	localparam [4:0] LoadBaseAddr = (DmBaseAddress == 0 ? 5'd0 : 5'd10);
	localparam [11:0] dm_DataAddr = 12'h380;
	localparam [11:0] DataBaseAddr = dm_DataAddr;
	localparam [11:0] DataEndAddr = 903;
	localparam [11:0] ProgBufBaseAddr = 864;
	localparam [11:0] ProgBufEndAddr = 895;
	localparam [11:0] AbstractCmdBaseAddr = ProgBufBaseAddr - 40;
	localparam [11:0] AbstractCmdEndAddr = ProgBufBaseAddr - 1;
	localparam [11:0] WhereToAddr = 'h300;
	localparam [11:0] FlagsBaseAddr = 'h400;
	localparam [11:0] FlagsEndAddr = 'h7ff;
	localparam [11:0] HaltedAddr = 'h100;
	localparam [11:0] GoingAddr = 'h108;
	localparam [11:0] ResumingAddr = 'h110;
	localparam [11:0] ExceptionAddr = 'h118;
	wire [255:0] progbuf;
	reg [511:0] abstract_cmd;
	wire [NrHarts - 1:0] halted_d;
	reg [NrHarts - 1:0] halted_q;
	wire [NrHarts - 1:0] resuming_d;
	reg [NrHarts - 1:0] resuming_q;
	reg resume;
	reg go;
	reg going;
	reg exception;
	reg unsupported_command;
	wire [63:0] rom_rdata;
	reg [63:0] rdata_d;
	reg [63:0] rdata_q;
	reg word_enable32_q;
	wire [HartSelLen - 1:0] hartsel;
	wire [HartSelLen - 1:0] wdata_hartsel;
	assign hartsel = hartsel_i[HartSelLen - 1:0];
	assign wdata_hartsel = wdata_i[HartSelLen - 1:0];
	wire [NrHartsAligned - 1:0] resumereq_aligned;
	wire [NrHartsAligned - 1:0] haltreq_aligned;
	reg [NrHartsAligned - 1:0] halted_d_aligned;
	wire [NrHartsAligned - 1:0] halted_q_aligned;
	reg [NrHartsAligned - 1:0] halted_aligned;
	wire [NrHartsAligned - 1:0] resumereq_wdata_aligned;
	reg [NrHartsAligned - 1:0] resuming_d_aligned;
	wire [NrHartsAligned - 1:0] resuming_q_aligned;
	function automatic [NrHartsAligned - 1:0] sv2v_cast_DFF07;
		input reg [NrHartsAligned - 1:0] inp;
		sv2v_cast_DFF07 = inp;
	endfunction
	assign resumereq_aligned = sv2v_cast_DFF07(resumereq_i);
	assign haltreq_aligned = sv2v_cast_DFF07(haltreq_i);
	assign resumereq_wdata_aligned = sv2v_cast_DFF07(resumereq_i);
	assign halted_q_aligned = sv2v_cast_DFF07(halted_q);
	function automatic [NrHarts - 1:0] sv2v_cast_178F2;
		input reg [NrHarts - 1:0] inp;
		sv2v_cast_178F2 = inp;
	endfunction
	assign halted_d = sv2v_cast_178F2(halted_d_aligned);
	assign resuming_q_aligned = sv2v_cast_DFF07(resuming_q);
	assign resuming_d = sv2v_cast_178F2(resuming_d_aligned);
	wire fwd_rom_d;
	reg fwd_rom_q;
	wire [23:0] ac_ar;
	function automatic [23:0] sv2v_cast_24;
		input reg [23:0] inp;
		sv2v_cast_24 = inp;
	endfunction
	assign ac_ar = sv2v_cast_24(cmd_i[23-:24]);
	assign debug_req_o = haltreq_i;
	assign halted_o = halted_q;
	assign resuming_o = resuming_q;
	assign progbuf = progbuf_i;
	reg [1:0] state_d;
	reg [1:0] state_q;
	always @(*) begin : p_hart_ctrl_queue
		if (_sv2v_0)
			;
		cmderror_valid_o = 1'b0;
		cmderror_o = 3'd0;
		state_d = state_q;
		go = 1'b0;
		resume = 1'b0;
		cmdbusy_o = 1'b1;
		(* full_case, parallel_case *)
		case (state_q)
			2'd0: begin
				cmdbusy_o = 1'b0;
				if ((cmd_valid_i && halted_q_aligned[hartsel]) && !unsupported_command)
					state_d = 2'd1;
				else if (cmd_valid_i) begin
					cmderror_valid_o = 1'b1;
					cmderror_o = 3'd4;
				end
				if (((resumereq_aligned[hartsel] && !resuming_q_aligned[hartsel]) && !haltreq_aligned[hartsel]) && halted_q_aligned[hartsel])
					state_d = 2'd2;
			end
			2'd1: begin
				cmdbusy_o = 1'b1;
				go = 1'b1;
				if (going)
					state_d = 2'd3;
			end
			2'd2: begin
				cmdbusy_o = 1'b1;
				resume = 1'b1;
				if (resuming_q_aligned[hartsel])
					state_d = 2'd0;
			end
			2'd3: begin
				cmdbusy_o = 1'b1;
				go = 1'b0;
				if (halted_aligned[hartsel])
					state_d = 2'd0;
			end
			default:
				;
		endcase
		if (unsupported_command && cmd_valid_i) begin
			cmderror_valid_o = 1'b1;
			cmderror_o = 3'd2;
		end
		if (exception) begin
			cmderror_valid_o = 1'b1;
			cmderror_o = 3'd3;
		end
		if (ndmreset_i) begin
			state_d = 2'd0;
			go = 1'b0;
			resume = 1'b0;
		end
	end
	wire [63:0] word_mux;
	assign word_mux = (fwd_rom_q ? rom_rdata : rdata_q);
	generate
		if (BusWidth == 64) begin : gen_word_mux64
			assign rdata_o = word_mux;
		end
		else begin : gen_word_mux32
			assign rdata_o = (word_enable32_q ? word_mux[32+:32] : word_mux[0+:32]);
		end
	endgenerate
	reg [63:0] data_bits;
	reg [63:0] rdata;
	localparam [63:0] dm_HaltAddress = 64'h0000000000000800;
	localparam [63:0] dm_ResumeAddress = 2056;
	function automatic [31:0] dm_jal;
		input reg [4:0] rd;
		input reg [20:0] imm;
		dm_jal = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h6f};
	endfunction
	function automatic [20:0] sv2v_cast_21;
		input reg [20:0] inp;
		sv2v_cast_21 = inp;
	endfunction
	function automatic [$clog2(4'h2) - 1:0] sv2v_cast_68FD0;
		input reg [$clog2(4'h2) - 1:0] inp;
		sv2v_cast_68FD0 = inp;
	endfunction
	function automatic [$clog2(5'h08) - 1:0] sv2v_cast_63A1A;
		input reg [$clog2(5'h08) - 1:0] inp;
		sv2v_cast_63A1A = inp;
	endfunction
	function automatic [2:0] sv2v_cast_3;
		input reg [2:0] inp;
		sv2v_cast_3 = inp;
	endfunction
	function automatic [11:0] sv2v_cast_C1AAB;
		input reg [11:0] inp;
		sv2v_cast_C1AAB = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		(* xprop_off *)
		begin : p_rw_logic
			halted_d_aligned = sv2v_cast_DFF07(halted_q);
			resuming_d_aligned = sv2v_cast_DFF07(resuming_q);
			rdata_d = rdata_q;
			data_bits = data_i;
			rdata = 1'sb0;
			data_valid_o = 1'b0;
			exception = 1'b0;
			halted_aligned = 1'sb0;
			going = 1'b0;
			if (clear_resumeack_i)
				resuming_d_aligned[hartsel] = 1'b0;
			if (req_i) begin
				if (we_i) begin
					(* full_case, parallel_case *)
					if (addr_i[11:0] == HaltedAddr) begin
						halted_aligned[wdata_hartsel] = 1'b1;
						halted_d_aligned[wdata_hartsel] = 1'b1;
					end
					else if (addr_i[11:0] == GoingAddr)
						going = 1'b1;
					else if (addr_i[11:0] == ResumingAddr) begin
						halted_d_aligned[wdata_hartsel] = 1'b0;
						resuming_d_aligned[wdata_hartsel] = 1'b1;
					end
					else if (addr_i[11:0] == ExceptionAddr)
						exception = 1'b1;
					else if ((DataBaseAddr <= addr_i[11:0]) && (DataEndAddr >= addr_i[11:0])) begin
						data_valid_o = 1'b1;
						begin : sv2v_autoblock_1
							reg signed [31:0] dc;
							for (dc = 0; dc < dm_DataCount; dc = dc + 1)
								if ((addr_i[11:2] - DataBaseAddr[11:2]) == dc) begin : sv2v_autoblock_2
									reg signed [31:0] i;
									for (i = 0; i < (BusWidth / 8); i = i + 1)
										if (be_i[i]) begin
											if (i > 3) begin
												if ((dc + 1) < dm_DataCount)
													data_bits[((dc + 1) * 32) + ((i - 4) * 8)+:8] = wdata_i[i * 8+:8];
											end
											else
												data_bits[(dc * 32) + (i * 8)+:8] = wdata_i[i * 8+:8];
										end
								end
						end
					end
				end
				else
					(* full_case, parallel_case *)
					if (addr_i[11:0] == WhereToAddr) begin
						if (resumereq_wdata_aligned[wdata_hartsel])
							rdata_d = {32'b00000000000000000000000000000000, dm_jal(1'sb0, sv2v_cast_21(dm_ResumeAddress[11:0]) - sv2v_cast_21(WhereToAddr))};
						if (cmdbusy_o) begin
							if (((cmd_i[31-:8] == 8'h00) && !ac_ar[17]) && ac_ar[18])
								rdata_d = {32'b00000000000000000000000000000000, dm_jal(1'sb0, sv2v_cast_21(ProgBufBaseAddr) - sv2v_cast_21(WhereToAddr))};
							else
								rdata_d = {32'b00000000000000000000000000000000, dm_jal(1'sb0, sv2v_cast_21(AbstractCmdBaseAddr) - sv2v_cast_21(WhereToAddr))};
						end
					end
					else if ((DataBaseAddr <= addr_i[11:0]) && (DataEndAddr >= addr_i[11:0]))
						rdata_d = {data_i[sv2v_cast_68FD0(((addr_i[11:3] - DataBaseAddr[11:3]) << 1) + 1'b1) * 32+:32], data_i[sv2v_cast_68FD0((addr_i[11:3] - DataBaseAddr[11:3]) << 1) * 32+:32]};
					else if ((ProgBufBaseAddr <= addr_i[11:0]) && (ProgBufEndAddr >= addr_i[11:0]))
						rdata_d = progbuf[sv2v_cast_63A1A(addr_i[11:3] - ProgBufBaseAddr[11:3]) * 64+:64];
					else if ((AbstractCmdBaseAddr <= addr_i[11:0]) && (AbstractCmdEndAddr >= addr_i[11:0]))
						rdata_d = abstract_cmd[sv2v_cast_3(addr_i[11:3] - AbstractCmdBaseAddr[11:3]) * 64+:64];
					else if ((FlagsBaseAddr <= addr_i[11:0]) && (FlagsEndAddr >= addr_i[11:0])) begin
						if (({addr_i[11:3], 3'b000} - FlagsBaseAddr[11:0]) == (sv2v_cast_C1AAB(hartsel) & {{9 {1'b1}}, 3'b000}))
							rdata[(sv2v_cast_C1AAB(hartsel) & sv2v_cast_C1AAB(3'b111)) * 8+:8] = {6'b000000, resume, go};
						rdata_d = rdata;
					end
			end
			if (ndmreset_i) begin
				halted_d_aligned = 1'sb0;
				resuming_d_aligned = 1'sb0;
			end
			data_o = data_bits;
		end
	end
	function automatic [31:0] dm_auipc;
		input reg [4:0] rd;
		input reg [20:0] imm;
		dm_auipc = {imm[20], imm[10:1], imm[11], imm[19:12], rd, 7'h17};
	endfunction
	function automatic [31:0] dm_csrr;
		input reg [11:0] csr;
		input reg [4:0] dest;
		dm_csrr = {csr, 8'h02, dest, 7'h73};
	endfunction
	function automatic [31:0] dm_csrw;
		input reg [11:0] csr;
		input reg [4:0] rs1;
		dm_csrw = {csr, rs1, 15'h1073};
	endfunction
	function automatic [31:0] dm_ebreak;
		input reg _sv2v_unused;
		dm_ebreak = 32'h00100073;
	endfunction
	function automatic [31:0] dm_float_load;
		input reg [2:0] size;
		input reg [4:0] dest;
		input reg [4:0] base;
		input reg [11:0] offset;
		dm_float_load = {offset[11:0], base, size, dest, 7'b0000111};
	endfunction
	function automatic [31:0] dm_float_store;
		input reg [2:0] size;
		input reg [4:0] src;
		input reg [4:0] base;
		input reg [11:0] offset;
		dm_float_store = {offset[11:5], src, base, size, offset[4:0], 7'b0100111};
	endfunction
	function automatic [31:0] dm_illegal;
		input reg _sv2v_unused;
		dm_illegal = 32'h00000000;
	endfunction
	function automatic [31:0] dm_load;
		input reg [2:0] size;
		input reg [4:0] dest;
		input reg [4:0] base;
		input reg [11:0] offset;
		dm_load = {offset[11:0], base, size, dest, 7'h03};
	endfunction
	function automatic [31:0] dm_nop;
		input reg _sv2v_unused;
		dm_nop = 32'h00000013;
	endfunction
	function automatic [31:0] dm_slli;
		input reg [4:0] rd;
		input reg [4:0] rs1;
		input reg [5:0] shamt;
		dm_slli = {6'b000000, shamt[5:0], rs1, 3'h1, rd, 7'h13};
	endfunction
	function automatic [31:0] dm_srli;
		input reg [4:0] rd;
		input reg [4:0] rs1;
		input reg [5:0] shamt;
		dm_srli = {6'b000000, shamt[5:0], rs1, 3'h5, rd, 7'h13};
	endfunction
	function automatic [31:0] dm_store;
		input reg [2:0] size;
		input reg [4:0] src;
		input reg [4:0] base;
		input reg [11:0] offset;
		dm_store = {offset[11:5], src, base, size, offset[4:0], 7'h23};
	endfunction
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(*) begin : p_abstract_cmd_rom
		if (_sv2v_0)
			;
		unsupported_command = 1'b0;
		abstract_cmd[31-:32] = dm_illegal(0);
		abstract_cmd[63-:32] = (HasSndScratch ? dm_auipc(5'd10, 1'sb0) : dm_nop(0));
		abstract_cmd[95-:32] = (HasSndScratch ? dm_srli(5'd10, 5'd10, 6'd12) : dm_nop(0));
		abstract_cmd[127-:32] = (HasSndScratch ? dm_slli(5'd10, 5'd10, 6'd12) : dm_nop(0));
		abstract_cmd[159-:32] = dm_nop(0);
		abstract_cmd[191-:32] = dm_nop(0);
		abstract_cmd[223-:32] = dm_nop(0);
		abstract_cmd[255-:32] = dm_nop(0);
		abstract_cmd[287-:32] = (HasSndScratch ? dm_csrr(12'h7b3, 5'd10) : dm_nop(0));
		abstract_cmd[319-:32] = dm_ebreak(0);
		abstract_cmd[320+:192] = 1'sb0;
		(* full_case, parallel_case *)
		case (cmd_i[31-:8])
			8'h00: begin
				if (((sv2v_cast_32(ac_ar[22-:3]) < MaxAar) && ac_ar[17]) && ac_ar[16]) begin
					abstract_cmd[31-:32] = (HasSndScratch ? dm_csrw(12'h7b3, 5'd10) : dm_nop(0));
					if (ac_ar[15:14] != {2 {1'sb0}}) begin
						abstract_cmd[31-:32] = dm_ebreak(0);
						unsupported_command = 1'b1;
					end
					else if (((HasSndScratch && ac_ar[12]) && !ac_ar[5]) && (ac_ar[4:0] == 5'd10)) begin
						abstract_cmd[159-:32] = dm_csrw(12'h7b2, 5'd8);
						abstract_cmd[191-:32] = dm_load(ac_ar[22-:3], 5'd8, LoadBaseAddr, dm_DataAddr);
						abstract_cmd[223-:32] = dm_csrw(12'h7b3, 5'd8);
						abstract_cmd[255-:32] = dm_csrr(12'h7b2, 5'd8);
					end
					else if (ac_ar[12]) begin
						if (ac_ar[5])
							abstract_cmd[159-:32] = dm_float_load(ac_ar[22-:3], ac_ar[4:0], LoadBaseAddr, dm_DataAddr);
						else
							abstract_cmd[159-:32] = dm_load(ac_ar[22-:3], ac_ar[4:0], LoadBaseAddr, dm_DataAddr);
					end
					else begin
						abstract_cmd[159-:32] = dm_csrw(12'h7b2, 5'd8);
						abstract_cmd[191-:32] = dm_load(ac_ar[22-:3], 5'd8, LoadBaseAddr, dm_DataAddr);
						abstract_cmd[223-:32] = dm_csrw(ac_ar[11:0], 5'd8);
						abstract_cmd[255-:32] = dm_csrr(12'h7b2, 5'd8);
					end
				end
				else if (((sv2v_cast_32(ac_ar[22-:3]) < MaxAar) && ac_ar[17]) && !ac_ar[16]) begin
					abstract_cmd[31-:32] = (HasSndScratch ? dm_csrw(12'h7b3, LoadBaseAddr) : dm_nop(0));
					if (ac_ar[15:14] != {2 {1'sb0}}) begin
						abstract_cmd[31-:32] = dm_ebreak(0);
						unsupported_command = 1'b1;
					end
					else if (((HasSndScratch && ac_ar[12]) && !ac_ar[5]) && (ac_ar[4:0] == 5'd10)) begin
						abstract_cmd[159-:32] = dm_csrw(12'h7b2, 5'd8);
						abstract_cmd[191-:32] = dm_csrr(12'h7b3, 5'd8);
						abstract_cmd[223-:32] = dm_store(ac_ar[22-:3], 5'd8, LoadBaseAddr, dm_DataAddr);
						abstract_cmd[255-:32] = dm_csrr(12'h7b2, 5'd8);
					end
					else if (ac_ar[12]) begin
						if (ac_ar[5])
							abstract_cmd[159-:32] = dm_float_store(ac_ar[22-:3], ac_ar[4:0], LoadBaseAddr, dm_DataAddr);
						else
							abstract_cmd[159-:32] = dm_store(ac_ar[22-:3], ac_ar[4:0], LoadBaseAddr, dm_DataAddr);
					end
					else begin
						abstract_cmd[159-:32] = dm_csrw(12'h7b2, 5'd8);
						abstract_cmd[191-:32] = dm_csrr(ac_ar[11:0], 5'd8);
						abstract_cmd[223-:32] = dm_store(ac_ar[22-:3], 5'd8, LoadBaseAddr, dm_DataAddr);
						abstract_cmd[255-:32] = dm_csrr(12'h7b2, 5'd8);
					end
				end
				else if ((sv2v_cast_32(ac_ar[22-:3]) >= MaxAar) || (ac_ar[19] == 1'b1)) begin
					abstract_cmd[31-:32] = dm_ebreak(0);
					unsupported_command = 1'b1;
				end
				if (ac_ar[18] && !unsupported_command)
					abstract_cmd[319-:32] = dm_nop(0);
			end
			default: begin
				abstract_cmd[31-:32] = dm_ebreak(0);
				unsupported_command = 1'b1;
			end
		endcase
	end
	wire [63:0] rom_addr;
	function automatic [63:0] sv2v_cast_64;
		input reg [63:0] inp;
		sv2v_cast_64 = inp;
	endfunction
	assign rom_addr = sv2v_cast_64(addr_i);
	generate
		if (HasSndScratch) begin : gen_rom_snd_scratch
			debug_rom i_debug_rom(
				.clk_i(clk_i),
				.req_i(req_i),
				.addr_i(rom_addr),
				.rdata_o(rom_rdata)
			);
		end
		else begin : gen_rom_one_scratch
			debug_rom_one_scratch i_debug_rom(
				.clk_i(clk_i),
				.req_i(req_i),
				.addr_i(rom_addr),
				.rdata_o(rom_rdata)
			);
		end
	endgenerate
	assign fwd_rom_d = addr_i[11:0] >= dm_HaltAddress[11:0];
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni) begin
			fwd_rom_q <= 1'b0;
			rdata_q <= 1'sb0;
			state_q <= 2'd0;
			word_enable32_q <= 1'b0;
		end
		else begin
			fwd_rom_q <= fwd_rom_d;
			rdata_q <= rdata_d;
			state_q <= state_d;
			word_enable32_q <= addr_i[2];
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			halted_q <= 1'b0;
			resuming_q <= 1'b0;
		end
		else begin
			halted_q <= SelectableHarts & halted_d;
			resuming_q <= SelectableHarts & resuming_d;
		end
	initial _sv2v_0 = 0;
endmodule
module dm_sba (
	clk_i,
	rst_ni,
	dmactive_i,
	master_req_o,
	master_add_o,
	master_we_o,
	master_wdata_o,
	master_be_o,
	master_gnt_i,
	master_r_valid_i,
	master_r_err_i,
	master_r_other_err_i,
	master_r_rdata_i,
	sbaddress_i,
	sbaddress_write_valid_i,
	sbreadonaddr_i,
	sbaddress_o,
	sbautoincrement_i,
	sbaccess_i,
	sbreadondata_i,
	sbdata_i,
	sbdata_read_valid_i,
	sbdata_write_valid_i,
	sbdata_o,
	sbdata_valid_o,
	sbbusy_o,
	sberror_valid_o,
	sberror_o
);
	reg _sv2v_0;
	parameter [31:0] BusWidth = 32;
	parameter [0:0] ReadByteEnable = 1;
	input wire clk_i;
	input wire rst_ni;
	input wire dmactive_i;
	output wire master_req_o;
	output wire [BusWidth - 1:0] master_add_o;
	output wire master_we_o;
	output wire [BusWidth - 1:0] master_wdata_o;
	output wire [(BusWidth / 8) - 1:0] master_be_o;
	input wire master_gnt_i;
	input wire master_r_valid_i;
	input wire master_r_err_i;
	input wire master_r_other_err_i;
	input wire [BusWidth - 1:0] master_r_rdata_i;
	input wire [BusWidth - 1:0] sbaddress_i;
	input wire sbaddress_write_valid_i;
	input wire sbreadonaddr_i;
	output wire [BusWidth - 1:0] sbaddress_o;
	input wire sbautoincrement_i;
	input wire [2:0] sbaccess_i;
	input wire sbreadondata_i;
	input wire [BusWidth - 1:0] sbdata_i;
	input wire sbdata_read_valid_i;
	input wire sbdata_write_valid_i;
	output wire [BusWidth - 1:0] sbdata_o;
	output wire sbdata_valid_o;
	output wire sbbusy_o;
	output reg sberror_valid_o;
	output reg [2:0] sberror_o;
	localparam signed [31:0] BeIdxWidth = $clog2(BusWidth / 8);
	reg [2:0] state_d;
	reg [2:0] state_q;
	reg [BusWidth - 1:0] address;
	reg req;
	wire gnt;
	reg we;
	reg [(BusWidth / 8) - 1:0] be;
	reg [(BusWidth / 8) - 1:0] be_mask;
	reg [BeIdxWidth - 1:0] be_idx;
	assign sbbusy_o = state_q != 3'd0;
	function automatic signed [31:0] sv2v_cast_32_signed;
		input reg signed [31:0] inp;
		sv2v_cast_32_signed = inp;
	endfunction
	always @(*) begin : p_be_mask
		if (_sv2v_0)
			;
		be_mask = 1'sb0;
		(* full_case, parallel_case *)
		case (sbaccess_i)
			3'b000: be_mask[be_idx] = 1'sb1;
			3'b001: be_mask[sv2v_cast_32_signed({be_idx[BeIdxWidth - 1:1], 1'b0})+:2] = 1'sb1;
			3'b010:
				if (BusWidth == 32'd64)
					be_mask[sv2v_cast_32_signed({be_idx[BeIdxWidth - 1], 2'h0})+:4] = 1'sb1;
				else
					be_mask = 1'sb1;
			3'b011: be_mask = 1'sb1;
			default:
				;
		endcase
	end
	wire [BusWidth - 1:0] sbaccess_mask;
	assign sbaccess_mask = {BusWidth {1'b1}} << sbaccess_i;
	reg addr_incr_en;
	wire [BusWidth - 1:0] addr_incr;
	function automatic [BusWidth - 1:0] sv2v_cast_8CBFF;
		input reg [BusWidth - 1:0] inp;
		sv2v_cast_8CBFF = inp;
	endfunction
	assign addr_incr = (addr_incr_en ? sv2v_cast_8CBFF(1'b1) << sbaccess_i : {BusWidth {1'sb0}});
	assign sbaddress_o = sbaddress_i + addr_incr;
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	always @(*) begin : p_fsm
		if (_sv2v_0)
			;
		req = 1'b0;
		address = sbaddress_i;
		we = 1'b0;
		be = 1'sb0;
		be_idx = sbaddress_i[BeIdxWidth - 1:0];
		sberror_o = 1'sb0;
		sberror_valid_o = 1'b0;
		addr_incr_en = 1'b0;
		state_d = state_q;
		(* full_case, parallel_case *)
		case (state_q)
			3'd0: begin
				if (sbaddress_write_valid_i && sbreadonaddr_i)
					state_d = 3'd1;
				if (sbdata_write_valid_i)
					state_d = 3'd2;
				if (sbdata_read_valid_i && sbreadondata_i)
					state_d = 3'd1;
			end
			3'd1: begin
				req = 1'b1;
				if (ReadByteEnable)
					be = be_mask;
				if (gnt)
					state_d = 3'd3;
			end
			3'd2: begin
				req = 1'b1;
				we = 1'b1;
				be = be_mask;
				if (gnt)
					state_d = 3'd4;
			end
			3'd3:
				if (sbdata_valid_o) begin
					state_d = 3'd0;
					addr_incr_en = sbautoincrement_i;
					if (master_r_other_err_i) begin
						sberror_valid_o = 1'b1;
						sberror_o = 3'd7;
					end
					else if (master_r_err_i) begin
						sberror_valid_o = 1'b1;
						sberror_o = 3'd2;
					end
				end
			3'd4:
				if (sbdata_valid_o) begin
					state_d = 3'd0;
					addr_incr_en = sbautoincrement_i;
					if (master_r_other_err_i) begin
						sberror_valid_o = 1'b1;
						sberror_o = 3'd7;
					end
					else if (master_r_err_i) begin
						sberror_valid_o = 1'b1;
						sberror_o = 3'd2;
					end
				end
			default: state_d = 3'd0;
		endcase
		if ((sv2v_cast_32(sbaccess_i) > BeIdxWidth) && (state_q != 3'd0)) begin
			req = 1'b0;
			state_d = 3'd0;
			sberror_valid_o = 1'b1;
			sberror_o = 3'd4;
		end
		if (|(sbaddress_i & ~sbaccess_mask) && (state_q != 3'd0)) begin
			req = 1'b0;
			state_d = 3'd0;
			sberror_valid_o = 1'b1;
			sberror_o = 3'd3;
		end
	end
	always @(posedge clk_i or negedge rst_ni) begin : p_regs
		if (!rst_ni)
			state_q <= 3'd0;
		else
			state_q <= state_d;
	end
	wire [BeIdxWidth - 1:0] be_idx_masked;
	function automatic [BeIdxWidth - 1:0] sv2v_cast_F03CB;
		input reg [BeIdxWidth - 1:0] inp;
		sv2v_cast_F03CB = inp;
	endfunction
	assign be_idx_masked = be_idx & sv2v_cast_F03CB(sbaccess_mask);
	assign master_req_o = req;
	assign master_add_o = address[BusWidth - 1:0];
	assign master_we_o = we;
	assign master_wdata_o = sbdata_i[BusWidth - 1:0] << (8 * be_idx_masked);
	assign master_be_o = be[(BusWidth / 8) - 1:0];
	assign gnt = master_gnt_i;
	assign sbdata_valid_o = master_r_valid_i;
	assign sbdata_o = master_r_rdata_i[BusWidth - 1:0] >> (8 * be_idx_masked);
	initial _sv2v_0 = 0;
endmodule
module dmi_jtag (
	clk_i,
	rst_ni,
	testmode_i,
	test_rst_ni,
	dmi_rst_no,
	dmi_req_o,
	dmi_req_valid_o,
	dmi_req_ready_i,
	dmi_resp_i,
	dmi_resp_ready_o,
	dmi_resp_valid_i,
	tck_i,
	tms_i,
	trst_ni,
	td_i,
	td_o,
	tdo_oe_o
);
	reg _sv2v_0;
	parameter [31:0] IdcodeValue = 32'h00000001;
	input wire clk_i;
	input wire rst_ni;
	input wire testmode_i;
	input wire test_rst_ni;
	output wire dmi_rst_no;
	output wire [40:0] dmi_req_o;
	output wire dmi_req_valid_o;
	input wire dmi_req_ready_i;
	input wire [33:0] dmi_resp_i;
	output wire dmi_resp_ready_o;
	input wire dmi_resp_valid_i;
	input wire tck_i;
	input wire tms_i;
	input wire trst_ni;
	input wire td_i;
	output wire td_o;
	output wire tdo_oe_o;
	reg [1:0] error_d;
	reg [1:0] error_q;
	wire tck;
	wire jtag_dmi_clear;
	wire dmi_clear;
	wire update;
	wire capture;
	wire shift;
	wire tdi;
	wire dtmcs_select;
	reg [31:0] dtmcs_q;
	assign dmi_clear = jtag_dmi_clear || ((dtmcs_select && update) && dtmcs_q[17]);
	reg [31:0] dtmcs_d;
	function automatic [30:0] sv2v_cast_31;
		input reg [30:0] inp;
		sv2v_cast_31 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		dtmcs_d = dtmcs_q;
		if (capture) begin
			if (dtmcs_select)
				dtmcs_d = {20'h00001, error_q, 10'h071};
		end
		if (shift) begin
			if (dtmcs_select)
				dtmcs_d = {tdi, sv2v_cast_31(dtmcs_q >> 1)};
		end
	end
	always @(posedge tck or negedge trst_ni)
		if (!trst_ni)
			dtmcs_q <= 1'sb0;
		else
			dtmcs_q <= dtmcs_d;
	wire dmi_select;
	wire dmi_tdo;
	wire [40:0] dmi_req;
	wire dmi_req_ready;
	reg dmi_req_valid;
	wire [33:0] dmi_resp;
	wire dmi_resp_valid;
	wire dmi_resp_ready;
	reg [2:0] state_d;
	reg [2:0] state_q;
	reg [40:0] dr_d;
	reg [40:0] dr_q;
	reg [6:0] address_d;
	reg [6:0] address_q;
	reg [31:0] data_d;
	reg [31:0] data_q;
	wire [40:0] dmi;
	assign dmi = dr_q;
	assign dmi_req[40-:7] = address_q;
	assign dmi_req[31-:32] = data_q;
	assign dmi_req[33-:2] = (state_q == 3'd3 ? 2'h2 : 2'h1);
	assign dmi_resp_ready = 1'b1;
	reg error_dmi_busy;
	reg error_dmi_op_failed;
	function automatic [1:0] sv2v_cast_2;
		input reg [1:0] inp;
		sv2v_cast_2 = inp;
	endfunction
	always @(*) begin : p_fsm
		if (_sv2v_0)
			;
		error_dmi_busy = 1'b0;
		error_dmi_op_failed = 1'b0;
		state_d = state_q;
		address_d = address_q;
		data_d = data_q;
		error_d = error_q;
		dmi_req_valid = 1'b0;
		if (dmi_clear) begin
			state_d = 3'd0;
			data_d = 1'sb0;
			error_d = 2'h0;
			address_d = 1'sb0;
		end
		else begin
			(* full_case, parallel_case *)
			case (state_q)
				3'd0:
					if ((dmi_select && update) && (error_q == 2'h0)) begin
						address_d = dmi[40-:7];
						data_d = dmi[33-:32];
						if (sv2v_cast_2(dmi[1-:2]) == 2'h1)
							state_d = 3'd1;
						else if (sv2v_cast_2(dmi[1-:2]) == 2'h2)
							state_d = 3'd3;
					end
				3'd1: begin
					dmi_req_valid = 1'b1;
					if (dmi_req_ready)
						state_d = 3'd2;
				end
				3'd2:
					if (dmi_resp_valid) begin
						(* full_case, parallel_case *)
						case (dmi_resp[1-:2])
							2'h0: data_d = dmi_resp[33-:32];
							2'h2: begin
								data_d = 32'hdeadbeef;
								error_dmi_op_failed = 1'b1;
							end
							2'h3: begin
								data_d = 32'hb051b051;
								error_dmi_busy = 1'b1;
							end
							default: data_d = 32'hbaadc0de;
						endcase
						state_d = 3'd0;
					end
				3'd3: begin
					dmi_req_valid = 1'b1;
					if (dmi_req_ready)
						state_d = 3'd4;
				end
				3'd4:
					if (dmi_resp_valid) begin
						(* full_case, parallel_case *)
						case (dmi_resp[1-:2])
							2'h2: error_dmi_op_failed = 1'b1;
							2'h3: error_dmi_busy = 1'b1;
							default:
								;
						endcase
						state_d = 3'd0;
					end
				default:
					if (dmi_resp_valid)
						state_d = 3'd0;
			endcase
			if (update && (state_q != 3'd0))
				error_dmi_busy = 1'b1;
			if (capture && |{state_q == 3'd1, state_q == 3'd2})
				error_dmi_busy = 1'b1;
			if (error_dmi_busy && (error_q == 2'h0))
				error_d = 2'h3;
			if (error_dmi_op_failed && (error_q == 2'h0))
				error_d = 2'h2;
			if ((update && dtmcs_q[16]) && dtmcs_select)
				error_d = 2'h0;
		end
	end
	assign dmi_tdo = dr_q[0];
	always @(*) begin : p_shift
		if (_sv2v_0)
			;
		dr_d = dr_q;
		if (dmi_clear)
			dr_d = 1'sb0;
		else begin
			if (capture) begin
				if (dmi_select) begin
					if ((error_q == 2'h0) && !error_dmi_busy)
						dr_d = {address_q, data_q, 2'h0};
					else if ((error_q == 2'h3) || error_dmi_busy)
						dr_d = {address_q, data_q, 2'h3};
				end
			end
			if (shift) begin
				if (dmi_select)
					dr_d = {tdi, dr_q[40:1]};
			end
		end
	end
	always @(posedge tck or negedge trst_ni)
		if (!trst_ni) begin
			dr_q <= 1'sb0;
			state_q <= 3'd0;
			address_q <= 1'sb0;
			data_q <= 1'sb0;
			error_q <= 2'h0;
		end
		else begin
			dr_q <= dr_d;
			state_q <= state_d;
			address_q <= address_d;
			data_q <= data_d;
			error_q <= error_d;
		end
	dmi_jtag_tap #(
		.IrLength(5),
		.IdcodeValue(IdcodeValue)
	) i_dmi_jtag_tap(
		.tck_i(tck_i),
		.tms_i(tms_i),
		.trst_ni(trst_ni),
		.td_i(td_i),
		.td_o(td_o),
		.tdo_oe_o(tdo_oe_o),
		.testmode_i(testmode_i),
		.tck_o(tck),
		.dmi_clear_o(jtag_dmi_clear),
		.update_o(update),
		.capture_o(capture),
		.shift_o(shift),
		.tdi_o(tdi),
		.dtmcs_select_o(dtmcs_select),
		.dtmcs_tdo_i(dtmcs_q[0]),
		.dmi_select_o(dmi_select),
		.dmi_tdo_i(dmi_tdo)
	);
	dmi_cdc i_dmi_cdc(
		.testmode_i(testmode_i),
		.test_rst_ni(test_rst_ni),
		.tck_i(tck),
		.trst_ni(trst_ni),
		.jtag_dmi_cdc_clear_i(dmi_clear),
		.jtag_dmi_req_i(dmi_req),
		.jtag_dmi_ready_o(dmi_req_ready),
		.jtag_dmi_valid_i(dmi_req_valid),
		.jtag_dmi_resp_o(dmi_resp),
		.jtag_dmi_valid_o(dmi_resp_valid),
		.jtag_dmi_ready_i(dmi_resp_ready),
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.core_dmi_rst_no(dmi_rst_no),
		.core_dmi_req_o(dmi_req_o),
		.core_dmi_valid_o(dmi_req_valid_o),
		.core_dmi_ready_i(dmi_req_ready_i),
		.core_dmi_resp_i(dmi_resp_i),
		.core_dmi_ready_o(dmi_resp_ready_o),
		.core_dmi_valid_i(dmi_resp_valid_i)
	);
	initial _sv2v_0 = 0;
endmodule
module dmi_jtag_tap (
	tck_i,
	tms_i,
	trst_ni,
	td_i,
	td_o,
	tdo_oe_o,
	testmode_i,
	tck_o,
	dmi_clear_o,
	update_o,
	capture_o,
	shift_o,
	tdi_o,
	dtmcs_select_o,
	dtmcs_tdo_i,
	dmi_select_o,
	dmi_tdo_i
);
	reg _sv2v_0;
	parameter [31:0] IrLength = 5;
	parameter [31:0] IdcodeValue = 32'h00000001;
	input wire tck_i;
	input wire tms_i;
	input wire trst_ni;
	input wire td_i;
	output reg td_o;
	output reg tdo_oe_o;
	input wire testmode_i;
	output wire tck_o;
	output wire dmi_clear_o;
	output wire update_o;
	output wire capture_o;
	output wire shift_o;
	output wire tdi_o;
	output reg dtmcs_select_o;
	input wire dtmcs_tdo_i;
	output reg dmi_select_o;
	input wire dmi_tdo_i;
	reg [3:0] tap_state_q;
	reg [3:0] tap_state_d;
	reg update_dr;
	reg shift_dr;
	reg capture_dr;
	reg [IrLength - 1:0] jtag_ir_shift_d;
	reg [IrLength - 1:0] jtag_ir_shift_q;
	reg [IrLength - 1:0] jtag_ir_d;
	reg [IrLength - 1:0] jtag_ir_q;
	reg capture_ir;
	reg shift_ir;
	reg update_ir;
	reg test_logic_reset;
	function automatic [IrLength - 1:0] sv2v_cast_154DA;
		input reg [IrLength - 1:0] inp;
		sv2v_cast_154DA = inp;
	endfunction
	always @(*) begin : p_jtag
		if (_sv2v_0)
			;
		jtag_ir_shift_d = jtag_ir_shift_q;
		jtag_ir_d = jtag_ir_q;
		if (shift_ir)
			jtag_ir_shift_d = {td_i, jtag_ir_shift_q[IrLength - 1:1]};
		if (capture_ir)
			jtag_ir_shift_d = sv2v_cast_154DA(4'b0101);
		if (update_ir)
			jtag_ir_d = sv2v_cast_154DA(jtag_ir_shift_q);
		if (test_logic_reset) begin
			jtag_ir_shift_d = 1'sb0;
			jtag_ir_d = sv2v_cast_154DA('h1);
		end
	end
	always @(posedge tck_i or negedge trst_ni) begin : p_jtag_ir_reg
		if (!trst_ni) begin
			jtag_ir_shift_q <= 1'sb0;
			jtag_ir_q <= sv2v_cast_154DA('h1);
		end
		else begin
			jtag_ir_shift_q <= jtag_ir_shift_d;
			jtag_ir_q <= jtag_ir_d;
		end
	end
	reg [31:0] idcode_d;
	reg [31:0] idcode_q;
	reg idcode_select;
	reg bypass_select;
	reg bypass_d;
	reg bypass_q;
	function automatic [30:0] sv2v_cast_31;
		input reg [30:0] inp;
		sv2v_cast_31 = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		idcode_d = idcode_q;
		bypass_d = bypass_q;
		if (capture_dr) begin
			if (idcode_select)
				idcode_d = IdcodeValue;
			if (bypass_select)
				bypass_d = 1'b0;
		end
		if (shift_dr) begin
			if (idcode_select)
				idcode_d = {td_i, sv2v_cast_31(idcode_q >> 1)};
			if (bypass_select)
				bypass_d = td_i;
		end
		if (test_logic_reset) begin
			idcode_d = IdcodeValue;
			bypass_d = 1'b0;
		end
	end
	always @(*) begin : p_data_reg_sel
		if (_sv2v_0)
			;
		dmi_select_o = 1'b0;
		dtmcs_select_o = 1'b0;
		idcode_select = 1'b0;
		bypass_select = 1'b0;
		(* full_case, parallel_case *)
		case (jtag_ir_q)
			sv2v_cast_154DA('h0): bypass_select = 1'b1;
			sv2v_cast_154DA('h1): idcode_select = 1'b1;
			sv2v_cast_154DA('h10): dtmcs_select_o = 1'b1;
			sv2v_cast_154DA('h11): dmi_select_o = 1'b1;
			sv2v_cast_154DA('h1f): bypass_select = 1'b1;
			default: bypass_select = 1'b1;
		endcase
	end
	reg tdo_mux;
	always @(*) begin : p_out_sel
		if (_sv2v_0)
			;
		if (shift_ir)
			tdo_mux = jtag_ir_shift_q[0];
		else
			(* full_case, parallel_case *)
			case (jtag_ir_q)
				sv2v_cast_154DA('h1): tdo_mux = idcode_q[0];
				sv2v_cast_154DA('h10): tdo_mux = dtmcs_tdo_i;
				sv2v_cast_154DA('h11): tdo_mux = dmi_tdo_i;
				default: tdo_mux = bypass_q;
			endcase
	end
	wire tck_n;
	prim_clock_inv #(
		.HasScanMode(1'b1),
		.NoFpgaBufG(1'b1)
	) i_tck_inv(
		.clk_i(tck_i),
		.clk_no(tck_n),
		.scanmode_i(testmode_i)
	);
	always @(posedge tck_n or negedge trst_ni) begin : p_tdo_regs
		if (!trst_ni) begin
			td_o <= 1'b0;
			tdo_oe_o <= 1'b0;
		end
		else begin
			td_o <= tdo_mux;
			tdo_oe_o <= shift_ir | shift_dr;
		end
	end
	always @(*) begin : p_tap_fsm
		if (_sv2v_0)
			;
		test_logic_reset = 1'b0;
		capture_dr = 1'b0;
		shift_dr = 1'b0;
		update_dr = 1'b0;
		capture_ir = 1'b0;
		shift_ir = 1'b0;
		update_ir = 1'b0;
		(* full_case, parallel_case *)
		case (tap_state_q)
			4'd0: begin
				tap_state_d = (tms_i ? 4'd0 : 4'd1);
				test_logic_reset = 1'b1;
			end
			4'd1: tap_state_d = (tms_i ? 4'd2 : 4'd1);
			4'd2: tap_state_d = (tms_i ? 4'd9 : 4'd3);
			4'd3: begin
				capture_dr = 1'b1;
				tap_state_d = (tms_i ? 4'd5 : 4'd4);
			end
			4'd4: begin
				shift_dr = 1'b1;
				tap_state_d = (tms_i ? 4'd5 : 4'd4);
			end
			4'd5: tap_state_d = (tms_i ? 4'd8 : 4'd6);
			4'd6: tap_state_d = (tms_i ? 4'd7 : 4'd6);
			4'd7: tap_state_d = (tms_i ? 4'd8 : 4'd4);
			4'd8: begin
				update_dr = 1'b1;
				tap_state_d = (tms_i ? 4'd2 : 4'd1);
			end
			4'd9: tap_state_d = (tms_i ? 4'd0 : 4'd10);
			4'd10: begin
				capture_ir = 1'b1;
				tap_state_d = (tms_i ? 4'd12 : 4'd11);
			end
			4'd11: begin
				shift_ir = 1'b1;
				tap_state_d = (tms_i ? 4'd12 : 4'd11);
			end
			4'd12: tap_state_d = (tms_i ? 4'd15 : 4'd13);
			4'd13: tap_state_d = (tms_i ? 4'd14 : 4'd13);
			4'd14: tap_state_d = (tms_i ? 4'd15 : 4'd11);
			4'd15: begin
				update_ir = 1'b1;
				tap_state_d = (tms_i ? 4'd2 : 4'd1);
			end
			default:
				;
		endcase
	end
	always @(posedge tck_i or negedge trst_ni) begin : p_regs
		if (!trst_ni) begin
			tap_state_q <= 4'd1;
			idcode_q <= IdcodeValue;
			bypass_q <= 1'b0;
		end
		else begin
			tap_state_q <= tap_state_d;
			idcode_q <= idcode_d;
			bypass_q <= bypass_d;
		end
	end
	assign tck_o = tck_i;
	assign tdi_o = td_i;
	assign update_o = update_dr;
	assign shift_o = shift_dr;
	assign capture_o = capture_dr;
	assign dmi_clear_o = test_logic_reset;
	initial _sv2v_0 = 0;
endmodule
module dmi_cdc (
	testmode_i,
	test_rst_ni,
	tck_i,
	trst_ni,
	jtag_dmi_req_i,
	jtag_dmi_ready_o,
	jtag_dmi_valid_i,
	jtag_dmi_cdc_clear_i,
	jtag_dmi_resp_o,
	jtag_dmi_valid_o,
	jtag_dmi_ready_i,
	clk_i,
	rst_ni,
	core_dmi_rst_no,
	core_dmi_req_o,
	core_dmi_valid_o,
	core_dmi_ready_i,
	core_dmi_resp_i,
	core_dmi_ready_o,
	core_dmi_valid_i
);
	input wire testmode_i;
	input wire test_rst_ni;
	input wire tck_i;
	input wire trst_ni;
	input wire [40:0] jtag_dmi_req_i;
	output wire jtag_dmi_ready_o;
	input wire jtag_dmi_valid_i;
	input wire jtag_dmi_cdc_clear_i;
	output wire [33:0] jtag_dmi_resp_o;
	output wire jtag_dmi_valid_o;
	input wire jtag_dmi_ready_i;
	input wire clk_i;
	input wire rst_ni;
	output wire core_dmi_rst_no;
	output wire [40:0] core_dmi_req_o;
	output wire core_dmi_valid_o;
	input wire core_dmi_ready_i;
	input wire [33:0] core_dmi_resp_i;
	output wire core_dmi_ready_o;
	input wire core_dmi_valid_i;
	reg jtag_combined_rstn;
	always @(posedge tck_i or negedge trst_ni)
		if (!trst_ni)
			jtag_combined_rstn <= 1'sb0;
		else if (jtag_dmi_cdc_clear_i)
			jtag_combined_rstn <= 1'sb0;
		else
			jtag_combined_rstn <= 1'b1;
	wire combined_rstn_premux;
	prim_flop_2sync #(
		.Width(1),
		.ResetValue(0)
	) u_combined_rstn_sync(
		.clk_i(clk_i),
		.rst_ni(rst_ni & jtag_combined_rstn),
		.d_i(1'b1),
		.q_o(combined_rstn_premux)
	);
	wire combined_rstn;
	prim_clock_mux2 #(.NoFpgaBufG(1'b1)) u_rst_mux(
		.clk0_i(combined_rstn_premux),
		.clk1_i(test_rst_ni),
		.sel_i(testmode_i),
		.clk_o(combined_rstn)
	);
	prim_fifo_async_simple #(
		.Width(41),
		.EnRzHs(1)
	) i_cdc_req(
		.clk_wr_i(tck_i),
		.rst_wr_ni(trst_ni),
		.wvalid_i(jtag_dmi_valid_i),
		.wready_o(jtag_dmi_ready_o),
		.wdata_i(jtag_dmi_req_i),
		.clk_rd_i(clk_i),
		.rst_rd_ni(combined_rstn),
		.rvalid_o(core_dmi_valid_o),
		.rready_i(core_dmi_ready_i),
		.rdata_o(core_dmi_req_o)
	);
	prim_fifo_async_simple #(
		.Width(34),
		.EnRzHs(1)
	) i_cdc_resp(
		.clk_wr_i(clk_i),
		.rst_wr_ni(combined_rstn),
		.wvalid_i(core_dmi_valid_i),
		.wready_o(core_dmi_ready_o),
		.wdata_i(core_dmi_resp_i),
		.clk_rd_i(tck_i),
		.rst_rd_ni(trst_ni),
		.rvalid_o(jtag_dmi_valid_o),
		.rready_i(jtag_dmi_ready_i),
		.rdata_o(jtag_dmi_resp_o)
	);
	assign core_dmi_rst_no = combined_rstn;
endmodule
module debug_rom_one_scratch (
	clk_i,
	req_i,
	addr_i,
	rdata_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire req_i;
	input wire [63:0] addr_i;
	output reg [63:0] rdata_o;
	localparam [31:0] RomSize = 14;
	wire [895:0] mem;
	assign mem = 896'h7b2000737b20247310802823f1402473aa5ff06f7b20247310002423001000737b20247310002c23fddff06ffc0414e30024741340044403f140247302041263001474134004440310802023f14024737b2410730ff0000f000000130380006f000000130580006f000000130180006f;
	reg [3:0] addr_q;
	always @(posedge clk_i)
		if (req_i)
			addr_q <= addr_i[6:3];
	function automatic [3:0] sv2v_cast_31EC5;
		input reg [3:0] inp;
		sv2v_cast_31EC5 = inp;
	endfunction
	always @(*) begin : p_outmux
		if (_sv2v_0)
			;
		rdata_o = 1'sb0;
		if (addr_q < sv2v_cast_31EC5(RomSize))
			rdata_o = mem[addr_q * 64+:64];
	end
	initial _sv2v_0 = 0;
endmodule
module debug_rom (
	clk_i,
	req_i,
	addr_i,
	rdata_o
);
	reg _sv2v_0;
	input wire clk_i;
	input wire req_i;
	input wire [63:0] addr_i;
	output reg [63:0] rdata_o;
	localparam [31:0] RomSize = 20;
	wire [1279:0] mem;
	assign mem = 1280'h7b2000737b2024737b30257310852823f1402473a79ff06f7b2024737b30257310052423001000737b2024737b30257310052c2300c5151300c5551300000517fd5ff06ffa0418e3002474134004440300a40433f140247302041c63001474134004440300a4043310852023f140247300c5151300c55513000005177b3510737b2410730ff0000f000000130500006f000000130840006f000000130180006f;
	reg [4:0] addr_q;
	always @(posedge clk_i)
		if (req_i)
			addr_q <= addr_i[7:3];
	function automatic [4:0] sv2v_cast_CA402;
		input reg [4:0] inp;
		sv2v_cast_CA402 = inp;
	endfunction
	always @(*) begin : p_outmux
		if (_sv2v_0)
			;
		rdata_o = 1'sb0;
		if (addr_q < sv2v_cast_CA402(RomSize))
			rdata_o = mem[addr_q * 64+:64];
	end
	initial _sv2v_0 = 0;
endmodule
module pwm (
	clk_i,
	rst_ni,
	pulse_width_i,
	max_counter_i,
	modulated_o
);
	parameter signed [31:0] CtrSize = 8;
	input wire clk_i;
	input wire rst_ni;
	input wire [CtrSize - 1:0] pulse_width_i;
	input wire [CtrSize - 1:0] max_counter_i;
	output reg modulated_o;
	reg [CtrSize - 1:0] counter;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			counter <= 'b0;
			modulated_o <= 'b0;
		end
		else if (max_counter_i == 0) begin
			counter <= 'b0;
			modulated_o <= 'b0;
		end
		else begin
			if (counter < max_counter_i)
				counter <= counter + 1;
			else
				counter <= 0;
			if (pulse_width_i > counter)
				modulated_o <= 1'b1;
			else
				modulated_o <= 1'b0;
		end
endmodule
module spi_top (
	clk_i,
	rst_ni,
	device_req_i,
	device_addr_i,
	device_we_i,
	device_be_i,
	device_wdata_i,
	device_rvalid_o,
	device_rdata_o,
	spi_rx_i,
	spi_tx_o,
	sck_o,
	byte_data_o
);
	parameter [31:0] ClockFrequency = 20000000;
	parameter [31:0] BaudRate = 5000000;
	parameter [0:0] CPOL = 0;
	parameter [0:0] CPHA = 0;
	parameter [31:0] AddrWidth = 32;
	parameter [31:0] DataWidth = 32;
	parameter [31:0] RegAddr = 12;
	input wire clk_i;
	input wire rst_ni;
	input wire device_req_i;
	input wire [AddrWidth - 1:0] device_addr_i;
	input wire device_we_i;
	input wire [3:0] device_be_i;
	input wire [DataWidth - 1:0] device_wdata_i;
	output reg device_rvalid_o;
	output wire [DataWidth - 1:0] device_rdata_o;
	input wire spi_rx_i;
	output wire spi_tx_o;
	output wire sck_o;
	output wire [7:0] byte_data_o;
	function automatic [RegAddr - 1:0] sv2v_cast_33151;
		input reg [RegAddr - 1:0] inp;
		sv2v_cast_33151 = inp;
	endfunction
	localparam [RegAddr - 1:0] SpiTxReg = sv2v_cast_33151('h0);
	localparam [RegAddr - 1:0] SpiStatusReg = sv2v_cast_33151('h4);
	wire [RegAddr - 1:0] reg_addr;
	reg read_status_q;
	wire read_status_d;
	wire next_tx_byte_d;
	reg next_tx_byte_q;
	wire tx_fifo_wvalid;
	wire tx_fifo_rvalid;
	wire tx_fifo_rready;
	wire [7:0] tx_fifo_rdata;
	wire tx_fifo_full;
	wire tx_fifo_empty;
	wire [6:0] tx_fifo_depth;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			next_tx_byte_q <= 1'sb0;
			device_rvalid_o <= 1'sb0;
		end
		else begin
			next_tx_byte_q <= next_tx_byte_d;
			device_rvalid_o <= device_req_i;
		end
	assign tx_fifo_rready = next_tx_byte_d && ~next_tx_byte_q;
	assign reg_addr = device_addr_i[RegAddr - 1:0];
	assign tx_fifo_empty = tx_fifo_depth == 0;
	assign tx_fifo_wvalid = ((device_req_i & (reg_addr == SpiTxReg)) & device_we_i) & device_be_i[0];
	assign read_status_d = (device_req_i & (reg_addr == SpiStatusReg)) & ~device_we_i;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			read_status_q <= 0;
		else
			read_status_q <= read_status_d;
	function automatic [((DataWidth - 3) >= 0 ? DataWidth - 2 : 4 - DataWidth) - 1:0] sv2v_cast_7582B;
		input reg [((DataWidth - 3) >= 0 ? DataWidth - 2 : 4 - DataWidth) - 1:0] inp;
		sv2v_cast_7582B = inp;
	endfunction
	function automatic [DataWidth - 1:0] sv2v_cast_8536A;
		input reg [DataWidth - 1:0] inp;
		sv2v_cast_8536A = inp;
	endfunction
	assign device_rdata_o = (read_status_q ? {sv2v_cast_7582B(1'sb0), tx_fifo_empty, tx_fifo_full} : sv2v_cast_8536A(1'sb0));
	prim_fifo_sync #(
		.Width(8),
		.Pass(1'b0),
		.Depth(127)
	) u_tx_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid_i(tx_fifo_wvalid),
		.wready_o(),
		.wdata_i(device_wdata_i[7:0]),
		.rvalid_o(tx_fifo_rvalid),
		.rready_i(tx_fifo_rready),
		.rdata_o(tx_fifo_rdata),
		.full_o(tx_fifo_full),
		.depth_o(tx_fifo_depth),
		.err_o()
	);
	spi_host #(
		.ClockFrequency(ClockFrequency),
		.BaudRate(BaudRate),
		.CPOL(CPOL),
		.CPHA(CPHA)
	) u_spi_host(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.spi_rx_i(spi_rx_i),
		.spi_tx_o(spi_tx_o),
		.sck_o(sck_o),
		.start_i(tx_fifo_rvalid),
		.byte_data_i(tx_fifo_rdata),
		.byte_data_o(byte_data_o),
		.next_tx_byte_o(next_tx_byte_d)
	);
	wire [(AddrWidth - 1) - RegAddr:0] unused_device_addr;
	wire [3:1] unused_device_be;
	wire [DataWidth - 9:0] unused_device_wdata;
	assign unused_device_addr = device_addr_i[AddrWidth - 1:RegAddr];
	assign unused_device_be = device_be_i[3:1];
	assign unused_device_wdata = device_wdata_i[DataWidth - 1:8];
endmodule
module sram_controller (
	clk_i,
	rst_ni,
	sram_req_i,
	sram_we_i,
	sram_addr_i,
	sram_wdata_i,
	sram_be_i,
	sram_rdata_o,
	sram_rvalid_o,
	mem_en_o,
	mem_we_o,
	mem_addr_o,
	mem_wdata_o,
	mem_rdata_i
);
	parameter signed [31:0] AW = 32;
	parameter signed [31:0] DW = 32;
	parameter signed [31:0] WORD_ADDR_WIDTH = 11;
	parameter ECC_ENABLE = 0;
	parameter [31:0] SRAM_BASE = 32'h00102000;
	parameter signed [31:0] SRAM_SIZE = 32'd8192;
	input wire clk_i;
	input wire rst_ni;
	input wire sram_req_i;
	input wire sram_we_i;
	input wire [AW - 1:0] sram_addr_i;
	input wire [DW - 1:0] sram_wdata_i;
	input wire [(DW / 8) - 1:0] sram_be_i;
	output wire [DW - 1:0] sram_rdata_o;
	output reg sram_rvalid_o;
	output wire mem_en_o;
	output wire [(DW / 8) - 1:0] mem_we_o;
	output wire [WORD_ADDR_WIDTH - 1:0] mem_addr_o;
	output wire [DW - 1:0] mem_wdata_o;
	input wire [DW - 1:0] mem_rdata_i;
	wire addr_valid;
	wire [AW - 1:0] local_addr;
	assign addr_valid = (sram_addr_i >= SRAM_BASE) && (sram_addr_i < (SRAM_BASE + SRAM_SIZE[AW - 1:0]));
	assign local_addr = sram_addr_i - SRAM_BASE;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			sram_rvalid_o <= 1'b0;
		else
			sram_rvalid_o <= sram_req_i && addr_valid;
	assign mem_en_o = sram_req_i && addr_valid;
	assign mem_we_o = ((sram_req_i && addr_valid) && sram_we_i ? sram_be_i : {DW / 8 {1'sb0}});
	assign mem_addr_o = local_addr[WORD_ADDR_WIDTH + 1:2];
	assign mem_wdata_o = sram_wdata_i;
	assign sram_rdata_o = mem_rdata_i;
endmodule
module gpio (
	clk_i,
	rst_ni,
	device_req_i,
	device_addr_i,
	device_we_i,
	device_be_i,
	device_wdata_i,
	device_rvalid_o,
	device_rdata_o,
	gp_i,
	gp_o
);
	reg _sv2v_0;
	parameter [31:0] GpiWidth = 8;
	parameter [31:0] GpoWidth = 16;
	parameter [31:0] AddrWidth = 32;
	parameter [31:0] DataWidth = 32;
	parameter [31:0] RegAddr = 12;
	input wire clk_i;
	input wire rst_ni;
	input wire device_req_i;
	input wire [AddrWidth - 1:0] device_addr_i;
	input wire device_we_i;
	input wire [3:0] device_be_i;
	input wire [DataWidth - 1:0] device_wdata_i;
	output reg device_rvalid_o;
	output reg [DataWidth - 1:0] device_rdata_o;
	input wire [GpiWidth - 1:0] gp_i;
	output reg [GpoWidth - 1:0] gp_o;
	localparam [31:0] GPIO_OUT_REG = 32'h00000000;
	localparam [31:0] GPIO_IN_REG = 32'h00000004;
	localparam [31:0] GPIO_IN_DBNC_REG = 32'h00000008;
	wire [RegAddr - 1:0] reg_addr;
	reg [(3 * GpiWidth) - 1:0] gp_i_q;
	wire [GpiWidth - 1:0] gp_i_dbnc;
	wire [GpoWidth - 1:0] gp_o_d;
	wire gp_o_wr_en;
	wire gp_i_rd_en_d;
	reg gp_i_rd_en_q;
	wire gp_i_dbnc_rd_en_d;
	reg gp_i_dbnc_rd_en_q;
	genvar _gv_i_34;
	generate
		for (_gv_i_34 = 0; _gv_i_34 < GpiWidth; _gv_i_34 = _gv_i_34 + 1) begin : gen_debounce
			localparam i = _gv_i_34;
			debounce #(.ClkCount(500)) dbnc(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.btn_i(gp_i_q[(2 * GpiWidth) + i]),
				.btn_o(gp_i_dbnc[i])
			);
		end
	endgenerate
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			gp_i_q <= 1'sb0;
			gp_o <= 1'sb0;
			device_rvalid_o <= 1'sb0;
			gp_i_rd_en_q <= 1'sb0;
			gp_i_dbnc_rd_en_q <= 1'sb0;
		end
		else begin
			gp_i_q <= {gp_i_q[0+:GpiWidth * 2], gp_i};
			if (gp_o_wr_en)
				gp_o <= gp_o_d;
			device_rvalid_o <= device_req_i;
			gp_i_rd_en_q <= gp_i_rd_en_d;
			gp_i_dbnc_rd_en_q <= gp_i_dbnc_rd_en_d;
		end
	wire [3:0] unused_device_be;
	genvar _gv_i_byte_1;
	generate
		for (_gv_i_byte_1 = 0; _gv_i_byte_1 < 4; _gv_i_byte_1 = _gv_i_byte_1 + 1) begin : gen_gp_o_d
			localparam i_byte = _gv_i_byte_1;
			if ((i_byte * 8) < GpoWidth) begin : gen_gp_o_d_inner
				localparam signed [31:0] gpo_byte_end = (((i_byte + 1) * 8) <= GpoWidth ? (i_byte + 1) * 8 : GpoWidth);
				assign gp_o_d[gpo_byte_end - 1:i_byte * 8] = (device_be_i[i_byte] ? device_wdata_i[gpo_byte_end - 1:i_byte * 8] : gp_o[gpo_byte_end - 1:i_byte * 8]);
				assign unused_device_be[i_byte] = 0;
			end
			else begin : gen_unused_device_be
				assign unused_device_be[i_byte] = device_be_i[i_byte];
			end
		end
	endgenerate
	assign reg_addr = device_addr_i[RegAddr - 1:0];
	assign gp_o_wr_en = (device_req_i & device_we_i) & (reg_addr == GPIO_OUT_REG[RegAddr - 1:0]);
	assign gp_i_rd_en_d = (device_req_i & ~device_we_i) & (reg_addr == GPIO_IN_REG[RegAddr - 1:0]);
	assign gp_i_dbnc_rd_en_d = (device_req_i & ~device_we_i) & (reg_addr == GPIO_IN_DBNC_REG[RegAddr - 1:0]);
	always @(*) begin
		if (_sv2v_0)
			;
		if (gp_i_dbnc_rd_en_q)
			device_rdata_o = {{DataWidth - GpiWidth {1'b0}}, gp_i_dbnc};
		else if (gp_i_rd_en_q)
			device_rdata_o = {{DataWidth - GpiWidth {1'b0}}, gp_i_q[2 * GpiWidth+:GpiWidth]};
		else
			device_rdata_o = {{DataWidth - GpoWidth {1'b0}}, gp_o};
	end
	wire [(AddrWidth - 1) - RegAddr:0] unused_device_addr;
	wire [(DataWidth - 1) - GpoWidth:0] unused_device_wdata;
	assign unused_device_addr = device_addr_i[AddrWidth - 1:RegAddr];
	assign unused_device_wdata = device_wdata_i[DataWidth - 1:GpoWidth];
	initial _sv2v_0 = 0;
endmodule
module boot_rom (
	clk_i,
	addr_i,
	data_o
);
	parameter signed [31:0] ADDR_WIDTH = 10;
	parameter INIT_FILE = "rtl/system/boot.mem";
	input wire clk_i;
	input wire [ADDR_WIDTH - 1:0] addr_i;
	output reg [31:0] data_o;
	reg [31:0] mem [0:(2 ** ADDR_WIDTH) - 1];
	initial $readmemh(INIT_FILE, mem);
	always @(posedge clk_i) data_o <= mem[addr_i];
endmodule
module i2c_master_bit_ctrl (
	clk,
	rst,
	nReset,
	clk_cnt,
	ena,
	cmd,
	cmd_ack,
	busy,
	al,
	din,
	dout,
	scl_i,
	scl_o,
	scl_oen,
	sda_i,
	sda_o,
	sda_oen
);
	input clk;
	input rst;
	input nReset;
	input ena;
	input [15:0] clk_cnt;
	input [3:0] cmd;
	output reg cmd_ack;
	output reg busy;
	output reg al;
	input din;
	output reg dout;
	input scl_i;
	output wire scl_o;
	output reg scl_oen;
	input sda_i;
	output wire sda_o;
	output reg sda_oen;
	reg sSCL;
	reg sSDA;
	reg dscl_oen;
	reg sda_chk;
	reg clk_en;
	wire slave_wait;
	reg [15:0] cnt;
	always @(posedge clk) dscl_oen <= #(1) scl_oen;
	assign slave_wait = dscl_oen && !sSCL;
	always @(posedge clk or negedge nReset)
		if (~nReset) begin
			cnt <= #(1) 16'h0000;
			clk_en <= #(1) 1'b1;
		end
		else if (rst) begin
			cnt <= #(1) 16'h0000;
			clk_en <= #(1) 1'b1;
		end
		else if (~|cnt || ~ena) begin
			if (~slave_wait) begin
				cnt <= #(1) clk_cnt;
				clk_en <= #(1) 1'b1;
			end
			else begin
				cnt <= #(1) cnt;
				clk_en <= #(1) 1'b0;
			end
		end
		else begin
			cnt <= #(1) cnt - 16'h0001;
			clk_en <= #(1) 1'b0;
		end
	reg dSCL;
	reg dSDA;
	reg sta_condition;
	reg sto_condition;
	always @(posedge clk or negedge nReset)
		if (~nReset) begin
			sSCL <= #(1) 1'b1;
			sSDA <= #(1) 1'b1;
			dSCL <= #(1) 1'b1;
			dSDA <= #(1) 1'b1;
		end
		else if (rst) begin
			sSCL <= #(1) 1'b1;
			sSDA <= #(1) 1'b1;
			dSCL <= #(1) 1'b1;
			dSDA <= #(1) 1'b1;
		end
		else begin
			sSCL <= #(1) scl_i;
			sSDA <= #(1) sda_i;
			dSCL <= #(1) sSCL;
			dSDA <= #(1) sSDA;
		end
	always @(posedge clk or negedge nReset)
		if (~nReset) begin
			sta_condition <= #(1) 1'b0;
			sto_condition <= #(1) 1'b0;
		end
		else if (rst) begin
			sta_condition <= #(1) 1'b0;
			sto_condition <= #(1) 1'b0;
		end
		else begin
			sta_condition <= #(1) (~sSDA & dSDA) & sSCL;
			sto_condition <= #(1) (sSDA & ~dSDA) & sSCL;
		end
	always @(posedge clk or negedge nReset)
		if (!nReset)
			busy <= #(1) 1'b0;
		else if (rst)
			busy <= #(1) 1'b0;
		else
			busy <= #(1) (sta_condition | busy) & ~sto_condition;
	reg cmd_stop;
	always @(posedge clk or negedge nReset)
		if (~nReset)
			cmd_stop <= #(1) 1'b0;
		else if (rst)
			cmd_stop <= #(1) 1'b0;
		else if (clk_en)
			cmd_stop <= #(1) cmd == 4'b0010;
	always @(posedge clk or negedge nReset)
		if (~nReset)
			al <= #(1) 1'b0;
		else if (rst)
			al <= #(1) 1'b0;
		else
			al <= #(1) ((sda_chk & ~sSDA) & sda_oen) | (sto_condition & ~cmd_stop);
	always @(posedge clk)
		if (sSCL & ~dSCL)
			dout <= #(1) sSDA;
	parameter [16:0] idle = 17'b00000000000000000;
	parameter [16:0] start_a = 17'b00000000000000001;
	parameter [16:0] start_b = 17'b00000000000000010;
	parameter [16:0] start_c = 17'b00000000000000100;
	parameter [16:0] start_d = 17'b00000000000001000;
	parameter [16:0] start_e = 17'b00000000000010000;
	parameter [16:0] stop_a = 17'b00000000000100000;
	parameter [16:0] stop_b = 17'b00000000001000000;
	parameter [16:0] stop_c = 17'b00000000010000000;
	parameter [16:0] stop_d = 17'b00000000100000000;
	parameter [16:0] rd_a = 17'b00000001000000000;
	parameter [16:0] rd_b = 17'b00000010000000000;
	parameter [16:0] rd_c = 17'b00000100000000000;
	parameter [16:0] rd_d = 17'b00001000000000000;
	parameter [16:0] wr_a = 17'b00010000000000000;
	parameter [16:0] wr_b = 17'b00100000000000000;
	parameter [16:0] wr_c = 17'b01000000000000000;
	parameter [16:0] wr_d = 17'b10000000000000000;
	reg [16:0] c_state;
	always @(posedge clk or negedge nReset)
		if (!nReset) begin
			c_state <= #(1) idle;
			cmd_ack <= #(1) 1'b0;
			scl_oen <= #(1) 1'b1;
			sda_oen <= #(1) 1'b1;
			sda_chk <= #(1) 1'b0;
		end
		else if (rst | al) begin
			c_state <= #(1) idle;
			cmd_ack <= #(1) 1'b0;
			scl_oen <= #(1) 1'b1;
			sda_oen <= #(1) 1'b1;
			sda_chk <= #(1) 1'b0;
		end
		else begin
			cmd_ack <= #(1) 1'b0;
			if (clk_en)
				case (c_state)
					idle: begin
						case (cmd)
							4'b0001: c_state <= #(1) start_a;
							4'b0010: c_state <= #(1) stop_a;
							4'b0100: c_state <= #(1) wr_a;
							4'b1000: c_state <= #(1) rd_a;
							default: c_state <= #(1) idle;
						endcase
						scl_oen <= #(1) scl_oen;
						sda_oen <= #(1) sda_oen;
						sda_chk <= #(1) 1'b0;
					end
					start_a: begin
						c_state <= #(1) start_b;
						scl_oen <= #(1) scl_oen;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					start_b: begin
						c_state <= #(1) start_c;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					start_c: begin
						c_state <= #(1) start_d;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					start_d: begin
						c_state <= #(1) start_e;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					start_e: begin
						c_state <= #(1) idle;
						cmd_ack <= #(1) 1'b1;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					stop_a: begin
						c_state <= #(1) stop_b;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					stop_b: begin
						c_state <= #(1) stop_c;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					stop_c: begin
						c_state <= #(1) stop_d;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b0;
						sda_chk <= #(1) 1'b0;
					end
					stop_d: begin
						c_state <= #(1) idle;
						cmd_ack <= #(1) 1'b1;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					rd_a: begin
						c_state <= #(1) rd_b;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					rd_b: begin
						c_state <= #(1) rd_c;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					rd_c: begin
						c_state <= #(1) rd_d;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					rd_d: begin
						c_state <= #(1) idle;
						cmd_ack <= #(1) 1'b1;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) 1'b1;
						sda_chk <= #(1) 1'b0;
					end
					wr_a: begin
						c_state <= #(1) wr_b;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) din;
						sda_chk <= #(1) 1'b0;
					end
					wr_b: begin
						c_state <= #(1) wr_c;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) din;
						sda_chk <= #(1) 1'b1;
					end
					wr_c: begin
						c_state <= #(1) wr_d;
						scl_oen <= #(1) 1'b1;
						sda_oen <= #(1) din;
						sda_chk <= #(1) 1'b1;
					end
					wr_d: begin
						c_state <= #(1) idle;
						cmd_ack <= #(1) 1'b1;
						scl_oen <= #(1) 1'b0;
						sda_oen <= #(1) din;
						sda_chk <= #(1) 1'b0;
					end
				endcase
		end
	assign scl_o = 1'b0;
	assign sda_o = 1'b0;
endmodule
module i2c_master_top (
	wb_clk_i,
	wb_rst_i,
	arst_i,
	wb_adr_i,
	wb_dat_i,
	wb_dat_o,
	wb_we_i,
	wb_stb_i,
	wb_cyc_i,
	wb_ack_o,
	wb_inta_o,
	scl_pad_i,
	scl_pad_o,
	scl_padoen_o,
	sda_pad_i,
	sda_pad_o,
	sda_padoen_o
);
	parameter ARST_LVL = 1'b0;
	input wb_clk_i;
	input wb_rst_i;
	input arst_i;
	input [2:0] wb_adr_i;
	input [7:0] wb_dat_i;
	output reg [7:0] wb_dat_o;
	input wb_we_i;
	input wb_stb_i;
	input wb_cyc_i;
	output reg wb_ack_o;
	output reg wb_inta_o;
	input scl_pad_i;
	output wire scl_pad_o;
	output wire scl_padoen_o;
	input sda_pad_i;
	output wire sda_pad_o;
	output wire sda_padoen_o;
	reg [15:0] prer;
	reg [7:0] ctr;
	reg [7:0] txr;
	wire [7:0] rxr;
	reg [7:0] cr;
	wire [7:0] sr;
	wire done;
	wire core_en;
	wire ien;
	wire irxack;
	reg rxack;
	reg tip;
	reg irq_flag;
	wire i2c_busy;
	wire i2c_al;
	reg al;
	wire rst_i = arst_i ^ ARST_LVL;
	wire wb_wacc = wb_we_i & wb_ack_o;
	always @(posedge wb_clk_i) wb_ack_o <= #(1) (wb_cyc_i & wb_stb_i) & ~wb_ack_o;
	always @(posedge wb_clk_i)
		case (wb_adr_i)
			3'b000: wb_dat_o <= #(1) prer[7:0];
			3'b001: wb_dat_o <= #(1) prer[15:8];
			3'b010: wb_dat_o <= #(1) ctr;
			3'b011: wb_dat_o <= #(1) rxr;
			3'b100: wb_dat_o <= #(1) sr;
			default: wb_dat_o <= #(1) 8'h00;
		endcase
	always @(posedge wb_clk_i or negedge rst_i)
		if (!rst_i) begin
			prer <= #(1) 16'hffff;
			ctr <= #(1) 8'h00;
			txr <= #(1) 8'h00;
		end
		else if (wb_rst_i) begin
			prer <= #(1) 16'hffff;
			ctr <= #(1) 8'h00;
			txr <= #(1) 8'h00;
		end
		else if (wb_wacc)
			case (wb_adr_i)
				3'b000: prer[7:0] <= #(1) wb_dat_i;
				3'b001: prer[15:8] <= #(1) wb_dat_i;
				3'b010: ctr <= #(1) wb_dat_i;
				3'b011: txr <= #(1) wb_dat_i;
				default:
					;
			endcase
	always @(posedge wb_clk_i or negedge rst_i)
		if (!rst_i)
			cr <= #(1) 8'h00;
		else if (wb_rst_i)
			cr <= #(1) 8'h00;
		else if (wb_wacc) begin
			if (core_en & (wb_adr_i == 3'b100))
				cr <= #(1) wb_dat_i;
		end
		else begin
			if (done | i2c_al)
				cr[7:4] <= #(1) 4'h0;
			cr[2:1] <= #(1) 2'b00;
			cr[0] <= #(1) 1'b0;
		end
	wire sta = cr[7];
	wire sto = cr[6];
	wire rd = cr[5];
	wire wr = cr[4];
	wire ack = cr[3];
	wire iack = cr[0];
	assign core_en = ctr[7];
	assign ien = ctr[6];
	i2c_master_byte_ctrl byte_controller(
		.clk(wb_clk_i),
		.rst(wb_rst_i),
		.nReset(rst_i),
		.ena(core_en),
		.clk_cnt(prer),
		.start(sta),
		.stop(sto),
		.read(rd),
		.write(wr),
		.ack_in(ack),
		.din(txr),
		.cmd_ack(done),
		.ack_out(irxack),
		.dout(rxr),
		.i2c_busy(i2c_busy),
		.i2c_al(i2c_al),
		.scl_i(scl_pad_i),
		.scl_o(scl_pad_o),
		.scl_oen(scl_padoen_o),
		.sda_i(sda_pad_i),
		.sda_o(sda_pad_o),
		.sda_oen(sda_padoen_o)
	);
	always @(posedge wb_clk_i or negedge rst_i)
		if (!rst_i) begin
			al <= #(1) 1'b0;
			rxack <= #(1) 1'b0;
			tip <= #(1) 1'b0;
			irq_flag <= #(1) 1'b0;
		end
		else if (wb_rst_i) begin
			al <= #(1) 1'b0;
			rxack <= #(1) 1'b0;
			tip <= #(1) 1'b0;
			irq_flag <= #(1) 1'b0;
		end
		else begin
			al <= #(1) i2c_al | (al & ~sta);
			rxack <= #(1) irxack;
			tip <= #(1) rd | wr;
			irq_flag <= #(1) ((done | i2c_al) | irq_flag) & ~iack;
		end
	always @(posedge wb_clk_i or negedge rst_i)
		if (!rst_i)
			wb_inta_o <= #(1) 1'b0;
		else if (wb_rst_i)
			wb_inta_o <= #(1) 1'b0;
		else
			wb_inta_o <= #(1) irq_flag && ien;
	assign sr[7] = rxack;
	assign sr[6] = i2c_busy;
	assign sr[5] = al;
	assign sr[4:2] = 3'h0;
	assign sr[1] = tip;
	assign sr[0] = irq_flag;
endmodule
module boot_rom_wrapper (
	clk_i,
	rst_ni,
	req_i,
	we_i,
	addr_i,
	wdata_i,
	be_i,
	rvalid_o,
	rdata_o
);
	input wire clk_i;
	input wire rst_ni;
	input wire req_i;
	input wire we_i;
	input wire [31:0] addr_i;
	input wire [31:0] wdata_i;
	input wire [3:0] be_i;
	output reg rvalid_o;
	output wire [31:0] rdata_o;
	wire [9:0] rom_word_addr;
	assign rom_word_addr = addr_i[11:2];
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rvalid_o <= 1'b0;
		else
			rvalid_o <= req_i & ~we_i;
	boot_rom #(
		.ADDR_WIDTH(10),
		.INIT_FILE("rtl/system/boot.mem")
	) u_boot_rom_macro(
		.clk_i(clk_i),
		.addr_i(rom_word_addr),
		.data_o(rdata_o)
	);
endmodule
module wb_interconnect (
	clk_i,
	rst_ni,
	wb_cyc_i,
	wb_stb_i,
	wb_we_i,
	wb_adr_i,
	wb_dat_i,
	wb_sel_i,
	wb_ack_o,
	wb_dat_o,
	wb_stall_o,
	bootrom_req_o,
	bootrom_we_o,
	bootrom_addr_o,
	bootrom_wdata_o,
	bootrom_be_o,
	bootrom_rvalid_i,
	bootrom_rdata_i,
	sram_req_o,
	sram_we_o,
	sram_addr_o,
	sram_wdata_o,
	sram_be_o,
	sram_rvalid_i,
	sram_rdata_i,
	xip_req_o,
	xip_we_o,
	xip_addr_o,
	xip_wdata_o,
	xip_be_o,
	xip_rvalid_i,
	xip_rdata_i,
	uart_req_o,
	uart_we_o,
	uart_addr_o,
	uart_wdata_o,
	uart_be_o,
	uart_rvalid_i,
	uart_rdata_i,
	gpio_req_o,
	gpio_we_o,
	gpio_addr_o,
	gpio_wdata_o,
	gpio_be_o,
	gpio_rvalid_i,
	gpio_rdata_i,
	timer_req_o,
	timer_we_o,
	timer_addr_o,
	timer_wdata_o,
	timer_be_o,
	timer_rvalid_i,
	timer_rdata_i,
	spictrl_req_o,
	spictrl_we_o,
	spictrl_addr_o,
	spictrl_wdata_o,
	spictrl_be_o,
	spictrl_rvalid_i,
	spictrl_rdata_i,
	i2c_req_o,
	i2c_we_o,
	i2c_addr_o,
	i2c_wdata_o,
	i2c_be_o,
	i2c_rvalid_i,
	i2c_rdata_i,
	spihost_req_o,
	spihost_we_o,
	spihost_addr_o,
	spihost_wdata_o,
	spihost_be_o,
	spihost_rvalid_i,
	spihost_rdata_i,
	pwm_req_o,
	pwm_addr_o,
	pwm_we_o,
	pwm_be_o,
	pwm_wdata_o,
	pwm_rvalid_i,
	pwm_rdata_i
);
	reg _sv2v_0;
	parameter signed [31:0] AW = 32;
	parameter signed [31:0] DW = 32;
	input wire clk_i;
	input wire rst_ni;
	input wire wb_cyc_i;
	input wire wb_stb_i;
	input wire wb_we_i;
	input wire [AW - 1:0] wb_adr_i;
	input wire [DW - 1:0] wb_dat_i;
	input wire [(DW / 8) - 1:0] wb_sel_i;
	output reg wb_ack_o;
	output reg [DW - 1:0] wb_dat_o;
	output wire wb_stall_o;
	output reg bootrom_req_o;
	output reg bootrom_we_o;
	output reg [AW - 1:0] bootrom_addr_o;
	output reg [DW - 1:0] bootrom_wdata_o;
	output reg [(DW / 8) - 1:0] bootrom_be_o;
	input wire bootrom_rvalid_i;
	input wire [DW - 1:0] bootrom_rdata_i;
	output reg sram_req_o;
	output reg sram_we_o;
	output reg [AW - 1:0] sram_addr_o;
	output reg [DW - 1:0] sram_wdata_o;
	output reg [(DW / 8) - 1:0] sram_be_o;
	input wire sram_rvalid_i;
	input wire [DW - 1:0] sram_rdata_i;
	output reg xip_req_o;
	output reg xip_we_o;
	output reg [AW - 1:0] xip_addr_o;
	output reg [DW - 1:0] xip_wdata_o;
	output reg [(DW / 8) - 1:0] xip_be_o;
	input wire xip_rvalid_i;
	input wire [DW - 1:0] xip_rdata_i;
	output reg uart_req_o;
	output reg uart_we_o;
	output reg [AW - 1:0] uart_addr_o;
	output reg [DW - 1:0] uart_wdata_o;
	output reg [(DW / 8) - 1:0] uart_be_o;
	input wire uart_rvalid_i;
	input wire [DW - 1:0] uart_rdata_i;
	output reg gpio_req_o;
	output reg gpio_we_o;
	output reg [AW - 1:0] gpio_addr_o;
	output reg [DW - 1:0] gpio_wdata_o;
	output reg [(DW / 8) - 1:0] gpio_be_o;
	input wire gpio_rvalid_i;
	input wire [DW - 1:0] gpio_rdata_i;
	output reg timer_req_o;
	output reg timer_we_o;
	output reg [AW - 1:0] timer_addr_o;
	output reg [DW - 1:0] timer_wdata_o;
	output reg [(DW / 8) - 1:0] timer_be_o;
	input wire timer_rvalid_i;
	input wire [DW - 1:0] timer_rdata_i;
	output reg spictrl_req_o;
	output reg spictrl_we_o;
	output reg [AW - 1:0] spictrl_addr_o;
	output reg [DW - 1:0] spictrl_wdata_o;
	output reg [(DW / 8) - 1:0] spictrl_be_o;
	input wire spictrl_rvalid_i;
	input wire [DW - 1:0] spictrl_rdata_i;
	output reg i2c_req_o;
	output reg i2c_we_o;
	output reg [AW - 1:0] i2c_addr_o;
	output reg [DW - 1:0] i2c_wdata_o;
	output reg [(DW / 8) - 1:0] i2c_be_o;
	input wire i2c_rvalid_i;
	input wire [DW - 1:0] i2c_rdata_i;
	output reg spihost_req_o;
	output reg spihost_we_o;
	output reg [AW - 1:0] spihost_addr_o;
	output reg [DW - 1:0] spihost_wdata_o;
	output reg [(DW / 8) - 1:0] spihost_be_o;
	input wire spihost_rvalid_i;
	input wire [DW - 1:0] spihost_rdata_i;
	output reg pwm_req_o;
	output reg [31:0] pwm_addr_o;
	output reg pwm_we_o;
	output reg [3:0] pwm_be_o;
	output reg [31:0] pwm_wdata_o;
	input wire pwm_rvalid_i;
	input wire [31:0] pwm_rdata_i;
	localparam [31:0] BOOTROM_BASE = 32'h00100000;
	localparam [31:0] BOOTROM_MASK = 32'hfffff000;
	localparam [31:0] SRAM_BASE = 32'h00102000;
	localparam [31:0] SRAM_MASK = 32'hffffe000;
	localparam [31:0] XIP_BASE = 32'h20000000;
	localparam [31:0] XIP_MASK = 32'hf0000000;
	localparam [31:0] UART_BASE = 32'h40000000;
	localparam [31:0] UART_MASK = 32'hffffff00;
	localparam [31:0] GPIO_BASE = 32'h40000100;
	localparam [31:0] GPIO_MASK = 32'hffffff00;
	localparam [31:0] TIMER_BASE = 32'h40000200;
	localparam [31:0] TIMER_MASK = 32'hffffff00;
	localparam [31:0] SPICTRL_BASE = 32'h40000300;
	localparam [31:0] SPICTRL_MASK = 32'hffffff00;
	localparam [31:0] I2C_BASE = 32'h40000400;
	localparam [31:0] I2C_MASK = 32'hffffff00;
	localparam [31:0] SPIHOST_BASE = 32'h40000500;
	localparam [31:0] SPIHOST_MASK = 32'hffffff00;
	localparam [31:0] PWM_BASE = 32'h40000600;
	localparam [31:0] PWM_MASK = 32'hffffff00;
	reg bootrom_sel;
	reg sram_sel;
	reg xip_sel;
	reg uart_sel;
	reg gpio_sel;
	reg timer_sel;
	reg spictrl_sel;
	reg i2c_sel;
	reg spihost_sel;
	reg pwm_sel;
	reg [3:0] device_sel_resp;
	reg decode_err_resp;
	always @(*) begin
		if (_sv2v_0)
			;
		bootrom_sel = (wb_adr_i & BOOTROM_MASK) == BOOTROM_BASE;
		sram_sel = (wb_adr_i & SRAM_MASK) == SRAM_BASE;
		xip_sel = (wb_adr_i & XIP_MASK) == XIP_BASE;
		uart_sel = (wb_adr_i & UART_MASK) == UART_BASE;
		gpio_sel = (wb_adr_i & GPIO_MASK) == GPIO_BASE;
		timer_sel = (wb_adr_i & TIMER_MASK) == TIMER_BASE;
		spictrl_sel = (wb_adr_i & SPICTRL_MASK) == SPICTRL_BASE;
		i2c_sel = (wb_adr_i & I2C_MASK) == I2C_BASE;
		spihost_sel = (wb_adr_i & SPIHOST_MASK) == SPIHOST_BASE;
		pwm_sel = (wb_adr_i & PWM_MASK) == PWM_BASE;
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			device_sel_resp <= 4'd0;
			decode_err_resp <= 1'b0;
		end
		else begin
			if (bootrom_sel)
				device_sel_resp <= 4'd0;
			else if (sram_sel)
				device_sel_resp <= 4'd1;
			else if (xip_sel)
				device_sel_resp <= 4'd2;
			else if (uart_sel)
				device_sel_resp <= 4'd3;
			else if (gpio_sel)
				device_sel_resp <= 4'd4;
			else if (timer_sel)
				device_sel_resp <= 4'd5;
			else if (spictrl_sel)
				device_sel_resp <= 4'd6;
			else if (i2c_sel)
				device_sel_resp <= 4'd7;
			else if (spihost_sel)
				device_sel_resp <= 4'd8;
			else if (pwm_sel)
				device_sel_resp <= 4'd9;
			decode_err_resp <= (wb_cyc_i & wb_stb_i) & !(((((((((bootrom_sel | sram_sel) | xip_sel) | uart_sel) | gpio_sel) | timer_sel) | spictrl_sel) | i2c_sel) | spihost_sel) | pwm_sel);
		end
	always @(*) begin
		if (_sv2v_0)
			;
		bootrom_req_o = 1'sb0;
		bootrom_we_o = 1'sb0;
		bootrom_addr_o = 1'sb0;
		bootrom_wdata_o = 1'sb0;
		bootrom_be_o = 1'sb0;
		sram_req_o = 1'sb0;
		sram_we_o = 1'sb0;
		sram_addr_o = 1'sb0;
		sram_wdata_o = 1'sb0;
		sram_be_o = 1'sb0;
		xip_req_o = 1'sb0;
		xip_we_o = 1'sb0;
		xip_addr_o = 1'sb0;
		xip_wdata_o = 1'sb0;
		xip_be_o = 1'sb0;
		uart_req_o = 1'sb0;
		uart_we_o = 1'sb0;
		uart_addr_o = 1'sb0;
		uart_wdata_o = 1'sb0;
		uart_be_o = 1'sb0;
		gpio_req_o = 1'sb0;
		gpio_we_o = 1'sb0;
		gpio_addr_o = 1'sb0;
		gpio_wdata_o = 1'sb0;
		gpio_be_o = 1'sb0;
		timer_req_o = 1'sb0;
		timer_we_o = 1'sb0;
		timer_addr_o = 1'sb0;
		timer_wdata_o = 1'sb0;
		timer_be_o = 1'sb0;
		spictrl_req_o = 1'sb0;
		spictrl_we_o = 1'sb0;
		spictrl_addr_o = 1'sb0;
		spictrl_wdata_o = 1'sb0;
		spictrl_be_o = 1'sb0;
		i2c_req_o = 1'sb0;
		i2c_we_o = 1'sb0;
		i2c_addr_o = 1'sb0;
		i2c_wdata_o = 1'sb0;
		i2c_be_o = 1'sb0;
		spihost_req_o = 1'sb0;
		spihost_we_o = 1'sb0;
		spihost_addr_o = 1'sb0;
		spihost_wdata_o = 1'sb0;
		spihost_be_o = 1'sb0;
		pwm_req_o = 1'sb0;
		pwm_we_o = 1'sb0;
		pwm_addr_o = 1'sb0;
		pwm_wdata_o = 1'sb0;
		pwm_be_o = 1'sb0;
		if (bootrom_sel) begin
			bootrom_req_o = wb_cyc_i & wb_stb_i;
			bootrom_we_o = wb_we_i;
			bootrom_addr_o = wb_adr_i;
			bootrom_wdata_o = wb_dat_i;
			bootrom_be_o = wb_sel_i;
		end
		if (sram_sel) begin
			sram_req_o = wb_cyc_i & wb_stb_i;
			sram_we_o = wb_we_i;
			sram_addr_o = wb_adr_i;
			sram_wdata_o = wb_dat_i;
			sram_be_o = wb_sel_i;
		end
		if (xip_sel) begin
			xip_req_o = wb_cyc_i & wb_stb_i;
			xip_we_o = wb_we_i;
			xip_addr_o = wb_adr_i;
			xip_wdata_o = wb_dat_i;
			xip_be_o = wb_sel_i;
		end
		if (uart_sel) begin
			uart_req_o = wb_cyc_i & wb_stb_i;
			uart_we_o = wb_we_i;
			uart_addr_o = wb_adr_i;
			uart_wdata_o = wb_dat_i;
			uart_be_o = wb_sel_i;
		end
		if (gpio_sel) begin
			gpio_req_o = wb_cyc_i & wb_stb_i;
			gpio_we_o = wb_we_i;
			gpio_addr_o = wb_adr_i;
			gpio_wdata_o = wb_dat_i;
			gpio_be_o = wb_sel_i;
		end
		if (timer_sel) begin
			timer_req_o = wb_cyc_i & wb_stb_i;
			timer_we_o = wb_we_i;
			timer_addr_o = wb_adr_i;
			timer_wdata_o = wb_dat_i;
			timer_be_o = wb_sel_i;
		end
		if (spictrl_sel) begin
			spictrl_req_o = wb_cyc_i & wb_stb_i;
			spictrl_we_o = wb_we_i;
			spictrl_addr_o = wb_adr_i;
			spictrl_wdata_o = wb_dat_i;
			spictrl_be_o = wb_sel_i;
		end
		if (i2c_sel) begin
			i2c_req_o = wb_cyc_i & wb_stb_i;
			i2c_we_o = wb_we_i;
			i2c_addr_o = wb_adr_i;
			i2c_wdata_o = wb_dat_i;
			i2c_be_o = wb_sel_i;
		end
		if (spihost_sel) begin
			spihost_req_o = wb_cyc_i & wb_stb_i;
			spihost_we_o = wb_we_i;
			spihost_addr_o = wb_adr_i;
			spihost_wdata_o = wb_dat_i;
			spihost_be_o = wb_sel_i;
		end
		if (pwm_sel) begin
			pwm_req_o = wb_cyc_i & wb_stb_i;
			pwm_we_o = wb_we_i;
			pwm_addr_o = wb_adr_i;
			pwm_wdata_o = wb_dat_i;
			pwm_be_o = wb_sel_i;
		end
	end
	always @(*) begin
		if (_sv2v_0)
			;
		wb_ack_o = 1'b0;
		wb_dat_o = 1'sb0;
		if (decode_err_resp) begin
			wb_ack_o = 1'b1;
			wb_dat_o = 1'sb0;
		end
		else
			case (device_sel_resp)
				4'd0: begin
					wb_ack_o = bootrom_rvalid_i;
					wb_dat_o = bootrom_rdata_i;
				end
				4'd1: begin
					wb_ack_o = sram_rvalid_i;
					wb_dat_o = sram_rdata_i;
				end
				4'd2: begin
					wb_ack_o = xip_rvalid_i;
					wb_dat_o = xip_rdata_i;
				end
				4'd3: begin
					wb_ack_o = uart_rvalid_i;
					wb_dat_o = uart_rdata_i;
				end
				4'd4: begin
					wb_ack_o = gpio_rvalid_i;
					wb_dat_o = gpio_rdata_i;
				end
				4'd5: begin
					wb_ack_o = timer_rvalid_i;
					wb_dat_o = timer_rdata_i;
				end
				4'd6: begin
					wb_ack_o = spictrl_rvalid_i;
					wb_dat_o = spictrl_rdata_i;
				end
				4'd7: begin
					wb_ack_o = i2c_rvalid_i;
					wb_dat_o = i2c_rdata_i;
				end
				4'd8: begin
					wb_ack_o = spihost_rvalid_i;
					wb_dat_o = spihost_rdata_i;
				end
				4'd9: begin
					wb_ack_o = pwm_rvalid_i;
					wb_dat_o = pwm_rdata_i;
				end
				default: begin
					wb_ack_o = 1'b0;
					wb_dat_o = 1'sb0;
				end
			endcase
	end
	assign wb_stall_o = 1'b0;
	initial _sv2v_0 = 0;
endmodule
module spi_host (
	clk_i,
	rst_ni,
	spi_rx_i,
	spi_tx_o,
	sck_o,
	start_i,
	byte_data_i,
	byte_data_o,
	next_tx_byte_o
);
	reg _sv2v_0;
	parameter [31:0] ClockFrequency = 20000000;
	parameter [31:0] BaudRate = 5000000;
	parameter [0:0] CPOL = 0;
	parameter [0:0] CPHA = 0;
	input clk_i;
	input rst_ni;
	input wire spi_rx_i;
	output reg spi_tx_o;
	output wire sck_o;
	input wire start_i;
	input wire [7:0] byte_data_i;
	output reg [7:0] byte_data_o;
	output reg next_tx_byte_o;
	localparam [31:0] ClocksPerBaud = ClockFrequency / BaudRate;
	localparam [31:0] ToggleCount = ClocksPerBaud / 2;
	localparam [31:0] CountWidth = $clog2(ToggleCount);
	wire [CountWidth - 1:0] limit;
	reg [CountWidth - 1:0] count;
	reg sck;
	wire count_at_limit;
	wire sck_pos;
	wire sck_neg;
	reg [1:0] state_q;
	reg [1:0] state_d;
	wire sck_en;
	assign sck_en = state_q == 2'd2;
	function automatic [CountWidth - 1:0] sv2v_cast_5AF1A;
		input reg [CountWidth - 1:0] inp;
		sv2v_cast_5AF1A = inp;
	endfunction
	assign limit = sv2v_cast_5AF1A(ToggleCount - 1);
	assign count_at_limit = count >= limit;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			count <= 1'sb0;
			sck <= CPOL;
		end
		else if (!(sck_en || start_i)) begin
			count <= 1'sb0;
			sck <= CPOL;
		end
		else if (count_at_limit) begin
			count <= 1'sb0;
			sck <= ~sck;
		end
		else
			count <= count + 1'b1;
	assign sck_o = (sck_en ? sck : CPOL);
	assign sck_pos = count_at_limit && !sck;
	assign sck_neg = count_at_limit && sck;
	reg [2:0] bit_counter_q;
	reg [2:0] bit_counter_d;
	reg [7:0] current_byte_q;
	reg [7:0] current_byte_d;
	reg [7:0] recieved_byte_d;
	reg [7:0] recieved_byte_q;
	always @(*) begin
		if (_sv2v_0)
			;
		spi_tx_o = 1'b1;
		bit_counter_d = bit_counter_q;
		current_byte_d = current_byte_q;
		next_tx_byte_o = 1'b0;
		state_d = state_q;
		byte_data_o = 1'sb0;
		case (state_q)
			2'd0: begin
				spi_tx_o = 1'b1;
				if (start_i)
					state_d = 2'd1;
			end
			2'd1: begin
				state_d = 2'd2;
				bit_counter_d = 3'd7;
				current_byte_d = byte_data_i;
			end
			2'd2: begin
				spi_tx_o = current_byte_q[7];
				current_byte_d = {current_byte_q[6:0], 1'b0};
				if (bit_counter_q == 3'd0)
					state_d = 2'd3;
				else
					bit_counter_d = bit_counter_q - 3'd1;
			end
			2'd3: begin
				spi_tx_o = 1'b1;
				next_tx_byte_o = 1'b1;
				byte_data_o = recieved_byte_q;
				state_d = 2'd0;
			end
		endcase
	end
	generate
		if (CPHA) begin : gen_cpha
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					current_byte_q <= 1'sb0;
					bit_counter_q <= 1'sb0;
					recieved_byte_q <= 1'sb0;
					state_q <= 2'd0;
				end
				else if (sck_pos) begin
					bit_counter_q <= bit_counter_d;
					recieved_byte_q <= recieved_byte_d;
					state_q <= state_d;
				end
				else if (sck_neg) begin
					current_byte_q <= current_byte_d;
					if (state_q == 2'd2)
						recieved_byte_d <= {recieved_byte_q[6:0], spi_rx_i};
				end
		end
		else begin : gen_no_cpha
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					current_byte_q <= 1'sb0;
					bit_counter_q <= 1'sb0;
					recieved_byte_q <= 1'sb0;
					state_q <= 2'd0;
				end
				else if (sck_pos) begin
					current_byte_q <= current_byte_d;
					if (state_q == 2'd2)
						recieved_byte_d <= {recieved_byte_q[6:0], spi_rx_i};
				end
				else if (sck_neg) begin
					bit_counter_q <= bit_counter_d;
					recieved_byte_q <= recieved_byte_d;
					state_q <= state_d;
				end
		end
	endgenerate
	initial _sv2v_0 = 0;
endmodule
module pwm_wrapper (
	clk_i,
	rst_ni,
	device_req_i,
	device_addr_i,
	device_we_i,
	device_be_i,
	device_wdata_i,
	device_rvalid_o,
	device_rdata_o,
	pwm_o
);
	parameter signed [31:0] PwmWidth = 12;
	parameter signed [31:0] PwmCtrSize = 8;
	parameter signed [31:0] BusAddrWidth = 32;
	parameter signed [31:0] BusDataWidth = 32;
	input wire clk_i;
	input wire rst_ni;
	input wire device_req_i;
	input wire [BusAddrWidth - 1:0] device_addr_i;
	input wire device_we_i;
	input wire [3:0] device_be_i;
	input wire [BusDataWidth - 1:0] device_wdata_i;
	output reg device_rvalid_o;
	output wire [BusDataWidth - 1:0] device_rdata_o;
	output wire [PwmWidth - 1:0] pwm_o;
	localparam [31:0] AddrWidth = 10;
	localparam [31:0] PwmIdxOffset = $clog2(BusAddrWidth / 8) + 1;
	localparam [31:0] PwmIdxWidth = AddrWidth - PwmIdxOffset;
	genvar _gv_i_35;
	generate
		for (_gv_i_35 = 0; _gv_i_35 < PwmWidth; _gv_i_35 = _gv_i_35 + 1) begin : gen_pwm
			localparam i = _gv_i_35;
			wire [PwmCtrSize - 1:0] data_d;
			reg [PwmCtrSize - 1:0] counter_q;
			reg [PwmCtrSize - 1:0] pulse_width_q;
			wire counter_en;
			wire pulse_width_en;
			wire [PwmIdxWidth - 1:0] pwm_idx;
			assign pwm_idx = i;
			assign data_d = device_wdata_i[PwmCtrSize - 1:0];
			assign counter_en = ((device_req_i & device_we_i) & (device_addr_i[9:PwmIdxOffset] == pwm_idx)) & device_addr_i[PwmIdxOffset - 1];
			assign pulse_width_en = ((device_req_i & device_we_i) & (device_addr_i[9:PwmIdxOffset] == pwm_idx)) & ~device_addr_i[PwmIdxOffset - 1];
			always @(posedge clk_i or negedge rst_ni)
				if (!rst_ni) begin
					counter_q <= 1'sb0;
					pulse_width_q <= 1'sb0;
				end
				else begin
					if (counter_en)
						counter_q <= data_d;
					if (pulse_width_en)
						pulse_width_q <= data_d;
				end
			pwm #(.CtrSize(PwmCtrSize)) u_pwm(
				.clk_i(clk_i),
				.rst_ni(rst_ni),
				.pulse_width_i(pulse_width_q),
				.max_counter_i(counter_q),
				.modulated_o(pwm_o[i])
			);
		end
	endgenerate
	assign device_rdata_o = 32'b00000000000000000000000000000000;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			device_rvalid_o <= 1'b0;
		else
			device_rvalid_o <= device_req_i;
	wire _unused;
	assign _unused = ^device_be_i ^ ^device_wdata_i;
endmodule
module sram_model (
	clk_i,
	req_i,
	addr_i,
	we_i,
	wdata_i,
	rdata_o
);
	parameter [31:0] Width = 32;
	parameter [31:0] Depth = 2048;
	parameter MemInitFile = "";
	input wire clk_i;
	input wire req_i;
	input wire [$clog2(Depth) - 1:0] addr_i;
	input wire [(Width / 8) - 1:0] we_i;
	input wire [Width - 1:0] wdata_i;
	output reg [Width - 1:0] rdata_o;
	reg [Width - 1:0] mem [0:Depth - 1];
	always @(posedge clk_i)
		if (req_i) begin
			begin : sv2v_autoblock_1
				reg signed [31:0] b;
				for (b = 0; b < (Width / 8); b = b + 1)
					if (we_i[b])
						mem[addr_i][b * 8+:8] <= wdata_i[b * 8+:8];
			end
			rdata_o <= mem[addr_i];
		end
	initial if (MemInitFile != "") begin
		$display("sram_model %m: initialising from '%s'", MemInitFile);
		$readmemh(MemInitFile, mem);
	end
endmodule
module obi2wb (
	clk_i,
	rst_ni,
	obi_req_i,
	obi_gnt_o,
	obi_addr_i,
	obi_we_i,
	obi_be_i,
	obi_wdata_i,
	obi_rvalid_o,
	obi_rdata_o,
	wb_cyc_o,
	wb_stb_o,
	wb_we_o,
	wb_adr_o,
	wb_dat_o,
	wb_sel_o,
	wb_ack_i,
	wb_dat_i,
	wb_stall_i
);
	reg _sv2v_0;
	parameter AW = 32;
	parameter DW = 32;
	input wire clk_i;
	input wire rst_ni;
	input wire obi_req_i;
	output wire obi_gnt_o;
	input wire [AW - 1:0] obi_addr_i;
	input wire obi_we_i;
	input wire [(DW / 8) - 1:0] obi_be_i;
	input wire [DW - 1:0] obi_wdata_i;
	output wire obi_rvalid_o;
	output wire [DW - 1:0] obi_rdata_o;
	output wire wb_cyc_o;
	output wire wb_stb_o;
	output wire wb_we_o;
	output wire [AW - 1:0] wb_adr_o;
	output wire [DW - 1:0] wb_dat_o;
	output wire [(DW / 8) - 1:0] wb_sel_o;
	input wire wb_ack_i;
	input wire [DW - 1:0] wb_dat_i;
	input wire wb_stall_i;
	reg [0:0] state_q;
	reg [0:0] state_d;
	reg [AW - 1:0] addr_q;
	reg [DW - 1:0] wdata_q;
	reg [(DW / 8) - 1:0] be_q;
	reg we_q;
	reg [DW - 1:0] rdata_q;
	reg req_sent_q;
	reg wb_active_q;
	reg obi_rvalid_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			state_q <= 1'd0;
			addr_q <= 1'sb0;
			wdata_q <= 1'sb0;
			be_q <= 1'sb0;
			we_q <= 1'sb0;
			rdata_q <= 1'sb0;
			req_sent_q <= 1'b0;
			wb_active_q <= 1'b0;
			obi_rvalid_q <= 1'b0;
		end
		else begin
			state_q <= state_d;
			obi_rvalid_q <= 1'b0;
			if ((((state_q == 1'd0) && obi_req_i) && !req_sent_q) && !wb_stall_i) begin
				addr_q <= obi_addr_i;
				wdata_q <= obi_wdata_i;
				be_q <= obi_be_i;
				we_q <= obi_we_i;
				req_sent_q <= 1'b1;
			end
			if ((((state_q == 1'd0) && obi_req_i) && !req_sent_q) && !wb_stall_i)
				wb_active_q <= 1'b1;
			else
				wb_active_q <= 1'b0;
			if ((state_q == 1'd1) && wb_ack_i) begin
				rdata_q <= wb_dat_i;
				obi_rvalid_q <= 1'b1;
				req_sent_q <= 1'b0;
			end
		end
	always @(*) begin
		if (_sv2v_0)
			;
		state_d = state_q;
		case (state_q)
			1'd0:
				if (obi_req_i && !req_sent_q)
					state_d = 1'd1;
			1'd1:
				if (wb_ack_i)
					state_d = 1'd0;
		endcase
	end
	assign wb_cyc_o = wb_active_q;
	assign wb_stb_o = wb_active_q;
	assign wb_we_o = we_q;
	assign wb_adr_o = addr_q;
	assign wb_dat_o = wdata_q;
	assign wb_sel_o = be_q;
	assign obi_gnt_o = (((state_q == 1'd0) && obi_req_i) && !req_sent_q) && !wb_stall_i;
	assign obi_rvalid_o = obi_rvalid_q;
	assign obi_rdata_o = rdata_q;
	initial _sv2v_0 = 0;
endmodule
module debounce (
	clk_i,
	rst_ni,
	btn_i,
	btn_o
);
	parameter [31:0] ClkCount = 500;
	input wire clk_i;
	input wire rst_ni;
	input wire btn_i;
	output wire btn_o;
	wire [$clog2(ClkCount + 1) - 1:0] cnt_d;
	reg [$clog2(ClkCount + 1) - 1:0] cnt_q;
	wire btn_d;
	reg btn_q;
	assign btn_o = btn_q;
	always @(posedge clk_i or negedge rst_ni) begin : p_fsm_reg
		if (!rst_ni) begin
			cnt_q <= 1'sb0;
			btn_q <= 1'sb0;
		end
		else begin
			cnt_q <= cnt_d;
			btn_q <= btn_d;
		end
	end
	function automatic [31:0] sv2v_cast_32;
		input reg [31:0] inp;
		sv2v_cast_32 = inp;
	endfunction
	assign btn_d = (sv2v_cast_32(cnt_q) >= ClkCount ? btn_i : btn_q);
	assign cnt_d = ((btn_i == btn_q) || (sv2v_cast_32(cnt_q) >= ClkCount) ? {$clog2(ClkCount + 1) {1'sb0}} : cnt_q + 1);
endmodule
module dm_top (
	clk_i,
	rst_ni,
	testmode_i,
	ndmreset_o,
	dmactive_o,
	debug_req_o,
	unavailable_i,
	device_req_i,
	device_we_i,
	device_addr_i,
	device_be_i,
	device_wdata_i,
	device_rdata_o,
	host_req_o,
	host_add_o,
	host_we_o,
	host_wdata_o,
	host_be_o,
	host_gnt_i,
	host_r_valid_i,
	host_r_rdata_i,
	tck_i,
	tms_i,
	trst_ni,
	td_i,
	td_o
);
	parameter signed [31:0] NrHarts = 1;
	parameter [31:0] IdcodeValue = 32'h00000001;
	parameter signed [31:0] BusWidth = 32;
	input wire clk_i;
	input wire rst_ni;
	input wire testmode_i;
	output wire ndmreset_o;
	output wire dmactive_o;
	output wire [NrHarts - 1:0] debug_req_o;
	input wire [NrHarts - 1:0] unavailable_i;
	input wire device_req_i;
	input wire device_we_i;
	input wire [BusWidth - 1:0] device_addr_i;
	input wire [(BusWidth / 8) - 1:0] device_be_i;
	input wire [BusWidth - 1:0] device_wdata_i;
	output wire [BusWidth - 1:0] device_rdata_o;
	output wire host_req_o;
	output wire [BusWidth - 1:0] host_add_o;
	output wire host_we_o;
	output wire [BusWidth - 1:0] host_wdata_o;
	output wire [(BusWidth / 8) - 1:0] host_be_o;
	input wire host_gnt_i;
	input wire host_r_valid_i;
	input wire [BusWidth - 1:0] host_r_rdata_i;
	input wire tck_i;
	input wire tms_i;
	input wire trst_ni;
	input wire td_i;
	output wire td_o;
	localparam [NrHarts - 1:0] SelectableHarts = {NrHarts {1'b1}};
	wire [(NrHarts * 32) - 1:0] hartinfo;
	wire [NrHarts - 1:0] halted;
	wire [NrHarts - 1:0] resumeack;
	wire [NrHarts - 1:0] haltreq;
	wire [NrHarts - 1:0] resumereq;
	wire clear_resumeack;
	wire cmd_valid;
	wire [31:0] cmd;
	wire cmderror_valid;
	wire [2:0] cmderror;
	wire cmdbusy;
	localparam [4:0] dm_ProgBufSize = 5'h08;
	wire [255:0] progbuf;
	localparam [3:0] dm_DataCount = 4'h2;
	wire [63:0] data_csrs_mem;
	wire [63:0] data_mem_csrs;
	wire data_valid;
	wire [19:0] hartsel;
	wire [BusWidth - 1:0] sbaddress_csrs_sba;
	wire [BusWidth - 1:0] sbaddress_sba_csrs;
	wire sbaddress_write_valid;
	wire sbreadonaddr;
	wire sbautoincrement;
	wire [2:0] sbaccess;
	wire sbreadondata;
	wire [BusWidth - 1:0] sbdata_write;
	wire sbdata_read_valid;
	wire sbdata_write_valid;
	wire [BusWidth - 1:0] sbdata_read;
	wire sbdata_valid;
	wire sbbusy;
	wire sberror_valid;
	wire [2:0] sberror;
	wire ndmreset;
	wire [40:0] dmi_req;
	wire [33:0] dmi_rsp;
	wire dmi_req_valid;
	wire dmi_req_ready;
	wire dmi_rsp_valid;
	wire dmi_rsp_ready;
	wire dmi_rst_n;
	localparam [11:0] dm_DataAddr = 12'h380;
	localparam [31:0] DebugHartInfo = {16'h0021, dm_DataCount, dm_DataAddr};
	genvar _gv_i_36;
	generate
		for (_gv_i_36 = 0; _gv_i_36 < NrHarts; _gv_i_36 = _gv_i_36 + 1) begin : gen_dm_hart_ctrl
			localparam i = _gv_i_36;
			assign hartinfo[i * 32+:32] = DebugHartInfo;
		end
	endgenerate
	assign ndmreset_o = ndmreset;
	dm_csrs #(
		.NrHarts(NrHarts),
		.BusWidth(BusWidth),
		.SelectableHarts(SelectableHarts)
	) i_dm_csrs(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.testmode_i(testmode_i),
		.dmi_rst_ni(dmi_rst_n),
		.dmi_req_valid_i(dmi_req_valid),
		.dmi_req_ready_o(dmi_req_ready),
		.dmi_req_i(dmi_req),
		.dmi_resp_valid_o(dmi_rsp_valid),
		.dmi_resp_ready_i(dmi_rsp_ready),
		.dmi_resp_o(dmi_rsp),
		.ndmreset_o(ndmreset),
		.dmactive_o(dmactive_o),
		.hartsel_o(hartsel),
		.hartinfo_i(hartinfo),
		.halted_i(halted),
		.unavailable_i(unavailable_i),
		.resumeack_i(resumeack),
		.haltreq_o(haltreq),
		.resumereq_o(resumereq),
		.clear_resumeack_o(clear_resumeack),
		.cmd_valid_o(cmd_valid),
		.cmd_o(cmd),
		.cmderror_valid_i(cmderror_valid),
		.cmderror_i(cmderror),
		.cmdbusy_i(cmdbusy),
		.progbuf_o(progbuf),
		.data_i(data_mem_csrs),
		.data_valid_i(data_valid),
		.data_o(data_csrs_mem),
		.sbaddress_o(sbaddress_csrs_sba),
		.sbaddress_i(sbaddress_sba_csrs),
		.sbaddress_write_valid_o(sbaddress_write_valid),
		.sbreadonaddr_o(sbreadonaddr),
		.sbautoincrement_o(sbautoincrement),
		.sbaccess_o(sbaccess),
		.sbreadondata_o(sbreadondata),
		.sbdata_o(sbdata_write),
		.sbdata_read_valid_o(sbdata_read_valid),
		.sbdata_write_valid_o(sbdata_write_valid),
		.sbdata_i(sbdata_read),
		.sbdata_valid_i(sbdata_valid),
		.sbbusy_i(sbbusy),
		.sberror_valid_i(sberror_valid),
		.sberror_i(sberror)
	);
	dm_sba #(.BusWidth(BusWidth)) i_dm_sba(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.master_req_o(host_req_o),
		.master_add_o(host_add_o),
		.master_we_o(host_we_o),
		.master_wdata_o(host_wdata_o),
		.master_be_o(host_be_o),
		.master_gnt_i(host_gnt_i),
		.master_r_valid_i(host_r_valid_i),
		.master_r_err_i(1'b0),
		.master_r_other_err_i(1'b0),
		.master_r_rdata_i(host_r_rdata_i),
		.dmactive_i(dmactive_o),
		.sbaddress_i(sbaddress_csrs_sba),
		.sbaddress_o(sbaddress_sba_csrs),
		.sbaddress_write_valid_i(sbaddress_write_valid),
		.sbreadonaddr_i(sbreadonaddr),
		.sbautoincrement_i(sbautoincrement),
		.sbaccess_i(sbaccess),
		.sbreadondata_i(sbreadondata),
		.sbdata_i(sbdata_write),
		.sbdata_read_valid_i(sbdata_read_valid),
		.sbdata_write_valid_i(sbdata_write_valid),
		.sbdata_o(sbdata_read),
		.sbdata_valid_o(sbdata_valid),
		.sbbusy_o(sbbusy),
		.sberror_valid_o(sberror_valid),
		.sberror_o(sberror)
	);
	dm_mem #(
		.NrHarts(NrHarts),
		.BusWidth(BusWidth),
		.SelectableHarts(SelectableHarts),
		.DmBaseAddress(1)
	) i_dm_mem(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.ndmreset_i(ndmreset),
		.debug_req_o(debug_req_o),
		.hartsel_i(hartsel),
		.haltreq_i(haltreq),
		.resumereq_i(resumereq),
		.clear_resumeack_i(clear_resumeack),
		.halted_o(halted),
		.resuming_o(resumeack),
		.cmd_valid_i(cmd_valid),
		.cmd_i(cmd),
		.cmderror_valid_o(cmderror_valid),
		.cmderror_o(cmderror),
		.cmdbusy_o(cmdbusy),
		.progbuf_i(progbuf),
		.data_i(data_csrs_mem),
		.data_o(data_mem_csrs),
		.data_valid_o(data_valid),
		.req_i(device_req_i),
		.we_i(device_we_i),
		.addr_i(device_addr_i),
		.wdata_i(device_wdata_i),
		.be_i(device_be_i),
		.rdata_o(device_rdata_o)
	);
	dmi_jtag #(.IdcodeValue(IdcodeValue)) dap(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.testmode_i(testmode_i),
		.test_rst_ni(1'b1),
		.dmi_rst_no(dmi_rst_n),
		.dmi_req_o(dmi_req),
		.dmi_req_valid_o(dmi_req_valid),
		.dmi_req_ready_i(dmi_req_ready),
		.dmi_resp_i(dmi_rsp),
		.dmi_resp_ready_o(dmi_rsp_ready),
		.dmi_resp_valid_i(dmi_rsp_valid),
		.tck_i(tck_i),
		.tms_i(tms_i),
		.trst_ni(trst_ni),
		.td_i(td_i),
		.td_o(td_o),
		.tdo_oe_o()
	);
endmodule
module i2c_wb_wrapper (
	clk_i,
	rst_i,
	i2c_req_o,
	i2c_we_o,
	i2c_addr_o,
	i2c_wdata_o,
	i2c_be_o,
	i2c_rvalid_i,
	i2c_rdata_i,
	scl_pad_i,
	scl_pad_o,
	scl_padoen_o,
	sda_pad_i,
	sda_pad_o,
	sda_padoen_o,
	wb_inta_o
);
	parameter signed [31:0] AW = 32;
	parameter signed [31:0] DW = 32;
	input wire clk_i;
	input wire rst_i;
	input wire i2c_req_o;
	input wire i2c_we_o;
	input wire [AW - 1:0] i2c_addr_o;
	input wire [DW - 1:0] i2c_wdata_o;
	input wire [(DW / 8) - 1:0] i2c_be_o;
	output wire i2c_rvalid_i;
	output wire [DW - 1:0] i2c_rdata_i;
	input wire scl_pad_i;
	output wire scl_pad_o;
	output wire scl_padoen_o;
	input wire sda_pad_i;
	output wire sda_pad_o;
	output wire sda_padoen_o;
	output wire wb_inta_o;
	wire [2:0] wb_adr_i;
	wire [7:0] wb_dat_i;
	wire [7:0] wb_dat_o;
	wire wb_we_i;
	wire wb_stb_i;
	wire wb_cyc_i;
	wire wb_ack_o;
	wire wb_rst_i;
	wire arst_i;
	assign wb_cyc_i = i2c_req_o;
	assign wb_stb_i = i2c_req_o;
	assign wb_we_i = i2c_we_o;
	assign wb_adr_i = i2c_addr_o[2:0];
	assign wb_dat_i = i2c_wdata_o[7:0];
	assign wb_rst_i = rst_i;
	assign arst_i = ~rst_i;
	assign i2c_rvalid_i = wb_ack_o;
	assign i2c_rdata_i = {{DW - 8 {1'b0}}, wb_dat_o};
	i2c_master_top u_i2c_master_top(
		.wb_clk_i(clk_i),
		.wb_rst_i(wb_rst_i),
		.arst_i(arst_i),
		.wb_adr_i(wb_adr_i),
		.wb_dat_i(wb_dat_i),
		.wb_dat_o(wb_dat_o),
		.wb_we_i(wb_we_i),
		.wb_stb_i(wb_stb_i),
		.wb_cyc_i(wb_cyc_i),
		.wb_ack_o(wb_ack_o),
		.wb_inta_o(wb_inta_o),
		.scl_pad_i(scl_pad_i),
		.scl_pad_o(scl_pad_o),
		.scl_padoen_o(scl_padoen_o),
		.sda_pad_i(sda_pad_i),
		.sda_pad_o(sda_pad_o),
		.sda_padoen_o(sda_padoen_o)
	);
endmodule
module wrapper_top (
	clk_i,
	rst_ni,
	obi_instr_req_i,
	obi_instr_gnt_o,
	obi_instr_addr_i,
	obi_instr_rvalid_o,
	obi_instr_rdata_o,
	obi_req_i,
	obi_gnt_o,
	obi_addr_i,
	obi_we_i,
	obi_be_i,
	obi_wdata_i,
	obi_rvalid_o,
	obi_rdata_o,
	uart_rx_i,
	uart_tx_o,
	uart_irq_o,
	gp_i,
	gp_o,
	timer_intr_o,
	spi_rx_i,
	spi_tx_o,
	spi_sck_o,
	spi_byte_data_o,
	i2c_scl_i,
	i2c_scl_o,
	i2c_scl_oe_o,
	i2c_sda_i,
	i2c_sda_o,
	i2c_sda_oe_o,
	i2c_irq_o,
	pwm_o,
	dbg_req_o,
	dbg_we_o,
	dbg_addr_o,
	dbg_wdata_o,
	dbg_be_o,
	dbg_rdata_i
);
	parameter [31:0] AW = 32;
	parameter [31:0] DW = 32;
	parameter [31:0] BootRomAddrWidth = 10;
	parameter [31:0] SramWordAddrWidth = 11;
	parameter [31:0] GpiWidth = 8;
	parameter [31:0] GpoWidth = 16;
	parameter [31:0] ClockFrequency = 20000000;
	parameter [31:0] BaudRate = 115200;
	parameter [31:0] PwmWidth = 12;
	input wire clk_i;
	input wire rst_ni;
	input wire obi_instr_req_i;
	output wire obi_instr_gnt_o;
	input wire [AW - 1:0] obi_instr_addr_i;
	output wire obi_instr_rvalid_o;
	output wire [DW - 1:0] obi_instr_rdata_o;
	input wire obi_req_i;
	output wire obi_gnt_o;
	input wire [AW - 1:0] obi_addr_i;
	input wire obi_we_i;
	input wire [(DW / 8) - 1:0] obi_be_i;
	input wire [DW - 1:0] obi_wdata_i;
	output wire obi_rvalid_o;
	output wire [DW - 1:0] obi_rdata_o;
	input wire uart_rx_i;
	output wire uart_tx_o;
	output wire uart_irq_o;
	input wire [GpiWidth - 1:0] gp_i;
	output wire [GpoWidth - 1:0] gp_o;
	output wire timer_intr_o;
	input wire spi_rx_i;
	output wire spi_tx_o;
	output wire spi_sck_o;
	output wire [7:0] spi_byte_data_o;
	input wire i2c_scl_i;
	output wire i2c_scl_o;
	output wire i2c_scl_oe_o;
	input wire i2c_sda_i;
	output wire i2c_sda_o;
	output wire i2c_sda_oe_o;
	output wire i2c_irq_o;
	output wire [PwmWidth - 1:0] pwm_o;
	output wire dbg_req_o;
	output wire dbg_we_o;
	output wire [AW - 1:0] dbg_addr_o;
	output wire [DW - 1:0] dbg_wdata_o;
	output wire [(DW / 8) - 1:0] dbg_be_o;
	input wire [DW - 1:0] dbg_rdata_i;
	localparam [AW - 1:0] UART_BASE = 32'h40000000;
	localparam [AW - 1:0] GPIO_BASE = 32'h40000100;
	localparam [AW - 1:0] TIMER_BASE = 32'h40000200;
	localparam [AW - 1:0] I2C_BASE = 32'h40000400;
	localparam [AW - 1:0] SPIHOST_BASE = 32'h40000500;
	localparam [AW - 1:0] PWM_BASE = 32'h40000600;
	localparam [AW - 1:0] DEBUG_BASE = 32'h1a110000;
	localparam [AW - 1:0] DEBUG_SIZE = 32'h00010000;
	localparam [AW - 1:0] DEBUG_MASK = ~(DEBUG_SIZE - 32'd1);
	wire arb_req;
	wire arb_gnt;
	wire arb_rvalid;
	wire arb_we;
	wire [AW - 1:0] arb_addr;
	wire [(DW / 8) - 1:0] arb_be;
	wire [DW - 1:0] arb_wdata;
	wire [DW - 1:0] arb_rdata;
	reg pending;
	reg pending_data;
	reg pending_debug;
	wire arb_sel_data;
	assign arb_sel_data = obi_req_i;
	assign arb_req = !pending && (obi_req_i || obi_instr_req_i);
	assign arb_addr = (arb_sel_data ? obi_addr_i : obi_instr_addr_i);
	assign arb_we = (arb_sel_data ? obi_we_i : 1'b0);
	assign arb_be = (arb_sel_data ? obi_be_i : {DW / 8 {1'b0}});
	assign arb_wdata = (arb_sel_data ? obi_wdata_i : {DW {1'b0}});
	wire debug_sel;
	assign debug_sel = (arb_addr & DEBUG_MASK) == DEBUG_BASE;
	wire dbg_req_int;
	reg dbg_rvalid_int;
	assign dbg_req_int = arb_req && debug_sel;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			dbg_rvalid_int <= 1'b0;
		else
			dbg_rvalid_int <= dbg_req_int;
	wire wb_obi_req;
	wire wb_obi_gnt;
	wire wb_obi_rvalid;
	wire [DW - 1:0] wb_obi_rdata;
	assign wb_obi_req = arb_req && !debug_sel;
	assign arb_gnt = arb_req && (debug_sel ? 1'b1 : wb_obi_gnt);
	assign arb_rvalid = dbg_rvalid_int | wb_obi_rvalid;
	assign arb_rdata = (pending_debug ? dbg_rdata_i : wb_obi_rdata);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			pending <= 1'b0;
			pending_data <= 1'b0;
			pending_debug <= 1'b0;
		end
		else if (!pending && arb_gnt) begin
			pending <= 1'b1;
			pending_data <= arb_sel_data;
			pending_debug <= debug_sel;
		end
		else if (pending && arb_rvalid)
			pending <= 1'b0;
	assign obi_gnt_o = (!pending && obi_req_i) && arb_gnt;
	assign obi_instr_gnt_o = ((!pending && !obi_req_i) && obi_instr_req_i) && arb_gnt;
	assign obi_rvalid_o = (pending && pending_data) && arb_rvalid;
	assign obi_instr_rvalid_o = (pending && !pending_data) && arb_rvalid;
	assign obi_rdata_o = arb_rdata;
	assign obi_instr_rdata_o = arb_rdata;
	assign dbg_req_o = dbg_req_int;
	assign dbg_we_o = arb_we;
	assign dbg_addr_o = arb_addr;
	assign dbg_wdata_o = arb_wdata;
	assign dbg_be_o = arb_be;
	wire wb_cyc;
	wire wb_stb;
	wire wb_we;
	wire [AW - 1:0] wb_adr;
	wire [DW - 1:0] wb_m_dat;
	wire [(DW / 8) - 1:0] wb_sel;
	wire wb_ack;
	wire [DW - 1:0] wb_s_dat;
	wire wb_stall;
	obi2wb #(
		.AW(AW),
		.DW(DW)
	) u_obi2wb(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.obi_req_i(wb_obi_req),
		.obi_gnt_o(wb_obi_gnt),
		.obi_addr_i(arb_addr),
		.obi_we_i(arb_we),
		.obi_be_i(arb_be),
		.obi_wdata_i(arb_wdata),
		.obi_rvalid_o(wb_obi_rvalid),
		.obi_rdata_o(wb_obi_rdata),
		.wb_cyc_o(wb_cyc),
		.wb_stb_o(wb_stb),
		.wb_we_o(wb_we),
		.wb_adr_o(wb_adr),
		.wb_dat_o(wb_m_dat),
		.wb_sel_o(wb_sel),
		.wb_ack_i(wb_ack),
		.wb_dat_i(wb_s_dat),
		.wb_stall_i(wb_stall)
	);
	wire bootrom_req;
	wire bootrom_we;
	wire [AW - 1:0] bootrom_addr;
	wire [DW - 1:0] bootrom_wdata;
	wire [(DW / 8) - 1:0] bootrom_be;
	reg bootrom_rvalid;
	wire [DW - 1:0] bootrom_rdata;
	wire sram_req;
	wire sram_we;
	wire [AW - 1:0] sram_addr;
	wire [DW - 1:0] sram_wdata;
	wire [(DW / 8) - 1:0] sram_be;
	wire sram_rvalid;
	wire [DW - 1:0] sram_rdata;
	wire xip_req;
	wire xip_we;
	wire [AW - 1:0] xip_addr;
	wire [DW - 1:0] xip_wdata;
	wire [(DW / 8) - 1:0] xip_be;
	reg xip_rvalid;
	wire [DW - 1:0] xip_rdata;
	wire uart_req;
	wire uart_we;
	wire [AW - 1:0] uart_addr;
	wire [DW - 1:0] uart_wdata;
	wire [(DW / 8) - 1:0] uart_be;
	wire uart_rvalid;
	wire [DW - 1:0] uart_rdata;
	wire gpio_req;
	wire gpio_we;
	wire [AW - 1:0] gpio_addr;
	wire [DW - 1:0] gpio_wdata;
	wire [(DW / 8) - 1:0] gpio_be;
	wire gpio_rvalid;
	wire [DW - 1:0] gpio_rdata;
	wire timer_req;
	wire timer_we;
	wire [AW - 1:0] timer_addr;
	wire [DW - 1:0] timer_wdata;
	wire [(DW / 8) - 1:0] timer_be;
	wire timer_rvalid;
	wire [DW - 1:0] timer_rdata;
	wire timer_err;
	wire spictrl_req;
	wire spictrl_we;
	wire [AW - 1:0] spictrl_addr;
	wire [DW - 1:0] spictrl_wdata;
	wire [(DW / 8) - 1:0] spictrl_be;
	reg spictrl_rvalid;
	wire [DW - 1:0] spictrl_rdata;
	wire i2c_req;
	wire i2c_we;
	wire [AW - 1:0] i2c_addr;
	wire [DW - 1:0] i2c_wdata;
	wire [(DW / 8) - 1:0] i2c_be;
	wire i2c_rvalid;
	wire [DW - 1:0] i2c_rdata;
	wire spihost_req;
	wire spihost_we;
	wire [AW - 1:0] spihost_addr;
	wire [DW - 1:0] spihost_wdata;
	wire [(DW / 8) - 1:0] spihost_be;
	wire spihost_rvalid;
	wire [DW - 1:0] spihost_rdata;
	wire pwm_req;
	wire pwm_we;
	wire [AW - 1:0] pwm_addr;
	wire [DW - 1:0] pwm_wdata;
	wire [(DW / 8) - 1:0] pwm_be;
	wire pwm_rvalid;
	wire [DW - 1:0] pwm_rdata;
	wb_interconnect #(
		.AW(AW),
		.DW(DW)
	) u_wb_interconnect(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.wb_cyc_i(wb_cyc),
		.wb_stb_i(wb_stb),
		.wb_we_i(wb_we),
		.wb_adr_i(wb_adr),
		.wb_dat_i(wb_m_dat),
		.wb_sel_i(wb_sel),
		.wb_ack_o(wb_ack),
		.wb_dat_o(wb_s_dat),
		.wb_stall_o(wb_stall),
		.bootrom_req_o(bootrom_req),
		.bootrom_we_o(bootrom_we),
		.bootrom_addr_o(bootrom_addr),
		.bootrom_wdata_o(bootrom_wdata),
		.bootrom_be_o(bootrom_be),
		.bootrom_rvalid_i(bootrom_rvalid),
		.bootrom_rdata_i(bootrom_rdata),
		.sram_req_o(sram_req),
		.sram_we_o(sram_we),
		.sram_addr_o(sram_addr),
		.sram_wdata_o(sram_wdata),
		.sram_be_o(sram_be),
		.sram_rvalid_i(sram_rvalid),
		.sram_rdata_i(sram_rdata),
		.xip_req_o(xip_req),
		.xip_we_o(xip_we),
		.xip_addr_o(xip_addr),
		.xip_wdata_o(xip_wdata),
		.xip_be_o(xip_be),
		.xip_rvalid_i(xip_rvalid),
		.xip_rdata_i(xip_rdata),
		.uart_req_o(uart_req),
		.uart_we_o(uart_we),
		.uart_addr_o(uart_addr),
		.uart_wdata_o(uart_wdata),
		.uart_be_o(uart_be),
		.uart_rvalid_i(uart_rvalid),
		.uart_rdata_i(uart_rdata),
		.gpio_req_o(gpio_req),
		.gpio_we_o(gpio_we),
		.gpio_addr_o(gpio_addr),
		.gpio_wdata_o(gpio_wdata),
		.gpio_be_o(gpio_be),
		.gpio_rvalid_i(gpio_rvalid),
		.gpio_rdata_i(gpio_rdata),
		.timer_req_o(timer_req),
		.timer_we_o(timer_we),
		.timer_addr_o(timer_addr),
		.timer_wdata_o(timer_wdata),
		.timer_be_o(timer_be),
		.timer_rvalid_i(timer_rvalid),
		.timer_rdata_i(timer_rdata),
		.spictrl_req_o(spictrl_req),
		.spictrl_we_o(spictrl_we),
		.spictrl_addr_o(spictrl_addr),
		.spictrl_wdata_o(spictrl_wdata),
		.spictrl_be_o(spictrl_be),
		.spictrl_rvalid_i(spictrl_rvalid),
		.spictrl_rdata_i(spictrl_rdata),
		.i2c_req_o(i2c_req),
		.i2c_we_o(i2c_we),
		.i2c_addr_o(i2c_addr),
		.i2c_wdata_o(i2c_wdata),
		.i2c_be_o(i2c_be),
		.i2c_rvalid_i(i2c_rvalid),
		.i2c_rdata_i(i2c_rdata),
		.spihost_req_o(spihost_req),
		.spihost_we_o(spihost_we),
		.spihost_addr_o(spihost_addr),
		.spihost_wdata_o(spihost_wdata),
		.spihost_be_o(spihost_be),
		.spihost_rvalid_i(spihost_rvalid),
		.spihost_rdata_i(spihost_rdata),
		.pwm_req_o(pwm_req),
		.pwm_we_o(pwm_we),
		.pwm_addr_o(pwm_addr),
		.pwm_wdata_o(pwm_wdata),
		.pwm_be_o(pwm_be),
		.pwm_rvalid_i(pwm_rvalid),
		.pwm_rdata_i(pwm_rdata)
	);
	boot_rom #(
		.ADDR_WIDTH(BootRomAddrWidth),
		.INIT_FILE("rtl/system/boot.mem")
	) u_boot_rom(
		.clk_i(clk_i),
		.addr_i(bootrom_addr[BootRomAddrWidth + 1:2]),
		.data_o(bootrom_rdata)
	);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			bootrom_rvalid <= 1'b0;
		else
			bootrom_rvalid <= bootrom_req;
	wire [(DW / 8) - 1:0] sram_mem_we;
	wire [SramWordAddrWidth - 1:0] sram_mem_addr;
	wire [DW - 1:0] sram_mem_wdata;
	wire [DW - 1:0] sram_mem_rdata;
	wire sram_mem_en;
	sram_controller #(
		.AW(AW),
		.DW(DW),
		.WORD_ADDR_WIDTH(SramWordAddrWidth)
	) u_sram_controller(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.sram_req_i(sram_req),
		.sram_we_i(sram_we),
		.sram_addr_i(sram_addr),
		.sram_wdata_i(sram_wdata),
		.sram_be_i(sram_be),
		.sram_rdata_o(sram_rdata),
		.sram_rvalid_o(sram_rvalid),
		.mem_en_o(sram_mem_en),
		.mem_we_o(sram_mem_we),
		.mem_addr_o(sram_mem_addr),
		.mem_wdata_o(sram_mem_wdata),
		.mem_rdata_i(sram_mem_rdata)
	);
	sram_model #(
		.Width(DW),
		.Depth(1 << SramWordAddrWidth)
	) u_sram_model(
		.clk_i(clk_i),
		.req_i(sram_mem_en),
		.addr_i(sram_mem_addr),
		.we_i(sram_mem_we),
		.wdata_i(sram_mem_wdata),
		.rdata_o(sram_mem_rdata)
	);
	uart #(
		.ClockFrequency(ClockFrequency),
		.BaudRate(BaudRate)
	) u_uart(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.device_req_i(uart_req),
		.device_addr_i(uart_addr - UART_BASE),
		.device_we_i(uart_we),
		.device_be_i(uart_be),
		.device_wdata_i(uart_wdata),
		.device_rvalid_o(uart_rvalid),
		.device_rdata_o(uart_rdata),
		.uart_rx_i(uart_rx_i),
		.uart_irq_o(uart_irq_o),
		.uart_tx_o(uart_tx_o)
	);
	gpio #(
		.GpiWidth(GpiWidth),
		.GpoWidth(GpoWidth),
		.AddrWidth(AW),
		.DataWidth(DW)
	) u_gpio(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.device_req_i(gpio_req),
		.device_addr_i(gpio_addr - GPIO_BASE),
		.device_we_i(gpio_we),
		.device_be_i(gpio_be),
		.device_wdata_i(gpio_wdata),
		.device_rvalid_o(gpio_rvalid),
		.device_rdata_o(gpio_rdata),
		.gp_i(gp_i),
		.gp_o(gp_o)
	);
	timer u_timer(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.timer_req_i(timer_req),
		.timer_addr_i(timer_addr - TIMER_BASE),
		.timer_we_i(timer_we),
		.timer_be_i(timer_be),
		.timer_wdata_i(timer_wdata),
		.timer_rvalid_o(timer_rvalid),
		.timer_rdata_o(timer_rdata),
		.timer_err_o(timer_err),
		.timer_intr_o(timer_intr_o)
	);
	spi_top u_spi_top(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.device_req_i(spihost_req),
		.device_addr_i(spihost_addr - SPIHOST_BASE),
		.device_we_i(spihost_we),
		.device_be_i(spihost_be),
		.device_wdata_i(spihost_wdata),
		.device_rvalid_o(spihost_rvalid),
		.device_rdata_o(spihost_rdata),
		.spi_rx_i(spi_rx_i),
		.spi_tx_o(spi_tx_o),
		.sck_o(spi_sck_o),
		.byte_data_o(spi_byte_data_o)
	);
	i2c_wb_wrapper #(
		.AW(AW),
		.DW(DW)
	) u_i2c_wb_wrapper(
		.clk_i(clk_i),
		.rst_i(~rst_ni),
		.i2c_req_o(i2c_req),
		.i2c_we_o(i2c_we),
		.i2c_addr_o(i2c_addr - I2C_BASE),
		.i2c_wdata_o(i2c_wdata),
		.i2c_be_o(i2c_be),
		.i2c_rvalid_i(i2c_rvalid),
		.i2c_rdata_i(i2c_rdata),
		.scl_pad_i(i2c_scl_i),
		.scl_pad_o(i2c_scl_o),
		.scl_padoen_o(i2c_scl_oe_o),
		.sda_pad_i(i2c_sda_i),
		.sda_pad_o(i2c_sda_o),
		.sda_padoen_o(i2c_sda_oe_o),
		.wb_inta_o(i2c_irq_o)
	);
	pwm_wrapper #(
		.BusAddrWidth(AW),
		.BusDataWidth(DW)
	) u_pwm(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.device_req_i(pwm_req),
		.device_addr_i(pwm_addr - PWM_BASE),
		.device_we_i(pwm_we),
		.device_be_i(pwm_be),
		.device_wdata_i(pwm_wdata),
		.device_rvalid_o(pwm_rvalid),
		.device_rdata_o(pwm_rdata),
		.pwm_o(pwm_o)
	);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			xip_rvalid <= 1'b0;
			spictrl_rvalid <= 1'b0;
		end
		else begin
			xip_rvalid <= xip_req;
			spictrl_rvalid <= spictrl_req;
		end
	assign xip_rdata = 1'sb0;
	assign spictrl_rdata = 1'sb0;
	wire unused_bootrom_sideband;
	wire unused_timer_err;
	wire unused_xip_sideband;
	wire unused_spictrl_sideband;
	assign unused_bootrom_sideband = ^{bootrom_we, bootrom_wdata, bootrom_be};
	assign unused_timer_err = timer_err;
	assign unused_xip_sideband = ^{xip_we, xip_addr, xip_wdata, xip_be};
	assign unused_spictrl_sideband = ^{spictrl_we, spictrl_addr, spictrl_wdata, spictrl_be};
endmodule
module uart (
	clk_i,
	rst_ni,
	device_req_i,
	device_addr_i,
	device_we_i,
	device_be_i,
	device_wdata_i,
	device_rvalid_o,
	device_rdata_o,
	uart_rx_i,
	uart_irq_o,
	uart_tx_o
);
	reg _sv2v_0;
	parameter [31:0] ClockFrequency = 20000000;
	parameter [31:0] BaudRate = 115200;
	parameter [31:0] RxFifoDepth = 128;
	parameter [31:0] TxFifoDepth = 128;
	parameter [31:0] AddrWidth = 32;
	parameter [31:0] DataWidth = 32;
	parameter [31:0] RegAddr = 12;
	input wire clk_i;
	input wire rst_ni;
	input wire device_req_i;
	input wire [AddrWidth - 1:0] device_addr_i;
	input wire device_we_i;
	input wire [3:0] device_be_i;
	input wire [DataWidth - 1:0] device_wdata_i;
	output wire device_rvalid_o;
	output wire [DataWidth - 1:0] device_rdata_o;
	input wire uart_rx_i;
	output wire uart_irq_o;
	output reg uart_tx_o;
	localparam [31:0] ClocksPerBaud = ClockFrequency / BaudRate;
	function automatic [RegAddr - 1:0] sv2v_cast_33151;
		input reg [RegAddr - 1:0] inp;
		sv2v_cast_33151 = inp;
	endfunction
	localparam [RegAddr - 1:0] UartRxReg = sv2v_cast_33151('h0);
	localparam [RegAddr - 1:0] UartTxReg = sv2v_cast_33151('h4);
	localparam [RegAddr - 1:0] UartStatusReg = sv2v_cast_33151('h8);
	reg [DataWidth - 1:0] device_rdata_d;
	reg [DataWidth - 1:0] device_rdata_q;
	reg device_rvalid_d;
	reg device_rvalid_q;
	wire [RegAddr - 1:0] reg_addr;
	reg [$clog2(ClocksPerBaud) - 1:0] rx_baud_counter_q;
	wire [$clog2(ClocksPerBaud) - 1:0] rx_baud_counter_d;
	wire rx_baud_tick;
	reg [1:0] rx_state_q;
	reg [1:0] rx_state_d;
	reg [2:0] rx_bit_counter_q;
	reg [2:0] rx_bit_counter_d;
	reg [7:0] rx_current_byte_q;
	reg [7:0] rx_current_byte_d;
	reg [2:0] rx_q;
	wire rx_start;
	reg rx_valid;
	wire rx_fifo_wvalid;
	reg rx_fifo_rready;
	wire [7:0] rx_fifo_rdata;
	wire rx_fifo_rvalid;
	wire rx_fifo_empty;
	reg [$clog2(ClocksPerBaud) - 1:0] tx_baud_counter_q;
	wire [$clog2(ClocksPerBaud) - 1:0] tx_baud_counter_d;
	wire tx_baud_tick;
	wire write_req;
	reg [1:0] tx_state_q;
	reg [1:0] tx_state_d;
	reg [2:0] tx_bit_counter_q;
	reg [2:0] tx_bit_counter_d;
	reg [7:0] tx_current_byte_q;
	reg [7:0] tx_current_byte_d;
	reg tx_next_byte;
	wire tx_fifo_wvalid;
	wire tx_fifo_rvalid;
	wire tx_fifo_rready;
	wire [7:0] tx_fifo_rdata;
	wire tx_fifo_full;
	assign reg_addr = device_addr_i[RegAddr - 1:0];
	function automatic [((DataWidth - 9) >= 0 ? DataWidth - 8 : 10 - DataWidth) - 1:0] sv2v_cast_7CD3F;
		input reg [((DataWidth - 9) >= 0 ? DataWidth - 8 : 10 - DataWidth) - 1:0] inp;
		sv2v_cast_7CD3F = inp;
	endfunction
	function automatic [((DataWidth - 3) >= 0 ? DataWidth - 2 : 4 - DataWidth) - 1:0] sv2v_cast_7582B;
		input reg [((DataWidth - 3) >= 0 ? DataWidth - 2 : 4 - DataWidth) - 1:0] inp;
		sv2v_cast_7582B = inp;
	endfunction
	always @(*) begin
		if (_sv2v_0)
			;
		device_rdata_d = 1'sb0;
		device_rvalid_d = 1'b0;
		rx_fifo_rready = 1'b0;
		if (device_req_i) begin
			device_rvalid_d = 1'b1;
			if (device_be_i[0] & ~device_we_i)
				case (reg_addr)
					UartRxReg: begin
						device_rdata_d = {sv2v_cast_7CD3F(1'sb0), rx_fifo_rdata};
						rx_fifo_rready = 1'b1;
					end
					UartTxReg: device_rdata_d = 1'sb0;
					UartStatusReg: device_rdata_d = {sv2v_cast_7582B(1'sb0), tx_fifo_full, rx_fifo_empty};
					default: device_rdata_d = 1'sb0;
				endcase
		end
	end
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			device_rdata_q <= 1'sb0;
			device_rvalid_q <= 1'b0;
		end
		else begin
			device_rdata_q <= device_rdata_d;
			device_rvalid_q <= device_rvalid_d;
		end
	assign device_rdata_o = device_rdata_q;
	assign device_rvalid_o = device_rvalid_q;
	assign rx_fifo_wvalid = rx_baud_tick & rx_valid;
	assign rx_fifo_empty = ~rx_fifo_rvalid;
	function automatic [$clog2(ClocksPerBaud) - 1:0] sv2v_cast_959C6;
		input reg [$clog2(ClocksPerBaud) - 1:0] inp;
		sv2v_cast_959C6 = inp;
	endfunction
	assign rx_baud_counter_d = (rx_baud_tick ? {$clog2(ClocksPerBaud) {1'sb0}} : (rx_start ? sv2v_cast_959C6(ClocksPerBaud >> 1) : rx_baud_counter_q + 1'b1));
	assign rx_baud_tick = rx_baud_counter_q == sv2v_cast_959C6(ClocksPerBaud - 1);
	prim_fifo_sync #(
		.Width(8),
		.Pass(1'b0),
		.Depth(RxFifoDepth)
	) u_rx_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid_i(rx_fifo_wvalid),
		.wready_o(),
		.wdata_i(rx_current_byte_q),
		.rvalid_o(rx_fifo_rvalid),
		.rready_i(rx_fifo_rready),
		.rdata_o(rx_fifo_rdata),
		.full_o(),
		.depth_o(),
		.err_o()
	);
	assign uart_irq_o = !rx_fifo_empty;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rx_q <= 1'sb0;
		else
			rx_q <= {rx_q[1:0], uart_rx_i};
	assign rx_start = (!rx_q[1] & rx_q[2]) & (rx_state_q == 2'd0);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rx_baud_counter_q <= 1'sb0;
		else
			rx_baud_counter_q <= rx_baud_counter_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			rx_state_q <= 2'd0;
			rx_bit_counter_q <= 1'sb0;
			rx_current_byte_q <= 1'sb0;
		end
		else if (rx_start || rx_baud_tick) begin
			rx_state_q <= rx_state_d;
			rx_bit_counter_q <= rx_bit_counter_d;
			rx_current_byte_q <= rx_current_byte_d;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		rx_valid = 0;
		rx_bit_counter_d = rx_bit_counter_q;
		rx_current_byte_d = rx_current_byte_q;
		rx_state_d = rx_state_q;
		case (rx_state_q)
			2'd0:
				if (rx_start)
					rx_state_d = 2'd1;
			2'd1: begin
				rx_current_byte_d = 1'sb0;
				rx_bit_counter_d = 1'sb0;
				if (!rx_q[2])
					rx_state_d = 2'd2;
				else
					rx_state_d = 2'd0;
			end
			2'd2: begin
				rx_current_byte_d = {rx_q[2], rx_current_byte_q[7:1]};
				if (rx_bit_counter_q == 3'd7)
					rx_state_d = 2'd3;
				else
					rx_bit_counter_d = rx_bit_counter_q + 3'd1;
			end
			2'd3: begin
				if (rx_q[2])
					rx_valid = 1;
				rx_state_d = 2'd0;
			end
		endcase
	end
	assign write_req = (device_req_i & device_be_i[0]) & device_we_i;
	assign tx_fifo_wvalid = (reg_addr == UartTxReg) & write_req;
	assign tx_fifo_rready = tx_baud_tick & tx_next_byte;
	assign tx_baud_counter_d = (tx_baud_tick ? {$clog2(ClocksPerBaud) {1'sb0}} : tx_baud_counter_q + 1'b1);
	assign tx_baud_tick = tx_baud_counter_q == sv2v_cast_959C6(ClocksPerBaud - 1);
	prim_fifo_sync #(
		.Width(8),
		.Pass(1'b0),
		.Depth(TxFifoDepth)
	) u_tx_fifo(
		.clk_i(clk_i),
		.rst_ni(rst_ni),
		.clr_i(1'b0),
		.wvalid_i(tx_fifo_wvalid),
		.wready_o(),
		.wdata_i(device_wdata_i[7:0]),
		.rvalid_o(tx_fifo_rvalid),
		.rready_i(tx_fifo_rready),
		.rdata_o(tx_fifo_rdata),
		.full_o(tx_fifo_full),
		.depth_o(),
		.err_o()
	);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			tx_baud_counter_q <= 1'sb0;
		else
			tx_baud_counter_q <= tx_baud_counter_d;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			tx_state_q <= 2'd0;
			tx_bit_counter_q <= 1'sb0;
			tx_current_byte_q <= 1'sb0;
		end
		else if (tx_baud_tick) begin
			tx_state_q <= tx_state_d;
			tx_bit_counter_q <= tx_bit_counter_d;
			tx_current_byte_q <= tx_current_byte_d;
		end
	always @(*) begin
		if (_sv2v_0)
			;
		uart_tx_o = 1'b0;
		tx_bit_counter_d = tx_bit_counter_q;
		tx_current_byte_d = tx_current_byte_q;
		tx_next_byte = 1'b0;
		tx_state_d = tx_state_q;
		case (tx_state_q)
			2'd0: begin
				uart_tx_o = 1'b1;
				if (tx_fifo_rvalid)
					tx_state_d = 2'd1;
			end
			2'd1: begin
				uart_tx_o = 1'b0;
				tx_state_d = 2'd2;
				tx_bit_counter_d = 3'd0;
				tx_current_byte_d = tx_fifo_rdata;
				tx_next_byte = 1'b1;
			end
			2'd2: begin
				uart_tx_o = tx_current_byte_q[0];
				tx_current_byte_d = {1'b0, tx_current_byte_q[7:1]};
				if (tx_bit_counter_q == 3'd7)
					tx_state_d = 2'd3;
				else
					tx_bit_counter_d = tx_bit_counter_q + 3'd1;
			end
			2'd3: begin
				uart_tx_o = 1'b1;
				if (tx_fifo_rvalid)
					tx_state_d = 2'd1;
				else
					tx_state_d = 2'd0;
			end
		endcase
	end
	wire [(AddrWidth - 1) - RegAddr:0] unused_device_addr;
	wire [3:1] unused_device_be;
	wire [DataWidth - 9:0] unused_device_wdata;
	assign unused_device_addr = device_addr_i[AddrWidth - 1:RegAddr];
	assign unused_device_be = device_be_i[3:1];
	assign unused_device_wdata = device_wdata_i[DataWidth - 1:8];
	initial _sv2v_0 = 0;
endmodule
module i2c_master_byte_ctrl (
	clk,
	rst,
	nReset,
	ena,
	clk_cnt,
	start,
	stop,
	read,
	write,
	ack_in,
	din,
	cmd_ack,
	ack_out,
	dout,
	i2c_busy,
	i2c_al,
	scl_i,
	scl_o,
	scl_oen,
	sda_i,
	sda_o,
	sda_oen
);
	input clk;
	input rst;
	input nReset;
	input ena;
	input [15:0] clk_cnt;
	input start;
	input stop;
	input read;
	input write;
	input ack_in;
	input [7:0] din;
	output reg cmd_ack;
	output reg ack_out;
	output wire i2c_busy;
	output wire i2c_al;
	output wire [7:0] dout;
	input scl_i;
	output wire scl_o;
	output wire scl_oen;
	input sda_i;
	output wire sda_o;
	output wire sda_oen;
	parameter [4:0] ST_IDLE = 5'b00000;
	parameter [4:0] ST_START = 5'b00001;
	parameter [4:0] ST_READ = 5'b00010;
	parameter [4:0] ST_WRITE = 5'b00100;
	parameter [4:0] ST_ACK = 5'b01000;
	parameter [4:0] ST_STOP = 5'b10000;
	reg [3:0] core_cmd;
	reg core_txd;
	wire core_ack;
	wire core_rxd;
	reg [7:0] sr;
	reg shift;
	reg ld;
	wire go;
	reg [2:0] dcnt;
	wire cnt_done;
	i2c_master_bit_ctrl bit_controller(
		.clk(clk),
		.rst(rst),
		.nReset(nReset),
		.ena(ena),
		.clk_cnt(clk_cnt),
		.cmd(core_cmd),
		.cmd_ack(core_ack),
		.busy(i2c_busy),
		.al(i2c_al),
		.din(core_txd),
		.dout(core_rxd),
		.scl_i(scl_i),
		.scl_o(scl_o),
		.scl_oen(scl_oen),
		.sda_i(sda_i),
		.sda_o(sda_o),
		.sda_oen(sda_oen)
	);
	assign go = ((read | write) | stop) & ~cmd_ack;
	assign dout = sr;
	always @(posedge clk or negedge nReset)
		if (!nReset)
			sr <= #(1) 8'h00;
		else if (rst)
			sr <= #(1) 8'h00;
		else if (ld)
			sr <= #(1) din;
		else if (shift)
			sr <= #(1) {sr[6:0], core_rxd};
	always @(posedge clk or negedge nReset)
		if (!nReset)
			dcnt <= #(1) 3'h0;
		else if (rst)
			dcnt <= #(1) 3'h0;
		else if (ld)
			dcnt <= #(1) 3'h7;
		else if (shift)
			dcnt <= #(1) dcnt - 3'h1;
	assign cnt_done = ~(|dcnt);
	reg [4:0] c_state;
	always @(posedge clk or negedge nReset)
		if (!nReset) begin
			core_cmd <= #(1) 4'b0000;
			core_txd <= #(1) 1'b0;
			shift <= #(1) 1'b0;
			ld <= #(1) 1'b0;
			cmd_ack <= #(1) 1'b0;
			c_state <= #(1) ST_IDLE;
			ack_out <= #(1) 1'b0;
		end
		else if (rst | i2c_al) begin
			core_cmd <= #(1) 4'b0000;
			core_txd <= #(1) 1'b0;
			shift <= #(1) 1'b0;
			ld <= #(1) 1'b0;
			cmd_ack <= #(1) 1'b0;
			c_state <= #(1) ST_IDLE;
			ack_out <= #(1) 1'b0;
		end
		else begin
			core_txd <= #(1) sr[7];
			shift <= #(1) 1'b0;
			ld <= #(1) 1'b0;
			cmd_ack <= #(1) 1'b0;
			case (c_state)
				ST_IDLE:
					if (go) begin
						if (start) begin
							c_state <= #(1) ST_START;
							core_cmd <= #(1) 4'b0001;
						end
						else if (read) begin
							c_state <= #(1) ST_READ;
							core_cmd <= #(1) 4'b1000;
						end
						else if (write) begin
							c_state <= #(1) ST_WRITE;
							core_cmd <= #(1) 4'b0100;
						end
						else begin
							c_state <= #(1) ST_STOP;
							core_cmd <= #(1) 4'b0010;
							cmd_ack <= #(1) 1'b1;
						end
						ld <= #(1) 1'b1;
					end
				ST_START:
					if (core_ack) begin
						if (read) begin
							c_state <= #(1) ST_READ;
							core_cmd <= #(1) 4'b1000;
						end
						else begin
							c_state <= #(1) ST_WRITE;
							core_cmd <= #(1) 4'b0100;
						end
						ld <= #(1) 1'b1;
					end
				ST_WRITE:
					if (core_ack) begin
						if (cnt_done) begin
							c_state <= #(1) ST_ACK;
							core_cmd <= #(1) 4'b1000;
						end
						else begin
							c_state <= #(1) ST_WRITE;
							core_cmd <= #(1) 4'b0100;
							shift <= #(1) 1'b1;
						end
					end
				ST_READ:
					if (core_ack) begin
						if (cnt_done) begin
							c_state <= #(1) ST_ACK;
							core_cmd <= #(1) 4'b0100;
						end
						else begin
							c_state <= #(1) ST_READ;
							core_cmd <= #(1) 4'b1000;
						end
						shift <= #(1) 1'b1;
						core_txd <= #(1) ack_in;
					end
				ST_ACK:
					if (core_ack) begin
						if (stop) begin
							c_state <= #(1) ST_STOP;
							core_cmd <= #(1) 4'b0010;
						end
						else begin
							c_state <= #(1) ST_IDLE;
							core_cmd <= #(1) 4'b0000;
							cmd_ack <= #(1) 1'b1;
						end
						ack_out <= #(1) core_rxd;
						core_txd <= #(1) 1'b1;
					end
					else
						core_txd <= #(1) ack_in;
				ST_STOP:
					if (core_ack) begin
						c_state <= #(1) ST_IDLE;
						core_cmd <= #(1) 4'b0000;
						cmd_ack <= #(1) 1'b1;
					end
			endcase
		end
endmodule
module spi_flash_xip (
	clk_i,
	rst_ni,
	xip_req_i,
	xip_we_i,
	xip_addr_i,
	xip_wdata_i,
	xip_be_i,
	xip_rvalid_o,
	xip_rdata_o,
	spi_sck_o,
	spi_csn_o,
	spi_mosi_o,
	spi_miso_i
);
	parameter signed [31:0] AW = 24;
	parameter signed [31:0] DW = 32;
	parameter signed [31:0] CLK_DIV = 4;
	input wire clk_i;
	input wire rst_ni;
	input wire xip_req_i;
	input wire xip_we_i;
	input wire [AW - 1:0] xip_addr_i;
	input wire [DW - 1:0] xip_wdata_i;
	input wire [(DW / 8) - 1:0] xip_be_i;
	output reg xip_rvalid_o;
	output reg [DW - 1:0] xip_rdata_o;
	output wire spi_sck_o;
	output wire spi_csn_o;
	output wire spi_mosi_o;
	input wire spi_miso_i;
	localparam [7:0] READ_CMD = 8'h03;
	function automatic signed [7:0] sv2v_cast_8_signed;
		input reg signed [7:0] inp;
		sv2v_cast_8_signed = inp;
	endfunction
	localparam [7:0] CLK_DIV_LAST = sv2v_cast_8_signed(CLK_DIV - 1);
	function automatic signed [5:0] sv2v_cast_6_signed;
		input reg signed [5:0] inp;
		sv2v_cast_6_signed = inp;
	endfunction
	localparam [5:0] DATA_LAST_BIT = sv2v_cast_6_signed(DW - 1);
	reg [2:0] state_q;
	reg [DW - 2:0] data_shift_q;
	reg [AW - 1:0] addr_reg_q;
	reg [7:0] out_shift_q;
	reg [5:0] bit_cnt_q;
	reg [1:0] addr_byte_q;
	reg [7:0] clk_cnt_q;
	reg spi_sck_q;
	wire xip_read_req;
	wire spi_tick;
	wire spi_rise;
	wire spi_fall;
	assign xip_read_req = xip_req_i & ~xip_we_i;
	assign spi_csn_o = (state_q == 3'd0) || (state_q == 3'd4);
	assign spi_sck_o = spi_sck_q & ~spi_csn_o;
	assign spi_mosi_o = out_shift_q[7];
	assign spi_tick = clk_cnt_q == CLK_DIV_LAST;
	assign spi_rise = ((spi_tick && (spi_sck_q == 1'b0)) && (state_q != 3'd0)) && (state_q != 3'd4);
	assign spi_fall = ((spi_tick && (spi_sck_q == 1'b1)) && (state_q != 3'd0)) && (state_q != 3'd4);
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni) begin
			state_q <= 3'd0;
			data_shift_q <= 1'sb0;
			addr_reg_q <= 1'sb0;
			out_shift_q <= 1'sb0;
			bit_cnt_q <= 1'sb0;
			addr_byte_q <= 1'sb0;
			clk_cnt_q <= 1'sb0;
			spi_sck_q <= 1'b0;
			xip_rvalid_o <= 1'b0;
			xip_rdata_o <= 1'sb0;
		end
		else begin
			xip_rvalid_o <= 1'b0;
			if ((state_q != 3'd0) && (state_q != 3'd4)) begin
				if (spi_tick) begin
					clk_cnt_q <= 1'sb0;
					spi_sck_q <= ~spi_sck_q;
				end
				else
					clk_cnt_q <= clk_cnt_q + 1'b1;
			end
			else begin
				clk_cnt_q <= 1'sb0;
				spi_sck_q <= 1'b0;
			end
			case (state_q)
				3'd0:
					if (xip_read_req) begin
						addr_reg_q <= xip_addr_i;
						out_shift_q <= READ_CMD;
						bit_cnt_q <= 6'd7;
						addr_byte_q <= 2'd0;
						data_shift_q <= 1'sb0;
						state_q <= 3'd1;
					end
				3'd1:
					if (spi_fall) begin
						if (bit_cnt_q == 0) begin
							out_shift_q <= addr_reg_q[23:16];
							bit_cnt_q <= 6'd7;
							addr_byte_q <= 2'd0;
							state_q <= 3'd2;
						end
						else begin
							out_shift_q <= {out_shift_q[6:0], 1'b0};
							bit_cnt_q <= bit_cnt_q - 1'b1;
						end
					end
				3'd2:
					if (spi_fall) begin
						if (bit_cnt_q == 0) begin
							if (addr_byte_q == 2'd0) begin
								out_shift_q <= addr_reg_q[15:8];
								bit_cnt_q <= 6'd7;
								addr_byte_q <= 2'd1;
							end
							else if (addr_byte_q == 2'd1) begin
								out_shift_q <= addr_reg_q[7:0];
								bit_cnt_q <= 6'd7;
								addr_byte_q <= 2'd2;
							end
							else begin
								out_shift_q <= 8'h00;
								bit_cnt_q <= DATA_LAST_BIT;
								state_q <= 3'd3;
							end
						end
						else begin
							out_shift_q <= {out_shift_q[6:0], 1'b0};
							bit_cnt_q <= bit_cnt_q - 1'b1;
						end
					end
				3'd3:
					if (spi_rise) begin
						data_shift_q <= {data_shift_q[DW - 3:0], spi_miso_i};
						if (bit_cnt_q == 0) begin
							xip_rdata_o <= {data_shift_q, spi_miso_i};
							state_q <= 3'd4;
						end
						else
							bit_cnt_q <= bit_cnt_q - 1'b1;
					end
				3'd4: begin
					xip_rvalid_o <= 1'b1;
					state_q <= 3'd0;
				end
				default: state_q <= 3'd0;
			endcase
		end
endmodule
module ibex_demo_system (
	clk_sys_i,
	rst_sys_ni,
	gp_i,
	gp_o,
	pwm_o,
	uart_rx_i,
	uart_tx_o,
	spi_rx_i,
	spi_tx_o,
	spi_sck_o,
	tck_i,
	tms_i,
	trst_ni,
	td_i,
	td_o
);
	parameter signed [31:0] GpiWidth = 8;
	parameter signed [31:0] GpoWidth = 16;
	parameter signed [31:0] PwmWidth = 12;
	parameter [31:0] ClockFrequency = 20000000;
	parameter [31:0] BaudRate = 115200;
	parameter integer RegFile = 32'sd1;
	parameter SRAMInitFile = "";
	input wire clk_sys_i;
	input wire rst_sys_ni;
	input wire [GpiWidth - 1:0] gp_i;
	output wire [GpoWidth - 1:0] gp_o;
	output wire [PwmWidth - 1:0] pwm_o;
	input wire uart_rx_i;
	output wire uart_tx_o;
	input wire spi_rx_i;
	output wire spi_tx_o;
	output wire spi_sck_o;
	input wire tck_i;
	input wire tms_i;
	input wire trst_ni;
	input wire td_i;
	output wire td_o;
	localparam [0:0] DBG = 1;
	wire uart_irq;
	wire timer_irq;
	wire rst_core_n;
	wire ndmreset_req;
	wire dm_debug_req;
	assign rst_core_n = rst_sys_ni & ~ndmreset_req;
	wire instr_req;
	wire instr_gnt;
	wire instr_rvalid;
	wire [31:0] instr_addr;
	wire [31:0] instr_rdata;
	wire data_req;
	wire data_gnt;
	wire data_rvalid;
	wire data_we;
	wire [3:0] data_be;
	wire [31:0] data_addr;
	wire [31:0] data_wdata;
	wire [31:0] data_rdata;
	wire dbg_req;
	wire dbg_we;
	wire [31:0] dbg_addr;
	wire [31:0] dbg_wdata;
	wire [3:0] dbg_be;
	wire [31:0] dbg_rdata;
	localparam [6:0] sv2v_uu_u_top_ext_instr_rdata_intg_i_0 = 1'sb0;
	localparam [6:0] sv2v_uu_u_top_ext_data_rdata_intg_i_0 = 1'sb0;
	localparam [0:0] sv2v_uu_u_top_ext_scramble_key_valid_i_0 = 1'sb0;
	localparam [31:0] sv2v_uu_u_top_ibex_pkg_SCRAMBLE_KEY_W = 128;
	localparam [127:0] sv2v_uu_u_top_ext_scramble_key_i_0 = 1'sb0;
	localparam [31:0] sv2v_uu_u_top_ibex_pkg_SCRAMBLE_NONCE_W = 64;
	localparam [63:0] sv2v_uu_u_top_ext_scramble_nonce_i_0 = 1'sb0;
	localparam signed [31:0] sv2v_uu_u_top_ibex_pkg_IbexMuBiWidth = 4;
	localparam [3:0] sv2v_uu_u_top_ext_fetch_enable_i_1 = 1'sb1;
	ibex_top #(
		.PMPEnable(1'b0),
		.PMPGranularity(0),
		.PMPNumRegions(1),
		.MHPMCounterNum(0),
		.MHPMCounterWidth(40),
		.RV32E(1'b0),
		.RV32M(32'sd3),
		.RV32B(32'sd0),
		.WritebackStage(1'b0),
		.ICache(1'b0),
		.ICacheECC(1'b0),
		.BranchPredictor(1'b0),
		.DbgTriggerEn(1'b0),
		.SecureIbex(1'b0),
		.ICacheScramble(1'b0),
		.DmHaltAddr(32'h1a110800),
		.DmExceptionAddr(32'h1a110808)
	) u_top(
		.clk_i(clk_sys_i),
		.rst_ni(rst_core_n),
		.test_en_i(1'b0),
		.scan_rst_ni(1'b1),
		.ram_cfg_i('b0),
		.hart_id_i(32'b00000000000000000000000000000000),
		.boot_addr_i(32'h00100000),
		.instr_req_o(instr_req),
		.instr_gnt_i(instr_gnt),
		.instr_rvalid_i(instr_rvalid),
		.instr_addr_o(instr_addr),
		.instr_rdata_i(instr_rdata),
		.instr_rdata_intg_i(sv2v_uu_u_top_ext_instr_rdata_intg_i_0),
		.instr_err_i(1'b0),
		.data_req_o(data_req),
		.data_gnt_i(data_gnt),
		.data_rvalid_i(data_rvalid),
		.data_we_o(data_we),
		.data_be_o(data_be),
		.data_addr_o(data_addr),
		.data_wdata_o(data_wdata),
		.data_rdata_i(data_rdata),
		.data_rdata_intg_i(sv2v_uu_u_top_ext_data_rdata_intg_i_0),
		.data_err_i(1'b0),
		.data_wdata_intg_o(),
		.irq_software_i(1'b0),
		.irq_timer_i(timer_irq),
		.irq_external_i(1'b0),
		.irq_fast_i({14'b00000000000000, uart_irq}),
		.irq_nm_i(1'b0),
		.scramble_key_valid_i(sv2v_uu_u_top_ext_scramble_key_valid_i_0),
		.scramble_key_i(sv2v_uu_u_top_ext_scramble_key_i_0),
		.scramble_nonce_i(sv2v_uu_u_top_ext_scramble_nonce_i_0),
		.scramble_req_o(),
		.debug_req_i(dm_debug_req),
		.crash_dump_o(),
		.double_fault_seen_o(),
		.fetch_enable_i(sv2v_uu_u_top_ext_fetch_enable_i_1),
		.alert_minor_o(),
		.alert_major_internal_o(),
		.alert_major_bus_o(),
		.core_sleep_o()
	);
	wrapper_top #(
		.GpiWidth(GpiWidth),
		.GpoWidth(GpoWidth),
		.ClockFrequency(ClockFrequency),
		.BaudRate(BaudRate)
	) u_wrapper(
		.clk_i(clk_sys_i),
		.rst_ni(rst_sys_ni),
		.obi_instr_req_i(instr_req),
		.obi_instr_gnt_o(instr_gnt),
		.obi_instr_addr_i(instr_addr),
		.obi_instr_rvalid_o(instr_rvalid),
		.obi_instr_rdata_o(instr_rdata),
		.obi_req_i(data_req),
		.obi_gnt_o(data_gnt),
		.obi_addr_i(data_addr),
		.obi_we_i(data_we),
		.obi_be_i(data_be),
		.obi_wdata_i(data_wdata),
		.obi_rvalid_o(data_rvalid),
		.obi_rdata_o(data_rdata),
		.uart_rx_i(uart_rx_i),
		.uart_tx_o(uart_tx_o),
		.uart_irq_o(uart_irq),
		.gp_i(gp_i),
		.gp_o(gp_o),
		.timer_intr_o(timer_irq),
		.spi_rx_i(spi_rx_i),
		.spi_tx_o(spi_tx_o),
		.spi_sck_o(spi_sck_o),
		.spi_byte_data_o(),
		.i2c_scl_i(1'b0),
		.i2c_scl_o(),
		.i2c_scl_oe_o(),
		.i2c_sda_i(1'b0),
		.i2c_sda_o(),
		.i2c_sda_oe_o(),
		.i2c_irq_o(),
		.pwm_o(pwm_o),
		.dbg_req_o(dbg_req),
		.dbg_we_o(dbg_we),
		.dbg_addr_o(dbg_addr),
		.dbg_wdata_o(dbg_wdata),
		.dbg_be_o(dbg_be),
		.dbg_rdata_i(dbg_rdata)
	);
	localparam [10:0] jtag_id_pkg_JEDEC_MANUFACTURER_ID = 11'h66f;
	localparam [3:0] jtag_id_pkg_JTAG_VERSION = 4'h1;
	localparam [31:0] jtag_id_pkg_RV_DM_JTAG_IDCODE = {jtag_id_pkg_JTAG_VERSION, 16'h1001, jtag_id_pkg_JEDEC_MANUFACTURER_ID, 1'b1};
	generate
		if (DBG) begin : gen_dm_top
			localparam signed [31:0] sv2v_uu_u_dm_top_BusWidth = 32;
			localparam [31:0] sv2v_uu_u_dm_top_ext_host_r_rdata_i_0 = 1'sb0;
			dm_top #(
				.NrHarts(1),
				.IdcodeValue(jtag_id_pkg_RV_DM_JTAG_IDCODE)
			) u_dm_top(
				.clk_i(clk_sys_i),
				.rst_ni(rst_sys_ni),
				.testmode_i(1'b0),
				.ndmreset_o(ndmreset_req),
				.dmactive_o(),
				.debug_req_o(dm_debug_req),
				.unavailable_i(1'b0),
				.device_req_i(dbg_req),
				.device_we_i(dbg_we),
				.device_addr_i(dbg_addr),
				.device_be_i(dbg_be),
				.device_wdata_i(dbg_wdata),
				.device_rdata_o(dbg_rdata),
				.host_req_o(),
				.host_add_o(),
				.host_we_o(),
				.host_wdata_o(),
				.host_be_o(),
				.host_gnt_i(1'b0),
				.host_r_valid_i(1'b0),
				.host_r_rdata_i(sv2v_uu_u_dm_top_ext_host_r_rdata_i_0),
				.tck_i(tck_i),
				.tms_i(tms_i),
				.trst_ni(trst_ni),
				.td_i(td_i),
				.td_o(td_o)
			);
		end
		else begin : gen_no_dm
			assign ndmreset_req = 1'b0;
			assign dm_debug_req = 1'b0;
			assign td_o = 1'b0;
			assign dbg_rdata = 32'b00000000000000000000000000000000;
		end
	endgenerate
endmodule
module timer (
	clk_i,
	rst_ni,
	timer_req_i,
	timer_addr_i,
	timer_we_i,
	timer_be_i,
	timer_wdata_i,
	timer_rvalid_o,
	timer_rdata_o,
	timer_err_o,
	timer_intr_o
);
	reg _sv2v_0;
	parameter [31:0] DataWidth = 32;
	parameter [31:0] AddressWidth = 32;
	input wire clk_i;
	input wire rst_ni;
	input wire timer_req_i;
	input wire [AddressWidth - 1:0] timer_addr_i;
	input wire timer_we_i;
	input wire [(DataWidth / 8) - 1:0] timer_be_i;
	input wire [DataWidth - 1:0] timer_wdata_i;
	output wire timer_rvalid_o;
	output wire [DataWidth - 1:0] timer_rdata_o;
	output wire timer_err_o;
	output wire timer_intr_o;
	localparam [31:0] TW = 64;
	localparam [31:0] ADDR_OFFSET = 10;
	localparam [9:0] MTIME_LOW = 0;
	localparam [9:0] MTIME_HIGH = 4;
	localparam [9:0] MTIMECMP_LOW = 8;
	localparam [9:0] MTIMECMP_HIGH = 12;
	wire timer_we;
	wire mtime_we;
	wire mtimeh_we;
	wire mtimecmp_we;
	wire mtimecmph_we;
	wire [DataWidth - 1:0] mtime_wdata;
	wire [DataWidth - 1:0] mtimeh_wdata;
	wire [DataWidth - 1:0] mtimecmp_wdata;
	wire [DataWidth - 1:0] mtimecmph_wdata;
	reg [63:0] mtime_q;
	wire [63:0] mtime_d;
	wire [63:0] mtime_inc;
	reg [63:0] mtimecmp_q;
	wire [63:0] mtimecmp_d;
	reg interrupt_q;
	wire interrupt_d;
	reg error_q;
	reg error_d;
	reg [DataWidth - 1:0] rdata_q;
	reg [DataWidth - 1:0] rdata_d;
	reg rvalid_q;
	assign timer_we = timer_req_i & timer_we_i;
	assign mtime_inc = mtime_q + 64'd1;
	genvar _gv_b_1;
	generate
		for (_gv_b_1 = 0; _gv_b_1 < (DataWidth / 8); _gv_b_1 = _gv_b_1 + 1) begin : gen_byte_wdata
			localparam b = _gv_b_1;
			assign mtime_wdata[b * 8+:8] = (timer_be_i[b] ? timer_wdata_i[b * 8+:8] : mtime_q[b * 8+:8]);
			assign mtimeh_wdata[b * 8+:8] = (timer_be_i[b] ? timer_wdata_i[b * 8+:8] : mtime_q[DataWidth + (b * 8)+:8]);
			assign mtimecmp_wdata[b * 8+:8] = (timer_be_i[b] ? timer_wdata_i[b * 8+:8] : mtimecmp_q[b * 8+:8]);
			assign mtimecmph_wdata[b * 8+:8] = (timer_be_i[b] ? timer_wdata_i[b * 8+:8] : mtimecmp_q[DataWidth + (b * 8)+:8]);
		end
	endgenerate
	assign mtime_we = timer_we & (timer_addr_i[9:0] == MTIME_LOW);
	assign mtimeh_we = timer_we & (timer_addr_i[9:0] == MTIME_HIGH);
	assign mtimecmp_we = timer_we & (timer_addr_i[9:0] == MTIMECMP_LOW);
	assign mtimecmph_we = timer_we & (timer_addr_i[9:0] == MTIMECMP_HIGH);
	assign mtime_d = {(mtimeh_we ? mtimeh_wdata : mtime_inc[63:32]), (mtime_we ? mtime_wdata : mtime_inc[31:0])};
	assign mtimecmp_d = {(mtimecmph_we ? mtimecmph_wdata : mtimecmp_q[63:32]), (mtimecmp_we ? mtimecmp_wdata : mtimecmp_q[31:0])};
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni)
			mtime_q <= 'b0;
		else
			mtime_q <= mtime_d;
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni)
			mtimecmp_q <= 'b0;
		else if (mtimecmp_we | mtimecmph_we)
			mtimecmp_q <= mtimecmp_d;
	assign interrupt_d = ((mtime_q >= mtimecmp_q) | interrupt_q) & ~(mtimecmp_we | mtimecmph_we);
	always @(posedge clk_i or negedge rst_ni)
		if (~rst_ni)
			interrupt_q <= 'b0;
		else
			interrupt_q <= interrupt_d;
	assign timer_intr_o = interrupt_q;
	always @(*) begin
		if (_sv2v_0)
			;
		rdata_d = 'b0;
		error_d = 1'b0;
		(* full_case, parallel_case *)
		case (timer_addr_i[9:0])
			MTIME_LOW: rdata_d = mtime_q[31:0];
			MTIME_HIGH: rdata_d = mtime_q[63:32];
			MTIMECMP_LOW: rdata_d = mtimecmp_q[31:0];
			MTIMECMP_HIGH: rdata_d = mtimecmp_q[63:32];
			default: begin
				rdata_d = 'b0;
				error_d = 1'b1;
			end
		endcase
	end
	always @(posedge clk_i)
		if (timer_req_i) begin
			rdata_q <= rdata_d;
			error_q <= error_d;
		end
	assign timer_rdata_o = rdata_q;
	always @(posedge clk_i or negedge rst_ni)
		if (!rst_ni)
			rvalid_q <= 1'b0;
		else
			rvalid_q <= timer_req_i;
	assign timer_rvalid_o = rvalid_q;
	assign timer_err_o = error_q;
	initial _sv2v_0 = 0;
endmodule
