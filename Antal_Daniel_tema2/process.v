`timescale 1ns / 1ps

module process (
        input                clk,		    	// clock 
        input  [23:0]        in_pix,	        // valoarea pixelului de pe pozitia [in_row, in_col] din imaginea de intrare (R 23:16; G 15:8; B 7:0)
        input  [8*512-1:0]   hiding_string,     // sirul care trebuie codat
        output reg [6-1:0]   row, col, 	        // selecteaza un rand si o coloana din imagine
        output               out_we, 		    // activeaza scrierea pentru imaginea de iesire (write enable)
        output [23:0]        out_pix,	        // valoarea pixelului care va fi scrisa in imaginea de iesire pe pozitia [out_row, out_col] (R 23:16; G 15:8; B 7:0)
        output reg           gray_done,		    // semnaleaza terminarea actiunii de transformare in grayscale (activ pe 1)
        output reg           compress_done,		// semnaleaza terminarea actiunii de compresie (activ pe 1)
        output               encode_done        // semnaleaza terminarea actiunii de codare (activ pe 1)
    );	
    
    //TODO - instantiate base2_to_base3 here
    
    //TODO - build your FSM here
	reg out = 0, done = 0, done_ambtc = 0, c_done = 0;
	reg [4:0] state = 0; 
	reg [4:0] next_state = 0;
	reg [23:0] pixel = 0;
	reg [6-1:0] copy_col = 0, copy_row = 0; // am facut o copie pentru cooana si pentru rand deoarece starea 4 se executa de 2 ori
	reg [7:0] max = 0, min = 255, R, G, B, diff;
	
	reg [23:0] array_sum [255:0], array_var [255:0], beta [255:0], avg[255:0], var[255:0], LM[255:0], HM[255:0];// folosesc un vector [255:0] la taskul 2 ca sa retin toate informtiile despre cele 256 de blocuri 4x4

	//partea secventiala
	always @(posedge clk) begin
   state <= next_state;
	col <= copy_col;
	row <= copy_row;
	gray_done <= done;
	compress_done <= c_done;
	end
	
	//partea combinationala
	always @(*) begin
	
		out = 0;//nu am nevoie de out = 1, mai mult decat timpukl pe care il petrece intr-o stare
		case(state)
		
			0: begin// in starea 0 doar initializez cu 0
			
					c_done = 0;
					pixel = 0;
					done = 0;
					next_state = 1;
					
				end
				
			1: begin
			
					R = in_pix[16+:8];
					G = in_pix[8+:8];
					B = in_pix[0+:8];
					
					max = (G >= R && G >= B) ? G:(B >= R && B >= G) ? B:R;
					min = (G <= R && G <= B) ? G:(B <= R && B <= G) ? B:R;
					pixel[8+:8] = (min + max)/2;//calculez media si o retin in variabila pixel
					
					next_state = 2;
					
				end
				
			2: begin
			
					out = 1;//schimb out in 1, astfel incat out_pix sa ia valorare lui pixel
					if ( array_sum[copy_col/4 + 16 * (copy_row/4)][0] === 1'bX ) begin//nu stiu cum sa initializez un vector cu 0, asa ca verific daca pe pozitia unde trebuie sa fac suma am prmul bit X
						array_sum[copy_col/4 + 16 * (copy_row/4)] = 24'b0;
						next_state = 2;
					end
					else begin
						array_sum[copy_col/4 + 16 * (copy_row/4)] = array_sum[copy_col/4 + 16 * (copy_row/4)] + pixel[8+:8];//calculez suma de care pentru fiecare bloc 4x4, de care o sa am nevoie la task-ul 2
						next_state = 3;
					end					
					
				end
				
			3: begin
			
				if( col == 63 && row == 63 ) begin//verific daca nu cumva am ajuns la ultima pozitie din matrice
					done = 1;
					copy_col = 0;
					copy_row = 0;
					next_state = 5;//daca am ajuns la ultima pozitie din matrice inseamna ca am terminat grayscale-ul
					end
				else next_state = 4;
				
				end
				
			4:	begin//starea 4 o folosesc de fiecare data cand vreau sa parcurg matricea
			
				if ( col < 63) begin//matricea este parcursa pe linii, de sus in jos si de la stanga la dreapta
					copy_col = col + 1;
				end
				else begin
				if ( row < 63 ) begin
						copy_col = 0;
						copy_row = row + 1;
					end
				end
				
				if ( done == 1 ) begin//daca am terminat cu grayscale-ul trec la compresie
					if( done_ambtc )//daca am terminat AMBTC trec la RECONSTRUCT
						next_state = 8;
					else next_state = 5;
				end
				else next_state = 0;
				
				end
				
			5: begin
			
				avg[copy_col/4 + 16 * (copy_row/4)] = array_sum[copy_col/4 + 16 * (copy_row/4)]/16;//calculez media pentru fiecare bloc 4x4(o sa fie calculat pentru fiecare pixel de fapt, dar oricum orice pixel din acelasi bloc 4x4 are aceeasi medie)
				next_state = 6;
				
				end
			
			6: begin
			
				if ( array_var[copy_col/4 + 16 * (copy_row/4)][0] === 1'bX )//aici rezolv din nou aceeasi problema cu vectorul array_var care este initializat cu X pe toti bitii
							array_var[copy_col/4 + 16 * (copy_row/4)] = 24'b0;
							
				if ( in_pix[8+:8] > avg[copy_col/4 + 16 * (copy_row/4)] )// fac modulul ui - AVG, de care am nevoie la var
					diff = in_pix[8+:8] - avg[copy_col/4 + 16 * (copy_row/4)];
				else diff = avg[copy_col/4 + 16 * (copy_row/4)] - in_pix[8+:8];
				
				array_var[copy_col/4 + 16 * (copy_row/4)] = array_var[copy_col/4 + 16 * (copy_row/4)] + diff;
				
				next_state = 7;
				
				end
			
			7: begin
			
				if ( beta[copy_col/4 + 16 * (copy_row/4)][0] === 1'bX )//aceeasi problema cu X
					beta[copy_col/4 + 16 * (copy_row/4)] = 24'b0;				
									
				if ( in_pix[8+:8] >= avg[copy_col/4 + 16 * (copy_row/4)] ) begin//inlocuiesc bitmapul direct in imagine
					pixel = 1;		
					beta[copy_col/4 + 16 * (copy_row/4)] = beta[copy_col/4 + 16 * (copy_row/4)] + 1;//numar pixelii de 1 din blocul 4x4
				end
				else pixel = 0;
				
				out = 1;//dau semnalul out 1 ca sa inlocuiesc pixelii
				next_state = 4;
				
				if ( col == 63 && row == 63 ) begin//daca ajung la final
					next_state = 8;
					done_ambtc = 1;//am terminat AMBTC
					copy_col = 0;
					copy_row = 0;//setez copiile la 0 ca sa pot parcurge din nou matricea
				end
				
				end
				
			8: begin
				
				//doar formule
				var[copy_col/4 + 16 * (copy_row/4)] = array_var[copy_col/4 + 16 * (copy_row/4)]/16;
				LM[copy_col/4 + 16 *(copy_row/4)] = avg[copy_col/4 + 16 * (copy_row/4)] - ((16 * var[copy_col/4 + 16 * (copy_row/4)])/(2 * (16 - beta[copy_col/4 + 16 * (copy_row/4)])));
				HM[copy_col/4 + 16 *(copy_row/4)] = avg[copy_col/4 + 16 * (copy_row/4)] + ((16 * var[copy_col/4 + 16 * (copy_row/4)])/(2 * beta[copy_col/4 + 16 * (copy_row/4)]));

				pixel = 0;
				if ( in_pix == 1)// fac RECONSTRUCT-ul
					pixel[8+:8] = HM[copy_col/4 + 16 * (copy_row/4)];
				else pixel[8+:8] = LM[copy_col/4 + 16 * (copy_row/4)];
							
				out = 1;//inlocuiesc in imagine
				next_state = 4;
				
				if (col == 63 && row == 63 ) begin//daca am ajuns la ultima pozitite din imagine, inseamna ca am terminat compresia
					next_state = 9;
					done_ambtc = 0;
					copy_col = 0;
					copy_row = 0;
					c_done = 1;
				end
				
				end
				
			9: begin// o stare finala in care sa ramana programul
			
				done = 0;
				c_done = 0;
				
				end
			
		endcase
	end
	
	assign out_we = out;
	assign out_pix = pixel;
    
endmodule
