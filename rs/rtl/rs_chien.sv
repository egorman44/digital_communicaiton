module rs_chien
  import gf_pkg::*;
   (
    input 		    aclk,
    input 		    aresetn,
    //input 	 poly_t error_locator,
    input [SYMB_WIDTH-1:0]  error_locator [T_LEN:0],
    input 		    error_locator_vld,
    output [SYMB_WIDTH-1:0] error_positions[T_LEN-1:0],
    output [T_LEN-1:0] 	    error_positions_sel,
    output 		    error_positions_vld,
    output 		    rs_chien_err
    );
   
   logic [SYMB_WIDTH-1:0]   roots[ROOTS_PER_CYCLE__CHIEN-1:0];
   wire 		    roots_vld;
   
   // Controling evaluation of errors position.
   logic 		    eval_in_proc;
   wire 		    eval_rst = error_locator_vld;

   logic [T_LEN-1:0] 	    poly_sel;
   
   // TODO: check that nonvalid poly is always zero.
   always_comb begin
      for(int i=0; i < T_LEN; ++i) 
	poly_sel[i] = |error_locator[T_LEN-1-i];
   end
   
   /////////////////////////////////////////////////
   // Roots generation for multicycle chien search
   /////////////////////////////////////////////////
   
   if(CYCLES_NUM__CHIEN > 1) begin : MULTICYCLE_CHIEN
      
      rs_chien_root_gen gf_pole_eval_roots_inst
	(
	 .alpha_current			(),
	 .vld				(error_locator_vld),
	 /*AUTOINST*/
	 // Outputs
	 .roots				(roots/*[SYMB_WIDTH-1:0].[ROOTS_PER_CYCLE__CHIEN-1:0]*/),
	 .roots_vld			(roots_vld),
	 // Inputs
	 .aclk				(aclk),
	 .aresetn			(aresetn));
   
   end // block: MULTICYCLE_CHIEN

   /////////////////////////////////////////////////
   // Roots generation for single cycle chien search
   /////////////////////////////////////////////////
   
   else if(CYCLES_NUM__CHIEN == 1) begin : SINGLE_CYCLE
      
      assign roots_vld = error_locator_vld;
      // Iterate over alpha^0 upto aplha^(2^m-2)
      always_comb begin
	 for(int i = 0; i < ROOTS_PER_CYCLE__CHIEN; ++i) begin
	    roots[i] = alpha_to_symb(i[SYMB_WIDTH-1:0]);
	 end	 
      end
   
   end

   /////////////////////////////////////////////////
   // Error config
   /////////////////////////////////////////////////
   
   else begin : CONFIG_ERROR

      initial begin
	 $fatal("[CHIEN] Wrong configuration");
      end
   
   end // else: !if(CYCLES_NUM__CHIEN == 1)
   
   /////////////////////////////////////////////////
   // GF_POLY_EVAL stage
   /////////////////////////////////////////////////
   
   wire 		    gf_poly_vld[ROOTS_PER_CYCLE__CHIEN-1:0];
   logic [ROOTS_PER_CYCLE__CHIEN-1:0] error_bit_pos;
   logic [ROOTS_PER_CYCLE__CHIEN-1:0] error_bit_pos_q;
   wire 			      error_bit_pos_vld;
   logic 			      error_bit_pos_vld_q;
   wire [SYMB_WIDTH-1:0] 	      error_locator_roots [ROOTS_PER_CYCLE__CHIEN-1:0];
   logic [ROOTS_PER_CYCLE__CHIEN-1:0] error_bit_pos_comb;      

   for(genvar i = 0; i < ROOTS_PER_CYCLE__CHIEN; ++i) begin : GF_POLY_EVAL
      gf_poly_eval gf_poly_eval_inst
		  (
		   .aclk(aclk),
		   .aresetn(aresetn),
		   .vld_i(roots_vld),
		   .poly(error_locator),
		   .poly_sel(poly_sel),
		   .symb(roots[i]),
		   .eval_value(error_locator_roots[i]),
		   .vld_o(gf_poly_vld[i])
		   );
   end // block: GF_POLY_EVAL

   // All gf_poly_vld should be the same 
   // for the current error_locator polynomial
   assign error_bit_pos_vld = gf_poly_vld[0];
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn)
	error_bit_pos_vld_q <= 1'b0;
      else
	error_bit_pos_vld_q <= error_bit_pos_vld;
   end
   
   always_comb begin
      for(int i = 0; i < ROOTS_PER_CYCLE__CHIEN; ++i) begin
   	 error_bit_pos_comb[i]	= (|error_locator_roots[i]);
	 error_bit_pos[i] = ~error_bit_pos_comb[i];
      end
   end // always_comb
   
   always_ff @(posedge aclk) begin
      if(gf_poly_vld[0])
	error_bit_pos_q <= error_bit_pos;
      else
	// Clear positions for bit position converter if not used
	error_bit_pos_q <= '0;
   end

   /////////////////////////////////////////////////
   // Convert bit position to number
   /////////////////////////////////////////////////

   /*rs_chien_pos_to_value AUTO_TEMPLATE
    (
    .\(error_bit_pos.*\) (\1_q),
    );*/
   rs_chien_pos_to_value rs_chien_pos_to_value_inst(/*AUTOINST*/
						    // Outputs
						    .error_positions	(error_positions/*[SYMB_WIDTH-1:0].[T_LEN-1:0]*/),
						    .error_positions_sel(error_positions_sel[T_LEN-1:0]),
						    .error_positions_vld(error_positions_vld),
						    // Inputs
						    .aclk		(aclk),
						    .aresetn		(aresetn),
						    .error_bit_pos_vld	(error_bit_pos_vld_q), // Templated
						    .error_bit_pos	(error_bit_pos_q)); // Templated
   
   /////////////////////////////////////////////////
   // Error interrupt generation
   //
   // If num of errors > T_LEN then it's an error.
   // The decoder couldn't decode the block properly.
   /////////////////////////////////////////////////

   localparam POS_CNTR_WIDTH = $clog2(ROOTS_NUM__CHIEN);
   logic [ROOTS_PER_CYCLE__CHIEN-1:0] 	error_bit_pos_filtered;
   logic 				eval_last = error_bit_pos_vld_q && error_bit_pos_vld;
   logic [POS_CNTR_WIDTH-1:0] 		count_pos, count_pos_q;   
   wire [ROOTS_PER_CYCLE__CHIEN-1:0] 	last_cycle_vld;
   
   if(NON_VALID__CHIEN != 0)
     assign last_cycle_vld = { {ROOTS_PER_CYCLE__CHIEN-NON_VALID__CHIEN{1'b0}}, {NON_VALID__CHIEN{1'b1}} };
   else
     assign last_cycle_vld = '1;

   // In multicycle if(ROOTS_NUM__CHIEN % ROOTS_PER_CYCLE__CHIEN) then
   // there are non valid bits.
   
   always_comb begin
      count_pos = '0;  
      for(int i = 0; i < ROOTS_PER_CYCLE__CHIEN; ++i) begin
	 if(eval_last)
	   error_bit_pos_filtered[i] = error_bit_pos_q[i] & last_cycle_vld[i];
	 else
	   error_bit_pos_filtered[i] = error_bit_pos_q[i];
   	 count_pos += POS_CNTR_WIDTH'(error_bit_pos_filtered[i]);
      end
   end
   
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn)
	count_pos_q <= '0;
      else begin
	 if(eval_rst)
	   count_pos_q <= '0;
	 else if(eval_in_proc)
	   count_pos_q <= count_pos_q + count_pos;
      end
   end

   // TODO: add outputs
   //assign rs_chien_err = (err_pos_capt_q) ? (count_pos_q > T_LEN) : 1'b0;
   //assign error_positions = error_positions_q;
   //assign error_positions_vld ;

endmodule // rs_chien
