`timescale 1ns/1ps


//поведение программы будет некорректным при MAX_TIME > 99
//при GREEN_SEC = YELLOW_SEC зелёный свет будет загараться на 1 такт
//при GREEN_SEC < YELLOW_SEC что угодно. Если жёлтый после обрезания всё ещё дольше, то зелёный свет будет переключаться только  по кнопке
module traffic_light_top #(
	parameter int DIV_LIMIT_1S = 50_000_000,
	parameter int GREEN_SECONDS  = 12,
	parameter int YELLOW_SECONDS = 3,
	parameter int PED_SECONDS    = 10,
	parameter int MAX_TIME = (GREEN_SECONDS > YELLOW_SECONDS)
								  ? ((GREEN_SECONDS > PED_SECONDS) ? GREEN_SECONDS : PED_SECONDS)
								  : ((YELLOW_SECONDS > PED_SECONDS) ? YELLOW_SECONDS : PED_SECONDS),
	parameter int TIME_W = (MAX_TIME <= 0) ? 1 : $clog2(MAX_TIME + 1)
) ( 
	input  logic CLOCK_50,
	input  logic [1:0] KEY,  //KEY[0] — сброс, KEY[1] — кнопка пешехода
	output logic [2:0] LEDR, //{RED, YELLOW, GREEN}
	output logic [1:0] LEDG, //{P_RED, P_GREEN}
	output logic [6:0] HEX0, // единицы
	output logic [6:0] HEX1, // десятки
	output logic [6:0] HEX2, // зануляем
	output logic [6:0] HEX3  //
);
	logic rst_n;
	logic btn_ped;
	logic [2:0] cars_lights;
	logic [1:0] ped_lights;
	logic [TIME_W-1:0] time_left;
	logic [1:0] fsm_state;

	logic [3:0] tens, units;

	assign rst_n = KEY[0];
	assign btn_ped = ~KEY[1];

	traffic_light_fsm #(
		.DIV_LIMIT_1S(DIV_LIMIT_1S),
		.GREEN_SECONDS (GREEN_SECONDS),
		.YELLOW_SECONDS(YELLOW_SECONDS),
		.PED_SECONDS   (PED_SECONDS)
	) fsm_inst (
		.clk(CLOCK_50),
		.rst_n(rst_n),
		.btn_ped(btn_ped),
		.cars_lights(cars_lights),
		.ped_lights(ped_lights),
		.time_left(time_left),
		.fsm_state(fsm_state)
	);

	assign LEDR = cars_lights;
	assign LEDG = ped_lights;

	bin_to_bcd #(.BIN_W(TIME_W)) u_bcd (
		.bin (time_left),
		.tens (tens),
		.units (units)
	);

	seven_seg_decoder dec0 (.bin(units), .seg(HEX0));
	seven_seg_decoder dec1 (.bin(tens), .seg(HEX1));
	assign HEX2 = ~7'b0000000;
	assign HEX3 = ~7'b0000000;
	
endmodule