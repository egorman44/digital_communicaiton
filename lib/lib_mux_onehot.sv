module lib_mux_onehot
  #(
    parameter PORTS_NUMBER = 4,
    parameter WIDTH = 8
    )
   (
    input [WIDTH-1:0] 	     data_i[PORTS_NUMBER-1:0],
    input [PORTS_NUMBER-1:0] sel,
    output [WIDTH-1:0] 	     data_o
    );

   logic [WIDTH-1:0]         data_and_sel[PORTS_NUMBER-1:0];

   // Intermediate ORs
   /* verilator lint_off UNOPTFLAT */
   logic [WIDTH-1:0] 	     ors_intr[PORTS_NUMBER-1:1];
   /* verilator lint_on UNOPTFLAT */

   always_comb begin
      foreach(data_and_sel[i])
        data_and_sel[i] = (sel[i]) ? data_i[i] : '0;

      for(int i = 1; i < PORTS_NUMBER; i++) begin
         if(i == 1)
           ors_intr[i] = data_and_sel[i] | data_and_sel[i-1];
         else
           ors_intr[i] = data_and_sel[i] | ors_intr[i-1];
      end
   end

   assign data_o = ors_intr[PORTS_NUMBER-1];

endmodule // lib_mux_onehot
