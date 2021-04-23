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

//// Maybe define some localparams for command encoding ///
localparam SET_PTCH = 8'h02;
localparam SET_ROLL = 8'h03;
localparam SET_YAW = 8'h04;
localparam SET_THRST = 8'h05;
localparam SET_CAL = 8'h06;
localparam SET_EMGL = 8'h07;
localparam SET_MOFF = 8'h08;

logic [7:0] cmd2snd;
logic [15:0] data2snd;
logic result;

////////////////////////////////////////////////////////////////
// Instantiate Physical Model of Copter with Inertial sensor //
//////////////////////////////////////////////////////////////	
CycloneIV iQuad(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MISO(MISO),
                .MOSI(MOSI),.INT(INT),.frnt_ESC(frnt_ESC),.back_ESC(back_ESC),
				.left_ESC(left_ESC),.rght_ESC(rght_ESC));				  			
	 
	 
////// Instantiate DUT ////////
QuadCopter iDUT(.clk(clk),.RST_n(RST_n),.SS_n(SS_n),.SCLK(SCLK),.MOSI(MOSI),.MISO(MISO),
                .INT(INT),.RX(RX),.TX(TX),.LED(LED),.FRNT(frnt_ESC),.BCK(back_ESC),
				.LFT(left_ESC),.RGHT(rght_ESC));


//// Instantiate Master UART (mimics host commands) //////
RemoteComm iREMOTE(.clk(clk), .rst_n(RST_n), .RX(TX), .TX(RX),
                     .cmd(host_cmd), .data(data), .send_cmd(send_cmd),
					 .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
					 .resp(resp), .clr_resp_rdy(clr_resp_rdy));

