module rs_chien_pos_to_value
  import gf_pkg::*;
   (
    input 			       aclk,
    input 			       aresetn,
    input 			       error_bit_pos_vld,
    input [ROOTS_PER_CYCLE__CHIEN-1:0] error_bit_pos,
    output [SYMB_WIDTH-1:0] 	       error_positions[T_LEN-1:0],
    output [T_LEN-1:0] 		       error_positions_sel,
    output 			       error_positions_vld
    );
   
   /////////////////////////////////////////////////
   // Convert bit posisiton into T_LEN number of
   // onehot vectors to get the binary value of root.
   /////////////////////////////////////////////////

   wire [T_LEN-1:0] 		       lib_decmps_vld;
   wire [T_LEN-1:0] 		       bypass;
   wire [ROOTS_PER_CYCLE__CHIEN-1:0]   mux_sel[T_LEN-1:0];
   
   lib_decmps_to_pow2
     #(
       .WIDTH(ROOTS_PER_CYCLE__CHIEN),
       .FFS_NUM(T_LEN),
       .LSB_MSB(1),
       .FF_STEP(FF_STEP__CHIEN_BIT_CONV)
       )
   lib_decmps_to_pow2_inst
     (
      .clk(aclk),
      .rstn(aresetn),
      .vect(error_bit_pos),
      .vld_i(error_bit_pos_vld),
      .vld_o(lib_decmps_vld),
      .bypass(bypass),
      .onehot(mux_sel)
      );
   
   /////////////////////////////////////////////////
   // In both pipelined and non-pipelined versions 
   // pos_conv_st_cntr_q is used to uniform the code.
   // It's used to correspond alpha roots to onehot mux value.
   // It should utilize less logic than alpha_mux_in 
   // pipelining over all stages of lib_decmps_to_pow2_inst
   // in pipelined version.
   /////////////////////////////////////////////////

   logic [SYMB_WIDTH-1:0] 	       pos_conv_st_cntr_q;
   wire 			       last_cycle = (pos_conv_st_cntr_q == SYMB_WIDTH'(CYCLES_NUM__CHIEN-1));
   logic [SYMB_WIDTH-1:0] 	       cntr_val[T_LEN-1:0];
   logic 			       error_bit_pos_vld_q;
   wire 			       start_cntr = ~error_bit_pos_vld_q && error_bit_pos_vld;
   
   
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn) begin
	 pos_conv_st_cntr_q	<= '0;
	 error_bit_pos_vld_q	<= '0;
      end
      else begin
	 error_bit_pos_vld_q	<= error_bit_pos_vld;
	 if(start_cntr)
	   pos_conv_st_cntr_q <= pos_conv_st_cntr_q + 1;
	 else if(|pos_conv_st_cntr_q) begin
	    if(last_cycle)
	      pos_conv_st_cntr_q <= '0;
	    else
	      pos_conv_st_cntr_q <= pos_conv_st_cntr_q + 1'b1;
	 end
      end
   end // always_ff @ (posedge aclk, negedge aresetn)

   if(FF_STEP__CHIEN_BIT_CONV == 0) begin

      always_comb begin
	 for(int i = 0; i < T_LEN; ++i) begin
	    cntr_val[i] = pos_conv_st_cntr_q;
	 end
      end
   
   end
   else begin      

      logic [SYMB_WIDTH-1:0] intrm__cntr_val[T_LEN-1:0];
      wire [SYMB_WIDTH-1:0] end__cntr_val[T_LEN-2:0];

      always_comb begin
	 for(int i = 0; i < T_LEN; ++i) begin
	    if(i == 0)
	      intrm__cntr_val[i] = pos_conv_st_cntr_q;
	    else
	      intrm__cntr_val[i] = end__cntr_val[i-1];
	    cntr_val[i] = intrm__cntr_val[i];
	 end
      end
      
      lib_pipe 
	#(
	  .WIDTH(SYMB_WIDTH),
	  .STAGE_NUM(T_LEN),
	  .FF_STEP(FF_STEP__CHIEN_BIT_CONV)
	  )
      cntr_pipe_inst
	(
	 .clk(aclk),
	 .rstn(aresetn),
	 .data_i(intrm__cntr_val),
	 .vld_i(),
	 .data_o(end__cntr_val),
	 .vld_o()
	 );
      
   end // else: !if(FF_STEP__CHIEN_BIT_CONV == 0)

   //////////////////////////////////////
   // Capture mux_seq to choose proper
   // roots
   //////////////////////////////////////

   logic [ROOTS_PER_CYCLE__CHIEN-1:0] mux_sel_q[T_LEN-1:0];
   logic [T_LEN-1:0] 		      err_pos_capt_q;
   logic [SYMB_WIDTH-1:0] 	      cntr_val_q[T_LEN-1:0];      
   logic 			      lib_decmps_vld_q;
   logic 			      lib_decmps_vld_qq;

   assign bypass = err_pos_capt_q;

   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn) begin
	 lib_decmps_vld_q <= 1'b0;
	 lib_decmps_vld_qq <= 1'b0;
      end
      else begin
	 lib_decmps_vld_q <= |lib_decmps_vld;
	 lib_decmps_vld_qq <= lib_decmps_vld_q;
      end
   end
   
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn) begin
	 for(int i = 0; i < T_LEN; ++i) begin
	    err_pos_capt_q[i]	<= '0;
	    mux_sel_q[i]	<= '0;
	    cntr_val_q[i]	<= '0;
	 end
      end
      else begin	 
	 if(|lib_decmps_vld) begin
	    for(int i = 0; i < T_LEN; ++i) begin
	       if(|mux_sel[i]) begin
		  err_pos_capt_q[i]	<= |mux_sel[i];
		  mux_sel_q[i]		<= mux_sel[i];
		  cntr_val_q[i]		<= cntr_val[i];
	       end
	    end
	 end
	 else begin
	    for(int i = 0; i < T_LEN; ++i) begin
	       err_pos_capt_q[i]	<= '0;
	       mux_sel_q[i]		<= '0;
	    end
	 end
      end // else: !if(~aresetn)
   end // always_ff @ (posedge aclk, negedge aresetn)

   /////////////////////////////////////////////////
   // Selecting roots
   /////////////////////////////////////////////////

   logic [SYMB_WIDTH-1:0] alpha_base   [ROOTS_PER_CYCLE__CHIEN-1:0];
   logic [SYMB_WIDTH-1:0] alpha_mux_in [T_LEN-1:0][ROOTS_PER_CYCLE__CHIEN-1:0];
   wire [SYMB_WIDTH-1:0]  error_positions_mux_out[T_LEN-1:0];
   wire [SYMB_WIDTH-1:0]  base [CYCLES_NUM__CHIEN-1:0];

   localparam BASE_ADDR_WIDTH = $clog2(CYCLES_NUM__CHIEN);
   
   for(genvar i =0; i < CYCLES_NUM__CHIEN; ++i) begin
      assign base[i] = i * ROOTS_PER_CYCLE__CHIEN;
   end

   always_comb begin
      for(int i = 0; i < ROOTS_PER_CYCLE__CHIEN; ++i) begin
	 alpha_base[i] = i[SYMB_WIDTH-1:0];	 
      end
      for(int mux_indx = 0; mux_indx < T_LEN; ++mux_indx) begin
	 for(int root_indx = 0; root_indx < ROOTS_PER_CYCLE__CHIEN; ++root_indx) begin
	    alpha_mux_in[mux_indx][root_indx] = alpha_base[root_indx] + base[BASE_ADDR_WIDTH'(cntr_val_q[mux_indx])];
	 end
      end
   end
   
   for(genvar i = 0; i < T_LEN; ++i) begin : ERROR_POSITIONS_MUX
      
      lib_mux_onehot
		  #(
		    .PORTS_NUMBER(ROOTS_PER_CYCLE__CHIEN),
		    .WIDTH(SYMB_WIDTH)
		    )
      lib_mux_onehot_inst
		  (
		   .data_i(alpha_mux_in[i]),
		   .sel(mux_sel_q[i]),
		   .data_o(error_positions_mux_out[i])
		   );
      
   end // for (genvar i = 0; i < T_LEN; ++i)

   /////////////////////////////////////////////////
   // Capture errors positions
   /////////////////////////////////////////////////

   logic [SYMB_WIDTH-1:0] error_positions_q[T_LEN-1:0];
   logic [T_LEN-1:0] 	  error_positions_sel_q;   
   wire 		  capture_positions = lib_decmps_vld_qq;
   
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn) begin
	 for(int i = 0; i < T_LEN; ++i) begin
	    error_positions_q[i] <= '0;
	    error_positions_sel_q[i] <= '0;
	 end
      end
      else begin
	 if(capture_positions) begin
	    for(int i = 0; i < T_LEN; ++i) begin
	       if(|mux_sel_q[i] && !error_positions_sel_q[i]) begin
		  error_positions_q[i] <= SYMB_NUM-2-error_positions_mux_out[i];
		  error_positions_sel_q[i] <= 1'b1;
	       end
	    end
	 end
	 else begin
	    for(int i = 0; i < T_LEN; ++i) begin
	       error_positions_q[i] <= '0;
	       error_positions_sel_q[i] <= 1'b0;
	    end
	 end	   
      end
   end
   
   assign error_positions = error_positions_q;
   assign error_positions_sel = error_positions_sel_q;
   assign error_positions_vld = lib_decmps_vld_qq && ~lib_decmps_vld_q;
   
endmodule // rs_chien_pos_to_value
