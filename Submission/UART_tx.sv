module UART_tx(clk, rst_n, TX, trmt, tx_data, tx_done);
   
   input clk, rst_n, trmt;
   input [7:0] tx_data;
   output TX;
   output reg tx_done;
   
   logic [11:0] baud_cnt;	 					// Used to count up until it is time to shift to the next bit to transmit
   logic [8:0] tx_shift_reg; 					// Shift register that holds the data to transmit
   logic [3:0] bit_cnt;							// Counts how many times we have shifted
   logic init, shift, transmitting, set_done; 	// High when initializing, shifting, transmitting, or done
   
   typedef enum reg {INIT, TRNS} state_t;
   state_t state, nxt_state;					// Variables for the state machine controlling the whole system
   
   
   // The shift register //
   always_ff @(posedge clk, negedge rst_n) begin
      if (~rst_n)
	     tx_shift_reg <= 9'h1FF;
	  else if(init)
	     tx_shift_reg <= {tx_data, 1'b0};
	  else if(shift)
	     tx_shift_reg <= {1'b1, tx_shift_reg[8:1]};
   end
   
   assign TX = tx_shift_reg[0]; // Transmit the next bit
   
   // Counter that lets the shift register know when to shift //
   always_ff @(posedge clk) begin
      if (init|shift)
	     baud_cnt <= 12'b0;
	  else if (transmitting)
	     baud_cnt <= baud_cnt + 1'b1;
   end
   
   assign shift = baud_cnt == 12'hA2C ? 1 : 0; // When baud_cnt is 2604 (decimal), assert shift
   
   // Count how many times we have shifted //
   always_ff @(posedge clk) begin
      if (init)
	     bit_cnt <= 4'b0;
	  else if (shift)
	     bit_cnt <= bit_cnt + 1'b1;
   end
   
   // State Machine //
   always_comb begin
      // Set Defaults to avoid latches //
	  nxt_state = INIT;
	  set_done = 0;
	  transmitting = 0;
	  init = 0;
	  // Pick a state //
	  case (state) 
	     INIT: 
		    if (trmt) begin
			   init = 1;
			   nxt_state = TRNS;
			end
		 default: // The TRNS case //
		    if (bit_cnt == 4'hA) begin
			   set_done = 1;
			   nxt_state = INIT;
			end else begin
			   transmitting = 1;
			   nxt_state = TRNS;
			end
	  endcase
   end
   
   // STATE FLOPS //
   always_ff @(posedge clk, negedge rst_n) begin
      if (~rst_n)
	     state <= INIT;
	  else
	     state <= nxt_state;
   end
   
   // The final flop - controls the output of the machine //
   always_ff @(posedge clk, negedge rst_n) begin
      if (~rst_n)
	     tx_done <= 1'b0;
	  else if (init)
	     tx_done <= 1'b0;
      else if (set_done)
	     tx_done <= 1'b1;
   end
   
endmodule