`timescale 1ns/1ps

module phase_timer #(
	parameter int SECONDS = 10,
	parameter int DIV_LIMIT_1S = 50_000_000
) (
	input logic clk,
	input logic rst_n,
	output logic timer_done,
	output logic [$clog2(SECONDS+1)-1:0] time_left
);
	logic tick_1s;
	
	clk_divider #(.DIV_LIMIT(DIV_LIMIT_1S)) u_sec_div (
		.clk(clk),
		.rst_n(rst_n),
		.tick(tick_1s)
	);

	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n)
			time_left <= SECONDS;
		else if (tick_1s && (time_left > 0))
			time_left <= time_left - 1'b1;
	end
	
	assign timer_done = tick_1s && (time_left == 1);
	
endmodule