package gf_pkg;

`ifndef SYMB_WIDTH_DEF
 `define SYMB_WIDTH_DEF 8
 `define POLY_DEF 285
`endif

`ifndef K_LEN
 `define K_LEN 255
`endif
`ifndef N_LEN
 `define N_LEN 239
`endif
   
   parameter N_LEN	= `N_LEN;
   parameter K_LEN	= `K_LEN;
   parameter SYMB_WIDTH = `SYMB_WIDTH_DEF;
   parameter POLY	= `POLY_DEF;
   parameter SYMB_NUM	= 2 ** SYMB_WIDTH;

   typedef logic [SYMB_WIDTH-1:0] alpha_to_symb_t [SYMB_NUM-1:0];

   typedef logic [SYMB_WIDTH-1:0] alpha_t;
   typedef logic [SYMB_WIDTH-1:0] symb_t;
   
   //////////////////////////////////////
   // Generate all alpha elements using LFSR rule.   
   //////////////////////////////////////
   
   function alpha_to_symb_t gen_alpha_to_symb();
      for(int i = 0; i < SYMB_NUM; ++i) begin
	 if(i == 0)
	   gen_alpha_to_symb[0] = 1;
	 else begin
	    // If MSB of prev symb is 1 then POLY should be XORed with shifted
	    // value because of the feedback
	    if (gen_alpha_to_symb[i-1][SYMB_WIDTH-1])
	      gen_alpha_to_symb[i]	= (gen_alpha_to_symb[i-1] << 1) ^ POLY[SYMB_WIDTH-1:0];
	    else
	      gen_alpha_to_symb[i]	= (gen_alpha_to_symb[i-1] << 1);
	 end
      end // for (int i = 0; i < SYMB_NUM; ++i)
   endfunction // gen_alpha_to_symb

   function symb_t alpha_to_symb(alpha_t alpha);
      alpha_to_symb_t alpha_to_symb_tbl;
      alpha_to_symb_tbl = gen_alpha_to_symb();
      alpha_to_symb	= alpha_to_symb_tbl[alpha];
   endfunction // alpha_to_symb   

   //////////////////////////////////////   
   // Inverse function.
   // Note. There is no alpha_to_symb[x] = 0, thus make it manually
   //////////////////////////////////////
   
   function alpha_to_symb_t gen_symb_to_alpha ();
      alpha_to_symb_t alpha_to_symb_tbl;
      alpha_to_symb_tbl = gen_alpha_to_symb();
      gen_symb_to_alpha[0] = 0;	 
      for(int i = 0; i < SYMB_NUM; ++i) begin
	 gen_symb_to_alpha[alpha_to_symb_tbl[i]] = i[SYMB_WIDTH-1:0];
      end
   endfunction // gen_symb_to_alpha

   function alpha_t symb_to_alpha(symb_t symb);
      alpha_to_symb_t symb_to_alpha_tbl;
      symb_to_alpha_tbl = gen_symb_to_alpha();
      symb_to_alpha	= symb_to_alpha_tbl[symb];
   endfunction // symb_to_alpha   

   //////////////////////////////////////   
   // gf mult
   //
   // 1. Convert symbols to alpha:
   // 2. Sum up the powers of alpha_a and alpha_b in GF(2^SYMB_WIDTH):
   // 3. Convert back to symbol
   //////////////////////////////////////

   function symb_t gf_mult(symb_t symb_a, symb_t symb_b);
      alpha_t alpha_a, alpha_b, alpha_sum;
      
      alpha_a = symb_to_alpha(symb_a);
      alpha_b = symb_to_alpha(symb_b);
      alpha_sum = (alpha_a + alpha_b) % (SYMB_NUM-1);
      if((symb_a == 0) || (symb_b == 0))
	gf_mult = 0;
      else
	gf_mult = alpha_to_symb(alpha_sum);
   endfunction // gf_mult   
   
   //////////////////////////////////////   
   // gf_mult_power is used in syndrome calculation
   //////////////////////////////////////

   function symb_t gf_mult_power(symb_t symb_a, symb_t symb_x, alpha_t power_x);
      alpha_t alpha_a, alpha_x, alpha_sum, alpha_x_power;
      
      alpha_a = symb_to_alpha(symb_a);
      alpha_x = symb_to_alpha(symb_x);
      // TODO: check more efficient way of mult in GF
      alpha_x_power = (alpha_x * power_x) % (SYMB_NUM-1);
      alpha_sum = (alpha_a + alpha_x) % (SYMB_NUM-1);
      if((symb_a == 0) || (symb_x == 0))
	gf_mult_power = 0;
      else
	gf_mult_power = alpha_to_symb(alpha_sum);
   endfunction // gf_mult   

endpackage // gf_pkg
   
