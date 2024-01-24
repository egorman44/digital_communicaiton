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
   
   logic [SYMB_WIDTH-1:0]   roots[ROOTS_PER_CYCLE__CHIEN-1:0];
   logic [SYMB_WIDTH-1:0]   roots_mux_in[ROOTS_PER_CYCLE__CHIEN-1:0];

   // Controling evaluation of errors position.
   logic 		    eval_in_proc;
   logic 		    eval_last;
   wire 		    eval_rst = error_locator_vld;

   
   /////////////////////////////////////////////////
   // Multicycle chien search
   /////////////////////////////////////////////////
   
   if(CYCLES_NUM__CHIEN > 1) begin : MULTICYCLE_CHIEN

      logic [SYMB_WIDTH-1:0] chien_st_cntr_q;         
      logic [SYMB_WIDTH-1:0] base_i[ROOTS_PER_CYCLE__CHIEN-1:0];
      logic [SYMB_WIDTH-1:0] current_i[ROOTS_PER_CYCLE__CHIEN-1:0];
      logic [SYMB_WIDTH-1:0] base_i_q[ROOTS_PER_CYCLE__CHIEN-1:0];
      wire 		     last_cycle = (chien_st_cntr_q == SYMB_WIDTH'(CYCLES_NUM__CHIEN-1));
      wire [SYMB_WIDTH-1:0]  base [CYCLES_NUM__CHIEN-1:0];
      logic 		     prolong_eval_q, prolong_eval_qq;
      
      for(genvar i =0; i < CYCLES_NUM__CHIEN; ++i) begin
	 assign base[i] = i * ROOTS_PER_CYCLE__CHIEN;
      end
      
      always_ff @(posedge aclk, negedge aresetn) begin
	 if(~aresetn) begin
	    chien_st_cntr_q	<= '0;
	    prolong_eval_q	<= '0;
	    prolong_eval_qq	<= '0;
	 end
	 else begin
	    prolong_eval_q	<= last_cycle;
	    prolong_eval_qq	<= prolong_eval_q;
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
   
       // TODO: chech the limit in for , shouldn't it be ROOTS_PER_CYCLE__CHIEN-1
       always_comb begin
         for(int i = 0; i < ROOTS_PER_CYCLE__CHIEN; ++i) begin
   	    base_i[i] = i[SYMB_WIDTH-1:0];
	    current_i[i] = base_i[i] + base[chien_st_cntr_q];
   	    roots[i] = alpha_to_symb(current_i[i]);
         end      
       end
   
       // Prolong eval_in_proc for one cycle because of a one cycle latenc
       always_ff @(posedge aclk) begin
	  for(int i =0; i < ROOTS_PER_CYCLE__CHIEN; ++i)
	    base_i_q[i] <= current_i[i];
       end

       assign roots_mux_in = base_i_q;

       // Prolong eval_in_proc for one cycle because of a one cycle latenc
       assign eval_in_proc = |chien_st_cntr_q || prolong_eval_q;
       assign eval_last = prolong_eval_q;
       assign error_positions_vld = prolong_eval_qq;
   
   end // block: MULTICYCLE_CHIEN

   /////////////////////////////////////////////////
   // Single cycle chien search
   /////////////////////////////////////////////////

   else if(CYCLES_NUM__CHIEN == 1) begin : SINGLE_CYCLE

      logic error_locator_vld_q, error_locator_vld_qq;
      
      // Iterate over alpha^0 upto aplha^(2^m-2)
      always_comb begin
	 for(int i = 0; i < ROOTS_PER_CYCLE__CHIEN; ++i) begin
	    roots[i] = alpha_to_symb(i[SYMB_WIDTH-1:0]);
	    roots_mux_in[i] = i[SYMB_WIDTH-1:0];
	 end	 
      end

      always_ff @(posedge aclk, negedge aresetn) begin
	 if(~aresetn) begin
	    error_locator_vld_q <= 1'b0;
	    error_locator_vld_qq <= 1'b0;
	 end
	 else begin	   
	    error_locator_vld_q <= error_locator_vld;
	    error_locator_vld_qq <= error_locator_vld_q;
	 end
      end
   
      assign eval_in_proc = error_locator_vld_q;
      assign eval_last = error_locator_vld_q;   
      assign error_positions_vld = error_locator_vld_qq;
   
   end
   else begin : CONFIG_ERROR

      initial begin
	 $fatal("[CHIEN] Wrong configuration");
      end
   
   end // else: !if(CYCLES_NUM__CHIEN == 1)
   
   /////////////////////////////////////////////////
   // RS CHIEN function
   /////////////////////////////////////////////////

   wire [ROOTS_PER_CYCLE__CHIEN-1:0]  error_bit_pos;
   logic [ROOTS_PER_CYCLE__CHIEN-1:0] error_bit_pos_q;
   
   rs_chien rs_chien_inst
     (/*AUTOINST*/
      // Outputs
      .error_bit_pos			(error_bit_pos[ROOTS_PER_CYCLE__CHIEN-1:0]),
      // Inputs
      .roots				(roots/*[SYMB_WIDTH-1:0].[ROOTS_PER_CYCLE__CHIEN-1:0]*/),
      .error_locator			(error_locator/*[SYMB_WIDTH-1:0].[T_LEN:0]*/));

   always_ff @(posedge aclk) begin
     error_bit_pos_q <= error_bit_pos;
   end
   
   /////////////////////////////////////////////////
   // Convert bit posisiton to binary value
   /////////////////////////////////////////////////
   
   logic [SYMB_WIDTH-1:0] error_positions_q[T_LEN-1:0];
   logic [T_LEN-1:0] 	  error_positions_vld_q;
   wire [ROOTS_PER_CYCLE__CHIEN-1:0] mux_sel[T_LEN-1:0];
   wire [T_LEN-1:0] 	  bypass = error_positions_vld_q;   
   wire [SYMB_WIDTH-1:0]  error_positions_mux_out[T_LEN-1:0];
   
   lib_decmps_to_pow2
     #(
       .WIDTH(ROOTS_PER_CYCLE__CHIEN),
       .FFS_NUM(T_LEN),
       .LSB_MSB(1)
       )
   lib_decmps_to_pow2
     (
      .vect(error_bit_pos_q),
      .bypass(bypass),
      .onehot(mux_sel)
      );
   
   for(genvar i = 0; i < T_LEN; ++i) begin : ERROR_POSITIONS_MUX
      
      lib_mux_onehot
	#(
	  .PORTS_NUMBER(ROOTS_PER_CYCLE__CHIEN),
	  .WIDTH(SYMB_WIDTH)
	  )
      lib_mux_onehot_inst
	(
	 .data_i(roots_mux_in),
	 .sel(mux_sel[i]),
	 .data_o(error_positions_mux_out[i])
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
	 if(eval_rst)begin
	    for(int i = 0; i < T_LEN; ++i) begin
	       error_positions_q[i] <= '0;
	       error_positions_vld_q[i] <= '0;
	    end
	 end
	 else if(eval_in_proc) begin
	    for(int i = 0; i < T_LEN; ++i) begin
	       if(|mux_sel[i])
		 error_positions_vld_q[i] <= |mux_sel[i];
	       if(|mux_sel[i] && !error_positions_vld_q[i])
		 error_positions_q[i] <= SYMB_NUM-2-error_positions_mux_out[i];	       
	    end
	 end	 
      end // else: !if(~aresetn)      
   end // always_ff @ (posedge aclk, negedge aresetn)

   /////////////////////////////////////////////////
   // Error position error
   //
   // If num of errors > T_LEN then it's an error
   /////////////////////////////////////////////////
   
   logic [$clog2(ROOTS_NUM__CHIEN-1):0] count_pos, count_pos_q;
   wire [ROOTS_PER_CYCLE__CHIEN-1:0] 	last_cycle_vld;
   logic [ROOTS_PER_CYCLE__CHIEN-1:0] 	error_bit_pos_filtered;
   
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
	   error_bit_pos_filtered[i] = error_bit_pos_q[i] & last_cycle_vld;
	 else
	   error_bit_pos_filtered[i] = error_bit_pos_q[i];
   	 count_pos += error_bit_pos_filtered[i];
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

   assign error_positions = error_positions_q;
   assign rs_chien_err = (error_positions_vld) ? (count_pos_q > T_LEN) : 1'b0;

endmodule // rs_chien_param
