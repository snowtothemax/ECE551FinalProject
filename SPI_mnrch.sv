module SPI_mnrch(clk, rst_n, SS_n, SCLK, MOSI, MISO, wrt, wt_data, done, rd_data);
   
   // Declare i/o signals //
   input clk, rst_n, wrt;	// 50MHz clock, reset, and the line that is high for 1 clk cycle to initiate SPI transaction
   input MISO; 				// Monarch in, Serf out
   input [15:0] wt_data;	// Data/command being sent to inertial sensor
   output SS_n, SCLK, MOSI;	// Other SPI protocol signals
   output reg done;				// Asserted when SPI transaction is complete. Stays asserted until next wrt
   output [15:0] rd_data;	// Data from the serf. We only use [7:0] for inertial sensor.
   
   // Generate variable //
   genvar i;
   
   // Shift Register //
   logic [15:0] shft_reg;
   
   // Internal Signals //
   logic shft; // Controls when the shift register shifts
   logic init; // High when initializing
   logic done16; // High when done shifting
   logic set_done; // High when we have finished and just have to say where are done
   logic ld_SCLK;	// assigned in state machine to load the sclk
   
   // 4-bit counter that controls SCLK //
   logic [3:0] SCLK_div;
   
   // Bit counter that lets us know when we are done //
   logic [4:0] bit_cntr;
   
   // State machine state defines //
   typedef enum {INIT, SHFT, WAIT} state_t;
   state_t state, nxt_state;
   
   
   /****************************
   * The 16-bit shift register *
   ****************************/
   always_ff @(posedge clk) begin
      if (init)
	     shft_reg <= wt_data;
	  else if (shft)
	     shft_reg <= {shft_reg[14:0], MISO};
   end
   
   assign MOSI = shft_reg[15]; // MOSI is driven by the MSB of the shift register
   assign rd_data = shft_reg;  // rd_data is the shift register, and when done is asserted it will be read
   
   /*********************
   * Production of SCLK *
   *********************/
   always_ff @(posedge clk) begin
      if (ld_SCLK) // SCLK_div gets set when the state is INIT here because that keeps the SCLK high when we are not transmitting data
	     SCLK_div <= 4'b1011;
	  else
	     SCLK_div <= SCLK_div + 1;
   end
   
   assign SCLK = SCLK_div[3]; // SCLK is normally high and controlled by the MSB of the counter
   assign full = (SCLK_div == 4'b1110) ? 1:0; // Full controls when to leave the WAIT state. Full is done one clk early to avoid SCLK glitching low.
   assign shft = (SCLK_div == 4'b1001) ? 1:0; // High when SCLK just went high, signifies to the shift register that it should shift in a new bit
   
   /***************************************************************************
   * The Bit Counter that informs us when we have completed all of our shifts *
   ***************************************************************************/
   always_ff @(posedge clk) begin
      if (init)
	     bit_cntr <= 5'b0;
	  else if (shft)
	     bit_cntr <= bit_cntr + 1;
   end
   
   assign done16 = bit_cntr[4]; // If the 5th bit of bit_cntr goes high then we have done 16 shifts and we are done.
   
   /*******************
   * State Controller *
   *******************/
   always_ff @(posedge clk) begin
      if (~rst_n)
	     state <= INIT;
	  else
	     state <= nxt_state;
   end
   
   /************
   * Done Flop *
   ************/
   always_ff @(posedge clk, negedge rst_n) begin
      if (~rst_n)
	     done <= 1'b0;
	  else if (init)
	     done <= 1'b0;
	  else if (set_done)
	     done <= 1'b1;
   end
   
   /****************
   * State Machine *
   ****************/
   always_comb begin
      // Set Defaults to avoid latches //
	  nxt_state = state;
	  init = 1'b0;
	  set_done = 1'b0;
	  ld_SCLK = 1'b0;
      case (state)
	     INIT: begin
		    if (wrt) begin
			   init = 1'b1;
			   nxt_state = SHFT;
			end
			ld_SCLK = 1'b1;
			end
		 SHFT: begin
		    if (done16)
			   nxt_state = WAIT;
		 end
		 default: // WAIT State
		    if (full) begin		
			   nxt_state = INIT;
			   set_done = 1'b1;
			end
	  endcase
   end
   
   assign SS_n = done;
   
endmodule