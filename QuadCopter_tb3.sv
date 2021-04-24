module QuadCopter_tb3();
	
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
logic [15:0]thrust, pitch, roll, yaw;

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
    task snd_cmd;
		input logic [7:0] cmd2snd;
		input logic [15:0] data2snd;
		 
        @(negedge clk);
        host_cmd = cmd2snd;
		data = data2snd;
		send_cmd = 1;
        @(negedge clk);
		send_cmd = 0;
    endtask
	
	task init();
		clk = 0;
		RST_n = 0;
		@(negedge clk);
		RST_n = 1;
	endtask
	
	// TASK: Checks if calibration worked //
	task check_if_cal();
		$display("Testing if calibration worked...");
		@(posedge iDUT.cal_done);
		if (iDUT.frnt_spd !== 11'h290 || iDUT.bck_spd !== 11'h290 || iDUT.lft_spd !== 11'h290 || iDUT.rght_spd !== 11'h290) begin
			$display("CALIBRATION ERROR: Motor speeds are not 0x290, but instead they are %h!", iDUT.frnt_spd);
			$stop();
		end else
			$display("YAHOO!! Calibration success!");
	endtask
	
	// TASK: Checks if emergency landing worked //
	task check_em_land();
		$display("Testing if emergency landing worked");
		@(posedge resp_rdy);
		if (iDUT.frnt_spd !== 11'h000 || iDUT.bck_spd !== 11'h000 || iDUT.lft_spd !== 11'h000 || iDUT.rght_spd !== 11'h000) begin
			$display("EMERGENCY LANDING ERROR: Motor speeds are not 0! Front motor is %h", iDUT.frnt_spd);
			$stop();
		end else
			$display("YAHOO!! EMERGENCY LANDING SUCCESS!");
	endtask
		
	task check_desired;
		input [7:0]cmd2check;
		input [15:0]data2check;
		@(posedge iDUT.cmd_rdy);
		@(posedge resp_rdy);
		case(cmd2check)
			SET_PTCH: begin
				if (iDUT.d_ptch != data2check) begin
					$display("d_ptch does not match input");
					$display("input: %h, d_ptch: %h", data2check, iDUT.d_ptch);
					//$stop();
				end else 
					$display("d_ptch correct!");
			end
			SET_ROLL: begin
				if (iDUT.d_roll != data2check) begin
					$display("d_roll does not match input");
					$display("input: %h, d_roll: %h", data2check, iDUT.d_roll);
					//$stop();
				end else 
					$display("d_roll correct!");
			end
			SET_YAW: begin
				if (iDUT.d_yaw != data2check) begin
					$display("d_yaw does not match input");
					$display("input: %h, d_yaw: %h", data2check, iDUT.d_yaw);
					//$stop();
				end else 
					$display("d_yaw correct!");
			end
			SET_MOFF: begin
				if ((iQuad.spd_frnt != 16'h0000) || (iQuad.spd_back != 16'h0000) || (iQuad.spd_left != 16'h0000) || (iQuad.spd_rght != 16'h0000)) begin
					$display("motors are not off when they should be");
					$display("front: %h, back: %h, left: %h, right: %h", iQuad.spd_frnt, iQuad.spd_back, iQuad.spd_left, iQuad.spd_rght);
					//$stop();
				end else
					$display("motors stopped successfully");
			end
			SET_EMGL: begin
				if ((iDUT.d_ptch != 16'h0000) || (iDUT.d_roll != 16'h0000) || (iDUT.d_yaw != 16'h0000) || (iDUT.thrst != 8'h00)) begin
					$display("emergency land values are not zero");
					$display("d_ptch: %h, d_roll: %h, d_yaw %h, thrust: %h", iDUT.d_ptch, iDUT.d_roll, iDUT.d_yaw, iDUT.thrst);
					//$stop();
				end else
					$display("emergency land values are zero");
			end
		endcase
	endtask

	task check_final;
		input [7:0]cmd2check;
		input [15:0]data2check;
		logic [16:0]lower_val;
		logic [16:0]upper_val;
		assign lower_val = data2check - 20;
		assign upper_val = data2check + 20;
		case(cmd2check)
			SET_PTCH: begin
				if ((iDUT.ptch < lower_val) | (iDUT.ptch > upper_val)) begin
					$display("final pitch not near input");
					$display("input: %d, upper limit: %d, lower limit: %d, final: %d", data2check, upper_val, lower_val, iDUT.ptch);
					//$stop();
				end else
					$display("final pitch correct!");
			end
			SET_ROLL: begin
				if ((iDUT.roll < lower_val) | (iDUT.roll > upper_val)) begin
					$display("final roll not near input");
					$display("input: %d, upper limit: %d, lower limit: %d, final: %d", data2check, upper_val, lower_val, iDUT.roll);
					//$stop();
				end else
					$display("final roll correct!");
			end
			SET_YAW: begin
				if ((iDUT.yaw < lower_val) | (iDUT.yaw > upper_val)) begin
					$display("final yaw not near input");
					$display("input: %d, upper limit: %d, lower limit: %d, final: %d", data2check, upper_val, lower_val, iDUT.yaw);
					//$stop();
				end else
					$display("final yaw correct!");
			end
		endcase
	endtask

	task wait_for_landing();
		while (iDUT.ptch != 16'h0000) @(posedge clk);
		$display("pitch zero");
		while (iDUT.roll != 16'h0000) @(posedge clk);
		$display("roll zero");
		while (iDUT.yaw != 16'h0000) @(posedge clk);
		$display("yaw zero");
		while (iQuad.thrst != 13'h000) @(posedge clk);
		$display("quadcopter successfully landed");
	endtask

initial begin
    init();
	//SET_CAL Testing.
    $display("Testing SET_CAL");
	// Wait for NEMO to initialize //
	fork 
		begin: timeout1
			repeat(1000000) @(posedge clk);
			$display("NEMO timed out (INT)!");
			$stop;
		end
		begin
			@(posedge INT);
			disable timeout1;
		end
	join
	
	// NEMO is now ready, let's calibrate //
	cmd2snd = SET_CAL;
	data2snd = 16'hxxxx;
	snd_cmd(cmd2snd, data2snd);
	check_if_cal();
	
	
	// SET THRUST //
	$display("Setting Thrust");
	thrust = 16'hFF;
	snd_cmd(SET_THRST, thrust);
	
	while (iQuad.airborne !== 1)
		@(posedge clk);
		
	// Set ptch, roll, yaw //
	$display("Setting pitch");
	pitch = 16'h0100;
	snd_cmd(SET_PTCH, pitch);
	check_desired(SET_PTCH, pitch);
	repeat(2000000) @(posedge clk);
	$display("Setting roll");
	roll = 16'hFF80;
	snd_cmd(SET_ROLL, roll);	
	check_desired(SET_ROLL,roll);
	repeat(2000000) @(posedge clk);
	$display("Setting yaw");
	yaw = 16'h0080;
	snd_cmd(SET_YAW, yaw);
	check_desired(SET_YAW,yaw);
	repeat(2000000) @(posedge clk);
	check_final(SET_PTCH,pitch);
	check_final(SET_ROLL,roll);
	check_final(SET_YAW,yaw);
	//emergency landing
	$display("emergency landing starting");
	snd_cmd(SET_EMGL, 16'h0000);
	check_desired(SET_EMGL, 16'h0000);
	//$display("turning motors off");
	//snd_cmd(SET_MOFF, 16'h0000);
	//check_desired(SET_MOFF, 16'h0000);
	wait_for_landing();
	$display("Finished Test");
   	$stop();
	
end

always
  #10 clk = ~clk;

endmodule	

