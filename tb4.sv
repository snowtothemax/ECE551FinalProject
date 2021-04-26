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
		@(posedge resp_rdy);
    endtask
	
	task init();
		clk = 0;
		RST_n = 0;
		@(negedge clk);
		RST_n = 1;
	endtask

initial begin
    init();
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
	$display("Calibrating");
	cmd2snd = SET_CAL;
	data2snd = 16'hxxxx;
	snd_cmd(cmd2snd, data2snd);
	
	
	// SET THRUST //
	$display("Setting Thrust");
	thrust = 16'hFF;
	snd_cmd(SET_THRST, thrust);
	
		
	// Set ptch, roll, yaw //
	$display("Setting pitch");
	pitch = 16'h0100;
	snd_cmd(SET_PTCH, pitch);
	if (resp !== 8'hA5) begin
		$display("ERROR: ACK not received! Received ack was %h", resp);
		$stop();
	end
	repeat(2000000) @(posedge clk); // Wait a bit for no particular reason other than to let pitch change
	$display("Setting roll");
	roll = 16'hFF80;
	snd_cmd(SET_ROLL, roll);	
	if (resp !== 8'hA5) begin
		$display("ERROR: ACK not received! Received ack was %h", resp);
		$stop();
	end
	repeat(2000000) @(posedge clk); // Wait again - this time for roll (pitch might still be adjusting at this point)
	$display("Setting yaw");
	yaw = 16'h0080;
	snd_cmd(SET_YAW, yaw);
	if (resp !== 8'hA5) begin
		$display("ERROR: ACK not received! Received ack was %h", resp);
		$stop();
	end
	repeat(2000000) @(posedge clk); // Wait
	
	// Emergency landing //
	$display("emergency landing starting");
	snd_cmd(SET_EMGL, 16'h0000);
	if (resp !== 8'hA5) begin
		$display("ERROR: ACK not received! Received ack was %h", resp);
		$stop();
	end
	repeat(2000000) @(posedge clk); // Let the motors idle down
	
	// We could set it all back up again to test motors_off, but since we have shown that the ack is working at this point in the testbench //
	$display("Finished Test");
   	$stop();
	
end

always
  #10 clk = ~clk;

endmodule	

