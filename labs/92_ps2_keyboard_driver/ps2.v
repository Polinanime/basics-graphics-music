`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: Montvydas Klumbys	
//
//////////////////////////////////////////////////////////////////////////////////

module ps2(
	input CLK,	//board clock
   input PS2_CLK,	//keyboard clock and data signals
   input PS2_DATA,
//	output reg scan_err,			//These can be used if the Keyboard module is used within a another module
//	output reg [10:0] scan_code,
//	output reg [3:0]COUNT,
	output reg TRIG_ARR,
	output reg [7:0]CODEWORD,
   output reg [7:0] LED	//8 LEDs
//	output reg [7:0] abcdefgh
   );

	wire [7:0] ARROW_UP = 8'h75;	//codes for arrows
	wire [7:0] ARROW_DOWN = 8'h72;
	//wire [7:0] ARROW_LEFT = 8'h6B;
	//wire [7:0] ARROW_RIGHT = 8'h74;
	//wire [7:0] EXTENDED = 8'hE0;	//codes 
	//wire [7:0] RELEASED = 8'hF0;

	reg read;				//this is 1 if still waits to receive more bits 
	reg [11:0] count_reading;		//this is used to detect how much time passed since it received the previous codeword
	reg PREVIOUS_STATE;			//used to check the previous state of the keyboard clock signal to know if it changed
	reg scan_err;				//this becomes one if an error was received somewhere in the packet
	reg [10:0] scan_code;			//this stores 11 received bits
//	reg [7:0] CODEWORD;			//this stores only the DATA codeword
//	reg TRIG_ARR;				//this is triggered when full 11 bits are received
	reg [3:0]COUNT;				//tells how many bits were received until now (from 0 to 11)
	reg TRIGGER = 0;			//This acts as a 250 times slower than the board clock. 
	reg [7:0]DOWNCOUNTER = 0;		//This is used together with TRIGGER - look the code
	
	wire	[7:0]	ascii;
	wire	[7:0]	segment;

	//Set initial values
	initial begin
		PREVIOUS_STATE = 1;		
		scan_err = 0;		
		scan_code = 0;
		COUNT = 0;			
		CODEWORD = 0;
		LED = 0;
		read = 0;
		count_reading = 0;
	end

	always @(posedge CLK) begin				//This reduces the frequency 250 times
		if (DOWNCOUNTER < 249) begin			//and uses variable TRIGGER as the new board clock 
			DOWNCOUNTER <= DOWNCOUNTER + 1;
			TRIGGER <= 0;
		end
		else begin
			DOWNCOUNTER <= 0;
			TRIGGER <= 1;
		end
	end
	
	always @(posedge CLK) begin	
		if (TRIGGER) begin
			if (read)				//if it still waits to read full packet of 11 bits, then (read == 1)
				count_reading <= count_reading + 1;	//and it counts up this variable
			else 						//and later if check to see how big this value is.
				count_reading <= 0;			//if it is too big, then it resets the received data
		end
	end


	always @(posedge CLK) begin		
	if (TRIGGER) begin						//If the down counter (CLK/250) is ready
		if (PS2_CLK != PREVIOUS_STATE) begin			//if the state of Clock pin changed from previous state
			if (!PS2_CLK) begin				//and if the keyboard clock is at falling edge
				read <= 1;				//mark down that it is still reading for the next bit
				scan_err <= 0;				//no errors
				scan_code[10:0] <= {PS2_DATA, scan_code[10:1]};	//add up the data received by shifting bits and adding one new bit
				COUNT <= COUNT + 1;			//
			end
		end
		else if (COUNT == 11) begin				//if it already received 11 bits
			COUNT <= 0;
			read <= 0;					//mark down that reading stopped
			TRIG_ARR <= 1;					//trigger out that the full pack of 11bits was received
			//calculate scan_err using parity bit
			if (!scan_code[10] || scan_code[0] || !(scan_code[1]^scan_code[2]^scan_code[3]^scan_code[4]
				^scan_code[5]^scan_code[6]^scan_code[7]^scan_code[8]
				^scan_code[9]))
				scan_err <= 1;
			else 
				scan_err <= 0;
		end	
		else  begin						//if it yet not received full pack of 11 bits
			TRIG_ARR <= 0;					//tell that the packet of 11bits was not received yet
			if (COUNT < 11 && count_reading >= 4000) begin	//and if after a certain time no more bits were received, then
				COUNT <= 0;				//reset the number of bits received
				read <= 0;				//and wait for the next packet
			end
		end
	PREVIOUS_STATE <= PS2_CLK;					//mark down the previous state of the keyboard clock
	end
	end


	always @(posedge CLK) begin
		if (TRIGGER) begin					//if the 250 times slower than board clock triggers
			if (TRIG_ARR) begin				//and if a full packet of 11 bits was received
				if (scan_err) begin			//BUT if the packet was NOT OK
					CODEWORD <= 8'd0;		//then reset the codeword register
				end
				else begin
					CODEWORD <= scan_code[8:1];	//else drop down the unnecessary  bits and transport the 7 DATA bits to CODEWORD reg
				end				//notice, that the codeword is also reversed! This is because the first bit to received
			end					//is supposed to be the last bit in the codeword…
			else CODEWORD <= 8'd0;				//not a full packet received, thus reset codeword
		end
		else CODEWORD <= 8'd0;					//no clock trigger, no data…
	end
	
	always @(posedge CLK) begin
	//if (TRIGGER) begin
	//	if (TRIG_ARR) begin
//		LED<=scan_code[8:1];			//You can put the code on the LEDs if you want to, that’s up to you 
		if (CODEWORD == ARROW_UP)				//if the CODEWORD has the same code as the ARROW_UP code
			LED <= LED + 1;					//count up the LED register to light up LEDs
		else if (CODEWORD == ARROW_DOWN)			//or if the ARROW_DOWN was pressed, then
			LED <= LED - 1;					//count down LED register 
		else if (CODEWORD == 8'h15 )		// Q - set count to 0
			LED <= 8'b00000000;
		//else										// display symbol on 7segment		
		//	abcdefgh <= segment;
		
		

			//if (CODEWORD == EXTENDED)			//For example you can check here if specific codewords were received
			//if (CODEWORD == RELEASED)
		//end
	//end
	end
	
	//---------------------------------------------------------------------------------
	
	key2ascii key2ascii (
		  .clk			( CLK ),
		  .ps2_byte_r  ( CODEWORD ),
		  .ps2_asci  	( ascii )
	 );
	 
	 ascii2segment ascii2segment (
		  .clk			( CLK 		),
		  .ascii			( ascii		),
		  .out			( segment	)
	 );
	
	//---------------------------------------------------------------------------------

endmodule



module key2ascii (
	input					clk,
	input  	  [7:0]	ps2_byte_r,
	output reg [7:0]	ps2_asci
);

	always @ (posedge clk) begin
		case (ps2_byte_r)
			8'h15: ps2_asci <= 8'h51;	//Q
			8'h1d: ps2_asci <= 8'h57;	//W
			8'h24: ps2_asci <= 8'h45;	//E
			8'h2d: ps2_asci <= 8'h52;	//R
			8'h2c: ps2_asci <= 8'h54;	//T
			8'h35: ps2_asci <= 8'h59;	//Y
			8'h3c: ps2_asci <= 8'h55;	//U
			8'h43: ps2_asci <= 8'h49;	//I
			8'h44: ps2_asci <= 8'h4f;	//O
			8'h4d: ps2_asci <= 8'h50;	//P				  	
			8'h1c: ps2_asci <= 8'h41;	//A
			8'h1b: ps2_asci <= 8'h53;	//S
			8'h23: ps2_asci <= 8'h44;	//D
			8'h2b: ps2_asci <= 8'h46;	//F
			8'h34: ps2_asci <= 8'h47;	//G
			8'h33: ps2_asci <= 8'h48;	//H
			8'h3b: ps2_asci <= 8'h4a;	//J
			8'h42: ps2_asci <= 8'h4b;	//K
			8'h4b: ps2_asci <= 8'h4c;	//L
			8'h1a: ps2_asci <= 8'h5a;	//Z
			8'h22: ps2_asci <= 8'h58;	//X
			8'h21: ps2_asci <= 8'h43;	//C
			8'h2a: ps2_asci <= 8'h56;	//V
			8'h32: ps2_asci <= 8'h42;	//B
			8'h31: ps2_asci <= 8'h4e;	//N
			8'h3a: ps2_asci <= 8'h4d;	//M

			8'h16: ps2_asci <= 8'h31;	//1
			8'h1e: ps2_asci <= 8'h32;	//2
			8'h26: ps2_asci <= 8'h33;	//3
			8'h25: ps2_asci <= 8'h34;	//4
			8'h2e: ps2_asci <= 8'h35;	//5
			8'h36: ps2_asci <= 8'h36;	//6
			8'h3d: ps2_asci <= 8'h37;	//7
			8'h3e: ps2_asci <= 8'h38;	//8
			8'h46: ps2_asci <= 8'h39;	//9
			8'h45: ps2_asci <= 8'h30;	//0

			default: ;//space
			endcase
	end

endmodule

module ascii2segment (
	input						clk,
	input			 [7:0]	ascii,
	output	reg [7:0] 	out
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
		 8'h20:out <= 8'b00000000;//space
		 8'h2E:out <= 8'b00000001;//.
		 8'h30:out <= 8'b11111100;//0
		 8'h31:out <= 8'b01100000;//1
		 8'h32:out <= 8'b11011010;//2
		 8'h33:out <= 8'b11110010;//3
		 8'h34:out <= 8'b01100110;//4
		 8'h35:out <= 8'b10110110;//5
		 8'h36:out <= 8'b00111110;//6
		 8'h37:out <= 8'b11100000;//7
		 8'h38:out <= 8'b11111110;//8
		 8'h39:out <= 8'b11100110;//9
		 
		 8'h41:out <= 8'b11101110;//A
		 8'h42:out <= 8'b11111110;//B
		 8'h43:out <= 8'b10011100;//C
		 8'h44:out <= 8'b01111010;//D
		 8'h45:out <= 8'b10011110;//E
		 8'h46:out <= 8'b10101100;//F
		 8'h47:out <= 8'b10111100;//G
		 8'h48:out <= 8'b01101110;	// 8'b01101110;//H

		 8'h49:out <= 8'b00001100;//I
		 8'h4A:out <= 8'b01110000;//J
		 8'h4B:out <= 8'b00000010;//K -
		 8'h4C:out <= 8'b00011100;//L
		 8'h4D:out <= 8'b00000010;//M -
		 8'h4E:out <= 8'b00101010;//N
		 8'h4F:out <= 8'b00111010;//O
		 8'h50:out <= 8'b00101100;//P
		 8'h51:out <= 8'b11100110;//Q
		 8'h52:out <= 8'b00001010;//R
		 8'h53:out <= 8'b10110110;//S
		 8'h54:out <= 8'b00011110;//T
		 8'h55:out <= 8'b00111000;//U
		 8'h56:out <= 8'b00000010;//V
		 8'h57:out <= 8'b01010100;//W
		 8'h58:out <= 8'b00000010;//X
		 8'h59:out <= 8'b01110110;//Y
		 8'h5A:out <= 8'b00011100;//Z




         
	  default:
		 out <= 8'b00000010; // -
	  endcase
  end

endmodule
