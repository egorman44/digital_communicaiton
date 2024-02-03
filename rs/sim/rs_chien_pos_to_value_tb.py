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
from cocotb.runner import get_runner

# Load modules we need

from rs_chien_pos_to_value_test import RsChienPosToValRandomTest
from rs_chien_pos_to_value_test import RsChienPosToValAllPosTest
from rs_chien_pos_to_value_test import RsChienPosToValCorruptInRawTest
from rs_param import *
# Parameters

ROOTS_NUM = N_LEN-K_LEN
T_LEN = math.floor(ROOTS_NUM/2)

    
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

@cocotb.test()
async def corrupt_in_raw_test(dut):
    
    test = RsChienPosToValCorruptInRawTest(dut)
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
    defines = {"ROOTS_PER_CYCLE__CHIEN" : ROOTS_PER_CYCLE__CHIEN}
    
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
    #os.environ["RANDOM_SEED"] = '1706722271'
    rs_chien_pos_to_value_tb()
