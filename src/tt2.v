/** tt2.v
 * Author: Aidan Medcalf
 * 
 * Top-level TinyTapeout 2 wrapper
 */

`default_nettype none

module AidanMedcalf_pid_controller (
	input  [7:0] io_in,
	output [7:0] io_out
);

	wire clk = io_in[0];
	wire reset = io_in[1];

	// just to see if the PID core fits, fake everything
	
	pid pid (.reset(reset), .clk(clk), .pv_stb(pv_stb),
			 .sp(4'b1011), .pv(io_in[7:4]),
			 .kp(4'd5), .ki(4'd3), .kd(4'd2),
			 .stimulus(io_out[3:0]));
	
	strobe pv_stb(.reset(reset), .clk(clk), .out(pv_stb));

endmodule
