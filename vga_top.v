`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Dustin Matthews
// 
// Create Date: 07/02/2023 02:49:43 PM
// Module Name: vga_top.v
// Project Name: VGA Controller
// Target Devices: BASYS 3
// Description: Instantiate 25MHz clock divider and vga controller modules
// Revision:
//////////////////////////////////////////////////////////////////////////////////

module vga_top(
    input clk_i, rst_i, // 25MHz clk, active high reset
    output hsync_o, vsync_o, clk_o,
    output disp_active,
    output [10:0] xcol_o, yrow_o  
    );
    
wire clk_25MHz;

//-----------------------------//
//-----Instantiate Modules-----//
//-----------------------------//
// clk divider
vga_clk_25MHz CD1(.clk_i(clk_i), .rst_i(rst_i), .clk_o(clk_25MHz));  
// controller                       
vga_controller VGA1(.clk_i(clk_25MHz), .rst_i(rst_i),.hsync_o(hsync_o), .vsync_o(vsync_o),
                    .disp_active(disp_active),.xcol_o(xcol_o), .yrow_o(yrow_o)); 
   
assign clk_o = clk_25MHz;    
endmodule
