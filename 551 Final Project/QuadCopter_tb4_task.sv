/**
    Initializing the logic needed for the tasks.
**/

logic [16:0]lower_val;
logic [16:0]upper_val;

/**
    This task is used to send the commands.
**/
task snd_cmd;
input logic [7:0] cmd2snd;
input logic [15:0] data2snd;
	begin
        @(negedge clk);

        host_cmd = cmd2snd;
		data = data2snd;
		send_cmd = 1;

        @(negedge clk);

		send_cmd = 0;
    end
endtask

/**
    This task is used to initialize the testbench.
**/
task init();
    begin
		clk = 0;
		RST_n = 0;

		@(negedge clk);

		RST_n = 1;
    end
endtask

/**
    This task is used to check calibration.
**/
task check_if_cal();
    begin
		$display("Testing if calibration worked...");
		@(posedge iDUT.cal_done);
		if (iDUT.frnt_spd !== 11'h290 || iDUT.bck_spd !== 11'h290 || iDUT.lft_spd !== 11'h290 || iDUT.rght_spd !== 11'h290) begin
			$display("CALIBRATION ERROR: Motor speeds are not 0x290, but instead they are %h!", iDUT.frnt_spd);
			$stop();
		end else
			$display("YAHOO!! Calibration success!");
    end
endtask

/**
    This task is used to check emergency landing.
**/
task check_em_land();
    begin
		$display("Testing if emergency landing worked");
		@(posedge resp_rdy);
		if (iDUT.frnt_spd !== 11'h000 || iDUT.bck_spd !== 11'h000 || iDUT.lft_spd !== 11'h000 || iDUT.rght_spd !== 11'h000) begin
			$display("EMERGENCY LANDING ERROR: Motor speeds are not 0! Front motor is %h", iDUT.frnt_spd);
			$stop();
		end else
			$display("YAHOO!! EMERGENCY LANDING SUCCESS!");
    end
endtask

/**
    This task is used to check the d_ptch, d_roll and d_yaw.
**/
task check_desired;
input [7:0]cmd2check;
input [15:0]data2check;
    begin
		@(posedge iDUT.cmd_rdy);
		@(posedge resp_rdy);

		case(cmd2check)
			SET_PTCH: begin
				if (iDUT.d_ptch !== data2check) begin
					$display("d_ptch does not match input");
					$display("input: %h, d_ptch: %h", data2check, iDUT.d_ptch);
					//$stop();
				end else 
					$display("YAHOO!! d_ptch correct!");
			end
			SET_ROLL: begin
				if (iDUT.d_roll !== data2check) begin
					$display("d_roll does not match input");
					$display("input: %h, d_roll: %h", data2check, iDUT.d_roll);
					//$stop();
				end else 
					$display("YAHOO!! d_roll correct!");
			end
			SET_YAW: begin
				if (iDUT.d_yaw !== data2check) begin
					$display("d_yaw does not match input");
					$display("input: %h, d_yaw: %h", data2check, iDUT.d_yaw);
					//$stop();
				end else 
					$display("YAHOO!! d_yaw correct!");
			end
			SET_MOFF: begin
				if (iQuad.thrst !== 13'h0000) begin
					$display("motors are not off when they should be");
					$display("thrst: %h", iQuad.thrst);
					//$stop();
				end else
					$display("YAHOO!! Motors stopped successfully");
			end
			SET_EMGL: begin
				if ((iDUT.d_ptch !== 16'h0000) || (iDUT.d_roll !== 16'h0000) || (iDUT.d_yaw !== 16'h0000) || (iDUT.thrst !== 8'h00)) begin
					$display("emergency land values are not zero");
					$display("d_ptch: %h, d_roll: %h, d_yaw %h, thrust: %h", iDUT.d_ptch, iDUT.d_roll, iDUT.d_yaw, iDUT.thrst);
					//$stop();
				end else
					$display("YAHOO!! Emergency land values are zero");
			end
		endcase
    end
endtask

/**
    This task is used to check the final ptch, roll and yaw values.
**/
task check_final;
input [7:0]cmd2check;
input [15:0]data2check;
    begin
		assign lower_val = data2check - 7;
		assign upper_val = data2check + 7;
		// Timeout after a long time if the ptch roll or yaw never get close to the desired value //
		case(cmd2check)
			SET_PTCH: begin
				fork
					begin : timeout2
						repeat(50000000) @(posedge clk);
						$display("ERROR: ptch check timed out");
						$stop();
					end
					begin
						$display("Waiting for pitch to be within range...");
						while (iDUT.ptch < lower_val || iDUT.ptch > upper_val)
							@(posedge clk);
						disable timeout2;
					end
				join
				$display("YAHOO!! Final ptch within range");
			end
			SET_ROLL: begin
				fork
					begin : timeout3
						repeat(50000000) @(posedge clk);
						$display("ERROR: roll check timed out");
						$stop();
					end
					begin
						$display("Waiting for roll to be within range...");
						while (iDUT.roll < lower_val || iDUT.roll > upper_val)
							@(posedge clk);
						disable timeout3;
					end
				join
				$display("YAHOO!! Final roll within range");
			end
			SET_YAW: begin
				fork
					begin : timeout4
						repeat(50000000) @(posedge clk);
						$display("ERROR: yaw check timed out");
						$stop();
					end
					begin
						$display("Waiting for yaw to be within range...");
						while (iDUT.yaw < lower_val || iDUT.yaw > upper_val)
							@(posedge clk);
						disable timeout4;
					end
				join
				$display("YAHOO!! Final yaw within range");
			end
		endcase
    end
endtask

/**
    This task is used to wait for landing of the quadcopter.
**/
task wait_for_landing();
    begin
		while (iDUT.ptch > 16'h0007 || iDUT.ptch < $signed(-7)) @(posedge clk);
		$display("YAHOO!! pitch zero");
		while (iDUT.roll > 16'h0007 || iDUT.roll < $signed(-7)) @(posedge clk);
		$display("YAHOO!! roll zero");
		while (iDUT.yaw > 16'h0007 || iDUT.yaw < $signed(-7)) @(posedge clk);
		$display("YAHOO!! yaw zero");
		while (iDUT.thrst !== 13'h0000) @(posedge clk);
		$display("YAHOO!! quadcopter successfully landed");
    end
endtask