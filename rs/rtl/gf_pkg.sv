package gf_pkg;

`ifndef SYMB_WIDTH
 `define SYMB_WIDTH 8
 `define POLY 285
`endif

`ifndef K_LEN
 `define K_LEN 239
`endif
`ifndef N_LEN
 `define N_LEN 255
`endif

`ifndef BUS_WIDTH_IN_SYMB
 `define BUS_WIDTH_IN_SYMB 4
`endif

`ifndef ROOTS_PER_CYCLE__CHIEN
   // TODO: What is the ROOTS_PER_CYCLE__CHIEN 
 //`define ROOTS_PER_CYCLE__CHIEN (2 ** SYMB_WIDTH)-2
 `define ROOTS_PER_CYCLE__CHIEN 16
`endif

   //////////////////////////////////////
   // Reed Solomon parameters
   //////////////////////////////////////
   
   parameter N_LEN	= `N_LEN;
   parameter K_LEN	= `K_LEN;
   parameter ROOTS_NUM  = N_LEN-K_LEN;
   parameter T_LEN	= ROOTS_NUM / 2;
   
   parameter SYMB_WIDTH = `SYMB_WIDTH;
   parameter POLY	= `POLY;
   parameter SYMB_NUM	= 2 ** SYMB_WIDTH;
   parameter FIELD_CHARAC = SYMB_NUM - 1;
   parameter BUS_WIDTH_IN_SYMB = `BUS_WIDTH_IN_SYMB;
   parameter [SYMB_WIDTH-1:0] FIRST_ROOT = 1;
   parameter LEN_WIDTH = $clog2(T_LEN+1);

   //////////////////////////////////////
   // Parameterized Chien search
   //
   // NON_VALID__CHIEN - shows which bits of error position vector is not valid.
   // FF_STEP__CHIEN - set value N to insert register after N number of stages.
   // FF_STEP__CHIEN_BIT_CONV
   //////////////////////////////////////
   
   parameter ROOTS_PER_CYCLE__CHIEN = `ROOTS_PER_CYCLE__CHIEN;
   parameter ROOTS_NUM__CHIEN = SYMB_NUM - 2;
   parameter NON_VALID__CHIEN = ROOTS_NUM__CHIEN % ROOTS_PER_CYCLE__CHIEN; 
   parameter CYCLES_NUM__CHIEN = (NON_VALID__CHIEN != 0) ? ((ROOTS_NUM__CHIEN / ROOTS_PER_CYCLE__CHIEN) + 1) : (ROOTS_NUM__CHIEN/ROOTS_PER_CYCLE__CHIEN);   
   parameter CNTR_WIDTH__CHIEN = $clog2(CYCLES_NUM__CHIEN);
   
   parameter FF_STEP__CHIEN_POLY_EVAL = 1;
   parameter FF_NUM__CHIEN_POLY_EVAL = (T_LEN/FF_STEP__CHIEN_POLY_EVAL)-1;
   parameter FF_STEP__CHIEN_BIT_CONV = T_LEN / 3;
   parameter FF_NUM__CHIEN_BIT_CONV = (T_LEN/FF_STEP__CHIEN_BIT_CONV)-1;
   
   //////////////////////////////////////
   // Typedefs
   //////////////////////////////////////
   
   typedef logic [SYMB_WIDTH-1:0] alpha_to_symb_t [SYMB_NUM-1:0];
   typedef logic [SYMB_WIDTH-1:0] all_alpha_t [SYMB_NUM-2:0];
   
   typedef logic [SYMB_WIDTH-1:0] alpha_t;
   typedef logic [SYMB_WIDTH-1:0] symb_t;
   typedef logic [SYMB_WIDTH-1:0] poly_t [T_LEN:0];
   
   // The size should be ROOTS_NUM+1 to use in BM 
   typedef poly_t poly_array_t [ROOTS_NUM:0];
   typedef poly_t poly_array_q_t [ROOTS_NUM:1];
      
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
	      gen_alpha_to_symb[i] = (gen_alpha_to_symb[i-1] << 1) ^ POLY[SYMB_WIDTH-1:0];
	    else
	      gen_alpha_to_symb[i] = (gen_alpha_to_symb[i-1] << 1);
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
      alpha_sum = (alpha_a + alpha_b) % FIELD_CHARAC;
      if((symb_a == 0) || (symb_b == 0))
	gf_mult = 0;
      else
	gf_mult = alpha_to_symb(alpha_sum);
   endfunction // gf_mult   

   //////////////////////////////////////   
   // gf_div
   //
   //////////////////////////////////////

   function symb_t gf_div(symb_t dividend, symb_t divider);
      // Check that divider != 0 outside the function
      alpha_t alpha_dividend, alpha_divider, alpha_diff, alpha_diff_test;
      alpha_dividend = symb_to_alpha(dividend);
      alpha_divider = symb_to_alpha(divider);
      alpha_diff = (alpha_dividend + FIELD_CHARAC - alpha_divider) % FIELD_CHARAC;
      if(dividend == 0)
	gf_div = 0;
      else
	gf_div = alpha_to_symb(alpha_diff);
   endfunction // gf_div
   
   //////////////////////////////////////   
   // gf_pow is used in syndrome calculation
   //////////////////////////////////////

   function all_alpha_t gen_pow_first_root();
      for(logic[SYMB_WIDTH-1:0] i = 0; i < N_LEN; ++i) begin
	 gen_pow_first_root[i] = (FIRST_ROOT * i) % FIELD_CHARAC;
      end
   endfunction // gf_pow

   function all_alpha_t gen_pow_first_root_min1();
      for(logic[SYMB_WIDTH-1:0] i = 0; i < N_LEN; ++i) begin
	 gen_pow_first_root_min1[i] = ((FIRST_ROOT-1) * i) % FIELD_CHARAC;
      end
   endfunction // gf_pow

   // TODO: check how this is synthesized in Vivado.   
   function all_alpha_t gen_pow_first_root_neg();
      for(logic[SYMB_WIDTH-1:0] i = 0; i < N_LEN; ++i) begin
	 gen_pow_first_root_neg[i] = FIRST_ROOT*(FIELD_CHARAC-i) % FIELD_CHARAC;
      end
   endfunction // gf_pow

   // TODO: Do we need to substitute it with LUT table?!
   function symb_t pow_first_root(symb_t power);
      all_alpha_t pow_first_root_tbl;
      pow_first_root_tbl	= gen_pow_first_root();
      pow_first_root		= alpha_to_symb(pow_first_root_tbl[power]);      
   endfunction // pow_first_root   

   function symb_t pow_first_root_neg(symb_t power);
      all_alpha_t pow_first_root_tbl;
      pow_first_root_tbl	= gen_pow_first_root_neg();
      pow_first_root_neg	= alpha_to_symb(pow_first_root_tbl[power]);
   endfunction // pow_first_root   

   function symb_t pow_first_root_min1(symb_t power);
      all_alpha_t pow_first_root_tbl;
      pow_first_root_tbl	= gen_pow_first_root_min1();
      pow_first_root_min1	= alpha_to_symb(pow_first_root_tbl[power]);
   endfunction // pow_first_root_min1
   
   //////////////////////////////////////
   // gf_mult_power is used in syndrome calculation
   //////////////////////////////////////

   function symb_t gf_mult_power(symb_t symb_a, symb_t root, alpha_t power_x);
      alpha_t alpha_a, alpha_x, alpha_sum, alpha_x_power;
      
      alpha_a = symb_to_alpha(symb_a);
      alpha_x = symb_to_alpha(root);
      // TODO: check more efficient way of mult in GF
      alpha_x_power = (alpha_x * power_x) % FIELD_CHARAC;
      alpha_sum = (alpha_a + alpha_x) % FIELD_CHARAC;
      if((symb_a == 0) || (root == 0))
	gf_mult_power = 0;
      else
	gf_mult_power = alpha_to_symb(alpha_sum);
   endfunction // gf_mult_power
      
   //////////////////////////////////////   
   // Inverse
   //////////////////////////////////////

   // TODO: Do we need to substitute it with LUT table?!
   function symb_t gf_inv(symb_t symb);
      alpha_t alpha_inv;
      alpha_inv = SYMB_NUM - 1 - symb_to_alpha(symb);
      gf_inv	= alpha_to_symb(alpha_inv);
   endfunction // gf_inv

   //////////////////////////////////////   
   //  gf_poly_eval function evaluates a polynomial at a particular value of x
   //////////////////////////////////////

   function symb_t gf_poly_eval(poly_t poly, symb_t symb);
      logic [SYMB_WIDTH-1:0] gf_mult_intrm[T_LEN-1:0];
      /* verilator lint_off UNOPTFLAT */
      logic [SYMB_WIDTH-1:0] xor_intrm[T_LEN-1:0];
      /* verilator lint_on UNOPTFLAT */
      for(int i = 0; i < T_LEN; ++i) begin
	 if(i == 0) begin
	    gf_mult_intrm[i]	= gf_mult(poly[T_LEN],symb);
	 end
	 else
	   gf_mult_intrm[i]	= gf_mult(xor_intrm[i-1], symb);
	 xor_intrm[i]		= gf_mult_intrm[i] ^ poly[T_LEN-1-i];
      end
      gf_poly_eval = xor_intrm[T_LEN-1];
   endfunction // gf_inv
   
   //////////////////////////////////////   
   // Poly arithmetic
   //////////////////////////////////////

   function poly_t gf_poly_mult(poly_t poly_a, poly_t poly_b);
      for(int i = 0; i < ROOTS_NUM; ++i)
	gf_poly_mult[i] = gf_mult(poly_a[i], poly_b[i]);
   endfunction // gf_poly_mult

   function poly_t gf_poly_mult_scalar(poly_t poly_a, symb_t symb);
      for(int i = 0; i < ROOTS_NUM; ++i)
	gf_poly_mult_scalar[i] = gf_mult(poly_a[i], symb);
   endfunction // gf_poly_mult_scalar
   
   function symb_t gf_poly_sum(poly_t poly_a);
      logic [SYMB_WIDTH-1:0] xor_intrm [ROOTS_NUM-1:1];
      for(int i = 1; i < ROOTS_NUM; ++i) begin
	 if(i == 1)
	   xor_intrm[i] = poly_a[1] ^ poly_a[0];
	 else
	   xor_intrm[i] = poly_a[i] ^ xor_intrm[i-1];
      end
      gf_poly_sum = xor_intrm[ROOTS_NUM-1];
   endfunction // gf_poly_sum
      
   function poly_t gf_poly_add(poly_t poly_a, poly_t poly_b);
      for(int i = 0; i < ROOTS_NUM; ++i)
	gf_poly_add[i] = poly_a[i] ^ poly_b[i];
   endfunction // gf_poly_add
   
   function poly_t gf_poly_mult_x(poly_t poly);
      for(int i = 0; i < ROOTS_NUM; ++i) begin
      	if(i == 0)
      	  gf_poly_mult_x[i] = '0;
      	else
      	  gf_poly_mult_x[i] = poly[i-1];
      end
   endfunction // gf_poly_mult_x

   function poly_t gf_poly_inv(poly_t poly_in);
      for(int i = 0; i < ROOTS_NUM; ++i)
	gf_poly_inv[i] = gf_inv(poly_in[i]);
   endfunction // gf_poly_inv

         
endpackage // gf_pkg
   
