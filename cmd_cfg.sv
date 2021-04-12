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
	parameter FAST_SIM = 1;
	logic [25:0] timer;
	
	// Declare SM signals //
	typedef enum reg [2:0] {IDLE, } state_t;
	state_t state, nxt_state;
	
	// d_ptch register //
	always_ff @(posedge clk, negedge rst_n)begin
		if (~rst_n)
			d_ptch <= 16'h0;
		else if (wptch)
			d_ptch <= data;
		else if (emergency)
			d_ptch <= 16'h0;
	end
	
	// d_roll register //
	always_ff @(posedge clk, negedge rst_n)begin
		if (~rst_n)
			d_roll <= 16'h0;
		else if (wroll)
			d_roll <= data;
		else if (emergency)
			d_roll <= 16'h0;
	end
	
	// d_yaw register //
	always_ff @(posedge clk, negedge rst_n)begin
		if (~rst_n)
			d_yaw <= 16'h0;
		else if (wyaw)
			d_yaw <= data;
		else if (emergency)
			d_yaw <= 16'h0;
	end
	
	// thrst register //
	always_ff @(posedge clk, negedge rst_n)begin
		if (~rst_n)
			thrst <= 16'h0;
		else if (wthrst)
			thrst <= data;
		else if (emergency)
			thrst <= 16'h0;
	end
	
	// Variable Width Timer & timer logic //
	always_ff @(posedge clk, negedge rst_n) begin						// This works, but it's ugly and probably not how we are meant to do it
		if (~rst_n)
			timer <= 26'h0;
		else if (tmr_full)
			timer <= 26'h0;
		else
			timer <= timer + 1'b1;
	end
	assign tmr_full = FAST_SIM ? (&(timer[8:0])) : (&(timer));
	
	// Output flop //
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			motors_off <= 1'b1;
		else if (mtrs_off)
			motors_off <= 1'b1;
		else if (inertial_cal)
			motors_off <= 1'b0;
	end
	
	// SM //
	
	
	// SM Controller //
	always_ff begin
		if (~rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
	
endmodule