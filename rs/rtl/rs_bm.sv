module rs_bm
  import gf_pkg::*;
  (
   input 		  aclk,
   input 		  aresetn,
   input [SYMB_WIDTH-1:0] syndrome[ROOTS_NUM-1:0],
   input 		  syndrome_vld,
   output 		  decode_error
   );
   
   // TODO: there is no need to have the ROOTS_NUM width,
   // since if error_locator_len > ROOTS_NUM/2 then we couln't
   // decode the message properly.
   
   // TODO: check the width of error_locator_len

   // TODO: add retiming
   //////////////////////////////////////////////
   // error_locator_len - keeps track of the length of the error_locator
   //   start with 0 the max size is T_VAL+1.
   //   T_VAL+1 is an error state.
   //////////////////////////////////////////////
   
   logic [LEN_WIDTH+1:0]  error_locator_len_x2[ROOTS_NUM:0];

   // TODO: check that it's a glitch of verilator. 
   /* verilator lint_off UNOPTFLAT */
   logic [LEN_WIDTH:0] 	  error_locator_len[ROOTS_NUM:0];
   /* verilator lint_on UNOPTFLAT */
   
   logic [ROOTS_NUM:0] 	  error_locator_len_vld[ROOTS_NUM:0];
   
   logic [SYMB_WIDTH-1:0] delta [ROOTS_NUM:0];
   logic [SYMB_WIDTH-1:0] delta_inv [ROOTS_NUM:0];
   
   poly_array_t syndrome_inv;
   poly_array_t syndrome_inv_vld;
   poly_array_t error_locator;
   poly_array_t error_locator_vld;
   poly_array_t delta_intrm;
   poly_array_t aux_B;
   poly_array_t B_x_X;   
   poly_array_t delta_x_B;   
   
   // TODO: Check VLD_WIDTH, why is it ROOTS_NUM+1, it should be ROOTS_NUM.
   
   for(genvar i = 0; i < ROOTS_NUM+1; ++i) begin : GEN_ERR_LEN_BIN_TO_VLD
      lib_bin_to_vld 
		  #(
		    .VLD_WIDTH(ROOTS_NUM+1)
		    )
      err_len_to_vld
		  (
		   .bin(error_locator_len[i]), 
		   .vld(error_locator_len_vld[i])
		   );
   end
   
   // invert syndrome to satisfy convolution
      
   always_comb begin
      for(int root_indx = 0; root_indx < ROOTS_NUM; ++root_indx) begin
	 for(int symb_indx = 0; symb_indx < ROOTS_NUM; ++symb_indx) begin
	    if(symb_indx <= root_indx) begin
	       syndrome_inv[root_indx][symb_indx] = syndrome[root_indx-symb_indx];	       
	    end	    
	    else begin
	       syndrome_inv[root_indx][symb_indx] = '0;
	    end
	    //syndrome_inv_vld[root_indx][symb_indx] = error_locator_len_vld[root_indx][symb_indx] ? syndrome_inv[root_indx][symb_indx] : '0;
	 end
      end      
   end
   
   always_comb begin
      
      // Initialize algorithm
      error_locator_len[0]	= 0;
      error_locator_len_x2[0]   = 0;
      delta[0]       		= 'x;
      delta_inv[0]		= 'x;
      
      for(int symb_indx = 0; symb_indx < ROOTS_NUM; ++symb_indx) begin
	 B_x_X[0][symb_indx]		= 'x;
	 delta_intrm[0][symb_indx]	= 'x;
	 if(symb_indx == 0) begin
	    error_locator[0][symb_indx] = 1;
	    aux_B[0][symb_indx] = 1;
	 end
	 else begin
	    error_locator[0][symb_indx] = 0;
	    aux_B[0][symb_indx] = 0;
	 end
	 error_locator_vld[0][symb_indx] = error_locator[0][symb_indx];
      end
      
      for(int i = 1; i < ROOTS_NUM + 1; ++i) begin

	 // Sum upper limit is L(r-1), then syndrome_inv should be ANDed
	 // with error_locator_len_vld to discard redundent items in error_locator[i-1]
	 // TODO: delta[1] = syndr[0]
	 delta_intrm[i]	= gf_poly_mult(syndrome_inv[i-1], error_locator_vld[i-1]);
	 delta[i]	= gf_poly_sum(delta_intrm[i]);
	 delta_inv[i]	= gf_inv(delta[i]);
	 
	 error_locator_len_x2[i-1] = {error_locator_len[i-1], 1'b0};
	 B_x_X[i]		= gf_poly_mult_x(aux_B[i-1]);
	 delta_x_B[i]		= gf_poly_mult_scalar(B_x_X[i], delta[i]);	 
	 // If discrepancy is not equal to zero then modify LFSR:
	 if(|delta[i]) begin
	    error_locator[i]	= gf_poly_add(error_locator_vld[i-1], delta_x_B[i]);
	    if(error_locator_len_x2[i-1] <= (i[LEN_WIDTH:0] - 1)) begin
	       error_locator_len[i] = i[LEN_WIDTH:0] - error_locator_len[i-1];		  
	       aux_B[i] = gf_poly_mult_scalar(error_locator_vld[i-1], delta_inv[i]);
	    end
	    else begin
	       error_locator_len[i] = error_locator_len[i-1];
	       aux_B[i] = gf_poly_mult_x(aux_B[i-1]);
	    end	    
	 end
	 else begin
	    error_locator_len[i] = error_locator_len[i-1];
	    aux_B[i] = gf_poly_mult_x(aux_B[i-1]);
	    error_locator[i] = error_locator_vld[i-1];
	 end // else: !if(|delta[i])	 
	 // TODO: rewrite syndrome_inv_vld
	 for(int symb_indx = 0; symb_indx < ROOTS_NUM; ++symb_indx) begin
	    error_locator_vld[i][symb_indx] = error_locator_len_vld[i][symb_indx] ? error_locator[i][symb_indx] : '0;
	 end	   
      end	   
   end // always_comb

   // TODO: add clear
   logic too_many_errors_q, too_many_errors;
   logic clear;

   //assign too_many_errors = (error_locator_len > T_VAL+1);
   
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn)
	too_many_errors_q <= '0;
      else begin
	 if(clear)
	   too_many_errors_q <= '0;
	 // TODO: check value
	 else
	   too_many_errors_q <= too_many_errors;
      end
   end // always_ff @ (posedge aclk, negedge aresetn)

   assign decode_error = ~too_many_errors_q && too_many_errors;
   
endmodule // rs_bs
