`default_nettype none
`timescale 1ns/1ps

/*
this testbench just instantiates the module and makes some convenient wires
that can be driven / tested by the cocotb test.py
*/

module pid_tb (
    // testbench is controlled by test.py
    input clk,
    input rst,
	input pv_stb,
	input [3:0] sp,
	input [3:0] pv,
	input [3:0] kp,
	input [3:0] ki,
	input [3:0] kd,
	input [3:0] out
   );

    // this part dumps the trace to a vcd file that can be viewed with GTKWave
    initial begin
        $dumpfile ("pid_tb.vcd");
        $dumpvars (0, pid_tb);
        #1;
    end

    // instantiate the DUT
	pid #(.BITS(4)) pid (.reset(rst), .clk(clk), .pv_stb(pv_stb), .sp(sp), .pv(pv), .kp(kp), .ki(ki), .kd(kd), .stimulus(out));

endmodule
