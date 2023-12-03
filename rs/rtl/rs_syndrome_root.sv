module rs_syndrome_root
  import gf_pkg::*;
  (/*AUTOINPUT*/
  // Beginning of automatic inputs (from unused autoinst inputs)
  input			aclk,			// To rs_syndrome_horney of rs_syndrome_horney.v
  input			aresetn,		// To rs_syndrome_horney of rs_syndrome_horney.v
  input [SYMB_WIDTH-1:0] root,			// To rs_syndrome_horney of rs_syndrome_horney.v
  input [BUS_WIDTH_IN_SYMB-1:0] [SYMB_WIDTH-1:0] s_tdata,// To rs_syndrome_horney of rs_syndrome_horney.v
  input [BUS_WIDTH_IN_SYMB-1:0] s_tkeep,	// To rs_syndrome_horney of rs_syndrome_horney.v
  input			s_tlast,		// To rs_syndrome_horney of rs_syndrome_horney.v
  input			s_tvalid,		// To rs_syndrome_horney of rs_syndrome_horney.v
  // End of automatics
   /*AUTOOUTPUT*/
   // Beginning of automatic outputs (from unused autoinst outputs)
   output logic [SYMB_WIDTH-1:0] syndrome	// From rs_syndrome_horney of rs_syndrome_horney.v
   // End of automatics
   );
   
   rs_syndrome_horney rs_syndrome_horney(/*AUTOINST*/
					 // Outputs
					 .syndrome		(syndrome[SYMB_WIDTH-1:0]),
					 // Inputs
					 .aclk			(aclk),
					 .aresetn		(aresetn),
					 .s_tvalid		(s_tvalid),
					 .s_tdata		(s_tdata/*[BUS_WIDTH_IN_SYMB-1:0][SYMB_WIDTH-1:0]*/),
					 .s_tlast		(s_tlast),
					 .s_tkeep		(s_tkeep[BUS_WIDTH_IN_SYMB-1:0]),
					 .root			(root[SYMB_WIDTH-1:0]));
endmodule // rs_syndrome_root
