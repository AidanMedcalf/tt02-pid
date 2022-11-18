/** spi_master_out.v
 * Author: Aidan Medcalf
 * 
 * SPI master (output only)
 */

`default_nettype none

// SPI slave (output only)
module spi_master_out #(
	parameter BITS = 4
) (
	input                 reset,
	input                 clk,
	input      [BITS-1:0] in_buf,
    input                 start,
	output reg            sck,
	output reg            cs,
	output reg            mosi
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
    strobe #(.BITS(2)) stb (.reset(stb_reset), .clk(clk), .level(2'd2), .out(sck_stb));

    always @(posedge clk) begin
        if (reset) begin
            bi <= 'b0;
            sck <= 'b1;
            cs <= 'b1;
            mosi <= 'b1;
            phase <= 'b0;
        end else begin
            if (!cs) begin
                if (sck_stb) begin
                    if (phase) begin
                        sck <= 'b1;
                        bi <= bi_next;
                        if (bi_next == 'b0) begin
                            cs = 'b1;
                        end
                        phase <= 'b0;
                    end else begin
                        mosi <= in_buf[bi];
                        sck <= 'b0;
                        phase <= 'b1;
                    end
                end
            end else begin
                bi <= 'b0;
                sck <= 'b1;
                mosi <= 'b1;
                if (start) begin
                    cs <= 'b0;
                end
            end
        end
    end

endmodule
