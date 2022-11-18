import cocotb
from cocotb.handle import Force, Release
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

async def send_bits(clk, miso, b3, b2, b1, b0):
    await ClockCycles(clk, 4)
    miso.value = not b3
    await ClockCycles(clk, 4)
    miso.value = not b2
    await ClockCycles(clk, 4)
    miso.value = not b1
    await ClockCycles(clk, 4)
    miso.value = not b0

@cocotb.test()
async def test_lets_go(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.en.value = 1
    dut.sck.value = 1
    dut.mosi.value = 1
    dut.cs.value = 1
    dut.io_in5.value = 0
    dut.ctrl_miso.value = 0

    dut.reset.value = 1
    await ClockCycles(dut.clk, 6)
    dut.reset.value = 0

    # wait until it asks for input
    await FallingEdge(dut.tt2.ctrl_in_cs)
    await ClockCycles(dut.clk, 1)
    await send_bits(dut.clk, dut.ctrl_miso, 0, 0, 1, 0)

    await FallingEdge(dut.tt2.ctrl_in_cs)
    await ClockCycles(dut.clk, 1)
    await send_bits(dut.clk, dut.ctrl_miso, 0, 0, 1, 0)

    await FallingEdge(dut.tt2.ctrl_in_cs)
    await ClockCycles(dut.clk, 1)
    await send_bits(dut.clk, dut.ctrl_miso, 0, 0, 1, 1)

    await FallingEdge(dut.tt2.ctrl_in_cs)
    await ClockCycles(dut.clk, 1)
    await send_bits(dut.clk, dut.ctrl_miso, 0, 0, 1, 1)

    await FallingEdge(dut.tt2.ctrl_in_cs)
    #await ClockCycles(dut.clk, 2)
    await send_bits(dut.clk, dut.ctrl_miso, 0, 1, 0, 0)

    await FallingEdge(dut.tt2.ctrl_in_cs)
    #await ClockCycles(dut.clk, 2)
    await send_bits(dut.clk, dut.ctrl_miso, 0, 1, 0, 0)

    await FallingEdge(dut.tt2.ctrl_in_cs)
    #await ClockCycles(dut.clk, 2)
    await send_bits(dut.clk, dut.ctrl_miso, 0, 1, 0, 1)

    await FallingEdge(dut.tt2.ctrl_in_cs)
    #await ClockCycles(dut.clk, 2)
    await send_bits(dut.clk, dut.ctrl_miso, 1, 0, 0, 0)

    await FallingEdge(dut.tt2.ctrl_in_cs)
    #await ClockCycles(dut.clk, 2)
    await send_bits(dut.clk, dut.ctrl_miso, 1, 0, 1, 0)

    await ClockCycles(dut.clk, 30)

@cocotb.test()
async def test_spi_master_in(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.en.value = 0
    dut.sck.value = 1
    dut.mosi.value = 1
    dut.cs.value = 1
    dut.io_in5.value = 0
    dut.ctrl_miso.value = 0

    dut.reset.value = 1
    await ClockCycles(dut.clk, 6)
    dut.reset.value = 0

    dut.tt2.spi_in.miso.value = Force(0)
    await ClockCycles(dut.clk, 1)

    dut.tt2.spi_in.start.value = Force(1)
    await ClockCycles(dut.clk, 1)
    dut.tt2.spi_in.start.value = Force(0)
    await ClockCycles(dut.clk, 14)
    dut.tt2.spi_in.miso.value = Force(1)
    await ClockCycles(dut.clk, 15)

    dut.tt2.spi_in.miso.value = Release()
    dut.tt2.spi_in.start.value = Release()

@cocotb.test()
async def test_spi_master_out(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.en.value = 0
    dut.sck.value = 1
    dut.mosi.value = 1
    dut.cs.value = 1
    dut.io_in5.value = 0
    dut.ctrl_miso.value = 0

    dut.reset.value = 1
    await ClockCycles(dut.clk, 10)
    dut.reset.value = 0

    dut.tt2.spi_out.in_buf.value = Force(5)
    dut.tt2.pid_stb.value = Force(0)

    await ClockCycles(dut.clk, 2)

    dut.tt2.pid_stb.value = Force(1)
    await ClockCycles(dut.clk, 1)
    #assert int(dut.tt2.cfg_cs) == 0
    await ClockCycles(dut.clk, 1)
    dut.tt2.pid_stb.value = Force(0)
    #assert int(dut.tt2.cfg_sck) == 1
    await ClockCycles(dut.clk, 1)
    #assert int(dut.tt2.cfg_sck) == 0
    #assert int(dut.tt2.cfg_mosi) == 1
    await ClockCycles(dut.clk, 30)

    dut.tt2.spi_out.in_buf.value = Release()
    dut.tt2.pid_stb.value = Release()

async def shift_bits(clk, sck, mosi, bits):
    for b in range(8):
        mosi.value = bits[b]
        #await ClockCycles(clk, 1)
        sck.value = 0
        await ClockCycles(clk, 1)
        sck.value = 1
        await ClockCycles(clk, 1)

@cocotb.test()
async def test_spi_in(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.en.value = 0
    dut.sck.value = 1
    dut.mosi.value = 1
    dut.cs.value = 1
    dut.io_in5.value = 0
    dut.ctrl_miso.value = 0

    dut.reset.value = 1
    await ClockCycles(dut.clk, 10)
    dut.reset.value = 0

    # shift in bad data while cs
    # cfg_buf is set to zero on reset
    # SPI signals are inverted (like usual)
    dut.cs.value = 1
    for w in range(4):
        await shift_bits(dut.clk, dut.sck, dut.mosi, [0,1,1,0,1,0,0,1])
        #for b in range(8):
            #dut.mosi.value = 0
            #dut.sck.value = 0
            #await ClockCycles(dut.clk, 1)
            #dut.sck.value = 1
            #await ClockCycles(dut.clk, 1)
    dut.cs.value = 1

    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_spi_buffer.value) == 0x00000000
    await ClockCycles(dut.clk, 1)

    # Reset values
    assert int(dut.tt2.cfg_buf[0]) == 0x4A
    assert int(dut.tt2.cfg_buf[1]) == 0x23
    assert int(dut.tt2.cfg_buf[2]) == 0x00
    assert int(dut.tt2.cfg_buf[3]) == 0x10

    # Shift in some bits
    dut.cs.value = 0
    dut.sck.value = 1
    await ClockCycles(dut.clk, 1)
    await shift_bits(dut.clk, dut.sck, dut.mosi, [1,1,1,1,1,1,1,0])
    await shift_bits(dut.clk, dut.sck, dut.mosi, [1,1,1,1,1,1,0,1])
    await shift_bits(dut.clk, dut.sck, dut.mosi, [1,1,1,1,1,1,0,0])
    await shift_bits(dut.clk, dut.sck, dut.mosi, [1,1,1,1,1,0,1,1])
    dut.cs.value = 1
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_spi_buffer.value) == 0x01020304
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_buf[0].value) == 1
    assert int(dut.tt2.cfg_buf[1].value) == 2
    assert int(dut.tt2.cfg_buf[2].value) == 3
    assert int(dut.tt2.cfg_buf[3].value) == 4

    # Shift in some bits
    dut.cs.value = 0
    dut.sck.value = 1
    await ClockCycles(dut.clk, 1)
    await shift_bits(dut.clk, dut.sck, dut.mosi, [0,0,0,0,0,0,0,0])
    await shift_bits(dut.clk, dut.sck, dut.mosi, [1,1,1,1,1,1,1,1])
    await shift_bits(dut.clk, dut.sck, dut.mosi, [0,0,0,0,0,0,0,0])
    await shift_bits(dut.clk, dut.sck, dut.mosi, [1,1,1,1,1,1,1,1])
    dut.cs.value = 1
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_spi_buffer.value) == 0xFF00FF00
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_buf[0].value) == 0xFF
    assert int(dut.tt2.cfg_buf[1].value) == 0
    assert int(dut.tt2.cfg_buf[2].value) == 0xFF
    assert int(dut.tt2.cfg_buf[3].value) == 0

