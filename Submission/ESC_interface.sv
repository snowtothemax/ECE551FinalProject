module ESC_interface(clk, rst_n, wrt, SPEED, PWM);

   input clk, rst_n, wrt;
   input [10:0] SPEED;
   output reg PWM;
   
   // Declare internal signals //
   logic [12:0] clk_cycles;
   logic [13:0] pulse_width;
   logic [13:0] counter; // The output to the first ff that is decremented and sent through the mux until it's zero
   logic wrt_pipe;
   logic [10:0] SPEED_pipe;

   
   // Multiply SPEED by 3 to get the clock cycles above the minimum that the PWM signal is high //
   assign clk_cycles = SPEED_pipe * 2'b11;
   
   // Add 6250 to clk_cycles because 6250 is the minimum pulse width (when speed = 0) //
   assign pulse_width = 14'h186A + clk_cycles; // the hex value is 6250 in decimal
   
   /* 
    * pulse_width goes into a mux with the select bit being wrt. When wrt is high, pulse_width is selected, otherwise
    * pulse_width - 1 is selected.
	*/
	
	// pipeline flops for meeting timing
	// wrt
	always_ff @(posedge clk, negedge rst_n) begin
		if(~rst_n) begin
			wrt_pipe <= 1'b0;
		end
		else begin
			wrt_pipe <= wrt;
		end
	end

	// speed
	always_ff @(posedge clk, negedge rst_n) begin
		if(~rst_n) begin
			SPEED_pipe <= 11'h000;
		end
		else begin
			SPEED_pipe <= SPEED;
		end
	end


	// This is the first ff combined with the mux right before it. It takes in the pulse_width and counts it down to 0 when wrt is asserted //			   
	always_ff @(posedge clk, negedge rst_n) begin
	   if (~rst_n)
	      counter <= 14'b0;
	   else if (wrt_pipe)
	      counter <= pulse_width;
	   else 
	      counter <= counter - 1;
	end
	
	// This is the second ff (Set/Reset/Hold). It controls the output of the function //
	always_ff @(posedge clk, negedge rst_n) begin
	   if (~rst_n)
	      PWM <= 1'b0;
	   else if (wrt_pipe)
	      PWM <= 1'b1;
	   else if (~|counter)
	      PWM <= 1'b0;
	end

endmodule