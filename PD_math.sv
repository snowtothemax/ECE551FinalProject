module PD_math(clk, rst_n, vld, desired, actual, pterm, dterm);
	/***************************************************
	*Calculates the pterm and dterm used for PD control*
	***************************************************/

	input clk, rst_n, vld;					// 50MHz clock, active low reset, and a new inertial sensor reading is valid
	input signed [15:0] desired, actual;	// Desired inertial position, actual inertial position
	output signed [9:0] pterm;				// P of PD (signed)
	output signed [11:0] dterm;				// D of PD (signed)

	localparam D_QUEUE_DEPTH = 12; 				// controls the depth of the delay queue for the dterm math
	logic signed [16:0] err;						// The difference between the actual and desired position
	logic signed [9:0] err_sat;						// Saturated err, the previous err term
	logic signed [6:0] D_diff_sat;					// Saturated D_diff
	logic signed [10:0] D_diff;						// The difference between the current and previous err
	genvar i; 										// For loop iterator (Oversized since D_QUEUE_DEPTH is unknown)  ASK
	logic signed [9:0] prev_err[0:D_QUEUE_DEPTH-1];		// Holds all of the flop values in the flop buffer

	localparam CONST = 5'b00111; // The constant term used to get dterm. 

	// Calculate the error //
	assign err = {actual[15], actual} - {desired[15], desired};
	// Saturate the error to 10 bits // 
	assign err_sat = (~err[16] & |err[15:9])    ? 10'h1FF : 
					 (err[16] & ~(&err[15:9]))  ? 10'h200 :
												err[9:0];
	// Form pterm (multiply err_sat by 5/8) //
	assign pterm = (err_sat >>> 1) + (err_sat >>> 3);
	// Find difference in err_sat and prev_err for calculating dterm //
	assign D_diff = err_sat - prev_err[D_QUEUE_DEPTH-1];
	// Saturate D_diff to 7 bits //
	assign D_diff_sat = (~D_diff[10] & |D_diff[9:6])    ? 7'h3F : 
						(D_diff[10] & ~(&D_diff[9:6]))  ? 7'h40 :
													   D_diff[6:0];
	// Perform the signed multiply to get dterm //
	assign dterm = D_diff_sat * $signed(CONST);

	// Form flop buffer //
	generate
		for (i = 0; i < D_QUEUE_DEPTH; i=i+1) begin
		   always_ff @(posedge clk, negedge rst_n) begin
		      if (!rst_n)
			     prev_err[i] <= 10'h000;
			  else if (vld) begin
			     if (i == 0)
			        prev_err[i] <= err_sat;
				 else
			        prev_err[i] <= prev_err[i-1];
			  end
		   end
		end
	endgenerate

	

endmodule