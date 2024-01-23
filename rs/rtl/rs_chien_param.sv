module rs_chien_param
  import gf_pkg::*;
   (
    input 		    aclk,
    input 		    aresetn,
    //input 	 poly_t error_locator,
    input [SYMB_WIDTH-1:0]  error_locator [T_LEN:0],
    input 		    error_locator_vld,
    output [SYMB_WIDTH-1:0] error_positions[T_LEN-1:0],
    output 		    error_positions_vld,
    output 		    rs_chien_err
    );

   // TODO: check CYCLES_NUM__CHIEN

   initial begin
      $display("CYCLES_NUM__CHIEN = %0d, CNTR_WIDTH__CHIEN = %0d", CYCLES_NUM__CHIEN, CNTR_WIDTH__CHIEN);
   end
   
   logic [SYMB_WIDTH-1:0]   roots[ROOTS_PER_CYCLE-1:0];
   logic [SYMB_WIDTH-1:0]   roots_mux_in[ROOTS_PER_CYCLE-1:0];
   logic 		    eval_position;
   
   /////////////////////////////////////////////////
   // Parameterize chien search to optimize utilization
   /////////////////////////////////////////////////
   
   if(CYCLES_NUM__CHIEN > 1) begin : MULTICYCLE_CHIEN

      logic [SYMB_WIDTH-1:0] chien_st_cntr_q;         
      logic [SYMB_WIDTH-1:0] base_i[ROOTS_PER_CYCLE-1:0];
      logic [SYMB_WIDTH-1:0] current_i[ROOTS_PER_CYCLE-1:0];
      logic [SYMB_WIDTH-1:0] base_i_q[ROOTS_PER_CYCLE-1:0];
      wire 		     last_cycle = (chien_st_cntr_q == SYMB_WIDTH'(CYCLES_NUM__CHIEN-1));
      wire [SYMB_WIDTH-1:0]  base [SYMB_WIDTH-1:0];

      for(genvar i =0; i < CYCLES_NUM__CHIEN; ++i) begin
	 assign base[i] = i * ROOTS_PER_CYCLE;
      end
      
      always_ff @(posedge aclk, negedge aresetn) begin
	 if(~aresetn) begin
	    chien_st_cntr_q <= '0;
	 end
	 else begin
	    if(error_locator_vld)
	      chien_st_cntr_q <= chien_st_cntr_q + 1;
	    else if(|chien_st_cntr_q) begin
	       if(last_cycle)
		 chien_st_cntr_q <= '0;
	       else
		 chien_st_cntr_q <= chien_st_cntr_q + 1'b1;
	    end
	 end
      end // always_ff @ (posedge aclk, negedge aresetn)
   
   // TODO: chech the limit in for , shouldn't it be ROOTS_PER_CYCLE-1
       always_comb begin
         for(int i = 0; i < ROOTS_PER_CYCLE; ++i) begin
   	    base_i[i] = i[SYMB_WIDTH-1:0];
	    current_i[i] = base_i[i] + base[chien_st_cntr_q];
   	    roots[i] = alpha_to_symb(current_i[i]);
         end      
       end

       always_ff @(posedge aclk) begin
	  for(int i=0; i<ROOTS_PER_CYCLE; ++i)
	    base_i_q[i] <= SYMB_NUM-2-current_i[i];
       end

       assign roots_mux_in = base_i_q;
       assign eval_position = |chien_st_cntr_q;   

   end // block: MULTICYCLE_CHIEN   
   else if(CYCLES_NUM__CHIEN == 1) begin : SINGLE_CYCLE

      logic error_locator_vld_q;
      // Iterate over alpha^0 upto aplha^(2^m-2)
      always_comb begin
	 for(int i = 0; i < ROOTS_PER_CYCLE; ++i) begin
	    roots[i] = alpha_to_symb(i[SYMB_WIDTH-1:0]);
	    roots_mux_in[i] = i[SYMB_WIDTH-1:0];
	 end	 
      end

      always_ff @(posedge aclk)
	error_locator_vld_q <= error_locator_vld;
   
      assign eval_position = error_locator_vld_q;
   
   end
   else begin : CONFIG_ERROR

      initial begin
	 $fatal("[CHIEN] Wrong configuration");
      end
   
   end // else: !if(CYCLES_NUM__CHIEN == 1)
   
   /////////////////////////////////////////////////
   // RS CHIEN function
   /////////////////////////////////////////////////

   wire [ROOTS_PER_CYCLE-1:0]  error_bit_pos;
   logic [ROOTS_PER_CYCLE-1:0] error_bit_pos_q;
   
   rs_chien rs_chien_inst
     (/*AUTOINST*/
      // Outputs
      .error_bit_pos			(error_bit_pos[ROOTS_PER_CYCLE-1:0]),
      // Inputs
      .roots				(roots/*[SYMB_WIDTH-1:0].[ROOTS_PER_CYCLE-1:0]*/),
      .error_locator			(error_locator/*[SYMB_WIDTH-1:0].[T_LEN:0]*/));

   always_ff @(posedge aclk) begin
     error_bit_pos_q <= error_bit_pos;
   end
   
   /////////////////////////////////////////////////
   // Convert bit posisiton to binary value
   /////////////////////////////////////////////////
   
   logic [SYMB_WIDTH-1:0] error_positions_q[T_LEN-1:0];
   logic [T_LEN-1:0] 	  error_positions_vld_q;
   wire [ROOTS_PER_CYCLE-1:0] mux_sel[T_LEN-1:0];
   wire [T_LEN-1:0] 	  bypass = error_positions_vld_q;   
   
   lib_decmps_to_pow2
     #(
       .WIDTH(ROOTS_PER_CYCLE),
       .FFS_NUM(T_LEN)
       )
   lib_decmps_to_pow2
     (
      .vect(error_bit_pos_q),
      .bypass(bypass),
      .onehot(mux_sel)
      );
   
   for(genvar i = 0; i < T_LEN; ++i) begin
      
      lib_mux_onehot
	#(
	  .PORTS_NUMBER(ROOTS_PER_CYCLE),
	  .WIDTH(SYMB_WIDTH)
	  )
      lib_mux_onehot_inst
	(
	 .data_i(roots_mux_in),
	 .sel(mux_sel[i]),
	 .data_o(error_positions[i])
	 );
      
   end // for (genvar i = 0; i < T_LEN; ++i)

   //////////////////////////////////////
   // Accumulate error positions
   //////////////////////////////////////
   
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn) begin
	 for(int i = 0; i < T_LEN; ++i) begin
	    error_positions_q[i] <= '0;
	    error_positions_vld_q[i] <= '0;
	 end
      end
      else begin
	 if(error_locator_vld)begin
	    for(int i = 0; i < T_LEN; ++i) begin
	       error_positions_q[i] <= '0;
	       error_positions_vld_q[i] <= '0;
	    end
	 end
	 else if(eval_position) begin
	    for(int i = 0; i < T_LEN; ++i) begin
	       if(|mux_sel[i])
		 error_positions_vld_q[i] <= |mux_sel[i];
	       if(|mux_sel[i] && !error_positions_vld_q[i])
		 error_positions_q[i] <= error_positions[i];	       
	    end	    
	 end // else: !if(error_locator_vld)	 
      end // else: !if(~aresetn)      
   end // always_ff @ (posedge aclk, negedge aresetn)
   
   
   // TODO: add rs_chien_error
   //logic [$clog2($bits(error_positions_comb_q)+1)-1:0] count_pos;
   //
   ///* verilator lint_off WIDTHEXPAND */   
   //always_comb begin
   //   count_pos = '0;  
   //   foreach(error_positions_comb_q[idx]) begin
   //	 count_pos += !error_positions_comb_q[idx];
   //   end
   //end
   ///* verilator lint_on WIDTHEXPAND */
   //
   //assign rs_chien_err = (error_locator_vld_q) ? (count_pos > T_LEN) : 1'b0;

endmodule // rs_chien_param
