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
	cmd2snd = SET_THRST;
	data2snd = 9'hFF;
	snd_cmd(cmd2snd, data2snd);
	while (iQuad.airborne !== 1)
		@(posedge clk);
	
	
	/* // Knock down thrust by testing emergency landing //
	cmd2snd = SET_EMGL;
	data2snd = 16'h0000;
	snd_cmd(cmd2snd, data2snd);
	check_em_land(); */
	
	
	// Set ptch, roll, yaw //
	$display("Setting pitch");
	cmd2snd = SET_PTCH;
	data2snd = 16'h0100;
	snd_cmd(cmd2snd, data2snd);
	repeat(2000000) @(posedge clk);
	$display("Setting roll");
	cmd2snd = SET_ROLL;
	data2snd = 16'hFF80;
	snd_cmd(cmd2snd, data2snd);
	repeat(2000000) @(posedge clk);
	$display("Setting yaw");
	cmd2snd = SET_YAW;
	data2snd = 16'h0080;
	snd_cmd(cmd2snd, data2snd);
	repeat(2000000) @(posedge clk);
	$display("Finished Testing");
	$stop();
	
end

always
  #10 clk = ~clk;

endmodule	
