import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

@cocotb.test()
async def test_proportional(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.kp.value = 15
    dut.ki.value = 0
    dut.kd.value = 0
    dut.sp.value = 10
    dut.pv.value = 10
    dut.pv_stb.value = 1 # hold pv_stb at 1 to latch error every clock
    
    dut.rst.value = 1
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0

    dut.kp.value = 15
    dut.sp.value = 10
    dut.pv.value = 10
    dut.pv_stb.value = 1
    await ClockCycles(dut.clk, 1)
    assert int(dut.out.value) == 0

    dut.kp.value = 15
    dut.sp.value = 10
    dut.pv.value = 0
    await ClockCycles(dut.clk, 2)
    #dut._log.info(f"accum   = {dut.pid.accumulator.value}")
    #dut._log.info(f"error   = {dut.pid.error.value}")
    #dut._log.info(f"error_p = {dut.pid.error_p.value}")
    #dut._log.info(f"sp      = {dut.pid.sp.value}")
    #dut._log.info(f"pv      = {dut.pid.pv.value}")
    assert int(dut.out.value) == int(150 / 16)

    dut.kp.value = 15
    dut.sp.value = 0
    dut.pv.value = 10
    await ClockCycles(dut.clk, 2)
    #dut._log.info(f"accum   = {dut.pid.accumulator.value}")
    #dut._log.info(f"error   = {dut.pid.error.value}")
    #dut._log.info(f"error_p = {dut.pid.error_p.value}")
    #dut._log.info(f"sp      = {dut.pid.sp.value}")
    #dut._log.info(f"pv      = {dut.pid.pv.value}")
    assert int(dut.out.value) == 0

    dut.kp.value = 0
    await ClockCycles(dut.clk, 2)
    assert int(dut.out.value) == 0

    dut.kp.value = 15
    dut.sp.value = 15
    dut.pv.value = 0
    await ClockCycles(dut.clk, 2)
    assert int(dut.out.value) == 14

@cocotb.test()
async def test_differential(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # basic settings
    dut.kp.value = 0
    dut.ki.value = 0
    dut.kd.value = 15
    dut.sp.value = 10
    dut.pv.value = 0
    dut.pv_stb.value = 0

    dut.rst.value = 1
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0

    assert int(dut.pid.error.value) == 10
    assert int(dut.pid.error_p.value) == 10
    assert int(dut.out.value) == 0

    dut.pv_stb.value = 0
    await ClockCycles(dut.clk, 1)
    dut.pv_stb.value = 1
    await ClockCycles(dut.clk, 1)
    assert int(dut.pid.error.value) == 10
    assert int(dut.pid.error_p.value) == 10
    assert int(dut.out.value) == 0

    dut.sp.value = 12
    await ClockCycles(dut.clk, 2)
    # error should be 12, error_p should be 10, out should be 30/16 = 1
    assert int(dut.pid.error.value) == 12
    assert int(dut.pid.error_p.value) == 10
    assert int(dut.out.value) == int(30/16)

    dut.pv.value = 4
    await ClockCycles(dut.clk, 2)
    # error should be 8, error_p should be 12, out should be 0
    assert int(dut.pid.error.value) == 8
    assert int(dut.pid.error_p.value) == 12
    assert int(dut.out.value) == 0

@cocotb.test()
async def test_integral(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    # basic settings
    dut.kp.value = 0
    dut.ki.value = 10
    dut.kd.value = 0
    dut.sp.value = 10
    dut.pv.value = 8
    dut.pv_stb.value = 0

    dut.rst.value = 1
    await ClockCycles(dut.clk, 4)
    dut.rst.value = 0

    assert int(dut.pid.error.value) == 2
    assert int(dut.pid.error_p.value) == 2
    assert int(dut.pid.error_i.value) == 0
    assert int(dut.out.value) == 0

    dut.pv_stb.value = 1
    await ClockCycles(dut.clk, 2);
    # error is 2, expect error_i = 2
    assert int(dut.pid.error.value) == 2
    assert int(dut.pid.error_i.value) == 2
    assert int(dut.out.value) == int(20/16)

    dut.sp.value = 6; # prepare for next cycle
    await ClockCycles(dut.clk, 1);
    assert int(dut.pid.error.value) == 2
    assert int(dut.pid.error_i.value) == 4
    assert int(dut.out.value) == int(40/16)

    await ClockCycles(dut.clk, 1);
    assert int(dut.pid.error.value) == 0b11110
    assert int(dut.pid.error_i.value) == 6
    assert int(dut.out.value) == int(60/16)

    await ClockCycles(dut.clk, 1);
    assert int(dut.pid.error.value) == 0b11110
    assert int(dut.pid.error_i.value) == 4
    assert int(dut.out.value) == int(40/16)

    await ClockCycles(dut.clk, 1);
    assert int(dut.pid.error.value) == 0b11110
    assert int(dut.pid.error_i.value) == 2
    assert int(dut.out.value) == int(20/16)

    await ClockCycles(dut.clk, 1);
    assert int(dut.pid.error.value) == 0b11110
    assert int(dut.pid.error_i.value) == 0
    assert int(dut.out.value) == 0

    await ClockCycles(dut.clk, 1);
    assert int(dut.pid.error.value) == 0b11110
    assert int(dut.pid.error_i.value) == 0b11110
    assert int(dut.out.value) == 0

    await ClockCycles(dut.clk, 1);
    assert int(dut.pid.error.value) == 0b11110
    assert int(dut.pid.error_i.value) == 0b11100
    assert int(dut.out.value) == 0
