`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    20:08:20 12/02/2022 
// Design Name: 
// Module Name:    base2_to_base3 
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
module base2_to_base3(    
	output   [31 : 0]  base3_no, 
   output             done,
   input    [15 : 0]  base2_no,
   input              en,
   input              clk
    );
	 
	reg [1:0] state = 2'b0; 
	reg [1:0] next_state = 2'b0; 
	reg [15:0] base2_no_r;
	reg [31:0]base3_no_r = 0;
	reg out;
	reg [5:0] i = 0;
	
	reg [15:0] x; //intrarile div_algo
	reg [15:0] y = 3;
	
	wire [15:0] Q; //iesirile div_algo
	wire [15:0] R;

	div_algo DIV(Q,R,x,y);

	always @(posedge clk) begin
   state <= next_state;
	end
	
	always @(*) begin
    case(state)
        0: begin
				out = 0;
				base3_no_r = 0;
				i = 0;
				
				if(!en) begin
					next_state = 0;
				end
				else begin
						base2_no_r = base2_no;
						next_state = 1;
						end
        end
			
        1: begin
				x = base2_no_r;
				next_state = 2;
        end
        
        2: begin
				base3_no_r[i+1-:2] = R;
				i = i + 2;
				base2_no_r = Q;
				
				if (base2_no_r != 0)begin
					next_state = 1;
				end
				else begin
					next_state = 3;
				end
        end
        
        3: begin
				next_state = 0;
				out = 1;
        end
		  
    endcase
	end
	
	assign done = out;
	assign base3_no = base3_no_r;
	 
endmodule
