def get_path(module_path):
    if module_path not in os.environ:
        print(f"[ERROR] {module_path} env var is not set.")
    else:
        return os.getenv(module_path)

import os
import sys
from pathlib import Path
# Set environment to load modules we need
dig_com_path = get_path('DIGITAL_COMMUNICAITON')
coco_path = get_path('COCO_PATH')

sys.path.append(dig_com_path + "/rs/python")
sys.path.append(dig_com_path + "/rs/sim")
sys.path.append(coco_path)

# Import COCOTB
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.runner import get_runner
from cocotb.triggers import Timer

import random

from rs import gf_pow
from rs import init_tables
from rs import rs_calc_syndromes

# Load modules we need
from coco_env.packet import Packet
from coco_env.scoreboard import Comparator
from coco_env.stimulus import reset_dut
from coco_env.stimulus import custom_clock
from coco_axis.axis import AxisDriver
from coco_axis.axis import AxisResponder
from coco_axis.axis import AxisMonitor
from coco_axis.axis import AxisIf

from rs_lib import RsPacket
from rs_lib import SyndrPredictor
from rs_lib import RsSyndromePacket
from rs_lib import RsErrLocatorPacket
from rs_lib import ErrLocatorPredictor

# Parameters
SYMB_WIDTH = 8
BUS_WIDTH_IN_SYMB = 4

if(SYMB_WIDTH == 8):
    POLY = 285
    N_LEN = 255
    K_LEN = 239
elif(SYMB_WIDTH == 7):
    POLY = 137
elif(SYMB_WIDTH == 6):
    POLY = 67
elif(SYMB_WIDTH == 5):
    POLY = 37
elif(SYMB_WIDTH == 4):
    POLY = 19
elif(SYMB_WIDTH == 3):
    POLY = 11
elif(SYMB_WIDTH == 2):
    POLY = 7

ROOTS_NUM = N_LEN-K_LEN
T_LEN = ROOTS_NUM/2

@cocotb.test()
async def rs_syndrome_test(dut):
    #random.seed(10)
    init_tables()

    # System signals
    aclk    = dut.aclk
    aresetn = dut.aresetn

    # Connect AXIS interdace
    s_if = AxisIf(aclk=aclk,
                  tdata=dut.syndrome,
                  tvalid=dut.syndrome_vld,
                  tlast=dut.syndrome_vld,
                  width=ROOTS_NUM)

    m_if = AxisIf(aclk=aclk,
                  tdata=dut.error_locator_out,
                  tvalid=dut.error_locator_vld,
                  tlast=dut.error_locator_vld,
                  width=T_LEN+1)

    # Create TB components:
    pkt_comp  = Comparator('BM comparator')
    s_drv     = AxisDriver('s_drv', s_if, ROOTS_NUM, 1)
    port_in = []
    predictor = ErrLocatorPredictor('err_loc_prd', pkt_comp.port_prd, ROOTS_NUM)
    s_mon     = AxisMonitor('s_mon', s_if, port_in, ROOTS_NUM, 0, 1)
    m_mon     = AxisMonitor('m_mon', m_if, pkt_comp.port_out, T_LEN+1, 0, 1)
    

    # Generate
    # reference message:
    corrupt_words_num = random.randint(1,T_LEN)
    ref_msg = RsPacket(roots_num=ROOTS_NUM, word_size=BUS_WIDTH_IN_SYMB, corrupt_words_num=corrupt_words_num)
    ref_msg.generate(K_LEN, 1)
    ref_msg.print_pkt("ENC_MSG_CORRUPT")

    # 
    predictor.port_in.append(ref_msg)
    
    pkt = RsSyndromePacket(roots_num=ROOTS_NUM, word_size=BUS_WIDTH_IN_SYMB)
    pkt.generate(ref_pkt=ref_msg)
    pkt.print_pkt("SYNDROME_PKT")

    err_loc_pkt = RsErrLocatorPacket(roots_num=ROOTS_NUM, word_size=BUS_WIDTH_IN_SYMB)
    err_loc_pkt.generate(ref_pkt=ref_msg)
    
    # START TEST
    await cocotb.start(reset_dut(aresetn,100))
    await Timer(50, units = "ns")

    await cocotb.start(custom_clock(aclk))
    await cocotb.start(s_mon.mon_if())
    await cocotb.start(m_mon.mon_if())
    
    await RisingEdge(aresetn)
    for i in range(10):
        await RisingEdge(aclk)
    await s_drv.send_pkt(pkt)
    
    for i in range (ROOTS_NUM*2):
        await RisingEdge(aclk)        

    predictor.predict()
    pkt_comp.compare()


def rs_bm_tb():
    
    test_module = "rs_bm_tb"
    hdl_toplevel = "rs_bm"
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")
    
    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    print(proj_path)
    # equivalent to setting the PYTHONPATH environment variable
    
    verilog_sources = []
    includes        = []
    f_file          = []

    verilog_sources.append(proj_path / "lib" / "lib_mux_onehot.sv")
    verilog_sources.append(proj_path / "lib" / "lib_ffs.sv")
    verilog_sources.append(proj_path / "lib" / "lib_mux_ffs.sv")
    verilog_sources.append(proj_path / "lib" / "lib_bin_to_vld.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "gf_pkg.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "rs_bm.sv")

    # Parameters    
    parameters = {}

    # Defines    
    defines = {}
    
    runner = get_runner(sim)
    build_args = [ '--trace' , '--trace-structs', '--trace-max-array', '512', '--trace-max-width', '512']

    runner.build(
        defines=defines,
        parameters=parameters,
        verilog_sources=verilog_sources,
        includes=includes,
        hdl_toplevel=hdl_toplevel,
        build_args=build_args,
        always=True,
    )
    
    runner.test(hdl_toplevel=hdl_toplevel,
                test_module=test_module,
                )



if __name__ == "__main__":
    rs_bm_tb()


