module gf_poly_eval
  import gf_pkg::*;
   (
    input 		    aclk,
    input 		    aresetn,
    input 		    vld_i,
    input [SYMB_WIDTH-1:0]  poly [T_LEN:0],
    input [T_LEN-1:0] 	    poly_sel,
    input [SYMB_WIDTH-1:0]  symb,
    output [SYMB_WIDTH-1:0] eval_value,
    output 		    vld_o
   );

   // TODO: make sure that there is no new POLY while current is in proc.
   // What should be the pause in between last cycle of POLY_0 and first
   // cycle of POLY_1
   
   logic [SYMB_WIDTH-1:0]  gf_mult_intrm[T_LEN-1:0];
   /* verilator lint_off ALWCOMBORDER */
   logic [SYMB_WIDTH*2-1:0] intrm__xor_and_symb[T_LEN-1:0];
   logic [SYMB_WIDTH:0]     intrm__xor_and_vld[T_LEN-1:0];   
   logic [SYMB_WIDTH-1:0]   intrm__symb[T_LEN-1:0];
   logic [SYMB_WIDTH-1:0]   intrm__xor[T_LEN-1:0];
   logic 		    intrm__vld[T_LEN-1:0];

   /* verilator lint_on ALWCOMBORDER */

   /* verilator lint_off UNOPTFLAT */
   logic [SYMB_WIDTH*2-1:0] end__xor_and_symb[T_LEN-2:0];
   logic [SYMB_WIDTH-1:0]  end__xor[T_LEN-2:0];
   logic [SYMB_WIDTH-1:0]  end__symb[T_LEN-2:0];
   logic 		   end__vld[T_LEN-2:0];
   /* verilator lint_on UNOPTFLAT */
   logic [SYMB_WIDTH:0]    xor_and_vld_out;
   
   if(FF_STEP__CHIEN_POLY_EVAL != 0) begin : PIPELING_POLY_EVAL
      
      lib_pipe 
	#(
	  .WIDTH(SYMB_WIDTH*2),
	  .STAGE_NUM(T_LEN),
	  .FF_STEP(FF_STEP__CHIEN_POLY_EVAL),
	  .FF_NUM(FF_NUM__CHIEN_POLY_EVAL)
	  )
	lib_pipe_inst
	  (
	   .clk(aclk),
	   .rstn(aresetn),
	   .data_i(intrm__xor_and_symb),
	   .vld_i(intrm__vld),
	   .data_o(end__xor_and_symb),
	   .vld_o(end__vld)
	   );
      
   end // block: PIPELING_POLY_EVAL   
   else begin : NO_PIPELING

      always_comb begin
	 for(int i =0; i < T_LEN-1; ++i) begin
	    end__xor[i] = intrm__xor[i];
	    end__vld[i] = intrm__vld[i];
	    end__symb[i] = end__symb[i];
	 end
      end
   
   end
   
   
   always_comb begin
      for(int i = 0; i < T_LEN; ++i) begin
	 {end__xor[i], end__symb[i]} = end__xor_and_symb[i];
   	 if(i == 0) begin
	   // There is always 1 in posiiton POLY[T_LEN] 
   	    gf_mult_intrm[i]	= gf_mult(1,symb); 
	    intrm__vld[i]        = vld_i;
	    intrm__symb[i]	= symb;
	 end
   	 else begin
   	    gf_mult_intrm[i]	= gf_mult(end__xor[i-1], end__symb[i-1]);
	    intrm__vld[i]        = end__vld[i-1];
	    intrm__symb[i]       = end__symb[i-1];
	 end	 
   	 intrm__xor[i]		= gf_mult_intrm[i] ^ poly[T_LEN-1-i];
	 intrm__xor_and_vld[i]  = {intrm__xor[i], intrm__vld[i]};
	 intrm__xor_and_symb[i] = {intrm__xor[i], intrm__symb[i]};
      end
   end // always_comb

   wire [T_LEN-1:0] base = { {T_LEN-1{1'b0}}, 1'b1};
   
   lib_mux_ffs
     #(
       .PORTS_NUMBER(T_LEN),
       .WIDTH(SYMB_WIDTH+1)
       )
   lib_mux_ffs_inst
     (
      .base(base),
      .data_i(intrm__xor_and_vld),
      .sel_non_ffs(poly_sel),
      .data_o(xor_and_vld_out),
      .sel_ffs()
      );

   assign {eval_value, vld_o} = xor_and_vld_out;
   
endmodule // gf_poly_eval
