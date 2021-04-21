module ESCs(clk, rst_n, frnt_spd, bck_spd, lft_spd, rght_spd, motors_off, frnt,bck,lft,rght);
	input clk, rst_n;										// Clock and rst_n
	input motors_off;										// tells the speeds to go to zero
	input wrt;												// tells to write to ESCs
	input [10:0] frnt_spd, bck_spd, lft_spd, rght_spd;		// input speed signals
	output reg frnt, bck, lft, rght;						// output pwm signals
	
	// Set speeds to zero on motors off
	localparam ZERO = 11'h000;
	
	// intermediates
	wire [10:0] frnt_input, bck_input, lft_input, rght_input;		// go into the interface
	
	/////////////////////////////////
	// instantiations of ESC ////////
	/////////////////////////////////
	
	// frnt
	ESC_interface frnt_ESC(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(frnt_input),.PWM(frnt));
	
	// bck
	ESC_interface frnt_ESC(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(bck_input),.PWM(bck));
	
	// lft
	ESC_interface frnt_ESC(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(lft_input),.PWM(lft));
	
	// rght
	ESC_interface frnt_ESC(.clk(clk), .rst_n(rst_n), .wrt(wrt), .SPEED(rght_input),.PWM(rght));
	
	//////////////////////////////////
	////////// logic /////////////////
	//////////////////////////////////
	
	// want to assign the inputs based on motors_off
	assign frnt_input = motors_off ? ZERO : frnt_spd;
	assign bck_input = motors_off ? ZERO : bck_spd;
	assign lft_input = motors_off ? ZERO : lft_spd;
	assign rght_input = motors_off ? ZERO : rght_spd;
	
endmodule