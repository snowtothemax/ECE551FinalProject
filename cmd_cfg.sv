module cmd_cfg(clk, rst_n, cmd_rdy, cmd, data, clr_cmd_rdy, resp, send_resp, d_ptch, d_roll, d_yaw, thrst, strt_cal, inertial_cal, cal_done, motors_off);
	
	input clk, rst_n;							// clock and active low reset
	input cmd_rdy;								// New command is valid
	input [7:0] cmd;							// The command opcode
	input [15:0] data;							// Data that comes with the command.
	input cal_done;								// Indicates when calibration is done
	output clr_cmd_rdy;							// Asserted to knock down cmd_rdy after we finish the command
	output [7:0] resp;							// The response back to the remote. Typically 0xA5
	output send_resp;							// Asserted when a response should be sent
	output signed [15:0] d_ptch, d_roll, d_yaw;	// Desired pitch, roll, and yaw SIGNED numbers
	output [8:0] thrst;							// UNSIGNED thrust level
	output strt_cal;							// Indicates when inertial_integrator should calibrate. 1 clock pulse after 1.34 seconds motor spinup period
	output inertial_cal;						// High during calibration (even motor spinup). Keeps motor at cal speed
	output motors_off;							// Shuts off motors
	
	// Declare internal signals //
	
	
	// Declare SM signals //
	typedef enum reg [2:0] {IDLE, } state_t;
	state_t state, nxt_state;
	
	// d_ptch register //
	
	
	// d_roll register //
	
	
	// d_yaw register //
	
	
	// thrst register //
	
	
	// Variable Width Timer //
	
	
	// Output flop & logic //
	
	
	// SM //
	
	
	// SM Controller //
	
	
endmodule