module crc_parallel
  (
   input [31:0]  data,
   output [31:0] crc
   );
   
   assign crc[0] = data[0] ^ data[6] ^ data[9] ^ data[10] ^ data[12] ^ data[16] ^ data[24] ^ data[25] ^ data[26] ^ data[28] ^ data[29] ^ data[30] ^ data[31];
   assign crc[1] = data[0] ^ data[1] ^ data[6] ^ data[7] ^ data[9] ^ data[11] ^ data[12] ^ data[13] ^ data[16] ^ data[17] ^ data[24] ^ data[27] ^ data[28];
   assign crc[2] = data[0] ^ data[1] ^ data[2] ^ data[6] ^ data[7] ^ data[8] ^ data[9] ^ data[13] ^ data[14] ^ data[16] ^ data[17] ^ data[18] ^ data[24] ^ data[26] ^ data[30] ^ data[31];
   assign crc[3] = data[1] ^ data[2] ^ data[3] ^ data[7] ^ data[8] ^ data[9] ^ data[10] ^ data[14] ^ data[15] ^ data[17] ^ data[18] ^ data[19] ^ data[25] ^ data[27] ^ data[31];
   assign crc[4] = data[0] ^ data[2] ^ data[3] ^ data[4] ^ data[6] ^ data[8] ^ data[11] ^ data[12] ^ data[15] ^ data[18] ^ data[19] ^ data[20] ^ data[24] ^ data[25] ^ data[29] ^ data[30] ^ data[31];
   assign crc[5] = data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[5] ^ data[6] ^ data[7] ^ data[10] ^ data[13] ^ data[19] ^ data[20] ^ data[21] ^ data[24] ^ data[28] ^ data[29];
   assign crc[6] = data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ data[7] ^ data[8] ^ data[11] ^ data[14] ^ data[20] ^ data[21] ^ data[22] ^ data[25] ^ data[29] ^ data[30];
   assign crc[7] = data[0] ^ data[2] ^ data[3] ^ data[5] ^ data[7] ^ data[8] ^ data[10] ^ data[15] ^ data[16] ^ data[21] ^ data[22] ^ data[23] ^ data[24] ^ data[25] ^ data[28] ^ data[29];
   assign crc[8] = data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[8] ^ data[10] ^ data[11] ^ data[12] ^ data[17] ^ data[22] ^ data[23] ^ data[28] ^ data[31];
   assign crc[9] = data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[9] ^ data[11] ^ data[12] ^ data[13] ^ data[18] ^ data[23] ^ data[24] ^ data[29];
   assign crc[10] = data[0] ^ data[2] ^ data[3] ^ data[5] ^ data[9] ^ data[13] ^ data[14] ^ data[16] ^ data[19] ^ data[26] ^ data[28] ^ data[29] ^ data[31];
   assign crc[11] = data[0] ^ data[1] ^ data[3] ^ data[4] ^ data[9] ^ data[12] ^ data[14] ^ data[15] ^ data[16] ^ data[17] ^ data[20] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[31];
   assign crc[12] = data[0] ^ data[1] ^ data[2] ^ data[4] ^ data[5] ^ data[6] ^ data[9] ^ data[12] ^ data[13] ^ data[15] ^ data[17] ^ data[18] ^ data[21] ^ data[24] ^ data[27] ^ data[30] ^ data[31];
   assign crc[13] = data[1] ^ data[2] ^ data[3] ^ data[5] ^ data[6] ^ data[7] ^ data[10] ^ data[13] ^ data[14] ^ data[16] ^ data[18] ^ data[19] ^ data[22] ^ data[25] ^ data[28] ^ data[31];
   assign crc[14] = data[2] ^ data[3] ^ data[4] ^ data[6] ^ data[7] ^ data[8] ^ data[11] ^ data[14] ^ data[15] ^ data[17] ^ data[19] ^ data[20] ^ data[23] ^ data[26] ^ data[29];
   assign crc[15] = data[3] ^ data[4] ^ data[5] ^ data[7] ^ data[8] ^ data[9] ^ data[12] ^ data[15] ^ data[16] ^ data[18] ^ data[20] ^ data[21] ^ data[24] ^ data[27] ^ data[30];
   assign crc[16] = data[0] ^ data[4] ^ data[5] ^ data[8] ^ data[12] ^ data[13] ^ data[17] ^ data[19] ^ data[21] ^ data[22] ^ data[24] ^ data[26] ^ data[29] ^ data[30];
   assign crc[17] = data[1] ^ data[5] ^ data[6] ^ data[9] ^ data[13] ^ data[14] ^ data[18] ^ data[20] ^ data[22] ^ data[23] ^ data[25] ^ data[27] ^ data[30] ^ data[31];
   assign crc[18] = data[2] ^ data[6] ^ data[7] ^ data[10] ^ data[14] ^ data[15] ^ data[19] ^ data[21] ^ data[23] ^ data[24] ^ data[26] ^ data[28] ^ data[31];
   assign crc[19] = data[3] ^ data[7] ^ data[8] ^ data[11] ^ data[15] ^ data[16] ^ data[20] ^ data[22] ^ data[24] ^ data[25] ^ data[27] ^ data[29];
   assign crc[20] = data[4] ^ data[8] ^ data[9] ^ data[12] ^ data[16] ^ data[17] ^ data[21] ^ data[23] ^ data[25] ^ data[26] ^ data[28] ^ data[30];
   assign crc[21] = data[5] ^ data[9] ^ data[10] ^ data[13] ^ data[17] ^ data[18] ^ data[22] ^ data[24] ^ data[26] ^ data[27] ^ data[29] ^ data[31];
   assign crc[22] = data[0] ^ data[9] ^ data[11] ^ data[12] ^ data[14] ^ data[16] ^ data[18] ^ data[19] ^ data[23] ^ data[24] ^ data[26] ^ data[27] ^ data[29] ^ data[31];
   assign crc[23] = data[0] ^ data[1] ^ data[6] ^ data[9] ^ data[13] ^ data[15] ^ data[16] ^ data[17] ^ data[19] ^ data[20] ^ data[26] ^ data[27] ^ data[29] ^ data[31];
   assign crc[24] = data[1] ^ data[2] ^ data[7] ^ data[10] ^ data[14] ^ data[16] ^ data[17] ^ data[18] ^ data[20] ^ data[21] ^ data[27] ^ data[28] ^ data[30];
   assign crc[25] = data[2] ^ data[3] ^ data[8] ^ data[11] ^ data[15] ^ data[17] ^ data[18] ^ data[19] ^ data[21] ^ data[22] ^ data[28] ^ data[29] ^ data[31];
   assign crc[26] = data[0] ^ data[3] ^ data[4] ^ data[6] ^ data[10] ^ data[18] ^ data[19] ^ data[20] ^ data[22] ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[28] ^ data[31];
   assign crc[27] = data[1] ^ data[4] ^ data[5] ^ data[7] ^ data[11] ^ data[19] ^ data[20] ^ data[21] ^ data[23] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[29];
   assign crc[28] = data[2] ^ data[5] ^ data[6] ^ data[8] ^ data[12] ^ data[20] ^ data[21] ^ data[22] ^ data[24] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[30];
   assign crc[29] = data[3] ^ data[6] ^ data[7] ^ data[9] ^ data[13] ^ data[21] ^ data[22] ^ data[23] ^ data[25] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[31];
   assign crc[30] = data[4] ^ data[7] ^ data[8] ^ data[10] ^ data[14] ^ data[22] ^ data[23] ^ data[24] ^ data[26] ^ data[27] ^ data[28] ^ data[29] ^ data[30];
   assign crc[31] = data[5] ^ data[8] ^ data[9] ^ data[11] ^ data[15] ^ data[23] ^ data[24] ^ data[25] ^ data[27] ^ data[28] ^ data[29] ^ data[30] ^ data[31];
   
endmodule // crc_parallel
