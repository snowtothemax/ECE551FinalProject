module cmd_cfg(clk, rst_n, cmd_rdy, cmd, data, clr_cmd_rdy, resp, send_resp, d_ptch, d_roll, d_yaw, thrst, strt_cal, inertial_cal, cal_done, motors_off);
	
	input clk, rst_n;							// clock and active low reset
	input cmd_rdy;								// New command is valid
	input [7:0] cmd;							// The command opcode
	input [15:0] data;							// Data that comes with the command.
	input cal_done;								// Indicates when calibration is done
	output reg clr_cmd_rdy;							// Asserted to knock down cmd_rdy after we finish the command
	output [7:0] resp;							// The response back to the remote. Typically 0xA5
	output reg send_resp;							// Asserted when a response should be sent
	output reg signed [15:0] d_ptch, d_roll, d_yaw;	// Desired pitch, roll, and yaw SIGNED numbers
	output reg [8:0] thrst;							// UNSIGNED thrust level
	output strt_cal;							// Indicates when inertial_integrator should calibrate. 1 clock pulse after 1.34 seconds motor spinup period
	output reg inertial_cal;						// High during calibration (even motor spinup). Keeps motor at cal speed
	output reg motors_off;							// Shuts off motors
	
	// Declare internal signals //
	parameter FAST_SIM = 1;
	logic [((8*FAST_SIM)+(25*!FAST_SIM)) : 0] timer;
	logic clr_tmr;			// Clears Timer
	logic tmr_en;			// Enables Timer
	// local params for command encodings
	localparam SET_PITCH = 8'h02;
	localparam SET_ROLL = 8'h03;
	localparam SET_YAW = 8'h04;
	localparam SET_THRST = 8'h05;
	localparam CALIBRATE = 8'h06;
	localparam EMER_LAND = 8'h07;
	localparam MTRS_OFF = 8'h08;
	
	// Declare internal signals //
	// signals declared for control from the SM
	logic wptch, wroll, wyaw, wthrst, mtrs_off, emergency, strt_cal;
	logic  [7:0] resp_ack;
	
	// Declare SM signals //
	typedef enum reg [2:0] {IDLE, CMD, CAL_WAIT, SEND} state_t;
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
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			timer <= 0;
		else if (clr_tmr)
			timer <= 0;
		else if (tmr_en)
			timer <= timer + 1'b1;
	end
	assign tmr_full = &(timer);
	
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
	always_comb begin
		wptch = 0;
		wroll = 0;
		wyaw = 0;
		wthrst = 0;
		mtrs_off = 0;
		clr_tmr = 0;
		emergency = 0;
		strt_cal = 0;
		resp_ack = 8'hA5;
		send_resp = 0;
		tmr_en = 1'b0;
		clr_cmd_rdy = 0;
		nxt_state = state;
		case(state)
			// wait for cmd ready in idle
			IDLE: begin
				if (cmd_rdy) begin
					clr_cmd_rdy = 1;
					nxt_state = CMD;
				end
			end
			//  switch through the opcodes of the command
			CMD: begin
				case(cmd)
					// basic states
					SET_PITCH: begin
						wptch = 1;
						nxt_state = SEND;
					end
					SET_ROLL: begin
						wroll = 1;
						nxt_state = SEND;
					end
					SET_YAW: begin
						wyaw = 1;
						nxt_state = SEND;
					end
					SET_THRST: begin
						wthrst = 1;
						nxt_state = SEND;
					end
					EMER_LAND: begin
						emergency = 1;
						nxt_state = SEND;
					end
					// assign motrs off
					MTRS_OFF: begin
						mtrs_off = 1;
						nxt_state = SEND;
					end
					// calibrate
					default: begin
						inertial_cal = 1;
						clr_tmr = 1;
						nxt_state = CAL_WAIT;
						tmr_en = 1'b1;
					end
				endcase
			end
			// wait for tmr full at first
			// Then wait for cal done
			CAL_WAIT: begin
				if(tmr_full) begin
					strt_cal = 1;
				end
				if(cal_done) begin
					nxt_state = SEND;
				end
				tmr_en = 1'b1;
			end
			// send the ack
			default: begin
				send_resp = 1'b1;
				nxt_state = IDLE;
			end
		endcase
	end
	
	// assign the resp to ack
	assign resp = resp_ack;
	
	
	// SM Controller //
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
	
endmodule