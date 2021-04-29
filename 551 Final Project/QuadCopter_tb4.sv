`timescale 1ns/1ps
module QuadCopter_tb4();
	
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

// Maybe define some localparams for command encoding ///
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

initial begin
	//Initialize the testbench.
    init();
	//Wait for NEMO to initialize
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
	
	//Start the calibration
    $display("Testing SET_CAL");
	cmd2snd = SET_CAL;
	data2snd = 16'hxxxx;
	snd_cmd(cmd2snd, data2snd);
	check_if_cal();
	
	
	//Set the thrust
	$display("Setting Thrust");
	thrust = 16'hFF;
	snd_cmd(SET_THRST, thrust);
	
	while (iQuad.airborne !== 1)
		@(posedge clk);
		
	//Set the pitch.
	$display("Setting pitch");
	pitch = 16'h0100;
	snd_cmd(SET_PTCH, pitch);
	check_desired(SET_PTCH, pitch);

	//Set the roll.
	$display("Setting roll");
	roll = 16'hFF80;
	snd_cmd(SET_ROLL, roll);	
	check_desired(SET_ROLL,roll);

	//Set the yaw.
	$display("Setting yaw");
	yaw = 16'h0080;
	snd_cmd(SET_YAW, yaw);
	check_desired(SET_YAW,yaw);

	//Check the final values of pitch, roll and yaw. - These tasks wait for the pitch, roll, and yaw to drop to near desired value.
	check_final(SET_PTCH,pitch);
	check_final(SET_ROLL,roll);
	check_final(SET_YAW,yaw);

	//Start the emergency landing.
	$display("emergency landing starting");
	snd_cmd(SET_EMGL, 16'h0000);
	check_desired(SET_EMGL, 16'h0000);

	wait_for_landing();
	
	// Recalibrate and reset the pitch, roll, yaw just like above to test motors_off //
    $display("Testing SET_CAL");
	cmd2snd = SET_CAL;
	data2snd = 16'hxxxx;
	snd_cmd(cmd2snd, data2snd);
	check_if_cal();
	
	
	//Set the thrust
	$display("Setting Thrust");
	thrust = 16'hFF;
	snd_cmd(SET_THRST, thrust);
	
	while (iQuad.airborne !== 1)
		@(posedge clk);
		
	@(posedge iDUT.cmd_rdy);
	@(posedge resp_rdy);
	//Set the pitch.
	$display("Setting pitch");
	pitch = 16'h0100;
	snd_cmd(SET_PTCH, pitch);
	check_desired(SET_PTCH, pitch);

	//Set the roll.
	$display("Setting roll");
	roll = 16'hFF80;
	snd_cmd(SET_ROLL, roll);	
	check_desired(SET_ROLL,roll);

	//Set the yaw.
	$display("Setting yaw");
	yaw = 16'h0080;
	snd_cmd(SET_YAW, yaw);
	check_desired(SET_YAW,yaw);
	
	//Start turning the motors off.
	$display("turning motors off");
	snd_cmd(SET_MOFF, 16'h0000);
	check_desired(SET_MOFF, 16'h0000);
	
	$display("YAHOO!! We Finished 551!");
   	$stop();
	
end

always
  #10 clk = ~clk;
  
  
`include "QuadCopter_tb4_task.sv"

endmodule	

