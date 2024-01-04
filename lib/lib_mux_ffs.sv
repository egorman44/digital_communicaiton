module lib_mux_ffs
  #(
    parameter PORTS_NUMBER = 4,
    parameter WIDTH = 8
    )
   (
   input [PORTS_NUMBER-1:0]  base,
   input [WIDTH-1:0] 	     data_i[PORTS_NUMBER-1:0],
   input [PORTS_NUMBER-1:0]  sel_non_ffs,
   output [WIDTH-1:0] 	     data_o,
   output [PORTS_NUMBER-1:0] sel_ffs
   );
   
   lib_ffs
     #(
       .WIDTH(PORTS_NUMBER)
       )
   lib_ffs_inst(
		// Outputs
		.vect_ffs	(sel_ffs),
		// Inputs
		.vect		(sel_non_ffs),
		.base		(base));

   lib_mux_onehot
     #(
       .PORTS_NUMBER(PORTS_NUMBER),
       .WIDTH(WIDTH)
       )
   lib_mux_onehot_inst
     (
      .data_i(data_i),
      .sel(sel_ffs),
      .data_o(data_o)
      );
   
   
endmodule // lib_mux_ffs
