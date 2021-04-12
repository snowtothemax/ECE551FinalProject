module inert_intf_test_tb();
	
	logic clk, RST_n, NEXT, MISO, INT, SS_n, SCLK, MOSI;
	logic [7:0] LED;
	
	inert_intf_test iDUT(.clk(clk), .RST_n(RST_n), .NEXT(NEXT), .MISO(MISO), .MOSI(MOSI), .INT(INT), .SCLK(SCLK), .SS_n(SS_n), .LED(LED));
	SPI_iNEMO2 iNEMO(.SCLK(SCLK), .SS_n(SS_n), .MOSI(MOSI), .MISO(MISO), .INT(INT));
	
	initial begin
		clk = 0;
		RST_n = 0;
		NEXT = 0;
		repeat(3) @(negedge clk);
		RST_n = 1;
		repeat(3) @(negedge clk);
		NEXT = 1;
		@(negedge clk);
		NEXT = 0;
		@(posedge iDUT.cal_done);
		force iDUT.ptch = 16'h1234;
		repeat(10) @(negedge clk);
		NEXT = 1;
		@(negedge clk);
		force iDUT.roll = 16'hABCD;
		NEXT = 0;
		repeat(10) @(negedge clk);
		NEXT = 1;
		@(negedge clk);
		force iDUT.yaw = 16'h7777;
		NEXT = 0;
		repeat(10) @(negedge clk);
		$display("DONE!");
		$stop();
		
		
	end
	
	always
		#10 clk = ~clk;
	
endmodule