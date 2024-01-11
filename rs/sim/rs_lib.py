import math
from rs import rs_encode_msg
from rs import rs_calc_syndromes
from rs import rs_find_error_locator
from rs import rs_find_errors
from rs import rs_correct_errata
from rs import rs_correct_msg_nofsynd

from coco_env.scoreboard import Predictor
from coco_env.packet import Packet

class RsPacket(Packet):
    
    def __init__(self, name, n_len, roots_num, word_size = 1, corrupt_words_num = 0, gen = 285):
        super().__init__(name,word_size)
        self.n_len = n_len
        self.roots_num = roots_num
        self.corrupt_words_num = corrupt_words_num
        self.gen = gen
    
    def gen_data(self, pattern, ref_data = None):
        # Generate origin message
        super().gen_data(pattern, ref_data)
        self.rs_gen_data()
        
    def rs_gen_data(self):
        msg = self.get_byte_list()
        enc_msg = rs_encode_msg(msg_in=msg, nsym=self.roots_num)
        self.write_byte_list(enc_msg)
        if self.corrupt_words_num != 0:
            self.corrupt_pkt(self.corrupt_words_num)
        
class RsSyndromePacket(RsPacket):
    
    def rs_gen_data(self):
        #super().rs_gen_data()        
        enc_msg = self.get_byte_list()
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        syndrome.pop(0)
        syndrome.reverse()
        self.pkt_size = self.roots_num
        self.word_size = self.roots_num
        self.write_byte_list(syndrome)

class RsErrLocatorPacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.get_byte_list()
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        error_locator.reverse()
        if(len(error_locator) < t_len):
               zeros = [0] * (t_len - len(error_locator))
               error_locator = error_locator + zeros
        self.pkt_size = t_len
        self.word_size = t_len
        self.write_byte_list(error_locator)

class RsErrPositionPacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.get_byte_list()
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        error_locator = error_locator[::-1]
        error_position = rs_find_errors(error_locator,len(enc_msg))
        print(f"{self.name}.syndrome = {syndrome}")
        print(f"{self.name}.error_position = {error_position}")
        #if(len(error_position) < t_len):
        #       zeros = [0] * (t_len - len(error_locator))
        #       error_position = error_locator + zeros
        self.pkt_size = len(error_position)
        self.word_size = t_len
        self.write_byte_list(error_position)

class RsErrValuePacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.get_byte_list()        
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        print(f"{self.name}.syndrome = {syndrome}")
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        error_locator = error_locator[::-1]
        error_position = rs_find_errors(error_locator,len(enc_msg))
        print(f"{self.name}.syndrome = {syndrome}")
        print(f"{self.name}.error_position = {error_position}")
        _, magnitude = rs_correct_errata(enc_msg, syndrome, error_position)
        print(f"{self.name}.magnitude = {magnitude}, {self.roots_num}")
        self.pkt_size = len(magnitude)
        self.word_size = t_len
        self.write_byte_list(magnitude)        
        self.print_pkt("RsErrValuePacket")
                
class RsDecodedPacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.get_byte_list()        
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        print(f"{self.name}.syndrome = {syndrome}")
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        error_locator = error_locator[::-1]
        error_position = rs_find_errors(error_locator,len(enc_msg))
        print(f"{self.name}.syndrome = {syndrome}")
        print(f"{self.name}.error_position = {error_position}")
        out_msg, magnitude = rs_correct_errata(enc_msg, syndrome, error_position)
        out_msg = out_msg[:-self.roots_num]
        
        self.write_byte_list(out_msg)
        self.pkt_size = len(out_msg)
        
'''
   *** PREDICTORS ***
'''

class SyndrPredictor(Predictor):    

    def __init__(self, name, port_prd, roots_num):
        super().__init__(name, port_prd)
        self.roots_num = roots_num
        
    def predict(self):
        for pkt in self.port_in:
            syndrome = rs_calc_syndromes(pkt.get_byte_list(), self.roots_num)
            syndrome.pop(0)
            syndrome.reverse()
            syndr_pkt = Packet(self.roots_num)
            syndr_pkt.pkt_size = self.roots_num
            syndr_pkt.write_byte_list(syndrome)
            syndr_pkt.print_pkt(self.name)
            self.port_prd.append(syndr_pkt)

class ErrLocatorPredictor(Predictor):    

    def __init__(self, name, port_prd, roots_num):
        super().__init__(name, port_prd)
        self.roots_num = roots_num
        
    def predict(self):
        t_len = math.floor(self.roots_num/2) + 1
        for pkt in self.port_in:
            syndrome = rs_calc_syndromes(pkt.get_byte_list(), self.roots_num)
            error_locator = rs_find_error_locator(syndrome, self.roots_num)
            error_locator.reverse()
            if(len(error_locator) < t_len):
               zeros = [0] * (t_len - len(error_locator))
               error_locator = error_locator + zeros
            syndr_pkt = Packet(t_len)
            syndr_pkt.pkt_size = t_len
            syndr_pkt.write_byte_list(error_locator)
            syndr_pkt.print_pkt(self.name)
            self.port_prd.append(syndr_pkt)

class ErrPositionPredictor(Predictor):    

    def __init__(self, name, port_prd, roots_num, n_len):
        super().__init__(name, port_prd)
        self.roots_num = roots_num
        self.n_len = n_len
        
    def predict(self):
        t_len = math.floor(self.roots_num/2) + 1
        for pkt in self.port_in:
            syndrome = rs_calc_syndromes(pkt.get_byte_list(), self.roots_num)
            error_locator = rs_find_error_locator(syndrome, self.roots_num)
            error_position_l = rs_find_errors(error_locator,self.n_len)
            error_position = 0
            xor_vector = (2 ** self.n_len)-1
            for bit_pos in error_position_l:
                error_position = error_position ^ (1 << bit_pos)            
            error_position_bin = [error_position ^ xor_vector]
            err_pos_pkt = RsErrPosPacket(self.roots_num)
            err_pos_pkt.pkt_size = self.n_len
            err_pos_pkt.write_byte_list(error_position_bin)
            err_pos_pkt.print_pkt()
            self.port_prd.append(err_pos_pkt)

class ErrValuePredictor(Predictor):    

    def __init__(self, name, port_prd, roots_num, n_len):
        super().__init__(name, port_prd)
        self.roots_num = roots_num
        self.err_val_num = math.floor(roots_num/2)
        print(f"TYPE = {self.err_val_num}")
        self.n_len = n_len
        
    def predict(self):
        t_len = math.floor(self.roots_num/2) + 1
        for pkt in self.port_in:
            pkt.print_pkt("PREDICTOR")
            err_val_pkt = RsErrValuePacket(name=self.name,
                                           n_len=self.n_len,
                                           roots_num=self.roots_num,
                                           word_size = pkt.word_size)
            err_val_pkt.generate(ref_pkt=pkt)
            err_val_pkt.print_pkt("PREDICTOR")
            self.port_prd.append(err_val_pkt)


            
