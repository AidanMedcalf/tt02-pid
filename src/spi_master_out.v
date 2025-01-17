/** spi_master_out.v
 * Author: Aidan Medcalf
 * 
 * SPI master (output only)
 */

`default_nettype none

// SPI slave (output only)
module spi_master_out #(
	parameter BITS = 8
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
    assign bi_next = bi - 'b1;
    
    reg phase;

    reg [2:0] stb;

    always @(posedge clk) begin
        if (reset) begin
            bi <= {BIBITS{1'b1}};
            sck <= 'b1;
            cs <= 'b1;
            mosi <= 'b1;
            phase <= 'b0;
	        stb <= 3'b010;
        end else begin
            if (!cs) begin
                stb <= { stb[1:0], stb[2] };
                if (stb[0]) begin
                    if (phase) begin
                        sck <= 'b1;
                        bi <= bi_next;
                        if (bi_next == {BIBITS{1'b1}}) begin
                            cs = 'b1;
                        end
                        phase <= 'b0;
                    end else begin
                        mosi <= ~in_buf[bi];
                        sck <= 'b0;
                        phase <= 'b1;
                    end
                end
            end else begin
                bi <= {BIBITS{1'b1}};
                sck <= 'b1;
                mosi <= 'b1;
                if (start) begin
                    cs <= 'b0;
                end
            end
        end
    end

endmodule
