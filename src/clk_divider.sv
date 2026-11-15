`timescale 1ns/1ps

module clk_divider #(parameter int DIV_LIMIT = 50_000_000)
(
	input logic clk,
	input logic rst_n,
	output logic tick
);
	localparam CNT_W = (DIV_LIMIT <= 1) ? 1 : $clog2(DIV_LIMIT);
	logic [CNT_W-1:0] cnt;
	
	always_ff @(posedge clk or negedge rst_n) begin
		if (!rst_n) begin
			cnt <= '0;
			tick <= 1'b0;
		end else begin
			tick <= 1'b0;
			if (DIV_LIMIT <= 1) begin
				tick <= 1'b1;
			end else if (cnt == DIV_LIMIT - 1) begin
				cnt <= '0;
				tick <= 1'b1;
			end else begin
				cnt <= cnt + 1'b1;
			end
		end
	end
endmodule