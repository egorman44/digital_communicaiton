# Set environment to load modules we need
def get_path(module_path):
    if module_path not in os.environ:
        print(f"[ERROR] {module_path} env var is not set.")
    else:
        return os.getenv(module_path)

import random
import os
import sys
import math
from pathlib import Path

dig_com_path = get_path('DIGITAL_COMMUNICAITON')
coco_path = get_path('COCO_PATH')
sys.path.append(dig_com_path + "/rs/python")
sys.path.append(coco_path)

# Import modules
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import FallingEdge
from cocotb.runner import get_runner
from cocotb.triggers import Timer
from cocotb.types import Logic

from coco_env.stimulus import reset_dut
from coco_env.stimulus import custom_clock

# Load modules we nee
coco_path = get_path('COCO_PATH')
sys.path.append(coco_path)
from rs import init_tables
from rs import gf_poly_eval

N_LEN = 255
K_LEN = 239
ROOTS_NUM = N_LEN - K_LEN
T_LEN = math.floor(ROOTS_NUM/2)

@cocotb.test()
async def gf_poly_3(dut):

    ###################################################
    # Conenct TB to DUT ports
    ###################################################
    
    #random.seed(123)

    # System signals
    aclk    = dut.clock
    aresetn = dut.clock

    init_tables()
    
    ###################################################
    # Conenct TB to DUT ports
    ###################################################

    ###################################################
    # START TEST
    ###################################################
    await cocotb.start(reset_dut(aresetn,100,1))
    await Timer(50, units = "ns")
    
    await cocotb.start(custom_clock(aclk))
    await FallingEdge(aresetn)
    for i in range(10):
        await RisingEdge(aclk)
    
    poly = [0]*(T_LEN+1)
    poly[0] = 0
    #poly[1] = 222
    #poly[2] = 102
    poly[1] = 0
    poly[2] = 0
    poly[3] = 0
    poly[4] = 0
    poly[5] = 0
    poly[6] = 0x4f
    poly[7] = 0xea
    poly[8] = 1

    poly_sel = 0x3
    
    symb = 2

    gf_poly_eval(poly, symb)
    
    await Timer(10, units = "ns")
    dut.io_errLocator_0.value = poly[0]
    dut.io_errLocator_1.value = poly[1]
    dut.io_errLocator_2.value = poly[2]
    dut.io_errLocator_3.value = poly[3]
    dut.io_errLocator_4.value = poly[4]
    dut.io_errLocator_5.value = poly[5]
    dut.io_errLocator_6.value = poly[6]
    dut.io_errLocator_7.value = poly[7]
    dut.io_errLocator_8.value = poly[8]
    dut.io_errLocatorSel = poly_sel
    
    dut.io_inSymb_valid.value = 1
    dut.io_inSymb_bits.value = 1    
    await RisingEdge(aclk)
    dut.io_inSymb_bits.value = 2
    await RisingEdge(aclk)    
    dut.io_inSymb_valid.value = 0
    for i in range(5):
        await RisingEdge(aclk)
    await RisingEdge(aclk)
    #dut.vld_.value = 1
    #dut.symb.value = 4
    ##await RisingEdge(aclk)
    ##dut.symb.value = 4
    #await RisingEdge(aclk)    
    #dut.vld_i.value = 0

    for i in range(12):
        await RisingEdge(aclk)
        
    await Timer(50, units = "ns")
    
def gf_poly_eval_tb():

    test_module = "gf_poly_eval_tb"
    hdl_toplevel = "Test"
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")

    proj_path = Path(__file__).resolve().parent.parent.parent.parent
    print(f"proj_path: {proj_path}")

    verilog_sources = []
    includes        = []
    f_file          = []
    
    verilog_sources.append(proj_path / "rs" / "sim" / "gf_poly_eval" / "Test.sv")
    
    # Parameters    
    parameters = {        
                  }
    
    # Defines    
    defines = {}
    
    runner = get_runner(sim)
    build_args = [ '--timing', '--assert' , '--trace' , '--trace-structs', '--trace-max-array', '512', '--trace-max-width', '512']

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
    gf_poly_eval_tb()



    

        
