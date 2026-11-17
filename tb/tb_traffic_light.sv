`timescale 1ns/1ps

module tb_traffic_light();
	logic CLOCK_50;
	logic [1:0] KEY;  //KEY[0] — сброс, KEY[1] — кнопка пешехода
	logic [2:0] LEDR; //{RED, YELLOW, GREEN}
	logic [1:0] LEDG; //{P_RED, P_GREEN}
	logic [6:0] HEX0; // единицы
	logic [6:0] HEX1; // десятки
	logic [6:0] HEX2; // зануляем
	logic [6:0] HEX3; //
	logic [1:0] debug_state;

	localparam logic [1:0] ST_GREEN = 2'b00;
	localparam logic [1:0] ST_YELLOW = 2'b01;
	localparam logic [1:0] ST_PED = 2'b11;
	
	traffic_light_top #(
		.DIV_LIMIT_1S(20),
		.GREEN_SECONDS(15),
		.YELLOW_SECONDS(3),
		.PED_SECONDS(10)
	) tested_u (
		.CLOCK_50(CLOCK_50),
		.KEY(KEY),
		.LEDR(LEDR),
		.LEDG(LEDG),
		.HEX0(HEX0),
		.HEX1(HEX1),
		.HEX2(HEX2),
		.HEX3(HEX3),
		.debug_state(debug_state)
	);
	
	initial begin
		CLOCK_50 = 0;
		forever #10 CLOCK_50 = ~CLOCK_50;
	end
	
	task automatic press_ped;
		begin
			@(posedge CLOCK_50);
			KEY[1] = 1'b0;
			@(posedge CLOCK_50);
			KEY[1] = 1'b1;
		end
	endtask
	
	task automatic check_outputs;
		case (tested_u.fsm_inst.fsm_state)
			ST_GREEN: begin
				if (LEDR !== 3'b001) $fatal(1, "GREEN: LEDR не 3'b001");
				if (LEDG !== 2'b10)  $fatal(1, "GREEN: LEDG не 2'b10");
			end
			ST_YELLOW: begin
				if (LEDR[2] || LEDR[0]) $fatal(1, "YELLOW: мигает не только LEDR[1]");
				if (LEDG !== 2'b10)     $fatal(1, "YELLOW: LEDG не 2'b10");
			end
			ST_PED: begin
				if (LEDR !== 3'b100) $fatal(1, "PED: LEDR не 3'b100");
				if (LEDG !== 2'b01)  $fatal(1, "PED: LEDG не 2'b01");
			end
			default: $fatal(1, "fsm_state == 2'b10 — недопустимое");
		endcase
	endtask
	
	initial begin
		KEY = 2'b10;
		repeat (5) @(posedge CLOCK_50);
		KEY[0] = 1'b1;
		repeat (2) @(posedge CLOCK_50);


		if (tested_u.fsm_inst.fsm_state !== ST_GREEN) $fatal(1, "Не в GREEN после сброса");
		if (tested_u.time_left !== 4'd15) $fatal(1, "time_left не 15 после сброса");
		check_outputs();

		wait (tested_u.fsm_inst.fsm_state == ST_GREEN && tested_u.time_left == 4'd12);
		press_ped();
		repeat (2) @(posedge CLOCK_50);
		if (tested_u.fsm_inst.fsm_state !== ST_YELLOW) $fatal(1, "Кнопка не перевела в YELLOW");
		if (tested_u.time_left !== 4'd3)                 $fatal(1, "Таймер не сократился до 3 с");
		check_outputs();
		
		begin
			logic b0, b1;
			b0 = LEDR[1];
			repeat (5) @(posedge CLOCK_50);
			b1 = LEDR[1];
			if (b0 === b1) $fatal(1, "LEDR[1] не мигает в фазе YELLOW");
		end

		wait (tested_u.fsm_inst.fsm_state == ST_PED);
		@(posedge CLOCK_50);
		if (tested_u.time_left !== 4'd10) $fatal(1, "PED: time_left не стартовал с 10");
		check_outputs();
		
		wait (tested_u.fsm_inst.fsm_state == ST_GREEN);
		@(posedge CLOCK_50);
		check_outputs();
		if (tested_u.time_left !== 4'd15) $fatal(1, "GREEN: таймер перезапустился не с 15");

		wait (tested_u.fsm_inst.fsm_state == ST_GREEN && tested_u.time_left == 4'd3);
		repeat (3) @(posedge CLOCK_50);
		if (tested_u.fsm_inst.fsm_state !== ST_YELLOW)
		$fatal(1, "Нет естественного перехода в YELLOW при time_left==3");

		wait (tested_u.fsm_inst.fsm_state == ST_PED);
		wait (tested_u.fsm_inst.fsm_state == ST_GREEN);

		$display("TEST PASSED");
		$finish;
	end

	always @(posedge CLOCK_50) begin
		if (LEDR[0] && LEDG[0])
			$fatal(1, "Одновременный зелёный авто и пешеходам");
	end
endmodule