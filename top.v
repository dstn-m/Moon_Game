`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2023 07:38:17 PM
// Design Name: 
// Module Name: top
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


module top(
    input clk_i, rst_i, btnr_i, btnl_i, btnt_i, // 25MHz clk, active high reset
    output hsync_o, vsync_o,
    output [3:0] red_o, grn_o, blu_o 
    );

wire clk_25MHz, clk_1k_o, clk_char_o, fwd, rvs, jump, scrn_refresh, char_active, char_body;    
wire[10:0] xcol, yrow; 
wire[11:0] color, gnd_color, char_color;
wire[1:0] offset_cnt;  
wire [8:0] ht_upper, ht_lower;
    
vga_top VGA1(.clk_i(clk_i), .rst_i(rst_i), .hsync_o(hsync_o), .vsync_o(vsync_o),
             .clk_o(clk_25MHz), .disp_active(disp_active),.xcol_o(xcol), .yrow_o(yrow)); 
btn_db DB1 (.clk_i(clk_1k_o), .rst_i(rst_i), .btn_i(btnr_i), .btn_db_o(fwd));
btn_db DB2 (.clk_i(clk_1k_o), .rst_i(rst_i), .btn_i(btnl_i), .btn_db_o(rvs));
btn_db DB3 (.clk_i(clk_1k_o), .rst_i(rst_i), .btn_i(btnt_i), .btn_db_o(jump));
map_engine #(.GND_LVL(351))
            ME1 (.clk_i(clk_25MHz), .rst_i(rst_i), .clk_slo(clk_char_o), .disp_active(disp_active), .fwd(fwd), .rvs(rvs),
                 .pix_x(xcol), .pix_y(yrow), .map_disp_active(map_disp_active), .scrn_refresh(scrn_refresh), .char_body(char_body),
				 .ht_upper(ht_upper), .ht_lower(ht_lower), 
                 .color_o(gnd_color));
character_controller CC1 (.clk_i(clk_25MHz), .rst_i(rst_i), .disp_active(disp_active), .fwd(fwd), .rvs(rvs), .jump(jump),
                          .scrn_refresh(scrn_refresh), .char_body(char_body), .ht_upper(ht_upper), .ht_lower(ht_lower), 
                          .pix_x(xcol), .pix_y(yrow), .character_active(char_active), 
                          .color_o(char_color));


			 
scroll_clk SC1 (.clk_i(clk_i), .rst_i(rst_i), .clk_1k_o(clk_1k_o), .clk_scroll_o(clk_char_o));  

assign color = (char_active)	 ? char_color :
			   (map_disp_active) ? gnd_color  : 
               //(disp_active) ? 12'hf0f : 
               12'h000;

assign red_o = color[11:8];
assign grn_o = color[7:4];
assign blu_o = color[3:0];                      
endmodule
