`timescale 1ns/1ps
module RemoteComm(clk, rst_n, RX, TX, cmd, data, send_cmd, cmd_sent, resp_rdy, resp, clr_resp_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_cmd;			// indicates to tranmit 24-bit command (cmd)
	input [7:0] cmd;		// 8-bit command to send
	input [15:0] data;		// 16-bit data that accompanies command
	input clr_resp_rdy;		// asserted in test bench to knock down resp_rdy

	output TX;				// serial data output
	output reg cmd_sent;	// indicates transmission of command complete
	output resp_rdy;		// indicates 8-bit response has been received
	output [7:0] resp;		// 8-bit response from DUT

	////////////////////////////////////////////////////
	// Declare any needed internal signals/registers //
	// below including state definitions            //
	/////////////////////////////////////////////////
	
	logic trmt;
	logic [1:0] sel;
	logic [7:0] data1, data2, tx_data;
	localparam FRST_DAT = 2'b00;
	localparam SCND_DAT = 2'b01;
	
	typedef enum reg [1:0] {INIT, TRNS_CMD, BYTE_ONE, BYTE_TWO} state_t;
	state_t state, nxt_state;
	
	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(tx_data), .trmt(trmt),
			   .tx_done(tx_done), .rx_data(resp), .rx_rdy(resp_rdy), .clr_rx_rdy(clr_resp_rdy));
		   
	/////////////////////////////////
	// Implement RemoteComm Below //
	///////////////////////////////

	// FF to hold the first byte of data //
	always_ff @(posedge clk)
	   if (send_cmd)
	      data1 <= data[15:8];
	
	// FF to hold the second byte of data //
	always_ff @(posedge clk)
	   if (send_cmd)
	      data2 <= data[7:0];
	
	// Assign tx_data to what is meant to be sent //
	assign tx_data = (sel == FRST_DAT) ? data1 :
					 (sel == SCND_DAT) ? data2 :
										 cmd;
	
	// State controller //
	always_ff @(posedge clk, negedge rst_n) begin
	   if (~rst_n)
	      state <= INIT;
	   else
	      state <= nxt_state;
	end
	
	// State machine //
	always_comb begin
	   // Set Defaults //
	   nxt_state = state;
	   trmt = 1'b0;
	   cmd_sent = 1'b0;
	   sel = 2'b00;
	   // States //
	   case (state)
	      INIT: 
		     if (send_cmd) begin
			    sel = 2'b10;
				trmt = 1'b1;
				nxt_state = TRNS_CMD;
			 end
		  TRNS_CMD: 
		     if (tx_done) begin
			    sel = 2'b00;
				trmt = 1'b1;
				nxt_state = BYTE_ONE;
			 end
		  BYTE_ONE:
		     if (tx_done) begin
			    sel = 2'b01;
				trmt = 1'b1;
				nxt_state = BYTE_TWO;
			 end
		  default: // BYTE_TWO State //
		     if (tx_done) begin
			    cmd_sent = 1'b1;
				nxt_state = INIT;
			 end
	   endcase
	end
endmodule	
