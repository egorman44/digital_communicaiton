///////////////////////////////////////////
// Find First Set bit module.
//
// base is used to set first position where
// ffs starts to look 1.
// LSB_MSB param defines seach derection:
//   0: from MSB to LSB
//   1: from LSB to MSB
///////////////////////////////////////////

module lib_ffs
  #(
    parameter LSB_MSB = 0,
    parameter WIDTH = 4
    )
   (
    input [WIDTH-1:0] 	     vect,
    input [WIDTH-1:0] 	     base,
    /* verilator lint_off UNOPTFLAT */
    output logic [WIDTH-1:0] vect_ffs
    /* verilator lint_on UNOPTFLAT */
    );
   
   logic [WIDTH-1:0] 	     vect_inrm;
   logic [WIDTH*2-1:0] 	     in_2x;
   logic [WIDTH*2-1:0] 	     out_2x;
   /* verilator lint_off UNOPTFLAT */
   logic [WIDTH-1:0] 	     vect_ffs_inrm;
   /* verilator lint_on UNOPTFLAT */


   //////////////////////////////////////
   // Swap input/output vectors if MSB -> LSB search
   //////////////////////////////////////
   
   always_comb begin
      if(LSB_MSB != 0) begin
	 vect_inrm	= vect;
	 vect_ffs	= vect_ffs_inrm;
      end
      else begin
	 for(int i = 0; i < WIDTH; ++i) begin
	    vect_inrm[i]	= vect[WIDTH-1-i];
	    vect_ffs[i]		= vect_ffs_inrm[WIDTH-1-i];
	 end	  
      end
   end // always_comb
      
   always_comb begin
      in_2x		= {vect_inrm, vect_inrm};
      out_2x		= in_2x & ~(in_2x - { {WIDTH{1'b0}},base } );
      vect_ffs_inrm	= out_2x[WIDTH-1:0] | out_2x[WIDTH*2-1:WIDTH];
   end
   
endmodule // lib_ffs
