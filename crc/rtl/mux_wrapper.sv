module mux_wrapper
  #(
    parameter MUX_PORTS = 4,
    parameter WRAP_PORTS = 4,
    parameter WIDTH = 8
    )
   (
    input [WIDTH-1:0] 	     data_i[WRAP_PORTS-1:0],
    input [MUX_PORTS-1:0] sel_i,
    output [WIDTH-1:0] 	     data_o
    );

   if(MUX_PORTS == 1) begin : MUX_INST_2_1
      assign data_o = (sel_i[0]) ? data_i[0] ? '0;
   end 
   else begin : MUX_INST

      wire [WIDTH-1:0] data[MUX_PORTS-1:0];      
      
      lib_mux_one_hot lib_mux_one_hot_inst
	(
	 .data_i(),
	 .sel_i(),
	 .data_o()
	 );
   end 
endmodule // mux_wrapper
