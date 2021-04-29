module reset_synch(RST_n, rst_n, clk);
	
	input clk, RST_n;
	output reg rst_n;
	
	// Internal Signals //
	logic ff_out1;
	
	// First flop for the machine //
	always_ff @(negedge clk, negedge RST_n) begin // QUESTION: If RST_n is asynch, then the reset can be asserted on a posedge of the clock. It just always unasserts on a negedge.
		if (!RST_n)
			ff_out1 <= 1'b0;
		else
			ff_out1 <= 1'b1;
	end
	
	// Second flop //
	always_ff @(negedge clk, negedge RST_n) begin
		if (!RST_n)
			rst_n <= 1'b0;
		else
			rst_n <= ff_out1;
	end
	
endmodule