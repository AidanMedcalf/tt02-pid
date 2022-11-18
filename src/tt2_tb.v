`default_nettype none
`timescale 1ns/1ps

/*
this testbench just instantiates the module and makes some convenient wires
that can be driven / tested by the cocotb test.py
*/

module tt2_tb (
    // testbench is controlled by test.py
	input reset,
	input clk,
	input en,
	input sck,
	input mosi,
	input io_in5,
	input cs,
	input ctrl_miso,
    output ctrl_clk,
    output ctrl_in_cs,
    output ctrl_out_cs,
    output ctrl_mosi,
    output io_out4,
    output io_out5,
    output io_out6,
    output io_out7
   );

    // this part dumps the trace to a vcd file that can be viewed with GTKWave
    //integer i;
    initial begin
        $dumpfile ("tt2_tb.vcd");
        $dumpvars (0, tt2_tb);
        //for (i = 0; i < 4; i = i + 1)
            //$dumpvars(1, tt2.cfg_buf[i]);
        #1;
    end

	wire [7:0] io_in;
	wire [7:0] io_out;
	//assign io_in = { clk, reset, en, sck, mosi, io_in5, cs, io_in7 };
	assign io_in = { ctrl_miso, cs, io_in5, mosi, sck, en, reset, clk };
    assign io_out = { io_out7, io_out6, io_out5, io_out4, ctrl_mosi, ctrl_out_cs, ctrl_in_cs, ctrl_clk };

    // instantiate the DUT
	AidanMedcalf_pid_controller tt2(.io_in(io_in), .io_out(io_out));

endmodule
