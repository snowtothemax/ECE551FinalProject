    /**
        Main task used for sending the command in FinalProject.
    **/
    task call_command(input [7:0]cmd2send, input [15:0]data2send);
        host_cmd = cmd2send;
        data = data2send;
        send_cmd = 1;

        @(posedge clk);
        @(negedge clk);

        send_cmd = 0;
    endtask

    /**
        Main task used for testing the command in FinalProject.
    **/
    task chck_output_of_cmd_cfg(input [7:0]cmd2send, input [15:0]data2send, output logic result);
        //Send the command.
        call_command(cmd2send, data2send);
        //Cases to test out different commands.
        case(cmd2send)
            (8'h02): begin
                result = 1;
                $display("Checking ACK!");
                chck_ACK(cmd2snd, result);
                if(result != 1) begin
                    $display("ACK failed!");
                    $Stop;
                end
                else begin
                    $display("ACK passed! Yahoo!");
                end
                clr_resp_rdy = 1;
                @(negedge clk);
                clr_resp_rdy = 0;
                //
                result = 1;
                //Checking d_ptch.
                if(iDUT.d_ptch !== data2send)begin
                    $display("d_ptch signal failed!")
                    result = 0;
                end
            end
            (8'h03): begin
                result = 1;
                $display("Checking ACK!");
                chck_ACK(cmd2snd, result);
                if(result != 1) begin
                    $display("ACK failed!");
                    $Stop;
                end
                else begin
                    $display("ACK passed! Yahoo!");
                end
                clr_resp_rdy = 1;
                @(negedge clk);
                clr_resp_rdy = 0;
                //
                result = 1;
                //Checking d_roll.
                if(iDUT.d_roll !== data2send)begin
                    $display("d_roll signal failed!")
                    result = 0;
                end
            end
            (8'h04): begin
                result = 1;
                $display("Checking ACK!");
                chck_ACK(cmd2snd, result);
                if(result != 1) begin
                    $display("ACK failed!");
                    $Stop;
                end
                else begin
                    $display("ACK passed! Yahoo!");
                end
                clr_resp_rdy = 1;
                @(negedge clk);
                clr_resp_rdy = 0;
                //
                result = 1;
                //Checking d_yaw.
                if(iDUT.d_yaw !== data2send)begin
                    $display("d_roll signal failed!")
                    result = 0;
                end
            end
            (8'h05): begin
                result = 1;
                $display("Checking ACK!");
                chck_ACK(cmd2snd, result);
                if(result != 1) begin
                    $display("ACK failed!");
                    $Stop;
                end
                else begin
                    $display("ACK passed! Yahoo!");
                end
                clr_resp_rdy = 1;
                @(negedge clk);
                clr_resp_rdy = 0;
                //
                result = 1;
                //Checking airborne.
                if(iQuad.airborne !== 1)begin
                    $display("airborne signal failed!")
                    result = 0;
                end
            end
            (8'h07): begin
                result = 1;
                $display("Checking ACK!");
                chck_ACK(cmd2snd, result);
                if(result != 1) begin
                    $display("ACK failed!");
                    $Stop;
                end
                else begin
                    $display("ACK passed! Yahoo!");
                end
                clr_resp_rdy = 1;
                @(negedge clk);
                clr_resp_rdy = 0;
                //
                result = 1;
                //Checking signals.
                if(iDUT.d_yaw !== 0)begin
                    $display("d_yaw signal failed!")
                    result = 0;
                end
                if(iDUT.d_ptch !== 0)begin
                    $display("d_ptch signal failed!")
                    result = 0;
                end
                if(iDUT.d_roll !== 0)begin
                    $display("d_roll signal failed!")
                    result = 0;
                end
                if(iDUT.thrst !== 0)begin
                    $display("thrust signal failed!")
                    result = 0;
                end
            end
            (8'h08): begin
                result = 1;
                $display("Checking ACK!");
                chck_ACK(cmd2snd, result);
                if(result != 1) begin
                    $display("ACK failed!");
                    $Stop;
                end
                else begin
                    $display("ACK passed! Yahoo!");
                end
                clr_resp_rdy = 1;
                @(negedge clk);
                clr_resp_rdy = 0;
                //
                result = 1;
                //Checking motors_off.
                if(iDUT.motors_off !== 1)begin
                    $display("motors_off signal failed!")
                    result = 0;
                end
            end
            (8'h06): begin
                result = 1;
                $display("Checking ACK!");
                chck_ACK(cmd2snd, result);
                if(result != 1) begin
                    $display("ACK failed!");
                    $Stop;
                end
                else begin
                    $display("ACK passed! Yahoo!");
                end
                clr_resp_rdy = 1;
                @(negedge clk);
                clr_resp_rdy = 0;
                //
                result = 1;
                if(iDUT.frnt_spd !== 11'h290)begin
                    $display("frnt_spd signal failed!")
                    result = 0;
                end
                if(iDUT.bck_spd !== 11'h290)begin
                    $display("bck_spd signal failed!")
                    result = 0;
                end
                if(iDUT.lft_spd !== 11'h290)begin
                    $display("lft_spd signal failed!")
                    result = 0;
                end
                if(iDUT.rght_spd !== 11'h290)begin
                    $display("rght_spd signal failed!")
                    result = 0;
                end
            end
        endcase
    endtask

    /**
        Task used to check ACK.
    **/

    task chck_ACK(input logic [7:0] cmd, output logic result);

        //Wait for resp_rdy.
        while (resp_rdy != 1) begin
            //wait
        end

        // Check the resp.
        if(resp !== 8'hA5) begin
            $display("ACK Failed for cmd(0x%h)!", cmd);
            result = 0;
        end
        else begin
            $display("ACK Passed for cmd(0x%h)!", cmd);
            result = 1;
        end
    endtask