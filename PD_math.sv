module PD_math(clk, rst_n, vld, desired, actual, pterm, dterm);
	/***************************************************
	*Calculates the pterm and dterm used for PD control*
	***************************************************/

	input clk, rst_n, vld;					// 50MHz clock, active low reset, and a new inertial sensor reading is valid
	input signed [15:0] desired, actual;	// Desired inertial position, actual inertial position
	output signed [9:0] pterm;				// P of PD (signed)
	output signed [11:0] dterm;				// D of PD (signed)

	localparam D_QUEUE_DEPTH = 12; 													// controls the depth of the delay queue for the dterm math
	logic signed [16:0] err;														// The difference between the actual and desired position
	logic signed [9:0] err_sat, err_sat_asr_1, err_sat_asr_3, err_sat_pipe;			// Saturated err, the previous err term
	logic signed [6:0] D_diff_sat;													// Saturated D_diff
	logic signed [10:0] D_diff;														// The difference between the current and previous err
	logic signed [9:0] pterm_pipe;
	logic signed [11:0] dterm_pipe1, dterm_pipe2;
	genvar i; 																		// For loop iterator (Oversized since D_QUEUE_DEPTH is unknown)  ASK
	logic signed [9:0] prev_err[0:D_QUEUE_DEPTH-1];									// Holds all of the flop values in the flop buffer
	logic vld_pipe;

	localparam CONST = 5'b00111; 													// The constant term used to get dterm. 

	// Calculate the error //
	assign err = {actual[15], actual} - {desired[15], desired};
	// Saturate the error to 10 bits // 
	assign err_sat = (~err[16] & |err[15:9])    ? 10'h1FF : 
					 (err[16] & ~(&err[15:9]))  ? 10'h200 :
												err[9:0];
	// Form pterm (multiply err_sat by 5/8) //
	assign pterm = pterm_pipe;
	// Find difference in err_sat and prev_err for calculating dterm //
	assign D_diff = err_sat_pipe - prev_err[D_QUEUE_DEPTH-1];
	// Saturate D_diff to 7 bits //
	assign D_diff_sat = (~D_diff[10] & |D_diff[9:6])    ? 7'h3F : 
						(D_diff[10] & ~(&D_diff[9:6]))  ? 7'h40 :
													   D_diff[6:0];
	// Perform the signed multiply to get dterm //
	assign dterm = dterm_pipe2;

	//////////////////////////////////////////
	///////// timing flops ///////////////////
	//////////////////////////////////////////

	// flops for timing PTERM and DTERM//
	
	// this takes in the flopped values from the arithmetic shifts for err sat
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			pterm_pipe <= 10'h000;
		end
		else begin
			pterm_pipe <= err_sat_asr_1 + err_sat_asr_3;
		end
	end

	// dterm_pipe1
	// just double flop the dterm
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			dterm_pipe1 <= 12'h000;
		end
		else begin
			dterm_pipe1 <= D_diff_sat * $signed(CONST);
		end
	end

	// dterm_pipe2
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			dterm_pipe2 <= 12'h000;
		end
		else begin
			dterm_pipe2 <= dterm_pipe1;
		end
	end

	/// err_sat stuff /////

	// the flopped values of the ASR err_sat
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			err_sat_asr_1 <= 10'h000;
		end
		else begin
			err_sat_asr_1 <= (err_sat_pipe >>> 1);
		end
	end

	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			err_sat_asr_3 <= 10'h000;
		end
		else begin
			err_sat_asr_3 <= (err_sat_pipe >>> 3);
		end
	end

	// the flopped err_sat
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			err_sat_pipe <= 10'h000;
		end
		else begin
			err_sat_pipe <= err_sat;
		end
	end

	/// vld flop
	always_ff @(posedge clk, negedge rst_n) begin
		if (~rst_n) begin
			vld_pipe <= 1'b0;
		end
		else begin
			vld_pipe <= vld;
		end
	end


	/////////////////////////////////////////////////////
	/////////////////////////////////////////////////////
	/////////////////////////////////////////////////////

	// Form flop buffer //
	generate
		for (i = 0; i < D_QUEUE_DEPTH; i=i+1) begin
		   always_ff @(posedge clk, negedge rst_n) begin
		      if (!rst_n)
			     prev_err[i] <= 10'h000;
			  else if (vld_pipe) begin
			     if (i == 0)
			        prev_err[i] <= err_sat_pipe;
				 else
			        prev_err[i] <= prev_err[i-1];
			  end
		   end
		end
	endgenerate

	

endmodule