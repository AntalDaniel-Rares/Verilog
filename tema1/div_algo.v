`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    21:08:23 12/01/2022 
// Design Name: 
// Module Name:    div_algo 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

module div_algo (
	output [15:0] Q,
	output [15:0] R,
	input  [15:0] N,
	input  [15:0] D);

	reg [4:0] i;	
	reg [15:0] cat;
	reg [15:0] rest;
	
	always @(*) begin
		
		i = 15;
		cat = 0;
		rest = 0;
		
		if(D == 0) begin 
			$display("Nu se poate efectua impartirea!");
		end
		
		else
		for(i = 15; i > 0; i = i - 1)
			begin
				rest = rest << 1;
				rest[0] = N[i];
				
				if(rest >= D) begin
					cat[i] = 1;
					rest = rest - D;
				end
			end
			
		if (i == 0)
			begin
				rest = rest << 1;
				rest[0] = N[i];
				
				if(rest >= D) begin
					cat[i] = 1;
					rest = rest - D;
				end
			end
			
	end
	
	assign Q = cat;
	assign R = rest;
	
endmodule

