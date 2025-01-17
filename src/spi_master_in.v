/** spi_master_in.v
 * Author: Aidan Medcalf
 * 
 * SPI master (input only)
 */

`default_nettype none

// SPI master (input only)
module spi_master_in #(
	parameter BITS = 8
) (
	input                 reset,
	input                 clk,
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

    reg [2:0] stb;
    //strobe #(.BITS(2)) stb (.reset(stb_reset), .clk(clk), .level(2'd2), .out(sck_stb));

    always @(posedge clk) begin
        if (reset) begin
            bi <= 'b0;
            sck <= 'b1;
            cs <= 'b1;
            phase <= 'b0;
            out_buf <= 'b0;
            stb <= 3'b010;
        end else begin
            if (!cs) begin
                stb <= { stb[1:0], stb[2] };
                if (stb[0]) begin
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
                stb <= 3'b010;
                if (start) begin
                    cs <= 'b0;
                end
            end
        end
    end

endmodule
