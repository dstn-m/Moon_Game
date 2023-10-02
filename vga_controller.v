`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Engineer: Dustin Matthews
// 
// Create Date: 07/02/2023 02:49:43 PM
// Module Name: vga_controller.v
// Project Name: VGA Controller
// Target Devices: BASYS 3
// Description: Control VGA RGB outputs, sync pulses, and disp_active signal.
//              Operates on 25MHz clock, 800x525 (active region 640x480 pixels)
//              ---------------------------------------------------------------
//              Outputs
//              -------
//              hsync_o (active low horizontal sync pulse)
//              vsync_o (active low vertial sync pulse)
//              xcol_o, yrow_o (current pixel position)
//              disp_active_o (active high, signals that current pixel is in display region)
//                                                              
//              _ _____________________________  sync  __________________________
//               |   disp region     | f porch |______| b porch  |    next disp...
//
//
//
// Revision:
//////////////////////////////////////////////////////////////////////////////////



module vga_controller(
    input clk_i, rst_i, // 25MHz clk, active high reset
    output hsync_o, vsync_o,
    output disp_active,
    output[10:0] xcol_o, yrow_o 
    );
    // define constant parameters 
    localparam H_DISP = 640;    // horizonal display module vga_controller
    localparam H_BPORCH = 48;   // horizontal back module vga_controller //40+8
    localparam H_FPORCH = 16;   // horizontal front module vga_controller //8+8 
    localparam H_SYNC = 96;     // horizontal sync // 96
    localparam H_FRAME = 800;   // total frame pixel width
    localparam V_DISP = 480;    // vertical display module vga_controller
    localparam V_BPORCH = 33;   // vertical back module vga_controller 
    localparam V_FPORCH = 10;   // vertical front module vga_controller  
    localparam V_SYNC = 2;     // vertical sync
    localparam V_FRAME = 525;   // vertial frame pixel heigh
 
reg[10:0] col_cnt, row_cnt = 0;
reg hsync, vsync = 0; 
reg sync_p = 0;
// row and column counter    
// increment the vertical counter and reset horizontal counter 
// when pixel reaches end of horizontal frame
always @(posedge clk_i)
begin
    if(rst_i) begin
        col_cnt <= 0;
        row_cnt <= 0;
    end
    else begin
        if (col_cnt == H_FRAME-1) begin
            col_cnt <= 0;
            if(row_cnt == V_FRAME-1) begin
                row_cnt <= 0;
            end
            else begin            
                row_cnt <= row_cnt + 1;
            end       
        end
        else begin    
            col_cnt <= col_cnt + 1;
        end   
    end   
end  

// horizontal sync  
always @(posedge clk_i) 
begin
    if (rst_i) begin
        hsync <= ~ sync_p;
    end
    else begin
        if ((col_cnt < (H_DISP + H_FPORCH)) ||
            (col_cnt > (H_FRAME - H_BPORCH-1))) begin
            hsync <= ~sync_p;
        end    
        else begin
            hsync <= sync_p;
        end                                              
    end
end 
  
// vertical sync 
always @(posedge clk_i) 
begin
    if (rst_i) begin
        vsync <= ~sync_p;
    end
    else begin   
        if ((row_cnt < (V_DISP + V_BPORCH)) ||
            (row_cnt > (V_FRAME - V_FPORCH -1))) begin
            vsync <= ~sync_p;
        end    
        else begin
            vsync <= sync_p;
        end                                                    
    end
end    

        
assign disp_active = ((col_cnt < H_DISP) && (row_cnt < V_DISP)) ? 1 : 0; 
assign hsync_o = hsync;
assign vsync_o = vsync;   
assign xcol_o = col_cnt;
assign yrow_o = row_cnt;

endmodule
