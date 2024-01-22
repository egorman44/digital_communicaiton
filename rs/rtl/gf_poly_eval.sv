module gf_poly_eval
  import gf_pkg::*;
  (
   input [SYMB_WIDTH-1:0]  poly [T_LEN:0],   
   input [SYMB_WIDTH-1:0]  symb,
   output [SYMB_WIDTH-1:0] eval_value
   );

   // TODO: check that nonvalid poly is always zero.
   logic [T_LEN-1:0] 	   poly_vld;   
   logic [SYMB_WIDTH-1:0]  gf_mult_intrm[T_LEN-1:0];
   /* verilator lint_off ALWCOMBORDER */
   logic [SYMB_WIDTH-1:0]  xor_intrm[T_LEN-1:0];
   /* verilator lint_on ALWCOMBORDER */

   always_comb begin
      for(int i = 0; i < T_LEN; ++i) begin
	 poly_vld[i] = |poly[T_LEN-1-i];
   	 if(i == 0)
   	   gf_mult_intrm[i]	= gf_mult(poly[T_LEN],symb);
   	 else
   	   gf_mult_intrm[i]	= gf_mult(xor_intrm[i-1], symb);
   	 xor_intrm[i]		= gf_mult_intrm[i] ^ poly[T_LEN-1-i];
      end
   end // always_comb

   lib_mux_ffs
     #(
       .PORTS_NUMBER(T_LEN),
       .WIDTH(SYMB_WIDTH)
       )
   lib_mux_ffs_inst
     (
      .base(1),
      .data_i(xor_intrm),
      .sel_non_ffs(poly_vld),
      .data_o(eval_value),
      .sel_ffs()
      );
   
endmodule // gf_poly_eval
