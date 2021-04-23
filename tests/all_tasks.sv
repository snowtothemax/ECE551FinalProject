task send_command;
	input [7:0]cmd2send;
	input [15:0]data2send;
	@(negedge clk);
        	host_cmd = cmd2snd;
		data = data2snd;
		send_cmd = 1;
        @(negedge clk);
		send_cmd = 0;
endtask

task check_posack;
	//???
endtask

task chck_output_of_cmd_cfg;
	input logic [7:0] cmd_sent;
	input logic [15:0] data_sent;
	output logic result;
		 
        @(posedge resp_rdy);
		result = 1;
		case(cmd2snd) 
			SET_PTCH: begin
                		if (iDUT.d_ptch != data) 
					result = 0;
			end
			SET_ROLL: begin
		   	 	if (iDUT.d_roll != data)
					result = 0;
			end
			SET_YAW: begin
		    		if (iDUT.d_yaw != data) 
					result = 0;
			end
			SET_THRST: begin
		    		if (iDUT.thrst != data) 
					result = 0;
			end
			SET_CAL: begin 
				if (iDUT.strt_cal == 1)
					result = 0;
				end
			SET_EMGL: // Make sure ptch, roll, yaw, thrst are all 0
		    		if (iDUT.d_ptch != 16'b0000) 
					result = 0;
		    		else if (iDUT.d_yaw != 16'h0000)
					result = 0;
				else if (iDUT.d_roll != 16'h0000) 
					result = 0;
		    		else if (iDUT.thrst != 16'h0000)
					result = 0;
		    	//motors off?
            		SET_MOFF : begin	// motors_off should be asserted 
		    		if (!iDUT.motors_off) 
					result = 0;
		 	end
		endcase
endtask


task chk_final_vals;
	input [7:0]cmd2chk;
	input [15:0]data2chk;
	output result;
	//is there some @(something) that says when a ptch,roll,or yaw is done changing?
	result = 1;
	case(cmd2chk);
		SET_PTCH: begin
			if (ptch != data2chk) 
				result = 0;
		end
		SET_ROLL: begin
			if (roll != data2chk)
				result = 0;
		end
		SET_YAW: begin
			if (yaw != data2chk)
				result = 0;
		end
	endcase
endtask
	
