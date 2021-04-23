module set_pitch_test();

initial begin
	/* TEST 1 */
	//send command
	$display("TEST1: Sending d_ptch");
	clk = 0;
	RST_n = 0;
	@(negedge clk);
	RST_n = 1;
	send_command(SET_PTCH, 16'h0001);
	//check posask
	//$display("TEST1: Waiting for posack");
	//check_posack();
	//$display("TEST1: Posack received");
	//check desired pitch
	$display("TEST1: Checking d_ptch");
	chck_output_of_cmd_cfg(SET_PTCH, 16'h0001,result);
	if (result) 
		$display("TEST1: d_ptch correct!");
	else begin
		$display("TEST1: d_ptch incorrect");
		$stop();
	end
	//check measured pitch
	$display("TEST1: Checking final pitch");
	chck_final_values(SET_PTCH, 16'h0001,result);
	if (result) begin
		$display("TEST1: final pitch correct!");
		$display("TEST1 Complete");
	end else begin
		$display("TEST1: final pitch incorrect");
		$stop();
	end

	/* TEST 2 */
	//send command
	$display("TEST2: Sending d_ptch");
	send_command(SET_PTCH, 16'h0800);
	//check posask
	//$display("TEST2: Waiting for posack");
	//check_posack();
	//$display("TEST2: Posack received");
	//check desired pitch
	$display("TEST2: Checking d_ptch");
	chck_output_of_cmd_cfg(SET_PTCH, 16'h0800,result);
	if (result) 
		$display("TEST2: d_ptch correct!");
	else begin
		$display("TEST2: d_ptch incorrect");
		$stop();
	end
	//check measured pitch
	$display("TEST1: Checking final pitch");
	chck_final_values(SET_PTCH, 16'h0800,result);
	if (result) begin
		$display("TEST2: final pitch correct!");
		$display("TEST2 Complete");
	end else begin
		$display("TEST2: final pitch incorrect");
		$stop();
	end

	/* TEST 3 */
	//send command
	$display("TEST3: Sending d_ptch");
	send_command(SET_PTCH, 16'hFFFF);
	//check posask
	//$display("TEST3: Waiting for posack");
	//check_posack();
	//$display("TEST3: Posack received");
	//check desired pitch
	$display("TEST1: Checking d_ptch");
	chck_output_of_cmd_cfg(SET_PTCH, 16'hFFFF,result);
	if (result) 
		$display("TEST3: d_ptch correct!");
	else begin
		$display("TEST3: d_ptch incorrect");
		$stop();
	end
	//check measured pitch
	$display("TEST1: Checking final pitch");
	chck_final_values(SET_PTCH, 16'hFFFF,result);
	if (result) begin
		$display("TEST3: final pitch correct!");
		$display("TEST3 Complete");
	end else begin
		$display("TEST3: final pitch incorrect");
		$stop();
	end

	/* TEST 4 */
	//send command
	$display("TEST4: Sending d_ptch");
	send_command(SET_PTCH, 16'h801C);
	//check posask
	//$display("TEST4: Waiting for posack");
	//check_posack();
	//$display("TEST4: Posack received");
	//check desired pitch
	$display("TEST4: Checking d_ptch");
	chck_output_of_cmd_cfg(SET_PTCH, 16'h801C,result);
	if (result) 
		$display("TEST4: d_ptch correct!");
	else begin
		$display("TEST4: d_ptch incorrect");
		$stop();
	end
	//check measured pitch
	$display("TEST4: Checking final pitch");
	chck_final_values(SET_PTCH, 16'h801C,result);
	if (result) begin
		$display("TEST4: final pitch correct!");
		$display("TEST4 Complete");
	end else begin
		$display("TEST4: final pitch incorrect");
		$stop();
	end
end

always
  #10 clk = ~clk;
