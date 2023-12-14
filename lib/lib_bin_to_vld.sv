//////////////////////////////////////
// Convert bin to vld signal, for example:
// [0] = 16'h1
// [1] = 16'h3
// [2] = 16'h7
// [3] = 16'hF
// ....
// [15] = 16'hFF_FF
// BIN_WDTH = 16 -> VLD_WIDTH = 4 -> bin = 0:15
// BIN_WDTH = 17 -> VLD_WIDTH = 5 -> bin = 0:31, we dont need bin > 17
//////////////////////////////////////

module lib_bin_to_vld
  #(
    parameter VLD_WIDTH = 8,
    parameter BIN_WDTH = $clog2(VLD_WIDTH)
    )
  (
   input [BIN_WDTH-1:0]   bin,
   output [VLD_WIDTH-1:0] vld   
   );
   
   wire [VLD_WIDTH-1:0]   vld_tbl[VLD_WIDTH-1:0];

   for(genvar i = 0; i < VLD_WIDTH; ++i) begin : GEN_VLD_TBL
      assign vld_tbl[i] = {{VLD_WIDTH-i-1{1'b0}} , {i+1{1'b1}}};
   end
      
   assign vld = vld_tbl[bin];

endmodule // lib_bin_to_vld
