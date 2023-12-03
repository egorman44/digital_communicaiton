from rs import rs_encode_msg
from coco_env.packet import Packet

class RsPacket(Packet):

    def __init__(self, roots_num, word_size = 1):
        super().__init__(word_size)
        self.roots_num = roots_num
        
    def gen_data(self, pattern):
        super().gen_data(pattern)
        self.print_pkt()
        msg = self.get_byte_list()
        enc_msg = rs_encode_msg(msg, self.roots_num)
        self.write_byte_list(enc_msg)
        self.print_pkt()
        
