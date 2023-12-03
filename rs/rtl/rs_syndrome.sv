module rs_syndrome
  import gf_pkg::*;
  (
   input 					 aclk,
   input 					 aresetn,
   input 					 s_tvalid,
   input [BUS_WIDTH_IN_SYMB-1:0][SYMB_WIDTH-1:0] s_tdata,
   input 					 s_tlast,
   input [BUS_WIDTH_IN_SYMB-1:0] 		 s_tkeep,
   input [SYMB_WIDTH-1:0] 			 roots [ROOTS_NUM-1:0],
   output logic [SYMB_WIDTH-1:0] 		 syndrome[ROOTS_NUM-1:0],
   output 					 syndrome_vld
   );

   /* rs_syndrome_root AUTO_TEMPLATE
    (
    .syndrome(syndrome[i]),
    .root(roots[i]),
    );
    */
   
   for(genvar i = 0; i < ROOTS_NUM; ++i) begin: RS_SYNDROME_ROOT
      
      rs_syndrome_root rs_syndrome_root_inst(/*AUTOINST*/
					     // Outputs
					     .syndrome		(syndrome[i]),	 // Templated
					     // Inputs
					     .aclk		(aclk),
					     .aresetn		(aresetn),
					     .root		(roots[i]),	 // Templated
					     .s_tdata		(s_tdata/*[BUS_WIDTH_IN_SYMB-1:0][SYMB_WIDTH-1:0]*/),
					     .s_tkeep		(s_tkeep[BUS_WIDTH_IN_SYMB-1:0]),
					     .s_tlast		(s_tlast),
					     .s_tvalid		(s_tvalid));
   end // block: RS_SYNDROME_ROOT
         
   assign syndrome_vld = s_tvalid && s_tlast;
   
endmodule // rs_syndrome
