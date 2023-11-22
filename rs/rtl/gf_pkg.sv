package gf_pkg;

`ifndef SYMB_WIDTH_DEF
 `define SYMB_WIDTH_DEF 8
 `define POLY_DEF 285
`endif
   
   parameter SYMB_WIDTH = `SYMB_WIDTH_DEF;
   parameter SYMB_NUM	= 2 ** SYMB_WIDTH;
   parameter POLY	= `POLY_DEF;

   typedef logic [SYMB_WIDTH-1:0] alpha_to_symb_t [SYMB_NUM-1:0];
   
   //////////////////////////////////////
   // Generate all alpha elements using LSFR rule.   
   //////////////////////////////////////
   
   function alpha_to_symb_t alpha_to_symb();
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
      end // for (int i = 0; i < SYMB_NUM; ++i)
   endfunction // alpha_to_symb

   //////////////////////////////////////   
   // Inverse function.
   // Note. There is no alpha_to_symb[x] = 0, thus make it manually
   //////////////////////////////////////
   
   function alpha_to_symb_t symb_to_alpha ();
      alpha_to_symb_t alpha_to_symb_tbl;
      alpha_to_symb_tbl = alpha_to_symb();
      symb_to_alpha[0] = 0;	 
      for(int i = 0; i < SYMB_NUM; ++i) begin
	 symb_to_alpha[alpha_to_symb_tbl[i]] = i[SYMB_WIDTH-1:0];
      end
   endfunction // symb_to_alpha
   
endpackage // gf_pkg
   
