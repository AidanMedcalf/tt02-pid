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
    input cfg_sck,
    input cfg_mosi,
    input io_in5,
    input cfg_cs,
    input pv_in_miso,
    output pv_in_clk,
    output pv_in_cs,
    output out_clk,
    output out_mosi,
    output out_cs,
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
    assign io_in = { pv_in_miso, cfg_cs, io_in5, cfg_mosi, cfg_sck, en, reset, clk };
    assign { io_out7, io_out6, io_out5, out_cs, out_mosi, out_clk, pv_in_cs, pv_in_clk } = io_out;

    // instantiate the DUT
    AidanMedcalf_pid_controller tt2(
        `ifdef GL_TEST
            .vccd1(1'b1),
            .vssd1(1'b0),
        `endif
        .io_in(io_in),
        .io_out(io_out)
    );

endmodule
