module cmd_cfg_tb();

    /**
        Setting the commands.
    **/

    localparam SET_PTCH = 8'h02;
    localparam SET_ROLL = 8'h03;
    localparam SET_YAW = 8'h04;
    localparam SET_THRST = 8'h05;
    localparam SET_CAL = 8'h06;
    localparam SET_EMGL = 8'h07;
    localparam SET_MOFF = 8'h08;

    /**
        Setting up the variables for input and output of the duts.
    **/

    //Shared by all.
    logic clk, rst_n;

    //Between RemoteComm and UART_comm.
    logic [15:0] data;
    logic [7:0] cmd, resp;
    logic snd_cmd, cmd_sent, resp_rdy, clr_resp_rdy, TX_RX, RX_TX;

    //Between UART_comm and cmd_cfg.
    logic [15:0] data_1, d_ptch, d_roll, d_yaw;
    logic [8:0] thrst;
    logic [7:0] cmd_1, resp_1;
    logic cmd_rdy, clr_cmd_rdy, snd_rsp, rsp_sent, strt_cal, inertial_cal, cal_done, motors_off;

    //Variables used for testing.
    logic [7:0] cmd2snd;
    logic [15:0] data2snd;
    logic result;

    /**
        Setting up the iDuts needed for the testbench.
    **/

    //RemoteComm Dut.
    RemoteComm IDut0(.clk(clk), .rst_n(rst_n), .RX(RX_TX), .send_cmd(snd_cmd), .cmd(cmd), .data(data), 
                    .clr_resp_rdy(clr_resp_rdy), .TX(TX_RX), .cmd_sent(cmd_sent), .resp_rdy(resp_rdy),
                    .resp(resp));

    //UART_comm DUT.
    UART_comm IDut1(.clk(clk), .rst_n(rst_n), .RX(TX_RX), .TX(RX_TX), .resp(resp_1),
                    .send_resp(snd_rsp), .resp_sent(rsp_sent), .cmd_rdy(cmd_rdy), .cmd(cmd_1), 
                    .data(data_1), .clr_cmd_rdy(clr_cmd_rdy));
            
    //cmd_cfg DUT.
    cmd_cfg IDut2(.clk(clk), .rst_n(rst_n), .cmd_rdy(cmd_rdy), .cmd(cmd_1), .data(data_1), 
                .clr_cmd_rdy(clr_cmd_rdy), .resp(resp_1), .send_resp(snd_rsp), .d_ptch(d_ptch), 
                .d_roll(d_roll), .d_yaw(d_yaw), .thrst(thrst), .strt_cal(strt_cal), 
                .inertial_cal(inertial_cal), .cal_done(cal_done), .motors_off(motors_off));

    /**
        Calling the tasks needed for the testbench.
    **/
    task chck_output_of_cmd_cfg;
		input logic [7:0] cmd2send;
		input logic [15:0] data2send;
		output logic result;
		
        @(negedge clk);
        cmd = cmd2send;
		data = data2send;
		snd_cmd = 1;
        @(negedge clk);
		snd_cmd = 0;
        @(posedge resp_rdy);
		result = 1;
		case(cmd2send) 
			SET_PTCH: begin
                if (d_ptch != data) 
					result = 0;
			end
			SET_ROLL: begin
		   	 	if (d_roll != data)
					result = 0;
			end
			SET_YAW: begin
		    	if (d_yaw != data) 
					result = 0;
			end
			SET_THRST: begin
		    	if (thrst != data) 
					result = 0;
			end
			SET_CAL: //nothing here?
				if (strt_cal != 1)
					result = 0;
			SET_EMGL:
		    	if (d_ptch != 16'b0000) 
					result = 0;
		    	else if (d_yaw != 16'h0000)
					result = 0;
				else if (d_roll != 16'h0000) 
					result = 0;
		    	else if (thrst != 16'h0000)
					result = 0;
		    	//motors off?
            SET_MOFF : begin
		    	if (!motors_off) 
					result = 0;
		 	end
		endcase
    endtask

    initial begin
        /**
            Calling the tasks
        **/

        //SET_PTCH Testing.
        $display("Testing SET_PTCH");
		clk = 0;
		rst_n = 0;
		@(negedge clk);
		rst_n = 1;
        cmd2snd = SET_PTCH;
        data2snd = 16'h0001;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_PTCH Test Failed!");
            $stop;
        end
        else begin
            $display("SET_PTCH Test Passed! YAHOO!!");
        end
		repeat(2) @(negedge clk);
        //SET_ROLL Testing.
        $display("Testing SET_ROLL");
        cmd2snd = SET_ROLL;
        data2snd = 16'h0002;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_ROLL Test Failed!");
            $stop;
        end
        else begin
            $display("SET_ROLL Test Passed! YAHOO!!");
        end

        //SET_YAW Testing.
        $display("Testing SET_YAW");
        cmd2snd = SET_YAW;
        data2snd = 16'h0001;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_YAW Test Failed!");
            $stop;
        end
        else begin
            $display("SET_YAW Test Passed! YAHOO!!");
        end

        //SET_THRST Testing.
        $display("Testing SET_THRST");
        cmd2snd = SET_THRST;
        data2snd = 16'h0001;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_THRST Test Failed!");
            $stop;
        end
        else begin
            $display("SET_THRST Test Passed! YAHOO!!");
        end

        //SET_CAL Testing.
        /* $display("Testing SET_CAL");
        cmd2snd = SET_CAL;
        data2snd = 16'hxxxx;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_CAL Test Failed!");
            $stop;
        end
        else begin
            $display("SET_CAL Test Passed! YAHOO!!");
        end */

        //SET_EMGL Testing.
        $display("Testing SET_EMGL");
        cmd2snd = SET_EMGL;
        data2snd = 16'h0000;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_EMGL Test Failed!");
            $stop;
        end
        else begin
            $display("SET_EMGL Test Passed! YAHOO!!");
        end

        //SET_EMGL Testing.
        $display("Testing SET_MOFF");
        cmd2snd = SET_MOFF;
        data2snd = 16'hxxxx;
        chck_output_of_cmd_cfg(cmd2snd, data2snd, result);
        if (result == 0) begin
            $display("SET_MOFF Test Failed!");
            $stop;
        end
        else begin
            $display("SET_MOFF Test Passed! YAHOO!!");
        end

        $display("All Tests Passed! YAHOO!!!!");
        $stop;

    end

    /**
        Setting up the clk for the testbench.
    **/

    always begin
        #10 clk = ~clk;
    end

endmodule
