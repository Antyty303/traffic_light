`timescale 1ns/1ps

module blink_gen #(parameter int DIV_LIMIT = 12_500_000)
(
	input logic clk,
	input logic rst_n,
	output logic blink
);
	logic tick;
	
	clk_divider #(.DIV_LIMIT(DIV_LIMIT)) u_clk_div (
		.clk(clk),
		.rst_n(rst_n),
		.tick(tick)
	);
	
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) blink <= 0'b0;
		else if (tick) blink <= ~blink;
	end
endmodule