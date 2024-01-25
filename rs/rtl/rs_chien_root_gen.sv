module rs_chien_root_gen
  import gf_pkg::*;
  (
   input 			 aclk, 
   input 			 aresetn,
   input 			 vld, 
   output logic [SYMB_WIDTH-1:0] alpha_current[ROOTS_PER_CYCLE__CHIEN-1:0],
   output logic [SYMB_WIDTH-1:0] roots[ROOTS_PER_CYCLE__CHIEN-1:0],
   output 			 roots_vld
   );

   logic [SYMB_WIDTH-1:0] chien_st_cntr_q;         
   wire [SYMB_WIDTH-1:0]  base [CYCLES_NUM__CHIEN-1:0];
   wire 		  last_cycle;

   assign last_cycle = (chien_st_cntr_q == SYMB_WIDTH'(CYCLES_NUM__CHIEN-1));
   
   for(genvar i =0; i < CYCLES_NUM__CHIEN; ++i) begin
      assign base[i] = i * ROOTS_PER_CYCLE__CHIEN;
   end

   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn) begin
	 chien_st_cntr_q	<= '0;
      end
      else begin
	 if(vld)
	   chien_st_cntr_q <= chien_st_cntr_q + 1;
	 else if(|chien_st_cntr_q) begin
	    if(last_cycle)
	      chien_st_cntr_q <= '0;
	    else
	      chien_st_cntr_q <= chien_st_cntr_q + 1'b1;
	 end
      end
   end // always_ff @ (posedge aclk, negedge aresetn)

   /////////////////////////////////////////////////
   // Generate alphas and roots each cycle
   /////////////////////////////////////////////////
   
   always_comb begin
      for(int i = 0; i < ROOTS_PER_CYCLE__CHIEN; ++i) begin
	 alpha_current[i]	= i[SYMB_WIDTH-1:0] + base[chien_st_cntr_q];
   	 roots[i]		= alpha_to_symb(alpha_current[i]);
      end      
   end

   assign roots_vld = vld || |chien_st_cntr_q;

endmodule // rs_chien_root_gen
