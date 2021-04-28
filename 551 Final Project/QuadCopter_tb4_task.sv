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
				if (iDUT.d_ptch != data2check) begin
					$display("d_ptch does not match input");
					$display("input: %h, d_ptch: %h", data2check, iDUT.d_ptch);
					//$stop();
				end else 
					$display("d_ptch correct!");
			end
			SET_ROLL: begin
				if (iDUT.d_roll != data2check) begin
					$display("d_roll does not match input");
					$display("input: %h, d_roll: %h", data2check, iDUT.d_roll);
					//$stop();
				end else 
					$display("d_roll correct!");
			end
			SET_YAW: begin
				if (iDUT.d_yaw != data2check) begin
					$display("d_yaw does not match input");
					$display("input: %h, d_yaw: %h", data2check, iDUT.d_yaw);
					//$stop();
				end else 
					$display("d_yaw correct!");
			end
			SET_MOFF: begin
				if ((iQuad.spd_frnt != 16'h0000) || (iQuad.spd_back != 16'h0000) || (iQuad.spd_left != 16'h0000) || (iQuad.spd_rght != 16'h0000)) begin
					$display("motors are not off when they should be");
					$display("front: %h, back: %h, left: %h, right: %h", iQuad.spd_frnt, iQuad.spd_back, iQuad.spd_left, iQuad.spd_rght);
					//$stop();
				end else
					$display("motors stopped successfully");
			end
			SET_EMGL: begin
				if ((iDUT.d_ptch != 16'h0000) || (iDUT.d_roll != 16'h0000) || (iDUT.d_yaw != 16'h0000) || (iDUT.thrst != 8'h00)) begin
					$display("emergency land values are not zero");
					$display("d_ptch: %h, d_roll: %h, d_yaw %h, thrust: %h", iDUT.d_ptch, iDUT.d_roll, iDUT.d_yaw, iDUT.thrst);
					//$stop();
				end else
					$display("emergency land values are zero");
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
		assign lower_val = data2check - 10;
		assign upper_val = data2check + 10;
		case(cmd2check)
			SET_PTCH: begin
				if ((iDUT.ptch < lower_val) | (iDUT.ptch > upper_val)) begin
					$display("final pitch not near input");
					$display("input: %d, upper limit: %d, lower limit: %d, final: %d", data2check, upper_val, lower_val, iDUT.ptch);
					//$stop();
				end else
					$display("final pitch correct!");
			end
			SET_ROLL: begin
				if ((iDUT.roll < lower_val) | (iDUT.roll > upper_val)) begin
					$display("final roll not near input");
					$display("input: %d, upper limit: %d, lower limit: %d, final: %d", data2check, upper_val, lower_val, iDUT.roll);
					//$stop();
				end else
					$display("final roll correct!");
			end
			SET_YAW: begin
				if ((iDUT.yaw < lower_val) | (iDUT.yaw > upper_val)) begin
					$display("final yaw not near input");
					$display("input: %d, upper limit: %d, lower limit: %d, final: %d", data2check, upper_val, lower_val, iDUT.yaw);
					//$stop();
				end else
					$display("final yaw correct!");
			end
		endcase
    end
endtask

/**
    This task is used to wait for landing of the quadcopter.
**/
task wait_for_landing();
    begin
		while (iDUT.ptch != 16'h0000) @(posedge clk);
		$display("pitch zero");
		while (iDUT.roll != 16'h0000) @(posedge clk);
		$display("roll zero");
		while (iDUT.yaw != 16'h0000) @(posedge clk);
		$display("yaw zero");
		while (iQuad.thrst != 13'h000) @(posedge clk);
		$display("quadcopter successfully landed");
    end
endtask