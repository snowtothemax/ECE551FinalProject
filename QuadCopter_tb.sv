module QuadCopter_tb();
			
//// Interconnects to DUT/support defined as type wire /////
wire SS_n,SCLK,MOSI,MISO,INT;
wire RX,TX;
wire [7:0] resp;				// response from DUT
wire cmd_sent,resp_rdy;
wire frnt_ESC, back_ESC, left_ESC, rght_ESC;

////// Stimulus is declared as type reg ///////
reg clk, RST_n;
reg [7:0] host_cmd;				// command host is sending to DUT
reg [15:0] data;				// data associated with command
reg send_cmd;					// asserted to initiate sending of command
reg clr_resp_rdy;				// asserted to knock down resp_rdy

wire [7:0] LED;

logic [15:0]data2snd;
logic [7:0]cmd2snd;
logic cmd, result;

//// Maybe define some localparams for command encoding ///
    /**
        Setting the commands.
    **/

    localparam SET_PTCH = 8'h02;
    localparam SET_ROLL = 8'h03;
    localparam SET_YAW = 8'h04;
    localparam SET_THRST = 8'h05;
    localparam SET_CAL = 8'h06;
    localparam SET_EMGL = 8'h07;
    localparam SET_MOFF = 8'h08;

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
//////////////////////////////////////////////////////////////	
CycloneIV iQuad(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                .MOSI(MOSI),.INT(INT),.frnt_ESC(frnt_ESC),.back_ESC(back_ESC),
				.left_ESC(left_ESC),.rght_ESC(rght_ESC));				  			
	 
	 
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.FRNT(frnt_ESC),.BCK(back_ESC),
				.LFT(left_ESC),.RGHT(rght_ESC));


//// Instantiate Master UART (mimics host commands) //////
RemoteComm iREMOTE(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                     .cmd(host_cmd), .data(data), .send_cmd(send_cmd),
					 .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
					 .resp(resp), .clr_resp_rdy(clr_resp_rdy));

    /**
        Calling the tasks needed for the testbench.
    **/
    task chck_output_of_cmd_cfg;
		input logic [7:0] cmd2snd;
		input logic [15:0] data2snd;
		output logic result;
		 
        @(negedge clk);
        	host_cmd = cmd2snd;
		data = data2snd;
		send_cmd = 1;
        @(negedge clk);
		send_cmd = 0;
        @(posedge resp_rdy);
		result = 1;
		case(cmd2snd) 
			SET_PTCH: begin
                		if (iDUT.d_ptch != data) 
					result = 0;
			end
			SET_ROLL: begin
		   	 	if (iDUT.d_roll != data)
					result = 0;
			end
			SET_YAW: begin
		    		if (iDUT.d_yaw != data) 
					result = 0;
			end
			SET_THRST: begin
		    		if (iDUT.thrst != data) 
					result = 0;
			end
			SET_CAL: begin 
				if (iDUT.strt_cal == 1)
					result = 0;
				end
			SET_EMGL: // Make sure ptch, roll, yaw, thrst are all 0
		    		if (iDUT.d_ptch != 16'b0000) 
					result = 0;
		    		else if (iDUT.d_yaw != 16'h0000)
					result = 0;
				else if (iDUT.d_roll != 16'h0000) 
					result = 0;
		    		else if (iDUT.thrst != 16'h0000)
					result = 0;
		    	//motors off?
            		SET_MOFF : begin	// motors_off should be asserted 
		    		if (!iDUT.motors_off) 
					result = 0;
		 	end
		endcase
    endtask

initial begin
        /**
            Calling the tasks
        **/

        //SET_CAL Testing.
        $display("Testing SET_CAL");
	clk = 0;
	RST_n = 0;
	@(negedge clk);
	RST_n = 1;
        cmd2snd = SET_CAL;
        data2snd = 16'h0000;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
		@(negedge clk);
        if (result == 0) begin
            $display("SET_CAL Test Failed!");
            $stop;
        end
        else begin
            $display("SET_CAL Test Passed! YAHOO!!");
        end
	
	//@(posedge iDUT.cal_done);
        //SET_THRST Testing.
        $display("Testing SET_THRST");
        cmd2snd = SET_THRST;
        data2snd = 16'h00FF;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_THRST Test Failed!");
            $stop;
        end
        else begin
            $display("SET_THRST Test Passed! YAHOO!!");
        end

	//@(posedge iQuad.airborne);
        //SET_PTCH Testing.
        $display("Testing SET_PTCH");
        cmd2snd = SET_PTCH;
        data2snd = 16'h0100;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_PTCH Test Failed!");
            $stop;
        end
        else begin
            $display("SET_PTCH Test Passed! YAHOO!!");
        end

	repeat(2e6) @(posedge clk);
        //SET_ROLL Testing.
        $display("Testing SET_ROLL");
        cmd2snd = SET_ROLL;
        data2snd = -16'h0080;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_ROLL Test Failed!");
            $stop;
        end
        else begin
            $display("SET_ROLL Test Passed! YAHOO!!");
        end

	repeat(2e6) @(posedge clk);

        //SET_YAW Testing.
        $display("Testing SET_YAW");
        cmd2snd = SET_YAW;
        data2snd = 16'h0080;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_YAW Test Failed!");
            $stop;
        end
        else begin
            $display("SET_YAW Test Passed! YAHOO!!");
        end

	repeat(2e6) @(posedge clk);

        //SET_EMGL Testing.
        $display("Testing SET_EMGL");
        cmd2snd = SET_EMGL;
        data2snd = 16'h0000;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_EMGL Test Failed!");
            $stop;
        end
        else begin
            $display("SET_EMGL Test Passed! YAHOO!!");
        end

        //SET_EMGL Testing.
        $display("Testing SET_MOFF");
        cmd2snd = SET_MOFF;
        data2snd = 16'h0000;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_MOFF Test Failed!");
            $stop;
        end
        else begin
            $display("SET_MOFF Test Passed! YAHOO!!");
        end

        $display("All Tests Passed! YAHOO!!!!");
        $stop;
end

always
  #10 clk = ~clk;

/// perhaps include a tb_tasks file with helper tasks for testing.

endmodule	
