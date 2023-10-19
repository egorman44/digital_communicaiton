module crc_byte_enable_tb();

   localparam CLK_PERIOD = 1000/100;
   localparam CRC_DEGREE = 32;
   localparam BYTES_NUM = 4;
   
   /*AUTOREGINPUT*/
   // Beginning of automatic reg inputs (for undeclared instantiated-module inputs)
   logic [BYTES_NUM-1:0] byte_vld;		// To DUT of crc_byte_enable.v
   logic		clk;			// To DUT of crc_byte_enable.v
   logic [BYTES_NUM-1:0] [7:0] data_in;		// To DUT of crc_byte_enable.v
   logic		data_vld;		// To DUT of crc_byte_enable.v
   logic		last_word;		// To DUT of crc_byte_enable.v
   logic		resetn;			// To DUT of crc_byte_enable.v
   // End of automatics
   /*AUTOLOGIC*/
   // Beginning of automatic wires (for undeclared instantiated-module outputs)
   logic [CRC_DEGREE-1:0] crc;			// From DUT of crc_byte_enable.v
   // End of automatics
   
   initial begin
      clk <= 1'b0;
      #($urandom_range(50,100));
      forever
	#(CLK_PERIOD/2) clk = ~clk;
   end

   initial begin
      resetn = 1'b0;
      #10;
      resetn = 1'b1;
   end

   initial begin
      $shm_open("test.shm");
      $shm_probe("AMC");

      data_vld <= 0;
      repeat(3)
	@(posedge clk);
      
      data_in <= 32'h01234_567;
      data_vld <= 1;
      byte_vld <= 4'b1111;
      
      @(posedge clk);
      data_in <= 32'h89AB_CDEF;
      data_vld <= 1;
      byte_vld <= 4'b1110;
      last_word <= 1;

      @(posedge clk);
      data_vld <= 0;
      
      repeat(5)
	@(posedge clk);
      $finish;
   end
   
   crc_byte_enable DUT(/*AUTOINST*/
		       // Outputs
		       .crc		(crc[CRC_DEGREE-1:0]),
		       // Inputs
		       .data_in		(data_in/*[BYTES_NUM-1:0][7:0]*/),
		       .byte_vld	(byte_vld[BYTES_NUM-1:0]),
		       .data_vld	(data_vld),
		       .last_word	(last_word),
		       .clk		(clk),
		       .resetn		(resetn));
   
endmodule // crc_byte_enable_tb
