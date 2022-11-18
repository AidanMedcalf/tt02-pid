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
    //output                done,
	output [BITS-1:0] out_buf
);

// TODO: transaction reset timer

	localparam BCBITS = $clog2(BITS);
	reg [BCBITS-1:0] bi; // bit index
	
	wire [BCBITS-1:0] bi_next;
	assign bi_next = bi + 'b1;

    reg [BITS-1:0] buffer;
    assign out_buf = buffer;

    reg busy;
    //reg last_busy;
    //assign done = !busy && last_busy;
	wire bit_out;
    assign bit_out = reset ? 1'b0 : !mosi;

    reg sck_last;

    always @(posedge clk) begin
        if (reset) begin
            buffer <= 'b0;
        end
		if (reset || cs) begin
            //last_busy <= 'b0;
			busy <= 'b0;
			bi <= 'b0;
            sck_last <= 'b0;
        end else begin
            //last_busy <= busy;
            sck_last <= sck;
            if (!sck && sck_last) begin // falling edge of SCK
                buffer <= { buffer[BITS-2:0], bit_out };
                bi <= bi_next;
                busy <= !busy || bi_next != 'b0;
            end
        end
    end

endmodule
