/** spi_slave_in.v
 * Author: Aidan Medcalf
 * 
 * SPI slave (input only)
 */

`default_nettype none

// SPI slave (input only)
module spi_slave_in #(
	parameter BITS = 32
) (
	input                 reset,
	input                 clk,
	input                 cs,
	input                 sck,
	input                 mosi,
    output                busy,
	output [BITS-1:0] out_buf
);

// TODO: transaction reset timer

	localparam BCBITS = $clog2(BITS);
	reg [BCBITS-1:0] bi; // bit index
	
	wire [BCBITS-1:0] bi_next;
	assign bi_next = bi + 'b1;

    reg [BITS-1:0] buffer;
    assign out_buf = buffer;

    reg int_busy;
    assign busy = int_busy;
	wire bit_out;
    assign bit_out = reset ? 1'b0 : !mosi;
	//assign buffer[wi][bi] = bit_out;

    integer i;
	always @(posedge clk) begin
		if (reset || cs) begin
			int_busy <= 'b0;
			bi <= 'b0;
            buffer <= 'b0;
		end
	end

	always @(negedge sck) begin
		if (!cs) begin
			//buffer[wi][bi] <= reset ? 1'b0 : bit_out;
            // Shift bit into output buffer
            buffer <= { buffer[BITS-2:0], bit_out };
            // Update indices
			bi <= bi_next;
            if (int_busy && bi_next == 'b0) begin
				int_busy <= 'b0;
            end else begin
			    int_busy <= 'b1;
            end
		end
	end

endmodule
