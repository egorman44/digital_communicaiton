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

# Import modules
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.runner import get_runner
from cocotb.triggers import Timer
from cocotb.types import Logic
# Load modules we nee
coco_path = get_path('COCO_PATH')
sys.path.append(coco_path)

from coco_env.packet import Packet
from coco_env.scoreboard import Comparator
from coco_env.scoreboard import Predictor
from coco_env.stimulus import reset_dut
from coco_env.stimulus import custom_clock
from coco_axis.axis import AxisDriver
from coco_axis.axis import AxisResponder
from coco_axis.axis import AxisMonitor
from coco_axis.axis import AxisIf

WIDTH = 12
LSB_MSB = 1

@cocotb.test()
async def lib_decmps_to_pow2_test(dut):

    #random.seed(4)
    
    ###################################################
    # Conenct TB to DUT ports
    ###################################################

    ###################################################
    # START TEST
    ###################################################
    vect = random.randint(1,(2 ** WIDTH)-1)
    #bypass = (2 ** random.randint(1,WIDTH))-1
    bypass = (2 ** random.randint(1,3))-1
    
    print(f"vect = {vect}")
    print(f"bypass = {bypass}")
    
    await Timer(10, units = "ns")
    dut.vect.value = vect
    dut.bypass.value = bypass
    await Timer(50, units = "ns")
    
def lib_decmps_to_pow2_tb():

    test_module = "lib_decmps_to_pow2_tb"
    hdl_toplevel = "lib_decmps_to_pow2"
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")

    proj_path = Path(__file__).resolve().parent.parent
    print(f"proj_path: {proj_path}")

    verilog_sources = []
    includes        = []
    f_file          = []

    verilog_sources.append(proj_path / "lib_decmps_to_pow2.sv")
    verilog_sources.append(proj_path / "lib_ffs.sv")

    # Parameters    
    parameters = {
        "WIDTH" : WIDTH,
        "LSB_MSB" : LSB_MSB
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
    lib_decmps_to_pow2_tb()



    

        
