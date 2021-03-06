module Snake(
		CLOCK_50,						//	On Board 50 MHz
		// Your inputs and outputs here
		SW,
		KEY,
		// The ports below are for the VGA output.  Do not change.
		VGA_CLK,   						//	VGA Clock
		VGA_HS,							//	VGA H_SYNC
		VGA_VS,							//	VGA V_SYNC
		VGA_BLANK_N,						//	VGA BLANK
		VGA_SYNC_N,						//	VGA SYNC
		VGA_R,   						//	VGA Red[9:0]
		VGA_G,	 						//	VGA Green[9:0]
		VGA_B   						//	VGA Blue[9:0]
	);

	input			CLOCK_50;				//	50 MHz
	input   [9:0]   SW;
	input   [3:0]   KEY;

	// Declare your inputs and outputs here
	// Do not change the following outputs
	output			VGA_CLK;   				//	VGA Clock
	output			VGA_HS;					//	VGA H_SYNC
	output			VGA_VS;					//	VGA V_SYNC
	output			VGA_BLANK_N;				//	VGA BLANK
	output			VGA_SYNC_N;				//	VGA SYNC
	output	[9:0]	VGA_R;   				//	VGA Red[9:0]
	output	[9:0]	VGA_G;	 				//	VGA Green[9:0]
	output	[9:0]	VGA_B;   				//	VGA Blue[9:0]
	
	wire resetn;
	assign resetn = SW[9];

	// Create an Instance of a VGA controller - there can be only one!
	// Define the number of colours as well as the initial background
	// image file (.MIF) for the controller.
	vga_adapter VGA(
		.resetn(SW[8]),
		.clock(CLOCK_50),
		.colour(color),
		.x(x),
		.y(y),
		.plot(1),
		/* Signals for the DAC to drive the monitor. */
		.VGA_R(VGA_R),
		.VGA_G(VGA_G),
		.VGA_B(VGA_B),
		.VGA_HS(VGA_HS),
		.VGA_VS(VGA_VS),
		.VGA_BLANK(VGA_BLANK_N),
		.VGA_SYNC(VGA_SYNC_N),
		.VGA_CLK(VGA_CLK)
	);

	defparam VGA.RESOLUTION = "160x120";
	defparam VGA.MONOCHROME = "FALSE";
	defparam VGA.BITS_PER_COLOUR_CHANNEL = 1;
	defparam VGA.BACKGROUND_IMAGE = "black.mif";
			
	// Put your code here. Your code should produce signals x,y,colour and writeEn/plot
	// for the VGA controller, in addition to any other functionality your design may require.
    
	wire stop_signal;
	wire right_signal;
	wire left_signal;
	wire up_signal;
	wire down_signal;
	wire [2:0] color;
	wire [7:0] x;
	wire [6:0] y;

	wire newClock;
   Slower_clock_maker rateDivider(
        .inputValue(2'b10),
        .clock(CLOCK_50),
        .out(newClock)
   );
	
	wire [1:0] go ;
	
	input_decoder d1(.left(~KEY[0]), .right(~KEY[1]), .up(~KEY[2]), .down(~KEY[3]), .go(go));
	 
   // Instansiate datapath
	// datapath d0(...);
	datapath d0(
		.clk(CLOCK_50),
		.resetn(resetn), 
		.stop_snake_sig(stop_signal),
		.move_right_sig(right_signal),
		.move_left_sig(left_signal),
		.move_up_sig(up_signal),
		.move_down_sig(down_signal),
		.colour(color),
		.x_out(x),
		.y_out(y)
	);

    // Instansiate FSM control
    // control c0(...);
	 control fsm(
		.clk(newClock),
		.resetn(resetn), 
		.go(go), 
		.stop_snake_sig(stop_signal), 
		.move_right_sig(right_signal), 
		.move_left_sig(left_signal), 
		.move_up_sig(up_signal), 
		.move_down_sig(down_signal)
	 );
    
endmodule

module control(clk, resetn, go, stop_snake_sig, move_right_sig, move_left_sig, move_up_sig, move_down_sig);
    // === Input Output Decarations ===
	input clk, resetn;
	input [1:0] go;

	output reg  stop_snake_sig, 
				move_right_sig, 
				move_left_sig, 
				move_up_sig, 
				move_down_sig;

    reg [2:0] 	current_state, next_state;


    // === Labels for states and inputs ===
    // Setting common names for readablity
    localparam  RESET = 3'd0,
    			SNAKE_MOVES_RIGHT = 3'd1, 
    			SNAKE_MOVES_LEFT = 3'd2, 
    			SNAKE_MOVES_UP = 2'd3, 
    			SNAKE_MOVES_DOWN = 3'd4;

    localparam 	LEFT = 2'd0,
    			RIGHT = 2'd1,
    			UP = 2'd2,
    			DOWN = 2'd3;


    // === State table ===
    // The state table should only contain the logic for state transitions
    // Do not mix in any output logic.  The output logic should be handled separately.
    // This will make it easier to read, modify and debug the code.
    always@(*)
    begin: state_table
        case (current_state)
        	RESET: next_state = SNAKE_MOVES_RIGHT;
			SNAKE_MOVES_RIGHT: begin 
				if (go == UP) 
					next_state = SNAKE_MOVES_UP;
				if (go == DOWN) 
					next_state = SNAKE_MOVES_DOWN;
				else next_state = SNAKE_MOVES_RIGHT;
			end
			SNAKE_MOVES_LEFT: begin
				if (go == UP) 
					next_state = SNAKE_MOVES_UP;
				if (go == DOWN) 
					next_state = SNAKE_MOVES_DOWN;
				else next_state = SNAKE_MOVES_LEFT;
			end
			SNAKE_MOVES_UP: begin 
				if (go == RIGHT) 
					next_state = SNAKE_MOVES_RIGHT;
				if (go == LEFT) 
					next_state = SNAKE_MOVES_LEFT;
				else next_state = SNAKE_MOVES_UP;
			end
			SNAKE_MOVES_DOWN: begin 
				if (go == RIGHT) 
					next_state = SNAKE_MOVES_RIGHT;
				if (go == LEFT) 
					next_state = SNAKE_MOVES_LEFT;
				else next_state = SNAKE_MOVES_DOWN;
			end
		default: next_state = current_state;
        endcase
    end


    // === Output Signals ===
    // These are signals that are used to drive the datapath.
    // aka all of our datapath control signals
    always@(*)
    begin: enable_signal
		move_right_sig = 1'b0;
		move_left_sig = 1'b0;
		move_up_sig = 1'b0;
		move_down_sig = 1'b0;
    	case (current_state)
			RESET: begin
				move_right_sig = 1'b0;
				move_left_sig = 1'b0;
				move_up_sig = 1'b0;
				move_down_sig = 1'b0;
				stop_snake_sig = 1'b1;
			end
			SNAKE_MOVES_RIGHT: begin 
				move_right_sig = 1'b1;
				move_left_sig = 1'b0;
				move_up_sig = 1'b0;
				move_down_sig = 1'b0;
				stop_snake_sig = 1'b0;					
			end
			SNAKE_MOVES_LEFT: begin
				move_right_sig = 1'b0;
				move_left_sig = 1'b1;
				move_up_sig = 1'b0;
				move_down_sig = 1'b0;
				stop_snake_sig = 1'b0;	
			end
			SNAKE_MOVES_UP: begin 
				move_right_sig = 1'b0;
				move_left_sig = 1'b0;
				move_up_sig = 1'b1;
				move_down_sig = 1'b0;
				stop_snake_sig = 1'b0;	
			end
			SNAKE_MOVES_DOWN: begin 
				move_right_sig = 1'b0;
				move_left_sig = 1'b0;
				move_up_sig = 1'b0;
				move_down_sig = 1'b1;
				stop_snake_sig = 1'b0;	
			end
			default: begin
				move_right_sig = 1'b0;
				move_left_sig = 1'b0;
				move_up_sig = 1'b0;
				move_down_sig = 1'b0;
				stop_snake_sig = 1'b0;
			end
    	endcase
    end


    // === Current_state registers ===
    // Used to update the states at the edge of the clock.
    always@(posedge clk)
    begin: state_FFs
        if(resetn)
            current_state <= RESET;
        else
            current_state <= next_state;
    end
endmodule


module datapath(clk, resetn, stop_snake_sig, move_right_sig, move_left_sig, move_up_sig, move_down_sig, colour, x_out, y_out);
    // === Input Output Decarations ===
	input clk, resetn;

	// Signals from FSM
	input   stop_snake_sig, 
			move_right_sig, 
			move_left_sig, 
			move_up_sig, 
			move_down_sig;

	output reg [7:0] x_out;
	output reg [6:0] y_out;
	
	// xb, yb are the blank squares that are drawn at the end of the snake
	// x_start and y_start are the initial points of the square to be drawn
	reg	[7:0] x_start, x1, x2, x3, x4, x5, xb;
	reg	[6:0] y_start, y1, y2, y3, y4, y5, yb;
	output reg [2:0] colour;

	wire newClock;
   Slower_clock_maker rateDivider(
        .inputValue(2'b00),
        .clock(clk),
        .out(newClock)
   );

	wire counter;
	Count_to_six c1(
		.reset_n(resetn),
		.clock(newClock),
		.enable(1'b1),
		.q(counter)
	);

	wire [3:0] counter2;
	Counter c2 (
		.reset_n(resetn), 
		.clock(clk), 
		.enable(1'b1), 
		.q(counter2)
	);


	// === Clock Edge Actions ===
	always @(posedge newClock) begin
        if (resetn) begin
    		x1 <= 8'd80;
        	y1 <= 7'd60;
        	
        	x5 <= x4 - 3'd4; x4 <= x3 - 3'd4; x3 <= x2 - 3'd4; x2 <= x1 - 3'd4; 
        	y5 <= y4 ; y4 <= y3 ; y3 <= y2; y2 <= y1;

        	xb <= x5 - 3'd4; 
    		yb <= y5 ;

    		x_start <= x1;
    		y_start <= y1;
        end
        else begin
    		x5 <= x4; x4 <= x3; x3 <= x2; x2 <= x1;
        	y5 <= y4; y4 <= y3; y3 <= y2; y2 <= y1;
			
        	if (move_right_sig)
        		x1 <= x1 + 3'd4;
        	if (move_left_sig)
        		x1 <= x1 - 3'd4;
        	if (move_up_sig)
        		y1 <= y1 - 3'd4;
        	if (move_down_sig)
        		y1 <= y1 + 3'd4;

        	if (counter == 1'd0) begin 
        		x_start <= x1;
        		y_start <= y1;
        		colour <= 3'b011;
        	end
        	if (counter == 1'd1) begin
        		x_start <= xb;
        		y_start <= yb;
        		colour <= 3'b000;
        	end
        end
		 end 

    always @(posedge clk) begin
			x_out <= x_start + counter2[1:0];
			y_out <= y_start + counter2[1:0];
		  end
	 
endmodule


module input_decoder(left, right, up, down, go);
	input left;
	input right;
	input up;
	input down;
	output [1:0] go;
	
	assign go[0] = left + right;
	assign go[1] = right + down;
endmodule


module Count_to_six(reset_n, clock, enable, q);           
    input clock;                  
    input reset_n;
    input enable; 
    output reg [3:0] q;            

    always @(posedge clock) begin
        if (reset_n == 0)
            q <= 0;
        else if (enable == 1'b1) begin
            if (q == 3'd6)    
                q <= 0;
            else 
                q <= q + 1'b1;
        end
    end
endmodule

module Counter(reset_n, clock, enable, q);           
    input clock;                  
    input reset_n;
    input enable; 
    output reg [3:0] q;                      

    always @(posedge clock) begin
        if (reset_n == 0)
            q <= 0;
        else if (enable == 1'b1) begin
            if (q == 4'b1111)    
                q <= 0;
            else 
                q <= q + 1'b1;
        end
    end
endmodule

module Slower_clock_maker(input [1:0]inputValue, input clock, output [27:0]out);
    wire [25:0] d;            
    reg [27:0] value;             
    reg [27:0] rateDivider;   

    always @(*) 
        case(inputValue)
				2'b00: value = 28'b0;
            2'b01: value = 28'd49999999;
            2'b10: value = 28'd8;
            2'b11: value = 28'd199999999;
            default value = 28'b0;
	endcase

    always @(posedge clock) begin
            if (rateDivider == 1'b0)begin
				
                
					 rateDivider <= value;
					 end
            else
                rateDivider <= rateDivider - 1'b1;
        end
    
    assign out = (rateDivider == 28'b0) ? 1 :0;
endmodule
