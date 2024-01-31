import math
from rs import rs_encode_msg
from rs import rs_calc_syndromes
from rs import rs_find_error_locator
from rs import rs_find_errors
from rs import rs_correct_errata
from rs import rs_correct_msg_nofsynd
from rs_param import CHIEN_ROOTS_NUM

from coco_env.scoreboard import Predictor
from coco_env.packet import Packet

class RsPacket(Packet):
    
    def __init__(self, name, n_len, roots_num, corrupt_words_num = 0, gen = 285, symb_width=8):
        super().__init__(name)
        self.n_len = n_len
        self.roots_num = roots_num
        self.corrupt_words_num = corrupt_words_num
        self.gen = gen
        self.symb_width = symb_width
    
    def gen_data(self, pattern, ref_data = None):
        # Generate origin message
        super().gen_data(pattern, ref_data)
        self.rs_gen_data()
        
    def rs_gen_data(self):
        print(f"self.data = {self.data} len = {len(self.data)}")
        msg = self.data.copy()
        print("HERE0")
        enc_msg = rs_encode_msg(msg_in=msg, nsym=self.roots_num)
        print("HERE0")
        self.data = enc_msg.copy()
        if self.corrupt_words_num != 0:
            self.corrupt_pkt(self.corrupt_words_num)
        self.print_pkt()
        
class RsSyndromePacket(RsPacket):
    
    def rs_gen_data(self):
        #super().rs_gen_data()        
        enc_msg = self.data
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        syndrome.pop(0)
        syndrome.reverse()
        self.pkt_size = self.roots_num
        self.data = syndrome.copy()

class RsErrLocatorPacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.data
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        error_locator.reverse()
        if(len(error_locator) < t_len):
               zeros = [0] * (t_len - len(error_locator))
               error_locator = error_locator + zeros
        self.pkt_size = t_len
        self.data = error_locator.copy()

class RsErrPositionPacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.data
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        error_locator = error_locator[::-1]
        error_position = rs_find_errors(error_locator,len(enc_msg))
        #print(f"{self.name}.syndrome = {syndrome}")
        #print(f"{self.name}.error_locator = {error_locator}")
        #print(f"{self.name}.error_position = {error_position}")
        #print(f"{self.name}.t_len = t_len")
        self.pkt_size = len(error_position)
        self.data = error_position.copy()

class RsErrBitPositionPacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.data
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        error_locator = error_locator[::-1]
        error_position = rs_find_errors(err_loc=error_locator, nmess=len(enc_msg), convert=0)
        error_bit_position = 0
        for pos in error_position:
            error_bit_position |= 1 << pos        
        #print(f"{self.name}.syndrome = {syndrome}")
        #print(f"{self.name}.error_locator = {error_locator}")
        #print(f"{self.name}.error_position = {error_position}")
        print(f"{self.name}.error_bit_position = {error_bit_position:x}")
        self.pkt_size = math.ceil(CHIEN_ROOTS_NUM/8)
        print(f"pkt_sizeq = {self.pkt_size} {CHIEN_ROOTS_NUM}")
        self.write_number(error_bit_position, 2 ** self.symb_width - 2)
        self.print_pkt("WERE")
        
class RsErrValuePacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.data        
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
        self.data = magnitude.copy()
        self.print_pkt("RsErrValuePacket")
                
class RsDecodedPacket(RsPacket):
    
    def rs_gen_data(self):
        t_len = math.floor(self.roots_num/2) + 1
        #super().rs_gen_data()
        enc_msg = self.data        
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        print(f"{self.name}.syndrome = {syndrome}")
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        error_locator = error_locator[::-1]
        error_position = rs_find_errors(error_locator,len(enc_msg))
        print(f"{self.name}.syndrome = {syndrome}")
        print(f"{self.name}.error_position = {error_position}")
        out_msg, magnitude = rs_correct_errata(enc_msg, syndrome, error_position)
        out_msg = out_msg[:-self.roots_num]
        self.data = out_msg.copy()
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
            #syndr_pkt.write_byte_list(syndrome)
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
            #syndr_pkt.write_byte_list(error_locator)
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
            #err_pos_pkt.write_byte_list(error_position_bin)
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
            err_val_pkt = RsErrValuePacket(name=self.name,
                                           n_len=self.n_len,
                                           roots_num=self.roots_num)
            err_val_pkt.generate(ref_pkt=pkt)
            self.port_prd.append(err_val_pkt)


            
