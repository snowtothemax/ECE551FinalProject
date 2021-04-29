module PB_release(PB, rst_n, clk, released);
	
	input clk, rst_n, PB;
	output released;
	
	// Internal flop signals //
	logic ff_out1, ff_out2, ff_out3;
	
	// Flop 1 - Meta stability purposes //
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			ff_out1 <= 1'b1;
		else
			ff_out1 <= PB;
	end
	
	// Flop 2 - Meta stability purposes //
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			ff_out2 <= 1'b1;
		else
			ff_out2 <= ff_out1;
	end
	
	// Flop 3 - Used for posedge detect after signal is stable //
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			ff_out3 <= 1'b1;
		else
			ff_out3 <= ff_out2;
	end
	
	// Do the posedge detect //
	assign released = ff_out2 & ~ff_out3;
	
endmodule