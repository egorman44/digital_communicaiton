module rs_forney
  import gf_pkg::*;
   (
    input 		   aclk,
    input 		   aresetn,
    input [SYMB_WIDTH-1:0] error_positions[T_LEN-1:0],
    input 		   error_positions_vld,
    input [SYMB_WIDTH-1:0] syndrome[ROOTS_NUM-1:0],
    input 		   syndrome_vld
    );
   
   // TODO: Get coef_pos

   logic [SYMB_WIDTH-1:0]  coef_position[T_LEN-1:0];
   logic [SYMB_WIDTH-1:0]  coef_position_pow[T_LEN-1:0];
   
   logic [SYMB_WIDTH-1:0]  err_loc[T_LEN-1:0][T_LEN:0];

   logic [SYMB_WIDTH-1:0]  synd_x_error_evaluator[ROOTS_NUM+T_LEN-1:0];
   
   // TODO: delete
   
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn) begin
	 coef_position[0] <= '0;
	 coef_position[1] <= '0;
	 coef_position[2] <= '0;
	 coef_position[3] <= '0;
	 coef_position[4] <= '0;
	 coef_position[5] <= '0;
	 coef_position[6] <= '0;
	 coef_position[7] <= '0;
      end // if (~aresetn)
      else begin
	 coef_position[0] <= 8;
	 coef_position[1] <= 17;
	 coef_position[2] <= 95;
	 coef_position[3] <= 111;
	 coef_position[4] <= 162;
	 coef_position[5] <= 169;
	 coef_position[6] <= 174;
	 coef_position[7] <= 196;
      end
   end

   
   // TODO: Reduce utilization ?!
   // TODO: reduce POLY, since in the [0] position always 1.
   always_comb begin
      for(int pos_indx = 0; pos_indx < T_LEN; ++pos_indx) begin
      	 coef_position_pow[pos_indx] = pow_first_root(coef_position[pos_indx]);
	 // GF polynimial multiplication:
	 // 
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
	 
      end // for (int pos_indx = 0; pos_indx < T_LEN; ++pos_indx)      
   end // always_comb

   
//   always_comb begin
//      for(int indx = 0; indx < ROOTS_NUM+T_LEN; ++indx)
//	synd_x_error_evaluator[indx] = '0;
//      for(int pos_indx = 0; pos_indx < T_LEN; ++pos_indx) begin
//	 for(int synd_indx = 0; synd_indx < ROOTS_NUM; ++synd_indx) begin
//	    //synd_x_error_evaluator[pos_indx+synd_indx] += gf_mult(err_loc[pos_indx], syndrome[synd_indx]);
//	    synd_x_error_evaluator[pos_indx+synd_indx] += err_loc[pos_indx] ^ syndrome[synd_indx];
//	 end
//      end
//   end
      
   
endmodule // rs_forney
