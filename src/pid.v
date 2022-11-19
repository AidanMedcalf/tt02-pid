/** pid.v
 * Author: Aidan Medcalf
 * 
 * PID calculator implemented in Verilog
 */

`default_nettype none

module pid #(
    parameter BITS=4
) (
    input             reset,
    input             clk,
	input             pv_stb, // latch PV
    input  [BITS-1:0] sp,
    input  [BITS-1:0] pv,
    input  [BITS-1:0] kp,
    input  [BITS-1:0] ki,
    input  [BITS-1:0] kd,
    output [BITS-1:0] stimulus
);

	wire signed [BITS:0] error_calc;
    reg  signed [BITS:0] error;
    //reg  signed [BITS:0] error_p;
    reg  signed [BITS:0] error_i;
	//wire signed [BITS:0] diff;
    
    wire signed [2*BITS:0] pacc;
    //wire signed [2*BITS:0] dacc;
    wire signed [2*BITS:0] iacc;
    wire signed [2*BITS:0] accumulator;

    assign error_calc = {1'b0,sp} - {1'b0,pv};
	//assign diff = error - error_p;

    //assign pacc = error * kp;
	// kp always positive, so sgn(pacc) = sgn(error)
	assign pacc[2*BITS] = error[BITS];
	Mult_Wallace4 #(.N(BITS)) pmul (.a(error[BITS-1:0]), .b(kp), .o(pacc[2*BITS-1:0]));

	//assign dacc = diff * kd;
    // TODO: not this
	// kd always positive, so sgn(dacc) = sgn(diff)
	//assign dacc[2*BITS] = diff[BITS];
	//Mult_Wallace4 #(.N(BITS)) dmul (.a(diff[BITS-1:0]), .b(kd), .o(dacc[2*BITS-1:0]));

	//assign iacc = error_i * ki;
    assign iacc[2*BITS] = error_i[BITS];
    Mult_Wallace4 #(.N(BITS)) imul (.a(error_i[BITS-1:0]), .b(ki), .o(iacc[2*BITS-1:0]));
	
	//assign accumulator = pacc - dacc + iacc;
	assign accumulator = pacc + iacc;
    // sat_add #(.BITS(2*BITS)) apadd (.A({2*BITS{1'b0}}), .B(pacc), .O(accumulator));
    assign stimulus = (reset || accumulator[2*BITS]) ? {2*BITS{1'b0}} : accumulator[2*BITS-1:BITS];

    always @(posedge clk) begin
		error <= error_calc;
        if (reset) begin
			//error_p <= error_calc;
			error_i <= 'b0;
        end else begin
			if (pv_stb) begin
                //error_p <= error;
				error_i <= error_i + error;
			end
        end
    end
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

// Below from GuzTech's TT 4x4 multiplier
// https://github.com/GuzTech/tinytapeout-4x4-multiplier

// Unsigned 4x4-bit multiplier with
// Wallace tree reduction. Generated
// with my own tool.
module Mult_Wallace4 # (
    parameter N = 4
)(
    input  wire [N-1:0] a,
    input  wire [N-1:0] b,
    output wire [2*N-1:0] o
);

    wire [N-1:0] ppts[N-1:0];

    assign ppts[0][0] = a[0] & b[0];
    assign ppts[0][1] = a[0] & b[1];
    assign ppts[0][2] = a[0] & b[2];
    assign ppts[0][3] = a[0] & b[3];
    assign ppts[1][0] = a[1] & b[0];
    assign ppts[1][1] = a[1] & b[1];
    assign ppts[1][2] = a[1] & b[2];
    assign ppts[1][3] = a[1] & b[3];
    assign ppts[2][0] = a[2] & b[0];
    assign ppts[2][1] = a[2] & b[1];
    assign ppts[2][2] = a[2] & b[2];
    assign ppts[2][3] = a[2] & b[3];
    assign ppts[3][0] = a[3] & b[0];
    assign ppts[3][1] = a[3] & b[1];
    assign ppts[3][2] = a[3] & b[2];
    assign ppts[3][3] = a[3] & b[3];

    wire [11:0] s;
    wire [11:0] cout;

    ha HA1 (.a(ppts[0][1]), .b(ppts[1][0]), .s(s[0]), .cout(cout[0]));
    fa FA2 (.a(ppts[0][2]), .b(ppts[1][1]), .cin(ppts[2][0]), .s(s[1]), .cout(cout[1]));
    fa FA3 (.a(ppts[0][3]), .b(ppts[1][2]), .cin(ppts[2][1]), .s(s[2]), .cout(cout[2]));
    ha HA4 (.a(ppts[1][3]), .b(ppts[2][2]), .s(s[3]), .cout(cout[3]));
    ha HA5 (.a(cout[0]), .b(s[1]), .s(s[4]), .cout(cout[4]));
    fa FA6 (.a(ppts[3][0]), .b(cout[1]), .cin(s[2]), .s(s[5]), .cout(cout[5]));
    fa FA7 (.a(ppts[3][1]), .b(cout[2]), .cin(s[3]), .s(s[6]), .cout(cout[6]));
    fa FA8 (.a(ppts[2][3]), .b(ppts[3][2]), .cin(cout[3]), .s(s[7]), .cout(cout[7]));
    ha HA9 (.a(cout[4]), .b(s[5]), .s(s[8]), .cout(cout[8]));
    fa FA10 (.a(cout[5]), .b(s[6]), .cin(cout[8]), .s(s[9]), .cout(cout[9]));
    fa FA11 (.a(cout[6]), .b(s[7]), .cin(cout[9]), .s(s[10]), .cout(cout[10]));
    fa FA12 (.a(ppts[3][3]), .b(cout[7]), .cin(cout[10]), .s(s[11]), .cout(cout[11]));

    assign o[7] = cout[11];
    assign o[6] = s[11];
    assign o[5] = s[10];
    assign o[4] = s[9];
    assign o[3] = s[8];
    assign o[2] = s[4];
    assign o[1] = s[0];
    assign o[0] = ppts[0][0];
endmodule

// Full adder
module fa (
    input  wire a,
    input  wire b,
    input  wire cin,
    output wire s,
    output wire cout
);

/*
 * Local signals
 */
    // wire int_a_xor_b;
    // wire int_a_and_b;
    // wire int_a_xor_b_and_cin;
/*
 * Logic
 */

    // Implement a full adder with individual gates.
    // assign int_a_xor_b         = a ^ b;
    // assign int_a_and_b         = a & b;
    // assign int_a_xor_b_and_cin = int_a_xor_b & cin;
    // assign s                   = int_a_xor_b ^ cin;
    // assign cout                = int_a_xor_b_and_cin | int_a_and_b;

    // Instantiate a full adder cell from the
    // standard cell library.
    // sky130_fd_sc_hd__fah inst_fa (
    //     .A   (a),
    //     .B   (b),
    //     .CI  (cin),
    //     .SUM (s),
    //     .COUT(cout)
    // );

    // Infer a full adder.
    assign {cout, s} = a + b + cin;
endmodule

// Half adder
module ha (
    input  wire a,
    input  wire b,
    output wire s,
    output wire cout
);

/*
 * Logic
 */

    // Implement a half adder with individual gates.
    // assign s    = a ^ b;
    // assign cout = a & b;

    // Instantiate a half adder cell from the
    // standard cell library.
    // sky130_fd_sc_hd__ha inst_ha (
    //     .A   (a),
    //     .B   (b),
    //     .SUM (s),
    //     .COUT(cout)
    // );

    // Infer a half adder.
    assign {cout, s} = a + b;
endmodule
