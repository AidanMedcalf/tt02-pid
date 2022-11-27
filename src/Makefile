# Makefile
# See https://docs.cocotb.org/en/stable/quickstart.html for more info

# defaults
SIM ?= icarus
TOPLEVEL_LANG ?= verilog

ifneq ($(GATES),yes)
# normal simulation
VERILOG_SOURCES += $(PWD)/tt2_tb.v $(PWD)/tt2.v $(PWD)/spi_slave.v $(PWD)/pid.v $(PWD)/spi_master_out.v $(PWD)/spi_master_in.v
else
# gate level simulation requires some extra setup
COMPILE_ARGS    += -DGL_TEST
COMPILE_ARGS    += -DFUNCTIONAL
COMPILE_ARGS    += -DUSE_POWER_PINS
COMPILE_ARGS    += -DSIM
COMPILE_ARGS    += -DUNIT_DELAY=#1
VERILOG_SOURCES += $(PDK_ROOT)/sky130B/libs.ref/sky130_fd_sc_hd/verilog/primitives.v
VERILOG_SOURCES += $(PDK_ROOT)/sky130B/libs.ref/sky130_fd_sc_hd/verilog/sky130_fd_sc_hd.v

# copy the gatelevel verilog from /runs/wokwi/results/final/verilog/gl/ and commit to this directory
VERILOG_SOURCES += $(PWD)/gl/tt2_tb.v $(PWD)/gl/AidanMedcalf_pid_controller.v
endif

# TOPLEVEL is the name of the toplevel module in your Verilog or VHDL file
TOPLEVEL = tt2_tb

# MODULE is the basename of the Python test file
ifneq ($(GATES),yes)
MODULE = test
else
MODULE = test_gl
endif

# include cocotb's make rules to take care of the simulator setup
include $(shell cocotb-config --makefiles)/Makefile.sim
