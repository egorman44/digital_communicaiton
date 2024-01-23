module rs_chien
  import gf_pkg::*;
   (
    input [SYMB_WIDTH-1:0] 	       roots[ROOTS_PER_CYCLE-1:0],
    input [SYMB_WIDTH-1:0] 	       error_locator [T_LEN:0],
    output logic [ROOTS_PER_CYCLE-1:0] error_bit_pos
    );
   
   wire [SYMB_WIDTH-1:0] error_locator_roots [ROOTS_PER_CYCLE-1:0];
   logic [ROOTS_PER_CYCLE-1:0] error_bit_pos_comb;   

   for(genvar i = 0; i < ROOTS_PER_CYCLE; ++i) begin : GF_POLY_EVAL
      gf_poly_eval gf_poly_eval_inst
		  (
		   .poly(error_locator),
		   .symb(roots[i]),
		   .eval_value(error_locator_roots[i])
		   );
   end
      
   always_comb begin
      for(int i = 0; i < ROOTS_PER_CYCLE; ++i) begin
   	 error_bit_pos_comb[i]	= (|error_locator_roots[i]);
	 // If a single cycle chien search then revert ERROR BIT order,
	 // if a multicycled then revert ROOTS in the rs_chien_param
	 if(CYCLES_NUM__CHIEN == 1)
   	   error_bit_pos[ROOTS_PER_CYCLE-1-i] = ~error_bit_pos_comb[i]; // Revert position
	 else
	   error_bit_pos[i] = ~error_bit_pos_comb[i]; // Revert position
      end
   end // always_comb

   

endmodule // rs_chien
