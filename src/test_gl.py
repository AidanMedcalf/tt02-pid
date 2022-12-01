import cocotb
from cocotb.handle import Force, Release
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, FallingEdge, Timer, ClockCycles

gdut = None
def loginfo(*args, **kwargs):
    #gdut._log.info(*args, **kwargs)
    pass

#async def shift_bits(clk, sck, mosi, bits, inv=False):
    #for b in range(len(bits)):
        #print(str(bits[b]), str(~bits[b]))
        #mosi.value = bits[b] if not inv else ~bits[b]
        #await ClockCycles(clk, 1)
        #sck.value = 0
        #await ClockCycles(clk, 1)
        #sck.value = 1
        #await ClockCycles(clk, 1)

#async def shift_int(clk, sck, mosi, val, width, inv=True):
    #arr = [(val >> i) & 1 for i in range(width-1, -1, -1)]
    #await shift_bits(clk, sck, mosi, arr, inv=inv)

async def spi_master_send(clk, sck, mosi, cs, val, width, inv=True):
    cs.value = 0
    sck.value = 1
    await ClockCycles(clk, 1)
    for i in range(width-1, -1, -1):
        v = (val >> i) & 1 if not inv else ~(val >> i) & 1
        mosi.value = v
        sck.value = 0
        await ClockCycles(clk, 1)
        sck.value = 1
        await ClockCycles(clk, 1)
    cs.value = 1
    sck.value = 1
    mosi.value = 1

def invert(b):
    return 0 if b else 1

async def spi_slave_send(clk, sck, miso, cs, val, width, inv=True):
    loginfo(f"spi_slave_send {width:d}'h{val:x}")
    await FallingEdge(cs)
    loginfo(f"spi_slave_send cs low")
    for i in range(width-1, -1, -1):
        await FallingEdge(sck)
        v = (val >> i) & 1 if not inv else invert((val >> i) & 1)
        miso.value = v
        loginfo(f"spi_slave_send [{i: 2}] send {v}")
    #await RisingEdge(cs)

async def spi_slave_receive(clk, sck, mosi, cs, bits, inv=True):
    loginfo(f"spi_slave_receive")
    await FallingEdge(cs)
    loginfo(f"spi_slave_receive cs low")
    await FallingEdge(sck)
    loginfo(f"spi_slave_receive sck low")
    v = 0
    for i in range(bits):
        await RisingEdge(sck)
        bv = int(mosi.value)&1 if not inv else invert(int(mosi.value)&1)
        loginfo(f"spi_slave_receive bit {i} v = ({v} << 1)[={v<<1}] | bv[={bv}] = {(v<<1)|bv}")
        v = (v << 1) | bv
        loginfo(f"spi_slave_receive bit {i} = {mosi.value&1}")
    loginfo(f"spi_slave_receive received {bits:d}'h{v:x}")
    return int(v)

async def pid_transact(dut, sendval, recval):
    loginfo(f"Send {sendval:X} expect {recval:X}")
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, sendval, 8)
    await ClockCycles(dut.clk, 1)
    #await spi_slave_receive(dut.clk, dut.out_clk, dut.out_mosi, dut.out_cs, 8)
    assert await spi_slave_receive(dut.clk, dut.out_clk, dut.out_mosi, dut.out_cs, 8) == recval

@cocotb.test()
async def test_gl(dut):
    global gdut
    gdut = dut
    clock = Clock(dut.clk, 10, units="us")
    cocotb.start_soon(clock.start())

    dut.en.value = 1
    dut.cfg_sck.value = 1
    dut.cfg_mosi.value = 1
    dut.cfg_cs.value = 1
    dut.io_in5.value = 0
    dut.pv_in_miso.value = 0

    loginfo("Reset")
    dut.reset.value = 1
    await ClockCycles(dut.clk, 6)
    dut.reset.value = 0

    # shift in config
    loginfo("Send cfg")
    await spi_master_send(dut.clk, dut.cfg_sck, dut.cfg_mosi, dut.cfg_cs, 0x352480, 24, inv=True)
    await ClockCycles(dut.clk, 1)

    await pid_transact(dut, 0x02, 0x2C)
    await pid_transact(dut, 0x02, 0x46)
    await pid_transact(dut, 0x03, 0x00)
    await pid_transact(dut, 0x04, 0x00)
    await pid_transact(dut, 0x08, 0x04)
    await pid_transact(dut, 0x10, 0x26)

    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x20, 8)
    await ClockCycles(dut.clk, 1)
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x40, 8)
    await ClockCycles(dut.clk, 1)
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x80, 8)
    await ClockCycles(dut.clk, 1)
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x8A, 8)
    await ClockCycles(dut.clk, 1)
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x86, 8)
    await ClockCycles(dut.clk, 1)
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x82, 8)
    await ClockCycles(dut.clk, 1)
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x80, 8)
    await ClockCycles(dut.clk, 1)
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x80, 8)
    await ClockCycles(dut.clk, 1)
    await spi_slave_send(dut.clk, dut.pv_in_clk, dut.pv_in_miso, dut.pv_in_cs, 0x80, 8)
    await ClockCycles(dut.clk, 1)

    loginfo("Input finished")

    await ClockCycles(dut.clk, 10)

    loginfo("Done")
