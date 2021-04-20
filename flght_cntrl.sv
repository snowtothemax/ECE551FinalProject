module flght_cntrl(clk,rst_n,vld,inertial_cal,d_ptch,d_roll,d_yaw,ptch,
					roll,yaw,thrst,frnt_spd,bck_spd,lft_spd,rght_spd);
				
input clk,rst_n;
input vld;									// tells when a new valid inertial reading ready
											// only update D_QUEUE on vld readings
input inertial_cal;							// need to run motors at CAL_SPEED during inertial calibration
input signed [15:0] d_ptch,d_roll,d_yaw;	// desired pitch roll and yaw (from cmd_cfg)
input signed [15:0] ptch,roll,yaw;			// actual pitch roll and yaw (from inertial interface)
input [8:0] thrst;							// thrust level from slider
output reg [10:0] frnt_spd;						// 11-bit unsigned speed at which to run front motor
output reg [10:0] bck_spd;						// 11-bit unsigned speed at which to back front motor
output reg [10:0] lft_spd;						// 11-bit unsigned speed at which to left front motor
output reg [10:0] rght_spd;						// 11-bit unsigned speed at which to right front motor


  //////////////////////////////////////////////////////
  // You will need a bunch of interal wires declared //
  // for intermediate math results...do that here   //
  ///////////////////////////////////////////////////
  logic [9:0] ptch_pterm, roll_pterm, yaw_pterm;
  logic [10:0] frnt_spd_sat, bck_spd_sat, lft_spd_sat, rght_spd_sat;
  logic [11:0] ptch_dterm, roll_dterm, yaw_dterm;
  logic [12:0] frnt_spd_ext, bck_spd_ext, lft_spd_ext, rght_spd_ext;
  logic [12:0] thrst_ext; 
  logic signed [12:0] ptch_dterm_ext, ptch_pterm_ext, yaw_pterm_ext, yaw_dterm_ext, roll_dterm_ext, roll_pterm_ext;

  ///////////////////////////////////////////////////////////////
  // some Parameters to keep things more generic and flexible //
  /////////////////////////////////////////////////////////////
  localparam CAL_SPEED = 11'h290;		// speed to run motors at during inertial calibration
  localparam MIN_RUN_SPEED = 13'h2C0;	// minimum speed while running  
  localparam D_COEFF = 5'b00111;		// D coefficient in PID control = +7
  
  //////////////////////////////////////
  // Instantiate 3 copies of PD_math //
  ////////////////////////////////////
  PD_math iPTCH(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_ptch),.actual(ptch),.pterm(ptch_pterm),.dterm(ptch_dterm));
  PD_math iROLL(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_roll),.actual(roll),.pterm(roll_pterm),.dterm(roll_dterm));
  PD_math iYAW(.clk(clk),.rst_n(rst_n),.vld(vld),.desired(d_yaw),.actual(yaw),.pterm(yaw_pterm),.dterm(yaw_dterm));  
  
  /////////////////////////////////////////////////////////////
  // Sign extend all variables to 13-bits to avoid overflow //
  ///////////////////////////////////////////////////////////
  
  assign thrst_ext = {4'b0000, thrst[8:0]};
  assign ptch_pterm_ext = {{3{ptch_pterm[9]}}, ptch_pterm[9:0]};
  assign ptch_dterm_ext = {ptch_dterm[11], ptch_dterm[11:0]};
  assign roll_pterm_ext = {{3{roll_pterm[9]}}, roll_pterm[9:0]};
  assign roll_dterm_ext = {roll_dterm[11], roll_dterm[11:0]};
  assign yaw_pterm_ext = {{3{yaw_pterm[9]}}, yaw_pterm[9:0]};
  assign yaw_dterm_ext = {yaw_dterm[11], yaw_dterm[11:0]};
  
  //////////////////////////////////////////
  // Calculate the engine speed required //
  ////////////////////////////////////////
  
  assign frnt_spd_ext = MIN_RUN_SPEED + thrst_ext - ptch_dterm_ext - ptch_pterm_ext - yaw_dterm_ext - yaw_pterm_ext;
  assign bck_spd_ext  = MIN_RUN_SPEED + thrst_ext + ptch_dterm_ext + ptch_pterm_ext - yaw_dterm_ext - yaw_pterm_ext;
  assign lft_spd_ext  = MIN_RUN_SPEED + thrst_ext - roll_dterm_ext - roll_pterm_ext + yaw_dterm_ext + yaw_pterm_ext;
  assign rght_spd_ext = MIN_RUN_SPEED + thrst_ext + roll_dterm_ext + roll_pterm_ext + yaw_dterm_ext + yaw_pterm_ext;
  
  ///////////////////////////////////////////////////////
  // Saturate the engine speeds to 11 bits (unsigned) //
  // because we only have an 11-bit ESC control      //
  ////////////////////////////////////////////////////  
  
  assign frnt_spd_sat = (|frnt_spd_ext[12:11]) ? 11'h7FF :
											 frnt_spd_ext[10:0];
  assign bck_spd_sat  = (|bck_spd_ext[12:11])  ? 11'h7FF :
											 bck_spd_ext[10:0];
  assign lft_spd_sat  = (|lft_spd_ext[12:11])  ? 11'h7FF :
											 lft_spd_ext[10:0];
  assign rght_spd_sat = (|rght_spd_ext[12:11]) ? 11'h7FF :
											 rght_spd_ext[10:0];
  
  //////////////////////////////////////////////////////////////////////////////////
  // Set the engine speed output to either the CAL_SPEED or desired engine speed //
  ////////////////////////////////////////////////////////////////////////////////
  
  // Front //
  assign frnt_spd = inertial_cal ? CAL_SPEED :
								   frnt_spd_sat;
  // Back //
  assign bck_spd  = inertial_cal ? CAL_SPEED :
								   bck_spd_sat;
  // Left //
  assign lft_spd  = inertial_cal ? CAL_SPEED :
								   lft_spd_sat;
  // Right //
  assign rght_spd = inertial_cal ? CAL_SPEED :
								   rght_spd_sat;
  
endmodule 
