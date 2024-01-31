# Set environment to load modules we need
def get_path(module_path):
    if module_path not in os.environ:
        print(f"[ERROR] {module_path} env var is not set.")
    else:
        return os.getenv(module_path)

import random
import math
import cocotb    
import os
import sys
from pathlib import Path
dig_com_path = get_path('DIGITAL_COMMUNICAITON')
coco_path = get_path('COCO_PATH')
sys.path.append(dig_com_path + "/rs/python")
sys.path.append(dig_com_path + "/rs/sim")
sys.path.append(dig_com_path + "/rs/sim/tests")
sys.path.append(coco_path)

# Import modules
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.runner import get_runner
from cocotb.triggers import Timer


from rs import gf_pow
from rs import init_tables
from rs import rs_calc_syndromes

# Load modules we need

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
from rs_lib import RsErrPositionPacket
from rs_lib import RsErrBitPositionPacket
from rs_lib import ErrPositionPredictor
from rs_lib import RsDecodedPacket
from rs_chien_pos_to_value_test import RsChienPosToValRandomTest
from rs_chien_pos_to_value_test import RsChienPosToValAllPosTest

from rs_param import *
# Parameters

ROOTS_NUM = N_LEN-K_LEN
T_LEN = math.floor(ROOTS_NUM/2)

ROOTS_PER_CYCLE__CHIEN = 16
ROOTS_PER_CYCLE__BYTES = int(ROOTS_PER_CYCLE__CHIEN / 2)

print(f"ROOTS_PER_CYCLE__BYTES = {ROOTS_PER_CYCLE__BYTES}")

    
@cocotb.test()
async def random_test(dut):
    
    test = RsChienPosToValRandomTest(dut)
    test.set_if()
    test.build_env()
    test.gen_stimilus()
    await test.run()
    test.post_run()

@cocotb.test()
async def all_positions_test(dut):
    
    test = RsChienPosToValAllPosTest(dut, T_LEN)
    test.set_if()
    test.build_env()
    test.gen_stimilus()
    await test.run()
    test.post_run()

def rs_chien_pos_to_value_tb():
    
    test_module = "rs_chien_pos_to_value_tb"
    hdl_toplevel = "rs_chien_pos_to_value"
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")
    
    proj_path = Path(__file__).resolve().parent.parent.parent
    print(proj_path)
    # equivalent to setting the PYTHONPATH environment variable
    
    verilog_sources = []
    includes        = []
    f_file          = []

    verilog_sources.append(proj_path / "lib" / "lib_mux_onehot.sv")
    verilog_sources.append(proj_path / "lib" / "lib_ffs.sv")
    verilog_sources.append(proj_path / "lib" / "lib_mux_ffs.sv")
    verilog_sources.append(proj_path / "lib" / "lib_pipe.sv")
    verilog_sources.append(proj_path / "lib" / "lib_bin_to_vld.sv")
    verilog_sources.append(proj_path / "lib" / "lib_decmps_to_pow2.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "gf_pkg.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "gf_poly_eval.sv")
    verilog_sources.append(proj_path / "rs" / "rtl" / "rs_chien_pos_to_value.sv")

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
    #os.environ["RANDOM_SEED"] = '123'
    rs_chien_pos_to_value_tb()
