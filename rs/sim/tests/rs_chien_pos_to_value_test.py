from rs import init_tables
import random
import cocotb
from cocotb.triggers import RisingEdge
from cocotb.triggers import Timer

from rs_param import *
from rs_test import RsTest
from coco_axis.axis import AxisIf
from coco_axis.axis import AxisDriver
from coco_axis.axis import AxisResponder
from coco_axis.axis import AxisMonitor
from coco_axis.axis import AxisIf
from coco_env.scoreboard import Comparator

from coco_env.stimulus import reset_dut
from coco_env.stimulus import custom_clock
from coco_env.packet import Packet

from rs_lib import RsPacket
from rs_lib import RsErrBitPositionPacket
from rs_lib import RsErrPositionPacket
  
class RsChienPosToValBaseTest(RsTest):
    
    def __init__(self, dut, pkt_num = None):
        super().__init__(dut)
        self.dut = dut
        self.pkt_num = pkt_num
        self.ref_msgs = []
        self.pkts = []
        self.prd_pkts = []
        
    def set_if(self):

        # System signals
        self.aclk    = self.dut.aclk
        self.aresetn = self.dut.aresetn
        
        # Connect AXIS interdace
        self.s_if = AxisIf(aclk=self.aclk,
                           tdata=self.dut.error_bit_pos,
                           tvalid=self.dut.error_bit_pos_vld,
                           unpack=0,
                           width=ROOTS_PER_CYCLE__CHIEN_BYTES)
    
        self.m_if = AxisIf(aclk=self.aclk,
                           tdata=self.dut.error_positions,
                           tkeep=self.dut.error_positions_sel,
                           tvalid=self.dut.error_positions_vld,
                           tlast=self.dut.error_positions_vld,
                           unpack=1,
                           width=T_LEN)

    def build_env(self):
        self.pkt_comp  = Comparator('CHIEN comparator')
        self.s_drv     = AxisDriver(name='s_drv', axis_if=self.s_if)
        self.m_mon     = AxisMonitor(name='m_mon', axis_if=self.m_if, aport=self.pkt_comp.port_out)

    def gen_stimilus(self):
        init_tables()
        if self.pkt_num is None:
            self.pkt_num = random.randint(5,10)
        
    async def run(self):
        await cocotb.start(reset_dut(self.aresetn,200))
        await Timer(50, units = "ns")

        await cocotb.start(custom_clock(self.aclk, 10))
        await cocotb.start(self.m_mon.mon_if())

        await RisingEdge(self.aresetn)
        for i in range(10):
            await RisingEdge(self.aclk)
            
        for pkt in self.pkts:
            await self.s_drv.send_pkt(pkt)
            for i in range (ROOTS_NUM*2):
                await RisingEdge(self.aclk)        

        for i in range(10):
            await RisingEdge(self.aclk)
        
    def post_run(self):
        for prd_pkt in self.prd_pkts:            
            self.pkt_comp.port_prd.append(prd_pkt)
        self.pkt_comp.compare()
    
class  RsChienPosToValRandomTest(RsChienPosToValBaseTest):

    def gen_stimilus(self):
        super().gen_stimilus()        
        #corrupts = random.randint(1, T_LEN)
        corrupts = 2
        
        for i in range(self.pkt_num):            
            ref_msg = Packet(name=f'ref_msg{i}')
            ref_msg.generate(K_LEN)
            
            enc_msg = RsPacket(name=f'enc_msg{i}', n_len=N_LEN, roots_num=ROOTS_NUM, corrupts=0)
            enc_msg.generate(ref_pkt=ref_msg)
            print(f"[DBG] COR_MSG_GEN {i}")
            cor_msg = RsPacket(name=f'cor_msg{i}', n_len=N_LEN, roots_num=ROOTS_NUM, corrupts=corrupts)
            cor_msg.generate(ref_pkt=ref_msg)

            print(f"[DBG] ERR_BIT_POS {i}")
            pkt = RsErrBitPositionPacket(name=f'err_bit_pos{i}', n_len=N_LEN, roots_num=ROOTS_NUM)
            pkt.generate(ref_pkt=cor_msg)

            print(f"[DBG] ERR_POS {i}")            
            err_pos_pkt = RsErrPositionPacket(name=f'err_pos{i}', n_len=N_LEN, roots_num=ROOTS_NUM)
            err_pos_pkt.generate(ref_pkt=cor_msg)
            err_pos_pkt.print_pkt()

            self.ref_msgs.append(ref_msg)
            self.pkts.append(pkt)
            self.prd_pkts.append(err_pos_pkt)


class  RsChienPosToValAllPosTest(RsChienPosToValBaseTest):

    def gen_stimilus(self):
        super().gen_stimilus()        
        corrupts = 1
        for i in range(T_LEN):            
            ref_msg = Packet(name=f'ref_msg{i}')
            ref_msg.generate(K_LEN)
        
            enc_msg = RsPacket(name=f'enc_msg{i}', n_len=N_LEN, roots_num=ROOTS_NUM, corrupts=0)
            enc_msg.generate(ref_pkt=ref_msg)
            
            cor_msg = RsPacket(name=f'cor_msg{i}', n_len=N_LEN, roots_num=ROOTS_NUM, corrupts=corrupts)
            cor_msg.generate(ref_pkt=ref_msg)
        
            pkt = RsErrBitPositionPacket(name=f'err_bit_pos{i}', n_len=N_LEN, roots_num=ROOTS_NUM)
            pkt.generate(ref_pkt=cor_msg)
        
            err_pos_pkt = RsErrPositionPacket(name=f'err_pos{i}', n_len=N_LEN, roots_num=ROOTS_NUM)
            err_pos_pkt.generate(ref_pkt=cor_msg)
            err_pos_pkt.print_pkt()

            corrupts = (corrupts + 1) % (T_LEN+1)
            self.ref_msgs.append(ref_msg)
            self.pkts.append(pkt)
            self.prd_pkts.append(err_pos_pkt)

class  RsChienPosToValCorruptInRawTest(RsChienPosToValBaseTest):

    def gen_stimilus(self):
        super().gen_stimilus()        
        for i in range(self.pkt_num):
            corrupts = []
            corrupts_pos = random.randint(0,ROOTS_PER_CYCLE__CHIEN-1)
            for i in range(T_LEN-1):
                corrupts.append(corrupts_pos)
                corrupts_pos += 1
            print(f"test_corrupts = {corrupts}")
            ref_msg = Packet(name=f'ref_msg{i}')
            ref_msg.generate(K_LEN)
        
            enc_msg = RsPacket(name=f'enc_msg{i}', n_len=N_LEN, roots_num=ROOTS_NUM, corrupts=0)
            enc_msg.generate(ref_pkt=ref_msg)
            
            cor_msg = RsPacket(name=f'cor_msg{i}', n_len=N_LEN, roots_num=ROOTS_NUM, corrupts=corrupts)
            cor_msg.generate(ref_pkt=ref_msg)
        
            pkt = RsErrBitPositionPacket(name=f'err_bit_pos{i}', n_len=N_LEN, roots_num=ROOTS_NUM)
            pkt.generate(ref_pkt=cor_msg)
        
            err_pos_pkt = RsErrPositionPacket(name=f'err_pos{i}', n_len=N_LEN, roots_num=ROOTS_NUM)
            err_pos_pkt.generate(ref_pkt=cor_msg)
            err_pos_pkt.print_pkt()

            self.ref_msgs.append(ref_msg)
            self.pkts.append(pkt)
            self.prd_pkts.append(err_pos_pkt)

            
