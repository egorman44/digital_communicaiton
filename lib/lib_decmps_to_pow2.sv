///////////////////////////////////////////
// The block decompose the vector into 
// one-hot vectors.
///////////////////////////////////////////

module lib_decmps_to_pow2
  #(
    parameter LSB_MSB	= 0,
    parameter WIDTH	= 16,
    parameter FFS_NUM	= WIDTH,
    parameter FF_STEP   = 0
    )
   (
    input 		clk,
    input 		rstn,
    input [WIDTH-1:0] 	vect,
    input [FFS_NUM-1:0] bypass,
    output [WIDTH-1:0] 	onehot[FFS_NUM-1:0]
    );

   /* verilator lint_off UNOPTFLAT */
   logic [WIDTH-1:0] 	intrm__vect[FFS_NUM-1:0];
   logic [WIDTH-1:0] 	intrm__handled_bits[FFS_NUM-1:0];
   logic [WIDTH-1:0] 	end__handled_bits[FFS_NUM-1:0];   
   logic [WIDTH-1:0] 	end__vect[FFS_NUM-1:0];
   /* verilator lint_on UNOPTFLAT */

   logic [WIDTH-1:0] 	ffs_vect_in[FFS_NUM-1:0];   
   wire [WIDTH-1:0] 	ffs_vect_out[FFS_NUM-1:0];   
   logic [WIDTH-1:0] 	onehot_bypass[FFS_NUM-1:0];   
   
   always_comb begin
      for(int i=0; i < FFS_NUM; ++i) begin
	 if(i == 0)
	   ffs_vect_in[i] = vect;
	 else
	   ffs_vect_in[i] = end__vect[i-1];
      end
      //////////////////////////////////
      // Dissable FFS output if it's bypassed,
      // there is no need to bypass 
      // the last FFS output
      //////////////////////////////////
      for(int i=0; i < FFS_NUM; ++i) begin
	 if(i == FFS_NUM-1)
	   onehot_bypass[i] = ffs_vect_out[i];
	 else
	   onehot_bypass[i] = (bypass[i]) ? '0 : ffs_vect_out[i];
      end
      //////////////////////////////////
      // XOR FFS output to accumulate bits 
      // that were already handled
      //////////////////////////////////
      for(int i=0; i < FFS_NUM; ++i) begin
	 if(i == 0)
	   intrm__handled_bits[i] = onehot_bypass[i];
	 else
	   intrm__handled_bits[i] = end__handled_bits[i-1] ^ onehot_bypass[i];
      end
      //////////////////////////////////
      // Filter out bits from the input 
      // vector that were already handled
      //////////////////////////////////
      for(int i=0; i < FFS_NUM; ++i) begin
	 if(i == 0)
	   intrm__vect[i] = intrm__handled_bits[i] ^ vect;
	 else
	   intrm__vect[i] = intrm__handled_bits[i] ^ end__vect[i-1];
      end
   end

   wire [WIDTH-1:0] base = { {WIDTH-1{1'b0}}, 1'b1 };

   //////////////////////////////////
   // FFS instances
   //////////////////////////////////
   
   for(genvar i = 0; i < FFS_NUM; ++i) begin : FFS_GEN
		    
      lib_ffs
		  #(
		    .LSB_MSB(LSB_MSB),
		    .WIDTH(WIDTH)
		    )
      lib_ffs_inst
		  (
		   .vect(ffs_vect_in[i]),
		   .base(base),
		   .vect_ffs(ffs_vect_out[i])
		   );

      assign onehot[i] = onehot_bypass[i];
   end // block: FFS_GEN

   //////////////////////////////////
   // Pipelining interface
   //////////////////////////////////
   
   if(FF_STEP != 0) begin : PIPELING

      typedef struct packed {
	 logic [WIDTH-1:0] ffs_vect;
	 logic [WIDTH-1:0] handled_bits;
      } pipe_data_t;

      pipe_data_t intrm__data[FFS_NUM-1:0];
      pipe_data_t end__data[FFS_NUM-1:0];

      always_comb begin
	 for(int i = 0; i < FFS_NUM; ++i) begin
	    end__vect[i] = end__data.ffs_vect[i];
	    end__handled_bits[i] = end__data.handled_bits[i];
	    intrm__data.ffs_vect[i] = intrm__vect[i];
	    intrm__data.handled_bits[i] = intrm__handled_bits[i];
	 end
      end
   
      lib_pipe 
	#(
	  .WIDTH($bits(pipe_data_t)),
	  .STAGE_NUM(FFS_NUM),
	  .FF_STEP(FF_STEP)
	  )
	lib_pipe_inst
	  (
	   .clk(clk),
	   .rstn(rstn),
	   .data_i(intrm__data),
	   .vld_i(),
	   .data_o(end__data),
	   .vld_o()
	   );
      
   end
   else begin

      always_comb begin
	 for(int i = 0; i < FFS_NUM; ++i) begin
	    end__handled_bits[i] = intrm__handled_bits[i];
	    end__vect[i] = intrm__vect[i];
	 end
      end // always_comb
         
   end

endmodule // lib_decmps_to_pow2
