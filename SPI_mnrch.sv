module SPI_mnrch(clk, rst_n,wrt, wt_data, done, rd_data, SS_n, SCLK, MOSI, MISO);
	//INPUTS AND OUTPUTS
	input clk, rst_n, wrt;
	input [15:0] wt_data;
	input MISO;
	output reg done;
	output SS_n;
	output SCLK;
	output [15:0] rd_data;
	output MOSI;
	
	// state defns
	typedef enum reg [1:0] {INIT, SHIFT, IDLE} state_t;
	state_t state, nxt_state;
	
	// default load for SCLK
	localparam SCLK_LOAD = 4'b1011;
	
	// intermediates
	reg init;			 		// control signals
	wire shift, full;			// control signals
	reg [15:0] shft_reg;		// The Shift register used for MOSI
	reg [3:0] SCLK_div;			// Produces shift and sends 
	reg ld_SCLK;				// determines if you should load the SCLK shift register
	wire done16;				// goes high when bit_cntr is 16
	reg [4:0] bit_cntr;			// counts how many bits have been transmitted
	reg set_done;				// for when we are done transmitting;
	
	
	// First we will implement the SCLK flip flop
	// Assign SCLK to the MSB of the SCLK_div(every 8);
	///////// SCLK /////////////////////////////
	always_ff @(posedge clk) begin
		if(init | (state == INIT))
			SCLK_div <= SCLK_LOAD;
		else
			SCLK_div <= SCLK_div + 1;
	end
	
	// SCLK logic
	assign SCLK = SCLK_div[3];				// bit 3 of SCLK_div is equal to SCLK
	assign full = (SCLK_div == 4'b1110);	// know div is full when we have reached 4'b1110 ( want that slight back porch)
	assign shift = (SCLK_div == 4'b1001);	// every time the shift reg is 1001 (1 count after 8 counts)
	
	/////////////////////////////////////////
	///////////// MOSI //////////////////////
	/////////////////////////////////////////
	always_ff @(posedge clk) begin
		if (init)
			shft_reg <= wt_data;
		else if (shift)
			shft_reg <= {shft_reg[14:0], MISO};
		else
			shft_reg <= shft_reg;
	end
	
	// logic
	assign MOSI = shft_reg[15];				// MOSI is just the msb of shft_reg
	
	/////////////////////////////////////////
	////////// bit counter /////////////////
	////////////////////////////////////////
	always_ff @(posedge clk) begin
		if (init)
			bit_cntr <= 5'b00000;
		else if (shift)
			bit_cntr <= bit_cntr + 1;
	end
	
	// logic
	assign done16 = bit_cntr[4];			// Goes high when bit 4 is 1, so 16
	
	
	/////////////////////////////////////////
	/////////// State Machine ///////////////
	/////////////////////////////////////////
	always_ff @(posedge clk, negedge rst_n) begin
		if (!rst_n)
			state <= INIT;
		else
			state <= nxt_state;
	end

	always_ff @(posedge clk, negedge rst_n) begin
		if(!rst_n)
			done = 0;
		else if (init)
			done = 0;
		else if (set_done)
			done = 1;
	end
	
	always_comb begin
		ld_SCLK = 0;
		init = 0;
		set_done = 0;
		nxt_state = state;
		case(state)
			INIT: begin
				if (wrt) begin
					ld_SCLK = 1;
					init = 1;
					nxt_state = SHIFT;
				end
			end
			SHIFT: begin
				if (done16) begin
					nxt_state = IDLE;
				end
			end
			// the IDLE state
			default: begin
				if (full) begin
					set_done = 1;
					nxt_state = INIT;
				end
			end
		endcase
	end
	
	assign SS_n = done;
	
endmodule
