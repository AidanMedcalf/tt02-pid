/** spi_master_in.v
 * Author: Aidan Medcalf
 * 
 * SPI master (input only)
 */

`default_nettype none

// SPI master (input only)
module spi_master_in #(
	parameter BITS = 4
) (
	input                 reset,
	input                 clk,
    input           [7:0] stb_level,
    input                 start,
    input                 miso,
	output reg [BITS-1:0] out_buf,
	output reg            sck,
	output reg            cs
);

    // CS = state = !busy
    // if not cs then we are in a transaction
    // if cs then we are idle
    // if cs and start, start transaction

    localparam BIBITS = $clog2(BITS);
    reg  [BIBITS-1:0] bi;
    wire [BIBITS-1:0] bi_next;
    assign bi_next = bi + 'b1;
    
    reg phase;

    wire stb_reset;
    assign stb_reset = reset || cs;
    wire sck_stb;
    strobe stb (.reset(stb_reset), .clk(clk), .level(stb_level), .out(sck_stb));

    always @(posedge clk) begin
        if (reset) begin
            bi <= 'b0;
            sck <= 'b1;
            cs <= 'b1;
            phase <= 'b0;
            out_buf <= 'b0;
        end else begin
            if (!cs) begin
                if (sck_stb) begin
                    if (phase) begin
                        sck <= 'b1;
                        out_buf <= { out_buf[BITS-2:0], !miso };
                        bi <= bi_next;
                        if (bi_next == 'b0) begin
                            cs = 'b1;
                        end
                        phase <= 'b0;
                    end else begin
                        sck <= 'b0;
                        phase <= 'b1;
                    end
                end
            end else begin
                bi <= 'b0;
                sck <= 'b1;
                phase <= 'b0;
                if (start) begin
                    cs <= 'b0;
                end
            end
        end
    end

endmodule
