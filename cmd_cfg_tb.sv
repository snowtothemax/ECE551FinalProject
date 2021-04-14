module cmd_cfg_tb();

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
        Setting up the tasks needed for the testbench.
    **/


    /**
        Setting up the clk for the testbench.
    **/

    always begin
        clk = ~clk;
    end

endmodule