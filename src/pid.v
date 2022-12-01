/** pid.v
 * Author: Aidan Medcalf
 * 
 * PID calculator implemented in Verilog
 */

`default_nettype none

module pid #(
    parameter BITS=8
) (
    input             reset,
    input             clk,
	input             pv_stb, // latch PV
    input  [BITS-1:0] sp,
    input  [BITS-1:0] pv,
    input  [BITS-1:0] kp,
    input  [BITS-1:0] ki,
    //input  [BITS-1:0] kd,
    output [BITS-1:0] stimulus
);

	wire signed [BITS:0] error_calc;
    reg  signed [BITS:0] error;
    //reg  signed [BITS:0] error_p;
    reg  signed [BITS:0] error_i;
	//wire signed [BITS:0] diff;
    
    wire signed [2*BITS-2:0] pacc;
    //wire signed [2*BITS:0] dacc;
    wire signed [2*BITS-2:0] iacc;
    wire signed [2*BITS:0] accumulator;

    assign error_calc = {1'b0,sp} - {1'b0,pv};
	//assign diff = error - error_p;

    //assign pacc = error * kp;
	// kp always positive, so sgn(pacc) = sgn(error)
    assign pacc[2*BITS-2] = error[BITS];
    //assign pacc[2*BITS-3:0] = { {BITS-2{1'b0}}, error[BITS-1:0] } * { {BITS{1'b0}}, kp[BITS-3:0] };
    mul #(.BITS(2*BITS-2)) pmul (
        .A({ {BITS-2{1'b0}}, error[BITS-1:0] }),
        .B({ {BITS-2{1'b0}}, kp[BITS-1:0] }),
        .O(pacc[2*BITS-3:0]));

	//assign dacc = diff * kd;
    // TODO: not this
	// kd always positive, so sgn(dacc) = sgn(diff)
	//assign dacc[2*BITS] = diff[BITS];
	//Mult_Wallace4 #(.N(BITS)) dmul (.a(diff[BITS-1:0]), .b(kd), .o(dacc[2*BITS-1:0]));

	//assign iacc = error_i * ki;
    assign iacc[2*BITS-2] = error_i[BITS];
    mul #(.BITS(2*BITS-2)) imul (
        .A({ {BITS-2{1'b0}}, error_i[BITS-1:0] }),
        .B({ {BITS-2{1'b0}}, ki[BITS-1:0] }),
        .O(iacc[2*BITS-3:0]));
	//assign iacc = { error_i[BITS], { {(BITS-1){1'b0}}, error_i[BITS-1:0] } * { {(BITS-1){1'b0}}, ki } };
    //Mult_Wallace4 #(.N(BITS)) imul (.a(error_i[BITS-1:0]), .b(ki), .o(iacc[2*BITS-1:0]));
	
	//assign accumulator = pacc - dacc + iacc;
	assign accumulator = pacc + iacc;
    // sat_add #(.BITS(2*BITS)) apadd (.A({2*BITS{1'b0}}), .B(pacc), .O(accumulator));
    assign stimulus = (reset || accumulator[2*BITS]) ? {BITS{1'b0}} : accumulator[2*BITS-1:BITS];

    always @(posedge clk) begin
		error <= error_calc;
        if (reset) begin
			//error_p <= error_calc;
            error <= 'b0;
			error_i <= 'b0;
        end else begin
			if (pv_stb) begin
                //error_p <= error;
				error_i <= error_i + error;
			end
        end
    end
endmodule

module mul #( parameter BITS=8 ) (
    input  [BITS-1:0] A,
    input  [BITS-1:0] B,
    output [BITS-1:0] O
);

    assign O = A * B;

endmodule

module sat_add #( parameter BITS=4 ) ( input [BITS-1:0] A, input [BITS-1:0] B, output [BITS-1:0] O );
    wire [BITS-1:0] sum;
    wire carry;
    assign { carry, sum } = A + B;
    assign O = carry ? ~0 : sum;
endmodule

module sat_sub #( parameter BITS=4 ) ( input [BITS-1:0] A, input [BITS-1:0] B, output [BITS-1:0] O );
    assign O = A > B ? A - B : '0;
endmodule

// taken from SO user CliffordVienna at https://stackoverflow.com/questions/16708338/how-to-design-a-64-x-64-bit-array-multiplier-in-verilog
module arrmul #( parameter WIDTH=8 ) (
    input  [WIDTH-1:0] a,
    input  [WIDTH-1:0] b,
    output [WIDTH-1:0] y
);

    wire [WIDTH*WIDTH-1:0] partials;

    genvar i;
    assign partials[WIDTH-1:0] = a[0] ? b : 'b0;
    generate for (i = 1; i < WIDTH; i = i + 1) begin:gen
        assign partials[WIDTH*(i+1)-1 : WIDTH*i] = (a[i] ? b << i : 'b0) + partials[WIDTH*i-1:WIDTH*(i-1)];
    end endgenerate

    assign y = partials[WIDTH*WIDTH-1:WIDTH*(WIDTH-1)];

endmodule
