module shift8(
	      input [2:0]   shift_val,
	      input [31:0]  data_i,
	      output [31:0] data_o
	      );

   assign data_o = data_i << 8*shift_val;
   
endmodule // shift8
