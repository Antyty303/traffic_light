`timescale 1ns/1ps

module bin_to_bcd #(parameter int BIN_W = 4) 
(
	input  logic [BIN_W-1:0] bin,
	output logic [3:0]       tens,
	output logic [3:0]       units
);
	logic [BIN_W+7:0] shift_reg;

	always_comb begin
		shift_reg = {8'b0, bin};
		for (int i = 0; i < BIN_W; i++) begin
		
			if (shift_reg[BIN_W +: 4] >= 4'd5)
				shift_reg[BIN_W +: 4] = shift_reg[BIN_W +: 4] + 4'd3;
				
			if (shift_reg[BIN_W+4 +: 4] >= 4'd5)
				shift_reg[BIN_W+4 +: 4] = shift_reg[BIN_W+4 +: 4] + 4'd3;

			shift_reg = shift_reg << 1;
		end

		units = shift_reg[BIN_W +: 4];
		tens  = shift_reg[BIN_W+4 +: 4];
	end

endmodule
