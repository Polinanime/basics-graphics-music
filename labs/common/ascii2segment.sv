module ascii2segment (
	input				clk,
	input		[7:0]	ascii,
	output	reg [7:0] 	abcdefgh
);

    //   --a--
    //  |     |
    //  f     b
    //  |     |
    //   --g--
    //  |     |
    //  e     c
    //  |     |
    //   --d--  h

	always @ ( posedge clk ) begin
	  case(ascii)
		 8'h20: abcdefgh <= 8'b00000000;//space
		 8'h2E: abcdefgh <= 8'b00000001;//.
		 8'h30: abcdefgh <= 8'b11111100;//0
		 8'h31: abcdefgh <= 8'b01100000;//1
		 8'h32: abcdefgh <= 8'b11011010;//2
		 8'h33: abcdefgh <= 8'b11110010;//3
		 8'h34: abcdefgh <= 8'b01100110;//4
		 8'h35: abcdefgh <= 8'b10110110;//5
		 8'h36: abcdefgh <= 8'b10111110;//6
		 8'h37: abcdefgh <= 8'b11100000;//7
		 8'h38: abcdefgh <= 8'b11111110;//8
		 8'h39: abcdefgh <= 8'b11110110;//9
		 
		 8'h41: abcdefgh <= 8'b11101110;//A
		 8'h42: abcdefgh <= 8'b00111110;//B
		 8'h43: abcdefgh <= 8'b10011100;//C
		 8'h44: abcdefgh <= 8'b01111010;//D
		 8'h45: abcdefgh <= 8'b10011110;//E
		 8'h46: abcdefgh <= 8'b10001110;//F
		 8'h47: abcdefgh <= 8'b10111100;//G
		 8'h48: abcdefgh <= 8'b01101110;//H

		 8'h49: abcdefgh <= 8'b00001100;//I
		 8'h4A: abcdefgh <= 8'b01110000;//J
		 8'h4B: abcdefgh <= 8'b00000010;//K -
		 8'h4C: abcdefgh <= 8'b00011100;//L
		 8'h4D: abcdefgh <= 8'b00000010;//M -
		 8'h4E: abcdefgh <= 8'b00101010;//N
		 8'h4F: abcdefgh <= 8'b00111010;//O
		 8'h50: abcdefgh <= 8'b00101100;//P
		 8'h51: abcdefgh <= 8'b11100110;//Q
		 8'h52: abcdefgh <= 8'b00001010;//R
		 8'h53: abcdefgh <= 8'b10110110;//S
		 8'h54: abcdefgh <= 8'b00011110;//T
		 8'h55: abcdefgh <= 8'b00111000;//U
		 8'h56: abcdefgh <= 8'b00000010;//V
		 8'h57: abcdefgh <= 8'b01010100;//W
		 8'h58: abcdefgh <= 8'b00000010;//X
		 8'h59: abcdefgh <= 8'b01110110;//Y
		 8'h5A: abcdefgh <= 8'b00011100;//Z

	  default:
		  abcdefgh <= 8'b00000010; // -
	  endcase
  end

endmodule
