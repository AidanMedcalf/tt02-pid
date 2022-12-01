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

    reg [BITS-1:0] buffer;
    assign out_buf = buffer;

    reg sck_last;

    always @(posedge clk) begin
        if (reset) begin
            buffer <= 'b0;
        end
		if (reset || cs) begin
            sck_last <= 'b0;
        end else begin
            sck_last <= sck;
            if (!sck && sck_last) begin // falling edge of SCK
                buffer <= { buffer[BITS-2:0], !mosi };
            end
        end
    end

endmodule
