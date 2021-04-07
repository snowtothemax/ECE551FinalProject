module inert_intf_tb();
	
	// Define Logic //
	logic clk, rst_n;					// Clock & active low reset
	logic strt_cal, cal_done;			// Start calibration signal and cal finished signal
	logic INT;							// INT pin from inertial sensor. High when a new measurement is ready
	logic vld;							// High when output from inert_inf is valid
	logic signed [15:0] ptch, roll, yaw;// Fusion Corrected Pitch, Roll, and Yaw values
	logic SS_n, SCLK, MOSI, MISO;		// SPI Signals
	
	// Instantiate DUTs //
	inert_inf   iDUT(.clk(clk), .rst_n(rst_n), .strt_cal(strt_cal), .INT(INT), .cal_done(cal_done), .vld(vld), 
				     .ptch(ptch), .roll(roll), .yaw(yaw), .SS_n(SS_n), .SCLK(SCLK), .MOSI(MOSI), .MISO(MISO));
	SPI_iNEMO2 iNEMO(.SS_n(SS_n), .SCLK(SCLK), .MISO(MISO), .MOSI(MOSI), .INT(INT));
	
	// Test the DUT //
	initial begin
		// Reset the DUT - Don't Assert start_cal yet! //
		rst_n = 0;
		clk = 0;
		// Wait for NEMO setup using the fork/join technique where we wait for _ to assert otherwise timeout //
		
		// Assert strt_cal //
		
		// Wait for cal_done - timeout loop should be ~1mil clk cycles //
		
		// Let it run for like 8mil clock cycles and plot ptch, roll, yaw in ModelSim as an analog signal to observe waveform //
		
	end
	
	
	
	// Controls the clock //
	always_ff
		#10 clk = ~clk;
	
endmodule