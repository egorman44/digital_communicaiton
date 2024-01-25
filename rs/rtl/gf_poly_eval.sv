module gf_poly_eval
  import gf_pkg::*;
   (
    input 		    aclk,
    input 		    aresetn,
    input 		    vld_i,
    input [SYMB_WIDTH-1:0]  poly [T_LEN:0], 
    input [SYMB_WIDTH-1:0]  symb,
    output [SYMB_WIDTH-1:0] eval_value,
    output 		    vld_o
   );

   // TODO: make sure that there is no new POLY while current is in proc.
   // TODO: check that nonvalid poly is always zero.
   logic [T_LEN-1:0] 	    poly_vld;   
   logic [SYMB_WIDTH-1:0]  gf_mult_intrm[T_LEN-1:0];
   /* verilator lint_off ALWCOMBORDER */
   logic [SYMB_WIDTH-1:0]  xor_intrm[T_LEN-1:0];
   logic [SYMB_WIDTH:0]    xor_and_vld_intrm[T_LEN-1:0];
   logic 		   vld_intrm[T_LEN-1:0];
   /* verilator lint_on ALWCOMBORDER */

   /* verilator lint_off UNOPTFLAT */
   logic [SYMB_WIDTH-1:0]  intrm_data_end[T_LEN-2:0];
   logic 		   intrm_vld_end[T_LEN-2:0];
   /* verilator lint_on UNOPTFLAT */
   logic [SYMB_WIDTH:0]    xor_and_vld_out;
   if(FF_STEP__CHIEN != 0) begin : PIPELING_POLY_EVAL
      
      lib_pipe 
	#(
	  .WIDTH(SYMB_WIDTH),
	  .STAGE_NUM(T_LEN),
	  .FF_STEP(FF_STEP__CHIEN)
	  )
	lib_pipe_inst
	  (
	   .clk(aclk),
	   .rstn(aresetn),
	   .data_i(xor_intrm),
	   .vld_i(vld_intrm),
	   .data_o(intrm_data_end),
	   .vld_o(intrm_vld_end)
	   );
      
   end // block: PIPELING_POLY_EVAL   
   else begin : NO_PIPELING

      always_comb begin
	 for(int i =0; i < T_LEN-1; ++i)
	   intrm_data_end[i] = xor_intrm[i];
      end
   
   end
   
   
   always_comb begin
      for(int i = 0; i < T_LEN; ++i) begin
	 poly_vld[i] = |poly[T_LEN-1-i];
   	 if(i == 0) begin
	   // There is always 1 in posiiton POLY[T_LEN] 
   	    gf_mult_intrm[i]	= gf_mult(1,symb); 
	    vld_intrm[i]        = vld_i;
	 end
   	 else begin
   	    gf_mult_intrm[i]	= gf_mult(intrm_data_end[i-1], symb);
	    vld_intrm[i]        = intrm_vld_end[i-1];
	 end	 
   	 xor_intrm[i]		= gf_mult_intrm[i] ^ poly[T_LEN-1-i];
	 xor_and_vld_intrm[i]   = {xor_intrm[i], vld_intrm[i]};
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
      .data_i(xor_and_vld_intrm),
      .sel_non_ffs(poly_vld),
      .data_o(xor_and_vld_out),
      .sel_ffs()
      );

   assign {eval_value, vld_o} = xor_and_vld_out;
   
endmodule // gf_poly_eval
