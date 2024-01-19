///////////////////////////////////////////
// The block decompose the vector into 
// one-hot vectors.
///////////////////////////////////////////

module lib_decmps_to_pow2
  #(
    parameter LSB_MSB = 0,
    parameter WIDTH = 4
    )
   (
    input [WIDTH-1:0]  vect,
    input [WIDTH-2:0]  bypass,
    output [WIDTH-1:0] onehot[WIDTH-1:0]
    );

   /* verilator lint_off UNOPTFLAT */
   logic [WIDTH-1:0] 	     ffs_vect_in[WIDTH-1:0];
   logic [WIDTH-1:0] 	     onehot_xor[WIDTH-1:0];   
   /* verilator lint_on UNOPTFLAT */

   
   wire [WIDTH-1:0] 	     ffs_vect_out[WIDTH-1:0];

   logic [WIDTH-1:0] 	     onehot_bypass[WIDTH-1:0];
   
   
   always_comb begin
      //////////////////////////////////
      // Dissable FFS output if it's bypassed,
      // there is no need to bypass 
      // the last FFS output
      //////////////////////////////////
      for(int i=0; i < WIDTH; ++i) begin
	 if(i == WIDTH-1)
	   onehot_bypass[i] = ffs_vect_out[i];
	 else
	   onehot_bypass[i] = (bypass[i]) ? '0 : ffs_vect_out[i];
      end
      //////////////////////////////////
      // XOR FFS output to accumulate bits 
      // that were already handled
      //////////////////////////////////
      for(int i=0; i < WIDTH; ++i) begin
	 if(i == 0)
	   onehot_xor[i] = 0;
	 else
	   onehot_xor[i] = onehot_xor[i-1] ^ onehot_bypass[i-1];
      end
      //////////////////////////////////
      // Filter out bits from the input 
      // vector that were already handled
      //////////////////////////////////
      for(int i=0; i < WIDTH; ++i) begin
	 if(i == 0)
	   ffs_vect_in[i] = vect;
	 else
	   ffs_vect_in[i] = onehot_xor[i] ^ vect;
      end
   end
   
   for(genvar i = 0; i < WIDTH; ++i) begin : FFS_GEN

      lib_ffs
		  #(
		    .LSB_MSB(LSB_MSB),
		    .WIDTH(WIDTH)
		    )
      lib_ffs_inst
		  (
		   .vect(ffs_vect_in[i]),
		   .base(1),
		   .vect_ffs(ffs_vect_out[i])
		   );

      assign onehot[i] = onehot_bypass[i];
   end

endmodule // lib_decmps_to_pow2
