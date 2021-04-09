module inert_intf_test_tb();
	
	logic clk, RST_n, NEXT, MISO, INT, SS_n, SCLK, MOSI;
	logic [7:0] LED;
	
	inert_intf_test iDUT(.clk(clk), .RST_n(RST_n), .NEXT(NEXT), .MISO(MISO), .MOSI(MOSI), .INT(INT), .SCLK(SCLK), .SS_n(SS_n), .LED(LED));
	
	initial begin
		clk = 0;
		RST_n = 0;
		repeat(3) @(negedge clk);
		NEXT = 1;
		@(negedge clk);
		NEXT = 0;
		@(posedge inert_intf_test.cal_done);
		repeat(10) @(negedge clk);
		NEXT = 1;
		@(negedge clk);
		NEXT = 0;
		repeat(10) @(negedge clk);
		NEXT = 1;
		@(negedge clk);
		NEXT = 0;
		repeat(10) @(negedge clk);
		$display("DONE!");
		$stop();
	end
	
	always
		#10 clk = ~clk;
	
endmodule