initial begin
 
  /**
    Starting the clock and reseting the DUTs.
  **/
  $display("Setting the clock and reseting the DUTs!");
  clk = 0;
  RST_n = 0;
  @(negedge clk);
  RST_n = 1;

  /**
    Starting and testing the calibration of the QuadCopter.
  **/
  $display("Testing calibration of the QuadCopter!");
  cmd2snd = SET_CAL;
  data2snd = 16'hxxxx;
  chck_output_of_cmd_cfg(cmd2snd, data2snd, send_cmd, iDUT.cmd_rdy, iDUT.strt_cal, iDUT.cal_done, result);
  if(result != 1) begin
    $display("Set calibration failed! Check signals strt_cal and cal_done!");
    $Stop;
  end
  else begin
    $display("Set calibration passed! Yahoo!");
  end

  /**
    Checking ACK.
  **/
  $display("Checking ACK!");
  chck_ACK(cmd2snd, resp_rdy, resp, result);
  if(result != 1) begin
    $display("ACK failed!");
    $Stop;
  end
  else begin
    $display("ACK passed! Yahoo!");
  end
  clr_resp_rdy = 1;
  @(negedge clk);
  clr_resp_rdy = 0;

  /**
    Testing the thrusters of the QuadCopter.
  **/
  $display("Testing thrusters of the QuadCopter!");
  cmd2snd = SET_THRST;
  data2snd = 16'h00FF;
  chck_output_of_cmd_cfg(cmd2snd, data2snd, send_cmd, iDUT.cmd_rdy, iDUT.thrst, iQuad.airborne, result);
  if(result != 1) begin
    $display("Set thrust failed! Check signals thrst and airborne!");
    $Stop;
  end
  else begin
    $display("Set thrust passed! Yahoo!");
  end

  /**
    Checking ACK.
  **/
  $display("Checking ACK!");
  chck_ACK(cmd2snd, resp_rdy, resp, result);
  if(result != 1) begin
    $display("ACK failed!");
    $Stop;
  end
  else begin
    $display("ACK passed! Yahoo!");
  end
  clr_resp_rdy = 1;
  @(negedge clk);
  clr_resp_rdy = 0;

  /**
    Testing the pitch of the QuadCopter.
  **/
  $display("Testing pitch of the QuadCopter!");
  cmd2snd = SET_PTCH;
  data2snd = 16'h0100;
  chck_output_of_cmd_cfg(cmd2snd, data2snd, send_cmd, iDUT.cmd_rdy, iDUT.d_ptch, iDUT.ptch, result);
  if(result != 1) begin
    $display("Set pitch failed! Check signals d_ptch and ptch!");
    $Stop;
  end
  else begin
    $display("Set pitch passed! Yahoo!");
  end

  /**
    Checking ACK.
  **/
  $display("Checking ACK!");
  chck_ACK(cmd2snd, resp_rdy, resp, result);
  if(result != 1) begin
    $display("ACK failed!");
    $Stop;
  end
  else begin
    $display("ACK passed! Yahoo!");
  end
  clr_resp_rdy = 1;
  @(negedge clk);
  clr_resp_rdy = 0;

  /**
    Testing the roll of the QuadCopter.
  **/
  $display("Testing roll of the QuadCopter!");
  cmd2snd = SET_ROLL;
  data2snd = -16'h0080;
  chck_output_of_cmd_cfg(cmd2snd, data2snd, send_cmd, iDUT.cmd_rdy, iDUT.d_roll, iDUT.roll, result);
  if(result != 1) begin
    $display("Set roll failed! Check signals d_roll and roll!");
    $Stop;
  end
  else begin
    $display("Set roll passed! Yahoo!");
  end

  /**
    Checking ACK.
  **/
  $display("Checking ACK!");
  chck_ACK(cmd2snd, resp_rdy, resp, result);
  if(result != 1) begin
    $display("ACK failed!");
    $Stop;
  end
  else begin
    $display("ACK passed! Yahoo!");
  end
  clr_resp_rdy = 1;
  @(negedge clk);
  clr_resp_rdy = 0;

  /**
    Testing the yaw of the QuadCopter.
  **/
  $display("Testing yaw of the QuadCopter!");
  cmd2snd = SET_YAW;
  data2snd = 16'h0080;
  chck_output_of_cmd_cfg(cmd2snd, data2snd, send_cmd, iDUT.cmd_rdy, iDUT.d_yaw, iDUT.yaw, result);
  if(result != 1) begin
    $display("Set yaw failed! Check signals d_yaw and yaw!");
    $Stop;
  end
  else begin
    $display("Set yaw passed! Yahoo!");
  end

  /**
    Checking ACK.
  **/
  $display("Checking ACK!");
  chck_ACK(cmd2snd, resp_rdy, resp, result);
  if(result != 1) begin
    $display("ACK failed!");
    $Stop;
  end
  else begin
    $display("ACK passed! Yahoo!");
  end
  clr_resp_rdy = 1;
  @(negedge clk);
  clr_resp_rdy = 0;

  /**
    Testing the emergency landing of the QuadCopter.
  **/
  $display("Testing emergency landing of the QuadCopter!");
  cmd2snd = SET_EMGL;
  data2snd = 16'h0000;
  chck_output_of_cmd_cfg(cmd2snd, send_cmd, iDUT.cmd_rdy, iDUT.d_yaw, iDUT.d_roll, iDUT.d_ptch, result);
  if(result != 1) begin
    $display("Set emergency landing failed! Check signals d_yaw, d_roll and d_ptch!");
    $Stop;
  end
  else begin
    $display("Set emergency landing passed! Yahoo!");
  end

  /**
    Checking ACK.
  **/
  $display("Checking ACK!");
  chck_ACK(cmd2snd, resp_rdy, resp, result);
  if(result != 1) begin
    $display("ACK failed!");
    $Stop;
  end
  else begin
    $display("ACK passed! Yahoo!");
  end
  clr_resp_rdy = 1;
  @(negedge clk);
  clr_resp_rdy = 0;

  /**
    Testing the motor off of the QuadCopter.
  **/
  $display("Testing motor off of the QuadCopter!");
  cmd2snd = SET_MOFF;
  data2snd = 16'hxxxx;
  chck_output_of_cmd_cfg(cmd2snd, data2snd, send_cmd, iDUT.cmd_rdy, iDUT.motors_off, 0'hxxxx, result);
  if(result != 1) begin
    $display("Set motors off failed! Check signal motors_off!");
    $Stop;
  end
  else begin
    $display("Set motors_off passed! Yahoo!");
  end

  /**
    Checking ACK.
  **/
  $display("Checking ACK!");
  chck_ACK(cmd2snd, resp_rdy, resp, result);
  if(result != 1) begin
    $display("ACK failed!");
    $Stop;
  end
  else begin
    $display("ACK passed! Yahoo!");
  end
  clr_resp_rdy = 1;
  @(negedge clk);
  clr_resp_rdy = 0;
  
end

always
  #10 clk = ~clk;

/// perhaps include a tb_tasks file with helper tasks for testing.

endmodule	
