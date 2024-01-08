module rs_forney
  import gf_pkg::*;
   (
    input 			  aclk,
    input 			  aresetn,
    input [SYMB_WIDTH-1:0] 	  error_positions[T_LEN-1:0],
    input [T_LEN-1:0] 		  error_positions_vld,
    input [SYMB_WIDTH-1:0] 	  syndrome[ROOTS_NUM-1:0],
    input 			  syndrome_vld,
    output logic [SYMB_WIDTH-1:0] magnitude [T_LEN-1:0],
    output 			  magnitude_vld,
    output 			  irq_error_magnitude
    
    );
   
   // TODO: Get coef_pos

   logic [SYMB_WIDTH-1:0]  coef_position[T_LEN-1:0];
   logic [SYMB_WIDTH-1:0]  coef_position_pow[T_LEN-1:0];

   logic [SYMB_WIDTH-1:0]  error_location [T_LEN-1:0];
   logic [SYMB_WIDTH-1:0]  error_location_inv [T_LEN-1:0];
   
   logic [SYMB_WIDTH-1:0]  coef_diff [T_LEN-1:0];
   
   //logic [SYMB_WIDTH-1:0]  err_loc[T_LEN-1:0][T_LEN:0];
   
   logic [T_LEN:0][SYMB_WIDTH-1:0] err_loc[T_LEN-1:0];
   

   logic [SYMB_WIDTH-1:0] 	   synd_x_error_evaluator[ROOTS_NUM+T_LEN-1:0];

   // TODO: what is the width [T_LEN:0] ?!   
   wire [T_LEN:0][SYMB_WIDTH-1:0]  error_evaluator;
   
   always_comb begin
      for(int i = 0; i < T_LEN; ++i) begin
	 coef_position[i]	= N_LEN - 1 - error_positions[i];
	 coef_diff[i]		= (SYMB_NUM-1)-coef_position[i];
	 error_location[i]	= pow_first_root_neg(coef_diff[i]);
	 error_location_inv[i]	= gf_inv(error_location[i]);
      end
   end

     
   // TODO: Reduce utilization ?!
   // TODO: reduce POLY, since in the [0] position always 1.
   always_comb begin
      // pow_first_root is used to get all cores of generator       
      // TODO: check that is synthesized in the static wires. 
      for(int pos_indx = 0; pos_indx < T_LEN; ++pos_indx) begin
      	 coef_position_pow[pos_indx] = pow_first_root(coef_position[pos_indx]);
	 // GF polynimial multiplication:
      	 if(pos_indx == 0) begin
	    err_loc[pos_indx][0] = 1;
	    err_loc[pos_indx][1] = coef_position_pow[pos_indx];
      	    for(int symb_indx = 2; symb_indx < T_LEN+1 ; ++symb_indx)
      	      err_loc[pos_indx][symb_indx] = '0;
      	 end
      	 else begin
	    for(int symb_indx = 0; symb_indx < T_LEN+1 ; ++symb_indx)
	      if(symb_indx == 0)
		err_loc[pos_indx][symb_indx] = 1;
	      else if(symb_indx == T_LEN)
		err_loc[pos_indx][symb_indx] = gf_mult(err_loc[pos_indx-1][symb_indx-1], coef_position_pow[pos_indx]);
	      else
      		err_loc[pos_indx][symb_indx] = err_loc[pos_indx-1][symb_indx] ^ gf_mult(err_loc[pos_indx-1][symb_indx-1], coef_position_pow[pos_indx]);
      	 end // else: !if(pos_indx == 0)
	 //
	 // pack err_loc
	 
      end // for (int pos_indx = 0; pos_indx < T_LEN; ++pos_indx)
   end // always_comb
   
   wire [T_LEN-1:0] base = { {T_LEN-1{1'b0}} , 1'b1 };
   wire [T_LEN:0][SYMB_WIDTH-1:0] err_loc_mux;
   wire [T_LEN-1:0] 		  error_positions_vld_msb;
   
   lib_mux_ffs
     #(
       .PORTS_NUMBER(T_LEN),
       .WIDTH((T_LEN+1)*(SYMB_WIDTH))
       )
   err_loc_mux_inst
     (
      .base(base),
      .data_i(err_loc),
      .sel_non_ffs(error_positions_vld),
      .data_o(err_loc_mux),
      .sel_ffs(error_positions_vld_msb)
      );
   
   // GF_POLY_MULT()
   logic [SYMB_WIDTH-1:0] 	  syndrome_rev[ROOTS_NUM-1:0];

   // TODO: Do we need all symbols or we can use only low part of it. 
   always_comb begin
      for(int i = 0; i < ROOTS_NUM; ++i)
	syndrome_rev[i] = syndrome[ROOTS_NUM-1-i];
      for(int indx = 0; indx < ROOTS_NUM+T_LEN; ++indx)
	synd_x_error_evaluator[indx] = '0;
      for(int pos_indx = 0; pos_indx < T_LEN+1; ++pos_indx) begin
	 for(int synd_indx = 0; synd_indx < ROOTS_NUM; ++synd_indx) begin	    
	    synd_x_error_evaluator[pos_indx+synd_indx] ^= gf_mult(err_loc_mux[pos_indx], syndrome_rev[synd_indx]);
	 end	 
      end
   end // always_comb
   

   wire [T_LEN+1:0] 		  divisor = {error_positions_vld_msb, 2'b00};

   // Divisor could vary from 1'b1 up to { 1'b1, {T_LEN-1{1'b0}} }   
   logic [T_LEN:0][SYMB_WIDTH-1:0] dividend_arr [T_LEN-1:0];
   
   always_comb begin
      for(int word_indx = 0; word_indx < T_LEN; ++word_indx) begin
	 for(int symb_indx = 0; symb_indx < T_LEN; ++symb_indx) begin
	    if(symb_indx > word_indx)
	      dividend_arr[word_indx][symb_indx] = '0;
	    else
	      dividend_arr[word_indx][symb_indx] = synd_x_error_evaluator[word_indx-symb_indx];
	 end
      end
   end
   
   lib_mux_onehot
     #(
       .PORTS_NUMBER(T_LEN),
       .WIDTH((T_LEN+1)*(SYMB_WIDTH))
       )
   divide_inst
     (
      .data_i(dividend_arr),
      .sel(error_positions_vld_msb),
      .data_o(error_evaluator)
      );

   // Compute the formal derivative of the error locator polynomial
   logic [SYMB_WIDTH-1:0] 	  err_loc_prime_tmp [T_LEN-1:0][T_LEN-2:0];
   logic [SYMB_WIDTH-1:0] 	  err_loc_prime_array [T_LEN-1:0][T_LEN-2:0];
   logic [SYMB_WIDTH-1:0][T_LEN-1:0] err_loc_prime;
   logic [SYMB_WIDTH-1:0][T_LEN-1:0] err_loc_prime_mux_in [T_LEN-1:0];
   
   
   always_comb begin
      for(int x_inv_indx = 0; x_inv_indx < T_LEN; ++x_inv_indx) begin
	 for(int x_indx = 0; x_indx < T_LEN-1; ++x_indx) begin
	    // Skip mult when x_inv_indx == x_indx
	    if(x_indx < x_inv_indx)
	      err_loc_prime_tmp[x_inv_indx][x_indx] = gf_mult(error_location_inv[x_inv_indx], error_location[x_indx]) ^ 1;
	    else
	      err_loc_prime_tmp[x_inv_indx][x_indx] = gf_mult(error_location_inv[x_inv_indx], error_location[x_indx+1]) ^ 1;
	    if(x_indx == 0)
	      err_loc_prime_array[x_inv_indx][x_indx] = err_loc_prime_tmp[x_inv_indx][x_indx];
	    else
	      err_loc_prime_array[x_inv_indx][x_indx] = gf_mult(err_loc_prime_array[x_inv_indx][x_indx-1] , err_loc_prime_tmp[x_inv_indx][x_indx]);
	 end // for (int x_indx = 0; x_indx < T_LEN-1; ++x_indx)
	 //err_loc_prime[x_inv_indx] = err_loc_prime_array[x_inv_indx][x_inv_indx];
      end // for (int x_inv_indx = 0; x_inv_indx < T_LEN; ++x_inv_indx)
      for(int col_indx = 0; col_indx < T_LEN; ++col_indx) begin	 
	 for(int row_indx = 0; row_indx < T_LEN; ++row_indx) begin
	    if(col_indx == 0) begin
	       err_loc_prime_mux_in[col_indx][row_indx] = 1;
	    end
	    else begin
	       err_loc_prime_mux_in[col_indx][row_indx] = err_loc_prime_array[row_indx][col_indx-1];
	    end
	 end
      end	      
   end // always_comb

   lib_mux_onehot
     #(
       .PORTS_NUMBER(T_LEN),
       .WIDTH(T_LEN*SYMB_WIDTH)
       )
   err_loc_prime_mux
     (
      .data_i(err_loc_prime_mux_in),
      .sel(error_positions_vld_msb),
      .data_o(err_loc_prime)
      );
   
   // TODO: add description for each block.
   // gf_poly_eval(error_evaluator, Xi_inv)
   logic [T_LEN-1:0][SYMB_WIDTH-1:0] xor_intrm [T_LEN:0];
   logic [T_LEN-1:0][SYMB_WIDTH-1:0] gf_mult_intrm [T_LEN:0];
   logic [T_LEN-1:0][SYMB_WIDTH-1:0] Yl;
   
   always_comb begin
      for(int x_inv_indx = 0; x_inv_indx < T_LEN; ++x_inv_indx) begin
	 for(int symb_indx = 0; symb_indx < T_LEN+1; ++symb_indx) begin
	    if(symb_indx == 0) begin	       
	       gf_mult_intrm[symb_indx][x_inv_indx]	= '0;
	       xor_intrm[symb_indx][x_inv_indx]		= error_evaluator[symb_indx];
	    end
	    else begin
	       gf_mult_intrm[symb_indx][x_inv_indx]	= gf_mult(xor_intrm[symb_indx-1][x_inv_indx], error_location_inv[x_inv_indx]);
	       xor_intrm[symb_indx][x_inv_indx]		= gf_mult_intrm[symb_indx][x_inv_indx] ^ error_evaluator[symb_indx];
	    end	    
	 end
      end // for (int symb_indx = 0; symb_indx < T_LEN; ++symb_indx)
   end // always_comb

   wire [T_LEN:0] gf_poly_eval_mux_sel = {error_positions_vld_msb, 1'b0};
   
   lib_mux_onehot
     #(
       .PORTS_NUMBER(T_LEN+1),
       .WIDTH(T_LEN*SYMB_WIDTH)
       )
   gf_poly_eval_mux_inst
     (
      .data_i(xor_intrm),
      .sel(gf_poly_eval_mux_sel),
      .data_o(Yl)
      );

   // Adjust to fcr parameter
   logic [SYMB_WIDTH-1:0] Yl_adjust [T_LEN-1:0];
   logic [SYMB_WIDTH-1:0] gf_pow_adjust [T_LEN-1:0];
   
   always_comb begin
      for(int symb_indx = 0; symb_indx < T_LEN; ++symb_indx) begin
	 if(FIRST_ROOT == 1) begin
	    gf_pow_adjust[symb_indx] = error_location[symb_indx];
	 end
	 else begin
	    gf_pow_adjust[symb_indx] = pow_first_root_min1(error_location[symb_indx]);
	 end
	 Yl_adjust[symb_indx] = gf_mult(gf_pow_adjust[symb_indx], Yl[symb_indx]);
	 magnitude[symb_indx] = gf_div(Yl_adjust[symb_indx], err_loc_prime[symb_indx]);
      end
   end // always_comb

   // err_loc_prime shouldn't be zero
   assign irq_error_magnitude = ~(|err_loc_prime);
   
endmodule // rs_forney
