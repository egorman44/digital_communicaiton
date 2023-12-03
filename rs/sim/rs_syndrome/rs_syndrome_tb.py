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

# Parameters
SYMB_WIDTH = 8
BUS_WIDTH_IN_SYMB = 4

if(SYMB_WIDTH == 8):
    POLY = 285
    N_LEN = 255
    K_LEN = 239
    ROOTS_NUM = N_LEN-K_LEN    
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


@cocotb.test()
async def rs_syndrome_test(dut):
    init_tables()

    root = []
    generator = 2
    fcr = 0
    for i in range(ROOTS_NUM):
        print(f"ROOT = {gf_pow(generator, i+fcr)}")
        dut.roots[i].value = gf_pow(generator, i+fcr)

    # System signals
    aclk = dut.aclk
    aresetn = dut.aresetn

    # Connect AXIS interdace

    s_if = AxisIf(aclk=aclk,
                  tdata=dut.s_tdata,
                  tvalid=dut.s_tvalid,
                  tlast=dut.s_tlast,
                  tkeep=dut.s_tkeep,
                  width=BUS_WIDTH_IN_SYMB)
    
    # Create TB components:
    pkt_comp = Comparator('ENCODER comparator')
    s_drv    = AxisDriver('s_drv', s_if)
    
    s_q = []
    s_mon    = AxisMonitor('s_mon', s_if, s_q, BUS_WIDTH_IN_SYMB, 0)

    # Generate
    pkt = RsPacket(roots_num=ROOTS_NUM, word_size=BUS_WIDTH_IN_SYMB)
    
    pkt.generate(K_LEN)
    pkt.corrupt()
    # START TEST
    await cocotb.start(reset_dut(aresetn,100))
    await Timer(50, units = "ns")

    await cocotb.start(custom_clock(aclk))
    await cocotb.start(s_mon.mon_if())

    await RisingEdge(aresetn)
    for i in range(10):
        await RisingEdge(aclk)
    await s_drv.send_pkt(pkt)

    for i in range (10):
        await RisingEdge(aclk)

    for pkt in s_q:        
        msg = pkt.get_byte_list()
        synd_prd = rs_calc_syndromes(msg, ROOTS_NUM)
        print(f"synd_prd {synd_prd}")
    
def rs_syndrome_tb():

    test_module = "rs_syndrome_tb"
    hdl_toplevel = "rs_syndrome"
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")
    
    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    print(proj_path)
    # equivalent to setting the PYTHONPATH environment variable
    
    verilog_sources = []
    includes        = []

    verilog_sources.append(proj_path / "lib" / "lib_mux_onehot.sv")
    verilog_sources.append(proj_path / "lib" / "lib_ffs.sv")
    verilog_sources.append(proj_path / "lib" / "lib_mux_ffs.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "gf_pkg.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "rs_syndrome_horney.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "rs_syndrome_root.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "rs_syndrome.sv")

    # Parameters    
    parameters = {}

    # Defines    
    defines = {}
    
    runner = get_runner(sim)
    build_args = ['--trace' , '--trace-structs', '--trace-max-array', '512', '--trace-max-width', '512']

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
    rs_syndrome_tb()
