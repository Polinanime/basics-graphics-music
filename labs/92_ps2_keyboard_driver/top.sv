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

	logic [w_digit-1:0][7:0] segment_shift_reg;

	wire        ps2_valid;
	wire [7:0]	ps2_ascii;
	wire [7:0]	ps2_segment, segment_r;

	always_ff @ (posedge clk) begin
		if (rst)
			segment_r <= '0;
		else if (ps2_valid & ps2_pressed)
		    segment_r <= ps2_segment;

	end
	 
	 always_ff @ (posedge clk) begin
		if (rst) begin
			segment_shift_reg <= '0;
		end
		if ( ps2_valid ) begin
			segment_shift_reg <= { segment_shift_reg[w_digit-2:0], ps2_segment };
		end
	end
	
    //------------------------------------------------------------------------

    // seven-segment display output

    logic [31:0] cnt;

    always_ff @ (posedge clk or posedge rst)
        if (rst)
            cnt <= '0;
        else
            cnt <= cnt + 1'd1;

    wire diplay_shift_enable = (cnt [17:0] == '0);

    logic [w_digit:0] digit_display_idx;
    always_ff @ (posedge clk or posedge rst)
      if (rst)
        digit_display_idx <= w_digit' (1);
      else if (diplay_shift_enable)
        digit_display_idx <= { digit_display_idx [0], digit_display_idx [w_digit - 1:1] };

	// assign abcdefgh = | (segment_shift_reg & {8 {digit_display_idx}});
	always_comb begin
		abcdefgh = '0;
		for(int i = 0; i < w_digit; i++) begin
			if(digit_display_idx>>i)
				abcdefgh = segment_shift_reg[i];
		end
	end

	// assign digit    = digit_display_idx;
	// assign abcdefgh = segment_r;
	assign digit    = digit_display_idx;
    
    //------------------------------------------------------------------------
	 
     ps2_keyboard keyboard ( 
        .CLK 		( clk ),
        .PS2_CLK  	( ps_clock  ),
        .PS2_DATA 	( ps_data   ),
		.LED 	  	( led ),
		
        .ps2_scancode  	(   ), 
        .ps2_valid 	( ps2_valid ) ,
		.ASCII 		( ps2_ascii )
    );
	 
	 ascii2segment ascii2segment (
		  .clk			( clk ),
		  .ascii		( ps2_ascii	  ),
		  .abcdefgh		( ps2_segment )
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
