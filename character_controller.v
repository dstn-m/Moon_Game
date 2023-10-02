`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/24/2023 06:13:21 PM
// Design Name: 
// Module Name: character_controller
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module character_controller(
    input clk_i, rst_i,
    input disp_active, scrn_refresh, jump, fwd, rvs,
	input [8:0] ht_upper, ht_lower, 
    input [10:0] pix_x, pix_y, 
	output character_active, char_body,
    output [11:0] color_o
	
    );

localparam GRN 		= 12'h0F0;
localparam HEIGHT 	= 48;
localparam WIDTH 	= 64;
localparam CHAR_H 	= 44;
localparam LEG_W 	= 32; 
localparam LEG_H 	= 24;
localparam LEG_DX 	= 6;
localparam LEG_RVS  = 20;

localparam CHAR_X_START = 127;
localparam CHAR_Y_START = 291;

localparam state_LEVEL 	 = 2'b00;
localparam state_JUMPING = 2'b01;
localparam state_FALLING = 2'b10;


wire[9:0] charx_w, chary_w, legx_w, legy_w, foot_y;
wire foot_x_b, foot_x_f;
wire[3:0] fall_increment;
reg [1:0]grounding_reg; 
reg grounded = 1, walking = 0;
reg[9:0] ground_b, ground_f;
wire char_active, char_body_w, char_disp, leg_active, leg_disp;
wire[5:0] char_col;
wire[6:0] char_row;
wire[11:0] char_color, leg_color;
wire[12:0] char_addr;
wire[11:0] leg_addr;

wire[7:0] leg_offset;
wire[5:0] char_offset;
reg [4:0] walk_counter = 0;
reg[7:0] dy_counter = 0;
reg jump_prev;
wire jump_pulse;

wire[4:0] leg_col;
wire[6:0] leg_row;
reg [9:0] charx = CHAR_X_START, chary;
wire[9:0] legx;
wire[9:0] legy;

reg[2:0] charstate_Curr, charstate_Next;

char_rom CR1 (.clk_i(clk_i), .addr(char_addr), .color_o(char_color));
leg_rom CR2 (.clk_i(clk_i), .addr(leg_addr), .color_o(leg_color));   

initial begin
	charstate_Curr <= state_LEVEL; 
	chary          <= 0;//CHAR_Y_START;
end  

//-----------------//
//-- State Logic --//
//-----------------//


// FSM for vertical character movements
always @ (posedge clk_i) begin 
    if(rst_i) begin
        // reload map 
        charstate_Next <= state_LEVEL;  
		chary <= CHAR_Y_START;	
		dy_counter <= 0;		
    end
    else begin
		jump_prev <= jump;
        case(charstate_Curr) 
            state_LEVEL : begin      
				//chary <= CHAR_Y_START;	
				if(jump) begin
					charstate_Next <= state_JUMPING;
				end
				else if (!grounded) begin
					charstate_Next <= state_FALLING;
				end
				else
					charstate_Next <= state_LEVEL;				
            end
            state_JUMPING : begin  
				if(scrn_refresh == 1) begin
					dy_counter	<= dy_counter + 1;
					charstate_Next <= state_JUMPING;					
					if (dy_counter < 8) begin
						chary <= chary - 4;
					end
					else if (dy_counter < 18) begin
						chary <= chary - 3;
					end	
					else if (dy_counter < 26) begin
						chary <= chary - 2;
					end	
					else if (dy_counter < 31) begin
						chary <= chary - 1;
					end		
					else begin
						charstate_Next <= state_FALLING;
                        dy_counter <= 0;
					end
				end	
            end
            state_FALLING: begin 
				if(grounded) begin
					charstate_Next <= state_LEVEL;
					dy_counter <= 0;
                end 
				else if(scrn_refresh == 1) begin			
					dy_counter	<= dy_counter + 1;	
					
					if (((foot_y + fall_increment) > ground_b) ||       // check if next y movement would
                        ((foot_y + fall_increment) > ground_f)) begin   // bring char below ground level...
                        if(ground_b < ground_f) begin                   // if back of foot higher than front of foot
                            chary <= ground_b - 60;                     // set new char coordinates at this level
                        end
                        else begin                                      // if front of foot higher than back of foot
                            chary <= ground_f - 60;                     // set new char coordinates at this level
                        end
                        charstate_Next <= state_LEVEL;  
                        dy_counter <= 0;
                    end   
                    else begin
                        chary <= chary + fall_increment;                // otherwise, continue falling
                    end    
				end
            end 

            default : begin           
                charstate_Next <= state_LEVEL;
            end            
        endcase            
    end
    charstate_Curr <= charstate_Next;
end

// determine if front or back of character foot is on a ground level
always @ (posedge clk_i) begin  
    if (foot_x_b && (pix_y == foot_y)) begin
        //ground_b <= ht_upper;
        if (foot_y <= ht_upper) begin
            ground_b <= ht_upper;
        end
        else
            ground_b <= ht_lower;
            
        if ((pix_y == ht_upper) || (pix_y == ht_lower)) begin
            grounding_reg[1] <= 1;
        end    
        else 
            grounding_reg[1] <= 0;            
    end
    
    if (foot_x_f && (pix_y == foot_y)) begin
        //ground_f <= ht_upper;
        if (foot_y <= ht_upper) begin
            ground_f <= ht_upper;
        end
        else
            ground_f <= ht_lower;
            
        if ((pix_y == ht_upper) || (pix_y == ht_lower)) begin
            grounding_reg[0] <= 1;
        end    
        else 
            grounding_reg[0] <= 0;            
    end
    
    if(scrn_refresh) begin                                              // recalculate grounded every time screen is refreshed
        grounded <= grounding_reg[1] | grounding_reg[0];
    end    

end 

// animate horizontal movements
always @ (posedge clk_i) begin 
    if(rst_i) begin
        walk_counter <= 0;
        walking <= 0;
    end 
    else begin 
        if(fwd || rvs) begin
            walking <= 1;
            if(scrn_refresh) begin
                walk_counter <= walk_counter + 1'b1;
            end
        end    
        else begin
            walk_counter <= 0;
            walking <= 0;
        end    
    end        
end

assign fall_increment = (charstate_Curr == state_FALLING) && (dy_counter == 32)? 0 :
                        (charstate_Curr == state_FALLING) && (dy_counter <  8) ? 1 :
                        (charstate_Curr == state_FALLING) && (dy_counter < 18) ? 2 :
                        (charstate_Curr == state_FALLING) && (dy_counter < 26) ? 3 :
                        (charstate_Curr == state_FALLING) && (dy_counter < 31) ? 4 : 
                                                                                 6;
// char rom 
assign char_offset = !grounded ? CHAR_H : 0;

assign char_active 	= ((pix_x >= charx) && (pix_x < (charx + WIDTH)) &&
                       (pix_y >= chary) && (pix_y < (chary + CHAR_H)));
assign char_col 	= 	pix_x - charx; //(char_active && rvs) ? body_dir - (pix_x - charx) :
                                                     
assign char_row 	= pix_y - chary + char_offset;
assign char_disp 	= char_active && (char_color != GRN); 

assign char_body_w  = char_disp && (char_col <= 33);       // main parts of character head/torso
assign char_body    = char_body_w;
//assign jump_pulse 	= jump & ~jump_prev;

// leg rom
assign leg_offset = !grounded                       ? 72 : // char in air
                    (walking && (walk_counter < 8)) ? 24 : // step right 
                    (walking && (walk_counter > 15) &&
                                (walk_counter < 24)) ? 48 : // step left
                                                        0;

assign foot_x_b =  pix_x == (legx + 6);
assign foot_x_f =  pix_x == (legx + 24);
assign foot_y   =  legy + 21;	  

assign legx = (rvs) ? CHAR_X_START + LEG_DX + LEG_RVS : 
                      CHAR_X_START + LEG_DX;
assign legy = chary + 39;
assign leg_active 	= ((pix_x >= legx) && (pix_x < (legx + LEG_W)) && // LEG_W +1
                       (pix_y >= legy) && (pix_y < (legy + LEG_H)));
					   
assign leg_col 		= pix_x - legx;
assign leg_row 		= pix_y - legy + leg_offset;

assign leg_disp 	= leg_active && (leg_color != GRN);  

assign character_active = char_disp || leg_disp;

assign char_addr = rvs ? {char_row, ~char_col} :
                         {char_row, char_col};
assign leg_addr  = rvs ? {leg_row, ~leg_col} :
                         {leg_row, leg_col};
	
assign color_o 		= char_disp  ? char_color :
				      leg_disp   ? leg_color  :
				      GRN;
	
endmodule
