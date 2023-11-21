
import os
import sys
from pathlib import Path

sys.path.append("/home/egorman44/digital_communicaiton/rs/python")

# Import COCOTB
import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge
from cocotb.triggers import Edge
from cocotb.runner import get_runner
from cocotb.triggers import Timer

import random

from rs import gf_mul
from rs import gf_mult_noLUT
from rs import init_tables

# Parameters
SYMB_WIDTH = 4

if(SYMB_WIDTH == 8):
    POLY = 285
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
async def gf_mult_test(dut):
    
    await Timer(2, units="ns")    
    init_tables(POLY,2,SYMB_WIDTH)
    
    for i in range(200):
        A = random.randint(0, 2**SYMB_WIDTH-1)
        B = random.randint(0, 2**SYMB_WIDTH-1)
        
        dut.A.value = A
        dut.B.value = B
        product = gf_mul(A,B)
        await Timer(2, units="ns")
        assert dut.product.value == product, f"[FAILED] GF(2^{SYMB_WIDTH}) : {A} x {B} = {dut.product.value} = {product}"
        

def gf_mult_tb():
    """Simulate the adder example using the Python runner.

    This file can be run directly or via pytest discovery.
    """

    test_module = "gf_mult_tb"
    hdl_toplevel = "gf_mult"
    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")
    
    proj_path = Path(__file__).resolve().parent.parent.parent
    print(proj_path)
    # equivalent to setting the PYTHONPATH environment variable
    
    verilog_sources = []
    includes        = []

    verilog_sources.append(proj_path / "rtl" / "gf_mult.sv")
    
    # equivalent to setting the PYTHONPATH environment variable
    sys.path.append(str(proj_path / "sim" / "gf_mult_tb"))


    # Parameters    
    parameters = {}    
    parameters['SYMB_WIDTH'] = SYMB_WIDTH
    parameters['POLY'] = POLY

    # Defines    
    defines = {}
    defines['DUMP_EN'] = 1
    
    runner = get_runner(sim)
    #build_args = ['--trace' '--trace-structs' '--trace-max-array 512 --trace-max-width 512']
    build_args = ['--trace' , '--trace-structs']
    
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
    gf_mult_tb()
