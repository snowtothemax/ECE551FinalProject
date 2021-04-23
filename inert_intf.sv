module inert_intf(clk, rst_n, strt_cal, INT, cal_done, vld, ptch, roll, yaw, SS_n, SCLK, MOSI, MISO);
	
	input clk, rst_n, strt_cal;				// 50 MHz clock, active low reset, and a signal that is high when calibration should begin
	input INT; 								// INT pin from inertial sensor. High when a new measurement is ready
	input MISO;
	output cal_done;						// high when calibration completed
	output reg vld;							// Asserted from SM when output is valid
	output signed [15:0] ptch, roll, yaw;	// Fusion corrected pitch, roll, and yaw
	output SS_n, SCLK, MOSI;				// SPI interface to inertial sensor
	
	parameter FAST_SIM = 1;					// used to accelerate simulation
	
	// Declare Internal Signals //
	logic wrt, done; 										// Write and done signals for the SPI
	logic waiting; 											// High when in the INIT1 state, where we have to wait for a 16-bit timer before moving on
	logic INT_ff1, INT_ff2; 								// Single and double flopped versions of INT
	logic [15:0] cmd, inert_data;							// The data to write and data to read (only 7:0 are valid for inert_data)
	logic signed [15:0] ptch_rt, roll_rt, yaw_rt, ax, ay; 	// All 16-bit registers used by the inertial integrator
	logic [15:0] timer; 									// 16-bit timer
	
	// Instantiate the SPI and Inertial integrator //
	SPI_mnrch iSPI(.clk(clk), .rst_n(rst_n), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO), .wrt(wrt), .wt_data(cmd), .done(done), .rd_data(inert_data));
	
	inertial_integrator #(FAST_SIM) iINT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .cal_done(cal_done), .vld(vld), .ptch_rt(ptch_rt), .roll_rt(roll_rt), .yaw_rt(yaw_rt), .ax(ax), 
							 .ay(ay), .ptch(ptch), .roll(roll), .yaw(yaw));
	
	// State Capture Signals //
	logic C_PH, C_PL, C_RH, C_RL, C_YH, C_YL, C_AXH, C_AXL, C_AYH, C_AYL, C_VLD;	// Capture <signal name> high/low
	
	// States //
	typedef enum reg [3:0] {INIT1, INIT2, INIT3, INIT4, READ, PL, PH, RL, RH, YL, YH, AXL, AXH, AYL, AYH} state_t;
	state_t state, nxt_state;
	
	// Controls the timer when initializing //
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			timer <= 16'h0000;
		else if (waiting)
			timer <= timer + 1;
	end
	
	// Double flop INT for stability purposes //
	always_ff @(posedge clk)
		INT_ff1 <= INT;
	always_ff @(posedge clk)
		INT_ff2 <= INT_ff1;
	
	// State Machine //
	always_comb begin
		nxt_state = state;
			waiting = 0;
			wrt = 0;
			C_PL = 0; C_PH = 0; C_RL = 0; C_RH = 0; C_YL = 0; C_YH = 0; C_AXL = 0; C_AXH = 0; C_AYL = 0; C_AYH = 0; C_VLD = 0;
		case(state)
			// Defaults //
			// cmd wasn't defaulted since it was assigned in each state, including the default. //
			
			INIT1 : begin
				if (&timer) begin
					nxt_state = INIT2;
					wrt = 1;
				end
				waiting = 1;
				cmd = 16'h0D02;
				end
			INIT2 : begin
				if (done) begin
					nxt_state = INIT3;
					wrt = 1;
				end
				cmd = 16'h1062;
				end
			INIT3 : begin
				if (done) begin
					nxt_state = INIT4;
					wrt = 1;
				end
				cmd = 16'h1162;
				end
			INIT4 : begin
				if (done) begin
					nxt_state = READ;
					wrt = 1;
				end
				cmd = 16'h1460;
				end
			READ : begin// Begin reading data
				if (INT_ff2) begin
					nxt_state = PL;
					wrt = 1;
				end
				cmd = 16'hA2xx;
				end
			PL : begin// Read lower bit of pitch
				if (done) begin
					nxt_state = PH;
					wrt = 1;
					C_PL = 1;
				end
				cmd = 16'hA3xx;
				end
			PH : begin// Read upper bit of pitch
				if (done) begin
					nxt_state = RL;
					wrt = 1;
					C_PH = 1;
				end
				cmd = 16'hA4xx;
				end
			RL : begin// Read lower bit of roll
				if (done) begin
					nxt_state = RH;
					wrt = 1;
					C_RL = 1;
				end
				cmd = 16'hA5xx;
				end
			RH : begin// Read upper bit of roll
				if (done) begin
					nxt_state = YL;
					wrt = 1;
					C_RH = 1;
				end
				cmd = 16'hA6xx;
				end
			YL : begin// Read lower bit of yaw
				if (done) begin
					nxt_state = YH;
					wrt = 1;
					C_YL = 1;
				end
				cmd = 16'hA7xx;
				end
			YH : begin// Read upper bit of yaw
				if (done) begin
					nxt_state = AXL;
					wrt = 1;
					C_YH = 1;
				end
				cmd = 16'hA8xx;
				end
			AXL : begin// Read lower bit of AX
				if (done) begin
					nxt_state = AXH;
					wrt = 1;
					C_AXL = 1;
				end
				cmd = 16'hA9xx;
				end
			AXH : begin// Read upper bit of AX
				if (done) begin
					nxt_state = AYL;
					wrt = 1;
					C_AXH = 1;
				end
				cmd = 16'hAAxx;
				end
			AYL : begin// Read lower bit of AY
				if (done) begin
					nxt_state = AYH;
					wrt = 1;
					C_AYL = 1;
				end
				cmd = 16'hABxx;
				end
			default : begin// Read upper bit of AY (AYH state)
				if (done) begin
					nxt_state = READ;
					C_AYH = 1;
					C_VLD = 1;
				end
				cmd = 16'hA2xx; // Reset cmd back to prepare for the next read. This isn't necessarily needed, but without this line cmd would have to be defaulted
				end
		endcase
	end
	
	// When the corresponding assertion takes place, store the valid part of inert_data in the appropriate register //
	always_ff @(posedge clk)
		if (C_PL)
			ptch_rt[7:0] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_PH)
			ptch_rt[15:8] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_RL)
			roll_rt[7:0] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_RH)
			roll_rt[15:8] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_YL)
			yaw_rt[7:0] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_YH)
			yaw_rt[15:8] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_AXL)
			ax[7:0] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_AXH)
			ax[15:8] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_AYL)
			ay[7:0] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_AYH)
			ay[15:8] <= inert_data[7:0];
	always_ff @(posedge clk)
		if (C_VLD)
			vld <= 1;
		else
			vld <= 0;
	
	// State flop //
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n)
			state = INIT1;
		else
			state = nxt_state;
	end
endmodule