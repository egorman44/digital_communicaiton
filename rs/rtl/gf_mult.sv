module gf_mult
  #(
    parameter SYMB_WIDTH	= 8,
    parameter POLY		= 285
    )
   (
    input [SYMB_WIDTH-1:0]  A,
    input [SYMB_WIDTH-1:0]  B,
    output [SYMB_WIDTH-1:0] P
    );

   localparam SYMB_NUM		= 2 ** SYMB_WIDTH;   
   
   logic [SYMB_WIDTH-1:0] symb_to_alpha[1:0][SYMB_NUM-1:0];
   logic [SYMB_WIDTH-1:0] alpha_to_symb[SYMB_NUM-1:0];
   
   // Generate all alpha elements using LSFR rule.   
   always_comb begin
      for(int i = 0; i < SYMB_NUM; ++i) begin
	 if(i == 0)
	   alpha_to_symb[0] = 1;
	 else begin
	    // If MSB of prev symb is 1 then POLY should be XORed with shifted
	    // value because of the feedback
	    if (alpha_to_symb[i-1][SYMB_WIDTH-1])
	      alpha_to_symb[i]	= (alpha_to_symb[i-1] << 1) ^ POLY[SYMB_WIDTH-1:0];
	    else
	      alpha_to_symb[i]	= (alpha_to_symb[i-1] << 1);
	 end
      end
   end
   
   // Inverse function.
   // Note. There is no alpha_to_symb[x] = 0, thus make it manually
   always_comb begin
      for(int tbl_indx = 0; tbl_indx < 2; ++tbl_indx) begin
	 symb_to_alpha[tbl_indx][0] = 0;	 
	 for(int i = 0; i < SYMB_NUM; ++i) begin
	    symb_to_alpha[tbl_indx][alpha_to_symb[i]] = i[SYMB_WIDTH-1:0];
	 end
      end
   end
   
   // 1. Convert symbols to alpha:
   
   wire [SYMB_WIDTH-1:0] alpha_A, alpha_B;

   assign alpha_A = symb_to_alpha[0][A];
   assign alpha_B = symb_to_alpha[1][B];

   // 2. Sum up the powers of alpha_A and alpha_B in GF(2^SYMB_WIDTH):

   wire [SYMB_WIDTH-1:0] sum_alpha_AB = (alpha_A + alpha_B) % (SYMB_NUM-1);

   // 3. Convert back to symbol
   logic [SYMB_WIDTH-1:0] product;

   always_comb begin
      if((A == 0) || (B == 0))
	product = 0;
      else
	product = alpha_to_symb[sum_alpha_AB];
   end
   
   assign P = product;
  
endmodule // gf_mult
