module gf_mult
  import gf_pkg::*;
   (
    input [SYMB_WIDTH-1:0]  A,
    input [SYMB_WIDTH-1:0]  B,
    output [SYMB_WIDTH-1:0] P
    );

   localparam SYMB_NUM		= 2 ** SYMB_WIDTH;   
   
   alpha_to_symb_t symb_to_alpha_tbl [1:0];
   alpha_to_symb_t alpha_to_symb_tbl;
   
   always_comb begin
      alpha_to_symb_tbl = alpha_to_symb();
      for(int tbl_indx = 0; tbl_indx < 2; ++tbl_indx)
	symb_to_alpha_tbl[tbl_indx] = symb_to_alpha();
   end
   
   // 1. Convert symbols to alpha:   
   wire [SYMB_WIDTH-1:0] alpha_A, alpha_B;
   
   assign alpha_A = symb_to_alpha_tbl[0][A];
   assign alpha_B = symb_to_alpha_tbl[1][B];
   
   // 2. Sum up the powers of alpha_A and alpha_B in GF(2^SYMB_WIDTH):

   wire [SYMB_WIDTH-1:0] sum_alpha_AB = (alpha_A + alpha_B) % (SYMB_NUM-1);

   // 3. Convert back to symbol
   logic [SYMB_WIDTH-1:0] product;

   always_comb begin
      if((A == 0) || (B == 0))
	product = 0;
      else
	product = alpha_to_symb_tbl[sum_alpha_AB];
   end
   
   assign P = product;
  
endmodule // gf_mult
