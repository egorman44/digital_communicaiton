module lib_pipe
  #(
    parameter WIDTH	= 8,
    parameter STAGE_NUM = 8,
    parameter FF_STEP	= 4,
    parameter FF_NUM    = (STAGE_NUM/FF_STEP)-1
    )
   (
    input 		     clk,
    input 		     rstn,
    input [WIDTH-1:0] 	     data_i [STAGE_NUM-1:0],
    input 		     vld_i [STAGE_NUM-1:0],
    /* verilator lint_off UNOPTFLAT */
    output logic [WIDTH-1:0] data_o[STAGE_NUM-2:0],
    output logic 	     vld_o[STAGE_NUM-2:0]
    /* verilator lint_on UNOPTFLAT */
    );   
   
   logic [WIDTH-1:0]  data_q[FF_NUM-1:0];
   logic 	      vld_q[FF_NUM-1:0];
   
   // TODO: add fatal condition
   if(FF_STEP > STAGE_NUM-1) begin
      initial begin
	 $fatal("[FATAL] lib_pipe wrong configuration. FF_STEP(%0d) > STAGE_NUM-1(%0d)", FF_STEP, STAGE_NUM-1);
      end
   end

   always_ff @(posedge clk) begin
      for(int i = 0; i < FF_NUM; ++i)
	data_q[i] <= data_i[(i*FF_STEP)+FF_STEP-1];
   end

   always_ff @(posedge clk, negedge rstn) begin
      if(~rstn) begin
	 for(int i = 0; i < FF_NUM; ++i)
	   vld_q[i] <= '0;
      end
      else begin
	 for(int i = 0; i < FF_NUM; ++i)
	   vld_q[i] <= vld_i[(i*FF_STEP)+FF_STEP-1];	 
      end
   end

   always_comb begin
      for(int i = 0; i < FF_NUM; ++i) begin
	 vld_o[(i*FF_STEP)+FF_STEP-1] = vld_q[i];
	 data_o[(i*FF_STEP)+FF_STEP-1] = data_q[i];	 
      end
      for(int i = 0; i < STAGE_NUM-1; ++i) begin
	if( (i+1) % FF_STEP != 0 ) begin
	   data_o[i] = data_i[i];
	   vld_o[i] = vld_i[i];
	end
      end
   end // always_comb
   
   //initial begin
   //   for(int i = 0; i < FF_NUM; ++i) begin
   //	 $display("q_connection[%0d]",(i*FF_STEP)+FF_STEP-1);
   //   end
   //   for(int i = 0; i < STAGE_NUM-1; ++i) begin
   //	 if( (i+1) % FF_STEP != 0 )
   //	   $display("wire_connection[%0d]", i);
   //   end
   //end
   
endmodule // lib_pipe
