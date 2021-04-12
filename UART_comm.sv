module UART_comm(clk, rst_n, RX, TX, resp, send_resp, resp_sent, cmd_rdy, cmd, data, clr_cmd_rdy);

	input clk, rst_n;		// clock and active low reset
	input RX;				// serial data input
	input send_resp;		// indicates to transmit 8-bit data (resp)
	input [7:0] resp;		// byte to transmit
	input clr_cmd_rdy;		// host asserts when command digested

	output TX;				// serial data output
	output resp_sent;		// indicates transmission of response complete
	output reg cmd_rdy;		// indicates 24-bit command has been received
	output reg [7:0] cmd;	// 8-bit opcode sent from host via BLE
	output reg [15:0] data;	// 16-bit parameter sent LSB first via BLE

	wire [7:0] rx_data;		// 8-bit data received from UART
	wire rx_rdy;			// indicates new 8-bit data ready from UART
	wire rx_rdy_posedge;	// output of posedge detector on rx_rdy used to transition SM
	logic out0, out1, low;  // Used to detect posedge rx_rdy

	////////////////////////////////////////////////////
	// declare any needed internal signals/registers //
	// below including any state definitions        //
	/////////////////////////////////////////////////
	
	logic take_cmd, first_byte, clr_cmd_rdy_sm, set_cmd_rdy, clr_rdy;
	typedef enum reg [1:0] {INIT, CMDI, DATI} state_t;
	state_t state, nxt_state;

	///////////////////////////////////////////////
	// Instantiate basic 8-bit UART transceiver //
	/////////////////////////////////////////////
	UART iUART(.clk(clk), .rst_n(rst_n), .RX(RX), .TX(TX), .tx_data(resp), .trmt(send_resp),
			   .tx_done(resp_sent), .rx_data(rx_data), .rx_rdy(rx_rdy), .clr_rx_rdy(clr_rdy));
		
	////////////////////////////////
	// Implement UART_comm below //
	//////////////////////////////
	
	// Takes the cmd data when ready //
	always_ff @(posedge clk)
	   if (take_cmd)
	      cmd <= rx_data;
	
	// Takes the first byte of the data when ready //
	always_ff @(posedge clk)
	   if (first_byte)
	      data[15:8] <= rx_data;
	
	// Takes the second byte of the data - this can be constantly assigned and just validated when rdy is asserted //
	assign data[7:0] = rx_data; 

	// Output flop //
	always_ff @(posedge clk, negedge rst_n) begin
	   if (~rst_n)
	      cmd_rdy <= 1'b0;
	   else if (clr_cmd_rdy | clr_cmd_rdy_sm)
	      cmd_rdy <= 1'b0;
	   else if (set_cmd_rdy)
	      cmd_rdy <= 1'b1;
	end
	
	// Flop controlling the state of the SM //
	always_ff @(posedge clk, negedge rst_n) begin
	   if (~rst_n)
	      state <= INIT;
	   else
	      state <= nxt_state;
	end
	
	// Detect posedge of rx_rdy //
	dff dff0(.D(rx_rdy), .clk(clk), .Q(out0));				// The first ff. The output of this ff is passed to the AND gate
	dff dff1(.D(out0), .clk(clk), .Q(out1));				// The second ff. The output of this ff is passed to a NOT, then AND.
	not not0(low, out1);
	and and0(rx_rdy_posedge, low, out0);
	
	// State Machine //
	always_comb begin
	   // Set defaults to avoid flops //
	   nxt_state = state;
	   set_cmd_rdy = 1'b0;		// Asserted when done with the whole process
	   first_byte = 1'b0;		// Asserted when the first byte of data is ready
	   clr_rdy = 1'b0;			// Asserted after the cmd or data has been taken
	   take_cmd = 1'b0;			// Asserted when cmd is ready
	   clr_cmd_rdy_sm = 1'b0;	// Asserted when a new process begins
	   // States //
	   case (state)
	      INIT:
		     if (rx_rdy_posedge) begin
			    take_cmd = 1'b1;
				clr_cmd_rdy_sm = 1'b1;
				clr_rdy = 1'b1;
				nxt_state = CMDI;
			 end
		  CMDI:
		     if (rx_rdy_posedge) begin
			    first_byte = 1'b1;
				clr_rdy = 1'b1;
				nxt_state = DATI;
			 end
		  default: // DATI state //
		     if (rx_rdy_posedge) begin
			    set_cmd_rdy = 1'b1;
				clr_rdy = 1'b1;
				nxt_state = INIT;
			 end
	   endcase
	end
endmodule	