`timescale 1ns/1ps

module traffic_light_fsm #(
	parameter int DIV_LIMIT_1S = 50_000_000,
	parameter int GREEN_SECONDS  = 12,
	parameter int YELLOW_SECONDS = 3,
	parameter int PED_SECONDS    = 10,
	parameter int MAX_TIME	= (GREEN_SECONDS > YELLOW_SECONDS)
									? ((GREEN_SECONDS > PED_SECONDS) ? GREEN_SECONDS : PED_SECONDS) 
									: ((YELLOW_SECONDS > PED_SECONDS) ? YELLOW_SECONDS : PED_SECONDS),
	parameter int TIME_W = (MAX_TIME <= 0) ? 1 : $clog2(MAX_TIME + 1)
) (
	input logic clk,
	input logic rst_n,
	input logic btn_ped,
	output logic [2:0] cars_lights, //{RED, YELLOW, GREEN}
	output logic [1:0] ped_lights, //{P_RED, P_GREEN}
	output logic [TIME_W-1:0] time_left,
	output logic [1:0] fsm_state
);
	typedef enum logic [1:0] {
		GREEN  = 2'b00,
		YELLOW = 2'b01,
		PED    = 2'b11
   } state_t;
	state_t state, next_state;
	
	logic green_rst_n, yellow_rst_n, ped_rst_n;
   logic yellow_done, ped_done;
   logic [$clog2(GREEN_SECONDS+1)-1:0] green_left;
	logic [$clog2(YELLOW_SECONDS+1)-1:0] yellow_left;
	logic [$clog2(PED_SECONDS+1)-1:0] ped_left;
   logic blink;

   localparam int BLINK_DIV = (DIV_LIMIT_1S < 4) ? 1 : (DIV_LIMIT_1S / 4);
   localparam logic [$clog2(GREEN_SECONDS+1)-1:0] YELLOW_TRIG = YELLOW_SECONDS;

   phase_timer #(.SECONDS(GREEN_SECONDS), .DIV_LIMIT_1S(DIV_LIMIT_1S))
	green_timer (
       .clk(clk),
       .rst_n(green_rst_n),
       .time_left(green_left)
   );

   phase_timer #(.SECONDS(YELLOW_SECONDS), .DIV_LIMIT_1S(DIV_LIMIT_1S))
	yellow_timer (
       .clk(clk),
       .rst_n(yellow_rst_n),
       .timer_done(yellow_done),
       .time_left(yellow_left)
   );

	phase_timer #(.SECONDS(PED_SECONDS), .DIV_LIMIT_1S(DIV_LIMIT_1S))
	ped_timer (
       .clk(clk),
       .rst_n(ped_rst_n),
       .timer_done(ped_done),
       .time_left(ped_left)
   );

   blink_gen #(.DIV_LIMIT(BLINK_DIV))
	u_blink (
       .clk(clk),
       .rst_n(rst_n),
       .blink(blink)
   );

   always_ff @(posedge clk or negedge rst_n) begin
       if (!rst_n) state <= GREEN;
       else state <= next_state;
   end
	 
	always_comb begin
		next_state = state;
		case (state)
			GREEN: begin
				if (green_left == YELLOW_TRIG)
					next_state = YELLOW;
				else if (btn_ped)
					next_state = YELLOW;
			end
			YELLOW: if (yellow_done) next_state = PED;
			PED: if (ped_done) next_state = GREEN;
         default: next_state = GREEN;
		endcase	
	end
	 
	assign green_rst_n = rst_n && (state_t == GREEN);
	assign yellow_rst_n = rst_n && (state_t == YELLOW);
	assign ped_rst_n = rst_n && (state_t == PED);
	 
	always_comb begin
		cars_lights = 3'b000;
		ped_lights = 2'b00;
		time_left = '0;
		case (state)
			GREEN: begin 
				cars_lights = 3'b001;
				ped_lights = 2'b10;
				time_left = TIME_W'(green_left);
			end
			YELLOW: begin
				cars_lights = {1'b0, blink, 1'b0};
				ped_lights = 2'b10;
				time_left = TIME_W'(yellow_left);
			end
			PED: begin
				cars_lights = 3'b100;
				ped_lights = 2'b01;
				time_left = TIME_W'(ped_left);
			end
			default: begin
				cars_lights = 3'b100;
				ped_lights = 2'b10;
				time_left = '0;
			end
		endcase
	end

	assign fsm_state = state;
endmodule