"""
@cocotb.test()
async def test_edge_det(dut):
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.en.value = 0
    dut.sck.value = 1
    dut.mosi.value = 1
    dut.cs.value = 1
    dut.io_in5.value = 0
    dut.ctrl_miso.value = 0

    dut.tt2.ctrl_in_cs_pe.out.value = Release()
    dut.reset.value = 1
    await ClockCycles(dut.clk, 6)
    dut.reset.value = 0

    # test positive edge
    dut.tt2.ctrl_in_cs_pe.sig.value = Force(0)
    await ClockCycles(dut.clk, 4)
    assert int(dut.tt2.ctrl_in_cs_pe.siglast.value) == 0
    assert int(dut.tt2.ctrl_in_cs_pe.sigin.value) == 0
    assert int(dut.tt2.ctrl_in_cs_pe.out.value) == 0
    dut.tt2.ctrl_in_cs_pe.sig.value = Force(1)
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.ctrl_in_cs_pe.siglast.value) == 0
    assert int(dut.tt2.ctrl_in_cs_pe.sigin.value) == 0
    assert int(dut.tt2.ctrl_in_cs_pe.out.value) == 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.ctrl_in_cs_pe.siglast.value) == 0
    assert int(dut.tt2.ctrl_in_cs_pe.sigin.value) == 1
    assert int(dut.tt2.ctrl_in_cs_pe.out.value) == 1
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.ctrl_in_cs_pe.siglast.value) == 1
    assert int(dut.tt2.ctrl_in_cs_pe.sigin.value) == 1
    assert int(dut.tt2.ctrl_in_cs_pe.out.value) == 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.ctrl_in_cs_pe.siglast.value) == 1
    assert int(dut.tt2.ctrl_in_cs_pe.sigin.value) == 1
    assert int(dut.tt2.ctrl_in_cs_pe.out.value) == 0

    dut.tt2.ctrl_in_cs_pe.sig.value = Release()
    dut.tt2.ctrl_in_cs_pe.out.value = Release()

    await ClockCycles(dut.clk, 5)

    dut.tt2.cfg_spi_busy_ne.out.value = Release()
    dut.tt2.cfg_spi_busy_ne.sig.value = Force(1)
    dut.reset.value = 1
    await ClockCycles(dut.clk, 6)
    dut.reset.value = 0

    # test negative edge
    dut.tt2.cfg_spi_busy_ne.sig.value = Force(1)
    await ClockCycles(dut.clk, 4)
    assert int(dut.tt2.cfg_spi_busy_ne.siglast.value) == 1
    assert int(dut.tt2.cfg_spi_busy_ne.sigin.value) == 1
    assert int(dut.tt2.cfg_spi_busy_ne.out.value) == 0
    dut.tt2.cfg_spi_busy_ne.sig.value = Force(0)
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_spi_busy_ne.siglast.value) == 1
    assert int(dut.tt2.cfg_spi_busy_ne.sigin.value) == 1
    assert int(dut.tt2.cfg_spi_busy_ne.out.value) == 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_spi_busy_ne.siglast.value) == 1
    assert int(dut.tt2.cfg_spi_busy_ne.sigin.value) == 0
    assert int(dut.tt2.cfg_spi_busy_ne.out.value) == 1
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_spi_busy_ne.siglast.value) == 0
    assert int(dut.tt2.cfg_spi_busy_ne.sigin.value) == 0
    assert int(dut.tt2.cfg_spi_busy_ne.out.value) == 0
    await ClockCycles(dut.clk, 1)
    assert int(dut.tt2.cfg_spi_busy_ne.siglast.value) == 0
    assert int(dut.tt2.cfg_spi_busy_ne.sigin.value) == 0
    assert int(dut.tt2.cfg_spi_busy_ne.out.value) == 0

    dut.tt2.cfg_spi_busy_ne.sig.value = Release()
    dut.tt2.cfg_spi_busy_ne.out.value = Release()
"""

