module UART_rcv(clk, rst_n, RX, clr_rdy, rx_data, rdy);
   
   input clk, rst_n, RX, clr_rdy;
   output reg rdy;
   output reg [7:0] rx_data;
   
   logic init, shift, set_rdy, receiving, RX_f1, RX_stable;
   logic [3:0] bit_cnt;
   logic [8:0] rx_data_big; // When the data transfer is done, this variable holds rx_data plus the stop bit
   logic [11:0] baud_cnt, preload;
   
   localparam BAUD = 12'hA2C;  // Amount of clock cycles for our baud rate
   localparam HBAUD = 12'h516; // Half of BAUD
   
   typedef enum reg {INIT, SHFT} state_t;
   state_t state, nxt_state;
   
   // Double Flop RX to stabalize it //
   always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)
	     RX_f1 <= 1'b1;
	  else
	     RX_f1 <= RX;
   always_ff @(posedge clk, negedge rst_n)
      if (~rst_n)
	     RX_stable <= 1'b1;
	  else
	     RX_stable <= RX_f1;
   
   // Shift register to store the data //
   always_ff @(posedge clk) begin
      if (shift)
	     rx_data_big <= {RX_stable, rx_data_big[8:1]};
   end
   
   // Baud Counter //
   always_ff @(posedge clk) begin
      if (init|shift)
	     baud_cnt <= preload;
	  else if (receiving)
	     baud_cnt <= baud_cnt - 1'b1;
   end
   
   assign preload = init ? HBAUD:	// If we are starting, count only half a baud, otherwise we want to count a full baud to get to the next bit
						   BAUD;
							
   assign shift = (baud_cnt == 12'h0) ? 1'b1: // shift to the next RX bit when the baud counter hits 0
										1'b0;
   assign rx_data = rx_data_big[7:0];
							
	// Bit Counter //
	always_ff @(posedge clk) begin
	   if (init)
	      bit_cnt <= 4'h0;
	   else if (shift)
	      bit_cnt <= bit_cnt + 1'b1;
	end
	
	// Output Controller //
	always_ff @(posedge clk, negedge rst_n) begin
	   if (~rst_n)
	      rdy <= 1'b0;
	   else if (init | clr_rdy)
	      rdy <= 1'b0;
	   else if (set_rdy)
	      rdy <= 1'b1;
	end
	
   // State Controller //
   always_ff @(posedge clk, negedge rst_n) begin
      if (~rst_n)
	     state <= INIT;
	  else
	     state <= nxt_state;
   end
   
   // State Machine //
   always_comb begin
      // Set Defaults //
      nxt_state = INIT;
	  init = 1'b0;
	  set_rdy = 1'b0;
	  receiving = 1'b0;
      // State Machine //
      case (state)
	     INIT:
		    if (~RX_stable) begin
			   init = 1'b1;
			   nxt_state = SHFT;
			end
		 SHFT:
		    if (bit_cnt == 4'hA) begin
			   set_rdy = 1'b1;
			   nxt_state = INIT;
			end else begin
			   receiving = 1'b1;
			   nxt_state = SHFT;
			end
	  endcase
   end
endmodule