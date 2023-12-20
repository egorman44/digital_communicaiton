module rs_chien
  import gf_pkg::*;
   (
    input 			aclk,
    input 			aresetn,
    //input 	 poly_t error_locator,
    input [SYMB_WIDTH-1:0] 	error_locator [T_LEN:0],
    input 			error_locator_vld,
    output logic [SYMB_NUM-2:0] error_positions ,
    output 			error_positions_vld
    );
   
   logic [SYMB_WIDTH-1:0] gf_elements [SYMB_NUM-2:0];
   logic [SYMB_WIDTH-1:0] error_locator_roots [SYMB_NUM-2:0];
   logic [SYMB_NUM-2:0]   error_positions_comb;
   logic [SYMB_NUM-2:0]   error_positions_comb_q;
   logic 		  error_locator_vld_q;
   
   // Iterate over alpha^0 upto aplha^(2^m-2)
   always_comb begin      
      for(int i = 0; i < SYMB_NUM-1; ++i) begin
	 gf_elements[i] = alpha_to_symb(i[SYMB_WIDTH-1:0]);
	 error_locator_roots[i] = gf_poly_eval(error_locator, gf_elements[i]);
	 error_positions_comb[i] = |error_locator_roots[i];	 
      end
   end // always_comb
   
   always_ff @(posedge aclk) begin
      error_positions_comb_q <= error_positions_comb;
   end
   
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn)
	error_locator_vld_q <= 1'b0;
      else
	error_locator_vld_q <= error_locator_vld;
   end

   /////////////////////////
   // Output assignments
   /////////////////////////
   
   assign error_positions_vld = error_locator_vld_q;

   // Revert position
   always_comb begin
      for(int i = 0; i < SYMB_NUM-1; ++i)
	error_positions[SYMB_NUM-2-i] = error_positions_comb_q[i];
   end
   
endmodule // rs_chien
