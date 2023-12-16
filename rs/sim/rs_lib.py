from rs import rs_encode_msg
from rs import rs_calc_syndromes
from rs import rs_find_error_locator

from coco_env.scoreboard import Predictor
from coco_env.packet import Packet

class RsPacket(Packet):
    
    def __init__(self, roots_num, word_size = 1, corrupt_words_num = 0):
        super().__init__(word_size)
        self.roots_num = roots_num
        self.corrupt_words_num = corrupt_words_num
    
    def gen_data(self, pattern, ref_data = None):
        # Generate origin message
        super().gen_data(pattern, ref_data)
        self.rs_gen_data()
    
    def rs_gen_data(self):
        msg = self.get_byte_list()
        enc_msg = rs_encode_msg(msg, self.roots_num)
        self.print_pkt("ENC_MSG")
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
        #super().rs_gen_data()
        enc_msg = self.get_byte_list()
        syndrome = rs_calc_syndromes(enc_msg, self.roots_num)
        error_locator = rs_find_error_locator(syndrome, self.roots_num)
        print(f"error_locator {error_locator}")
        
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
        t_len = int(self.roots_num/2) + 1
        for pkt in self.port_in:
            syndrome = rs_calc_syndromes(pkt.get_byte_list(), self.roots_num)
            err_locator = rs_find_error_locator(syndrome, self.roots_num)
            print(f"err_locator = {err_locator}")
            err_locator.reverse()
            print(f"err_locator = {err_locator}")
            if(len(err_locator) < t_len):
               zeros = [0] * (t_len - len(err_locator))
               err_locator = err_locator + zeros
               print(f"err_locator = {err_locator}")
            syndr_pkt = Packet(t_len)
            syndr_pkt.pkt_size = t_len
            syndr_pkt.write_byte_list(err_locator)
            syndr_pkt.print_pkt(self.name)
            self.port_prd.append(syndr_pkt)
