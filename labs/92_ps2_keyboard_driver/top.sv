`include "config.svh"

module top
# (
    parameter clk_mhz = 50,
              w_key   = 4,
              w_sw    = 8,
              w_led   = 8,
              w_digit = 8,
              w_gpio  = 100,
              w_vgar  = 4,
              w_vgag  = 4,
              w_vgab  = 4
)
(
    input                        clk,
    input                        slow_clk,
    input                        rst,

    // Keys, switches, LEDs

    input        [w_key   - 1:0] key,
    input        [w_sw    - 1:0] sw,
    output logic [w_led   - 1:0] led,

    // A dynamic seven-segment display

    output logic [          7:0] abcdefgh,
    output logic [w_digit - 1:0] digit,

    // VGA

    output logic                 vsync,
    output logic                 hsync,
    output logic [ w_vgar - 1:0] red,
    output logic [ w_vgag - 1:0] green,
    output logic [ w_vgab - 1:0] blue,

    input                        uart_rx,
    output                       uart_tx,

    input                        mic_ready,
    input        [         23:0] mic,
    output       [         15:0] sound,

    // General-purpose Input/Output

    inout        [w_gpio  - 1:0] gpio,

    // PS/2 pins

    input                       ps_clock,
    inout                       ps_data,

    // Buzzer

    output                      buzzer

);

	reg [31:0]  data;
	reg [31:0] 	hold;

   reg [7:0]	pskey;

	wire        flag;

   wire [7:0] letterCnt;
	 
	wire [7:0]	ps2_ascii;
	
	wire [7:0]	ps2_segment;
	
	wire			ps_enable;
	
	wire			fifo_empty;
	wire 			fifo_overflow;
	
	initial begin
		data <= 0;
		hold <= 0;
		ps_enable <= 1;
		flag <= 1;
	end
	 
	 always_ff @ ( posedge clk ) begin
		if ( rst	 ) begin
				data <= '0;
		end
		if ( flag ) begin
            data [31:24] <= data [23:16];
            data [23:16] <= data [15:8];
            data [15: 8] <= data [7:0];
            data [ 7: 0] <= ps2_segment;

            letterCnt <= letterCnt + 1;
		end
	end
	
    //------------------------------------------------------------------------

    // seven-segment display output
    always_ff @ ( posedge clk ) begin
        if ( rst ) begin
            abcdefgh <= '0;
				digit 	<= '0;
				// led 		<= '0;
        end 
        else begin
            abcdefgh <= data[7:0];
            // led      <= letterCnt;
            digit    <= '1; //letterCnt;
				ps_enable <= '1;
        end
    end
    
    //------------------------------------------------------------------------
	 
     ps2 keyboard ( 
        .CLK ( clk ),
        .PS2_CLK  ( ps_clock  ),
        .PS2_DATA ( ps_data   ),
		  .LED ( led ),
		  
        .CODEWORD  ( pskey  ), 
        .TRIG_ARR ( flag ) ,
		  // .abcdefgh ( abcdefgh )
    );
		  
	 key2ascii key2ascii (
		  .clk			( clk ),
		  .ps2_byte_r	( pskey ),
		  .ps2_asci		( ps2_ascii)
	 );
	 
	 ascii2segment ascii2segment (
		  .clk			( clk ),
		  .ascii		( ps2_ascii	  ),
		  .out			( ps2_segment )
	 );
	 
    

    //------------------------------------------------------------------------


    // assign led      = '0;
    // assign abcdefgh = '0;
    // assign digit    = '0;
       assign vsync    = '0;
       assign hsync    = '0;
       assign red      = '0;
       assign green    = '0;
       assign blue     = '0;
       assign sound    = '0;
       assign uart_tx  = '1;

endmodule
