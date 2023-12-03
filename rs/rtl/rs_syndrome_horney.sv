module rs_syndrome_horney
  import gf_pkg::*;
   (
    input 					  aclk,
    input 					  aresetn,
    input 					  s_tvalid,
    input [BUS_WIDTH_IN_SYMB-1:0][SYMB_WIDTH-1:0] s_tdata,
    input 					  s_tlast,
    input [BUS_WIDTH_IN_SYMB-1:0] 		  s_tkeep,
    input [SYMB_WIDTH-1:0] 			  root,
    output logic [SYMB_WIDTH-1:0] 		  syndrome
    );

   ///////////////////////////////////////
   // Horneys_method
   ///////////////////////////////////////
   
   logic [SYMB_WIDTH-1:0] xor_intrm [BUS_WIDTH_IN_SYMB-1:0];
   logic [SYMB_WIDTH-1:0] accum_q;
   logic 		  s_tvalid_q;

   // SOP generation
   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn)
	s_tvalid_q <= 1'b0;
      else begin
	 if(s_tvalid && s_tlast)
	   s_tvalid_q <= 1'b0;
	 else
	   s_tvalid_q <= s_tvalid;
      end
   end

   wire sop = s_tvalid && ~s_tvalid_q;
   
   logic [SYMB_WIDTH-1:0] gf_mult_intrm [BUS_WIDTH_IN_SYMB-1:0];
   always_comb begin
      for(int i = 0; i < BUS_WIDTH_IN_SYMB; ++i)
	if(i == 0)
	  if(sop) begin
	     gf_mult_intrm[i] = '0;
	     xor_intrm[i] = s_tdata[i];
	  end
	  else begin
	     gf_mult_intrm[i] = gf_mult(accum_q, root);
	     xor_intrm[i] = gf_mult_intrm[i] ^ s_tdata[i];
	  end
	else begin
	   gf_mult_intrm[i] = gf_mult(xor_intrm[i-1], root);
	   xor_intrm[i] = gf_mult_intrm[i] ^ s_tdata[i];
	end
   end

   // Choose which part should be sum up in accumulator.
   wire [BUS_WIDTH_IN_SYMB-1:0] base = { {BUS_WIDTH_IN_SYMB-1{1'b0}} , 1'b1};
   logic [SYMB_WIDTH-1:0] cycle_sum;
   
   lib_mux_ffs
     #(
       .PORTS_NUMBER(BUS_WIDTH_IN_SYMB),
       .WIDTH(SYMB_WIDTH)
       )
   lib_mux_ffs_inst
     (
      .base(base),
      .sel_non_ffs(s_tkeep),
      .data_i(xor_intrm),
      .data_o(cycle_sum)
      );

   always_ff @(posedge aclk, negedge aresetn) begin
      if(~aresetn) begin
	 accum_q <= '0;
      end
      else begin
	 if(s_tvalid) begin
	    if(s_tlast) begin
	       accum_q <= '0;
	    end	    
	    else
	      accum_q <= cycle_sum;
	 end	 
      end
   end // always_ff @ (posedge aclk, negedge aresetn)

   assign syndrome = cycle_sum;

endmodule // rs_syndrome_horney
