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

    wire clk;
    wire reset;
    wire enable;
    wire cfg_clk;
    wire cfg_mosi;
    wire cfg_cs;
    wire ctrl_miso;
    wire hold;
    assign hold = reset || !enable;

    assign clk       = io_in[0];
    assign reset     = io_in[1];
    assign enable    = io_in[2];
    assign cfg_clk   = io_in[3];
    assign cfg_mosi  = io_in[4];
    assign cfg_cs    = io_in[6];
    assign ctrl_miso = io_in[7];

    wire ctrl_clk;
    wire ctrl_in_cs;
    wire ctrl_out_cs;
    wire ctrl_mosi;

    assign io_out[0] = ctrl_clk;
    assign io_out[1] = ctrl_in_cs;
    assign io_out[2] = ctrl_out_cs;
    assign io_out[3] = ctrl_mosi;
    assign io_out[4] = 1'b0;
    assign io_out[5] = 1'b0;
    assign io_out[6] = 1'b0;
    assign io_out[7] = 1'b0;

    // Configuration registers
    reg  [7:0] cfg_buf[4];
    wire [3:0] sp;
    wire [3:0] kp;
    wire [3:0] ki;
    wire [3:0] kd;
    wire [15:0] stb_level;
    assign sp = cfg_buf[0][3:0];
    assign kp = cfg_buf[0][7:4];
    assign ki = cfg_buf[1][3:0];
    assign kd = cfg_buf[1][7:4];
    assign stb_level[7:0] = cfg_buf[2];
    assign stb_level[15:8] = cfg_buf[3];

    wire pv_stb;
    wire pid_stb;
    reg pid_stb_d1;

    // I/O registers
    reg [3:0] in_pv;
    reg [3:0] out;

    wire ctrl_in_clk;
    wire ctrl_out_clk;
    assign ctrl_clk = ctrl_in_clk & ctrl_out_clk;

    // Slave SPI for configuration
    wire cfg_spi_busy;
    wire [31:0] cfg_spi_buffer;
    spi_slave_in cfg_spi(.reset(reset), .clk(clk), .cs(cfg_cs), .sck(cfg_clk), .mosi(cfg_mosi),
                         .busy(cfg_spi_busy), .out_buf(cfg_spi_buffer));

    // Shift input in
    spi_master_in spi_in(.reset(reset), .clk(clk), .stb_level(8'd2),
                           .miso(ctrl_miso), .start(pv_stb),
                           .out_buf(in_pv), .sck(ctrl_in_clk), .cs(ctrl_in_cs));

    // Shift output out
    spi_master_out spi_out(.reset(reset), .clk(clk), .in_buf(out),
                           .stb_level(8'd2), .start(pid_stb_d1),
                           .sck(ctrl_out_clk), .cs(ctrl_out_cs), .mosi(ctrl_mosi));

    // just to see if the PID core fits, fake everything
    
    pid pid (.reset(hold), .clk(clk), .pv_stb(pid_stb),
             .sp(sp), .pv(in_pv),
             .kp(kp), .ki(ki), .kd(kd),
             .stimulus(out));
    
    strobe #(.BITS(16)) pv_stb_gen(.reset(reset), .clk(clk), .level(stb_level), .out(pv_stb));

    edge_detect ctrl_in_cs_pe(.reset(reset), .clk(clk), .sig(ctrl_in_cs), .pol(1'b1), .out(pid_stb));

    wire cfg_latch_stb;
    edge_detect cfg_spi_busy_ne(.reset(reset), .clk(clk), .sig(cfg_spi_busy), .pol(1'b0), .out(cfg_latch_stb));

    always @(posedge clk) begin
        if (reset) begin
            cfg_buf[0] <= 8'h4A;
            cfg_buf[1] <= 8'h23;
            cfg_buf[2] <= 8'h00;
            cfg_buf[3] <= 8'h10;
            pid_stb_d1 <= 'b0;
        end else begin
            pid_stb_d1 <= pid_stb;
            if (cfg_latch_stb) begin
                cfg_buf[3] <= cfg_spi_buffer[7:0];
                cfg_buf[2] <= cfg_spi_buffer[15:8];
                cfg_buf[1] <= cfg_spi_buffer[23:16];
                cfg_buf[0] <= cfg_spi_buffer[31:24];
            end
        end
    end

endmodule

module edge_detect (
    input  reset,
    input  clk,
    input  sig,
    input  pol,
    output out
);
    reg sigin;
    reg siglast;
    assign out = reset ? 1'b0 : (pol ? ((!siglast) && sigin) : (siglast && (!sigin)));
    always @(posedge clk) begin
        { siglast, sigin } <= { sigin, sig };
        //sigin <= sig;
        //siglast <= sigin;
    end
endmodule

module strobe #(
    parameter BITS=8
) (
    input reset,
    input clk,
    input [BITS-1:0] level,
    output out
);
    reg  [BITS-1:0] count;
    wire [BITS-1:0] next;
    assign next = count - 'b1;
    assign out = count == 0;
    always @(posedge clk) begin
        if (reset || out) begin
            count <= level;
        end else begin
            count <= next;
        end
    end
endmodule
