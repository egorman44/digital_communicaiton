from rs import rs_encode_msg
from rs import rs_calc_syndromes

from coco_env.scoreboard import Predictor

from coco_env.packet import Packet

class RsPacket(Packet):

    def __init__(self, roots_num, word_size = 1):
        super().__init__(word_size)
        self.roots_num = roots_num
        
    def gen_data(self, pattern):
        super().gen_data(pattern)
        msg = self.get_byte_list()
        enc_msg = rs_encode_msg(msg, self.roots_num)
        self.write_byte_list(enc_msg)        


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
