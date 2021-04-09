module inert_intf_test(clk, RST_n, NEXT, LED, SS_n, MOSI, MISO, SCLK, INT);
	
	input clk;					// 50MHz Clock
	input RST_n;				// Unsynchronized active low reset
	input NEXT;					// Initiates calibration and advances sel[1:0] to display the next value of ptch, roll, yaw on the LEDs
	input MISO, INT;			// SPI Signals
	output reg [7:0] LED;		// Flopped upper 8 bits of conversion results. Flopped when cnv_cmplt
	output SS_n, SCLK, MOSI;	// SPI signals
	
	// Declare Internal Signals //
	logic rst_n;							// Active low reset synchronized to our clock
	logic next;								// The result of the posedge detect in PB_release
	logic [1:0] sel;						// Controls the 4:1 mux that sets the LEDs
	logic signed [15:0] ptch, roll, yaw; 	// ptch, roll, and yaw from inert_intf
	logic strt_cal, cal_done;				// Calibration signals
	logic stat;								// High when calibrating - controls 1 LED during that phase
	
	// Connect PB_release, reset_synch, and inert_intf //
	reset_synch iSYNC(.clk(clk), .RST_n(RST_n), .rst_n(rst_n));
	
	PB_release iPB(.clk(clk), .rst_n(rst_n), .PB(NEXT), .released(next));
	
	inert_intf iINTF(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .MOSI(MOSI), .MISO(MISO), .SCLK(SCLK), .SS_n(SS_n), 
					 .INT(INT), .cal_done(cal_done), .vld(), .ptch(ptch), .roll(roll), .yaw(yaw));
	
	// SM Signals //
	typedef enum reg [2:0] {IDLE, WAIT, PTCH, ROLL, YAW} state_t;
	state_t state, nxt_state;
	
	localparam ptch_sel = 2'b01;
	localparam roll_sel = 2'b10;
	localparam yaw_sel  = 2'b11;
	
	// State controller flop //
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			state <= IDLE;
		else
			state <= nxt_state;
	end
	
	// SM //
	always_comb begin
		// Assign defaults //
		nxt_state = state;
		strt_cal = 1'b0;
		stat = 1'b0;
		sel = 2'b00;
		case(state)
			IDLE : begin
				if (next) begin
					nxt_state = WAIT;
					strt_cal = 1'b1;
				end
			end
			WAIT : begin // The DISP state
				if (cal_done)
					nxt_state = PTCH;
				stat = 1;
			end
			PTCH : begin
				if (next)
					nxt_state = ROLL;
				sel = ptch_sel;
			end
			ROLL : begin
				if (next)
					nxt_state = YAW;
				sel = roll_sel;
			end
			default : begin // YAW state
				if (next)
					nxt_state = PTCH;
				sel = yaw_sel;
			end
		endcase
	end
	
	// MUX that controls the LEDs //
	always_comb begin					// QUESTION: Does this synthesize how I'd expect it to? (4:1 mux)
		unique if (sel === 2'b00)
			LED = {7'b0, stat};
		else if (sel === ptch_sel)
			LED = ptch[8:1];
		else if (sel === roll_sel)
			LED = roll[8:1];
		else
			LED = yaw[8:1];
	end
	
endmodule