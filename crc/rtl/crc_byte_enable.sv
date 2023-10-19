///////////////////////////////////////////////
// Design supposed that MSB byte goes first.
///////////////////////////////////////////////

module crc_byte_enable
  #(
    parameter BYTES_NUM = 4,
    parameter CRC_DEGREE = 32
    )
   (
    input [BYTES_NUM-1:0][7:0] data_in,
    input [BYTES_NUM-1:0]      byte_vld,
    input 		       data_vld,
    input 		       last_word,
    input 		       clk,
    input 		       resetn,
    output [CRC_DEGREE-1:0]    crc
    );

   // TODO: check if it's divisible by 8
   localparam CRC_BYTES_NUM = CRC_DEGREE / 8;
   
   logic [CRC_DEGREE-1:0]  crc_q;
   
   wire [CRC_DEGREE-1:0]   crc_out[BYTES_NUM-1:0];
   wire [CRC_DEGREE-1:0]   crc_xor;
   
   /////////////////////////////////////////////
   // Input stage:
   // 1. XOR input data and previouse CRC
   // 2. Find FFS for bytes_valid that will
   // be used in all kinds of data muxers
   // 3. Shift previouse crc values and mux in
   // depends on bytes_valid
   /////////////////////////////////////////////
   logic [BYTES_NUM-1:0][7:0] data_xor_prev;   

   logic [CRC_DEGREE-1:0] prev_crc_q;
   logic [CRC_DEGREE-1:0] prev_crc_shift[BYTES_NUM-2:0];
   wire [CRC_DEGREE-1:0]  prev_crc_shift_mux;
   
   // TODO: what if data greater then 32, how we need to xor data and prev_crc   
   always_comb begin
      data_xor_prev = data_in ^ prev_crc_q;
      foreach(prev_crc_shift[i])
	prev_crc_shift[i] = prev_crc_q << (BYTES_NUM-1-i)*8;
   end
   
   wire [BYTES_NUM-1:0] base = {{BYTES_NUM-1{1'b0}}, 1'b1};
   wire [BYTES_NUM-1:0] byte_vld_prio;
   
   lib_ffs 
     #(
       .WIDTH(BYTES_NUM)
       )
   lib_ffs_inst
     (
      .vect_i(byte_vld),
      .base_i(base),
      .vect_o(byte_vld_prio)
      );
   
   lib_mux_one_hot
     #(
       .PORTS_NUMBER(BYTES_NUM-1),
       .WIDTH(CRC_DEGREE)
       )
   prev_crc_shift_mux_inst
     (
      .data_i(prev_crc_shift),
      .sel_i(byte_vld_prio[BYTES_NUM-1:1]),
      .data_o(prev_crc_shift_mux)
      );
     
   /////////////////////////////////////////////
   // Shift data_xor_prev
   /////////////////////////////////////////////

   logic [BYTES_NUM-1:0][7:0] data_xor_prev_shift[BYTES_NUM-1:0];
   wire [BYTES_NUM-1:0][7:0] mux_out;
   always_comb begin
      foreach(data_xor_prev_shift[i])
	data_xor_prev_shift[i] = data_xor_prev >> i*8;
   end   
   
   lib_mux_one_hot
     #(
       .PORTS_NUMBER(BYTES_NUM),
       .WIDTH(BYTES_NUM*8)
       )
   lib_mux_one_hot
     (
      .data_i(data_xor_prev_shift),
      .sel_i(byte_vld_prio),
      .data_o(mux_out)
      );
   
   /////////////////////////////////////////////
   // CRC generator
   /////////////////////////////////////////////
   
   logic [CRC_BYTES_NUM-1:0][7:0] crc_in [BYTES_NUM-1:0];
   
   always_comb begin
      for(int crc_indx = 0; crc_indx < BYTES_NUM; ++crc_indx) begin
	 for(int byte_indx = 0; byte_indx < BYTES_NUM; ++byte_indx) begin
	    if(byte_indx == crc_indx)
	      crc_in[crc_indx][byte_indx] = mux_out[crc_indx];
	    else
	      crc_in[crc_indx][byte_indx] = '0;	    
	 end
      end
   end

   for(genvar i = 0; i < BYTES_NUM; ++i) begin : CRC
      
      crc_parallel crc_parallel_inst
		  (
		   .data(crc_in[i]),
		   .crc(crc_out[i])
		   );
   end
   
   
   /////////////////////////////////////////////
   // Output XOR
   // 1. XOR all outputs from CRC generators
   // 2. XOR shifted previouse CRC with CRC output XOR	 
   /////////////////////////////////////////////

   // intermediate XOR
   logic [CRC_DEGREE-1:0] crc_out_xor_intr[BYTES_NUM-1:1];
   logic [CRC_DEGREE-1:0] crc_final_xor;
   
   always_comb begin
      for(int i = 1; i < BYTES_NUM; ++i) begin
	 if(i == 1)
	   crc_out_xor_intr[i] = crc_out[i] ^ crc_out[i-1];
	 else
	   crc_out_xor_intr[i] = crc_out[i] ^ crc_out_xor_intr[i-1];
      end
   end

   assign crc_final_xor = crc_out_xor_intr[BYTES_NUM-1] ^ prev_crc_shift_mux;
   assign crc = crc_final_xor;
   
   /////////////////////////////////////////////
   // CRC register
   /////////////////////////////////////////////   
   
   always_ff @(posedge clk, negedge resetn) begin
      if(~resetn)
	prev_crc_q <= 32'h0;
      else begin
	 if(data_vld) begin
	    if(last_word)
	      prev_crc_q <= '0;
	    else
	      prev_crc_q <= crc_final_xor;
	 end	   
      end
   end // always_ff @ (posedge clk, negedge resetn)
   
endmodule // crc_byte_enable

