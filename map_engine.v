`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 08/11/2023 07:20:55 PM
// Design Name: 
// Module Name: map_engine
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: Game map information is stored in bytes where each byte represents 
//              a 'map column' 64 pixels wide. Map images are stores at 16x16 pixel tiles. 
//              This is a total of 40 tiles when centered or 41 tiles when off-center due 
//              to scrolling. There are 10 map columns visible when centered and 11 visible
//              when off-center due to scrolling. Each 'map' column is split into 4 sections, 
//              two single tile sides and a middle section of two tiles. 
//              A series of counters manages the scrolling 
//
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module map_engine #(parameter GND_LVL = 351)
    (
    input clk_i, rst_i, clk_slo, char_body,
    input disp_active, fwd, rvs,
    input [10:0] pix_x, pix_y, 
    output map_disp_active, scrn_refresh,
	output [8:0] ht_upper, ht_lower,
    output [11:0] color_o
    );

// local parameters 
localparam LEVEL_MAX    = 80;
localparam LVL1_FRAMES  = 8;    // maximum bit in map ROM 
localparam MAX_X_CNT    = 639;  // maximum screen pixel width   
localparam MAX_Y_CNT    = 479;  // maximum screen pixel height
localparam MAX_TILES    = 40;   // maximum number of small tiles in x dimension
localparam MAX_COLS     = 10;   // max number of 64 pixel wide columns on screen
localparam TILE_XY      = 16;   // xy size of small tiles 
localparam COL_WIDTH    = 64;   // width of major columns   

// map parameters 
localparam FLAT         = 0;
localparam L_EDGE       = 1;
localparam HILL         = 2;
localparam R_EDGE       = 3;
localparam CUBE_PF      = 4;
localparam TANK         = 5;
localparam BOT          = 6;
//localparam FLAT         = 7;

localparam OFFSET_L1    = 64;
localparam OFFSET_L2    = 128;

//-- state variables --//
localparam gamestate_START  = 3'b000;
localparam gamestate_LOAD   = 3'b001; 
localparam gamestate_LEVEL  = 3'b010;
localparam gamestate_BOSS   = 3'b011;
localparam gamestate_FAIL   = 3'b100;

 
//-- Regs/Wires --//
// tile display 
reg[5:0]  map_col_x_cnt = 0;
reg[3:0]  tile_y_cnt = 0;
reg[4:0]  bg_tile_y_cnt = 0;
wire[5:0] tile_y_offset;        // choose which tile to read
wire[5:0] bg_y_offset;
wire[3:0] tile_col; 
wire[5:0] tile_row;
wire[4:0] bg_tile_col;
wire[5:0] bg_tile_row;
wire[10:0] tile_addr_w;
wire[10:0] bg_tile_addr_w;
wire[11:0]map_tile_color, bg_tile_color; 

// object wires 
wire[2:0] map_object;
wire gnd_upper, gnd_lower, corner_left, corner_right, edge_left, edge_right, dbl_lvl, empty, wall_tile;
wire tile_y_flip, tile_x_flip;

wire row_x_end, map_end, mem_addr_shift_r, mem_addr_shift_l, map_active, 
     fwd_en, rvs_en;
reg scroll_en = 0, scroll_dir = 1, scroll_dir_prev = 1;    // 1 = fwd, 0 = rvs 
reg wall_collision_fwd = 0, wall_collision_rvs = 0;
wire[7:0] map_rom_byte;
reg[LVL1_FRAMES-1:0] scroll_cnt = 0;
        
    // major column counter
reg[3:0] map_col_curr = 0, map_col_prev;  

reg[5:0] map_x_offset = 0, map_x_offset_prev = 0;
reg[LVL1_FRAMES-1:0] map_mem_addr = 0, map_mem_addr_prev; 
wire shift_fwd, shift_rvs;
 
reg[7:0]map_ram_data[0:10];

reg[2:0] gamestate_Curr, gamestate_Next;

//-- ROMS --//
map_rom  #(.SIZE(LVL1_FRAMES))
      MR1 (.clk_i(clk_i), .mem_addr_i(map_mem_addr), .map_mem_data_o(map_rom_byte));
gnd_tile_rom MR2 (.clk_i(clk_i), .addr(tile_addr_w), .color_o(map_tile_color));
bg_rom MR3 (.clk_i(clk_i), .addr(bg_tile_addr_w), .color_o(bg_tile_color));

initial begin
    gamestate_Curr <= gamestate_START;
end    

//------------------------------------------------ 
//-----------------//
//-- State Logic --//
//-----------------//
always @ (posedge clk_i) begin 
    if(rst_i) begin
        // reload map 
        gamestate_Next <= gamestate_START;  
        map_mem_addr    <= 0;    
        scroll_en       <= 0; 
        scroll_dir      <= 1; 
        scroll_dir_prev <= 1;
        scroll_cnt      <= 0;        
    end
    else begin
        map_mem_addr_prev <=  map_mem_addr;  // latch prev mem address
        case(gamestate_Curr) 
            gamestate_START : begin
                 // buffer state          
                gamestate_Next <= gamestate_LOAD;          
            end
            gamestate_LOAD : begin    
                // load first ten memory addresses         
                if (map_mem_addr < 10) begin
                    map_mem_addr <= map_mem_addr + 1;
                    gamestate_Next <= gamestate_LOAD;
                end     
                else begin
                    gamestate_Next <= gamestate_LEVEL;
                end           
            end
            gamestate_LEVEL: begin 
                scroll_en <= 1;               
                if(mem_addr_shift_r) begin  
                    scroll_dir_prev <= scroll_dir;
                    scroll_cnt <= scroll_cnt + 1;
                    if (scroll_dir == 0) begin
                        scroll_dir <= 1;
                        map_mem_addr <= map_mem_addr + 11;              // transition from reverse to forward, increment mem address by 10
                    end  
                    else begin 
                        map_mem_addr <= map_mem_addr + 1;               // forward scroll, increment mem address by 1
                    end 
                end    
                else if (mem_addr_shift_l) begin
                    scroll_dir_prev <= scroll_dir;                
                    scroll_cnt <= scroll_cnt - 1;
                    if (scroll_dir == 1) begin
                        scroll_dir <= 0;
                        map_mem_addr <= map_mem_addr - 11;              // transition from forward to reverse, decrement mem address by 10
                    end 
                    else begin
                        map_mem_addr <= map_mem_addr - 1;               // reverse scrll, decrement mem address by 1
                    end   
                end
                if((map_mem_addr == 0) && (map_x_offset == 0)) begin    // start of map reached, reset scrolling parameters to return to forward movement
                    map_mem_addr <= 10;
                    scroll_dir <= 1;
                end
                gamestate_Next <= gamestate_LEVEL;            
            end 
            gamestate_BOSS : begin 
                gamestate_Next <= gamestate_LEVEL;
            end     
            default : begin
                map_mem_addr <= 0;                
                gamestate_Next <= gamestate_LOAD;
            end            
        endcase            
    end
    gamestate_Curr <= gamestate_Next;
end

//-------------------------//
//-- Combinatorial Logic --//
//-------------------------//
//always @(*) begin
//    case(gamestate_Curr)       
//        gamestate_LEVEL : begin 
//                 
//        end
//        default : begin
//            // do nothing
//        end
//    endcase 
//end

//-- MAP RAM --//
    //shift contents of visible column registers when scrolling the map 
always @ (posedge clk_i) begin 
    map_ram_data[10] <= map_rom_byte;        
    if ((gamestate_Curr == gamestate_LOAD) || 
        ((map_col_curr == 10) && (map_col_prev == 10) && mem_addr_shift_r))  begin       
        // shift map data for forward scrolling        
        map_ram_data[0]  <= map_ram_data[1];
        map_ram_data[1]  <= map_ram_data[2];
        map_ram_data[2]  <= map_ram_data[3];
        map_ram_data[3]  <= map_ram_data[4];
        map_ram_data[4]  <= map_ram_data[5];
        map_ram_data[5]  <= map_ram_data[6];
        map_ram_data[6]  <= map_ram_data[7];
        map_ram_data[7]  <= map_ram_data[8];
        map_ram_data[8]  <= map_ram_data[9];
        map_ram_data[9]  <= map_ram_data[10];               
    end
    else if ((map_col_curr == 9) && (map_col_prev == 9) && 
             (map_x_offset == 0) && (map_x_offset_prev == 2)) begin//(map_x_offset_prev == 1)) begin 
    // shift map data for reverse scrolling         
        map_ram_data[0]  <= map_ram_data[10];
        map_ram_data[1]  <= map_ram_data[0];
        map_ram_data[2]  <= map_ram_data[1];
        map_ram_data[3]  <= map_ram_data[2];
        map_ram_data[4]  <= map_ram_data[3];
        map_ram_data[5]  <= map_ram_data[4];
        map_ram_data[6]  <= map_ram_data[5];
        map_ram_data[7]  <= map_ram_data[6];
        map_ram_data[8]  <= map_ram_data[7];
        map_ram_data[9]  <= map_ram_data[8];                                
    end 
end

//--------------------------// 
//-- map display counters --// 
//--------------------------//

    // pixel counter 
        // used to dictate tile pixel address and increment map columns
always @ (posedge clk_i) begin    
    if(rst_i) begin
        // load default values 
        tile_y_cnt <= 0;
        bg_tile_y_cnt <= 0;
        map_col_x_cnt <= 0;
    end
    else begin

        if (map_disp_active) begin                          // increment while in the ground region             
            if (row_x_end) begin                            // end of row
                tile_y_cnt <= tile_y_cnt + 1;               // increment row counter 
                bg_tile_y_cnt <= bg_tile_y_cnt + 1;
            end
            else begin
                map_col_x_cnt <= map_col_x_cnt + 1;
            end    
        end
        else begin
            map_col_x_cnt <= map_x_offset;        
        end
    end    
end

    // map column counter // 
        // default count is 0-9
always @ (posedge clk_i) begin 
    if(rst_i) begin
        // load default values 
        map_col_curr <= 0;
    end
    else if (map_disp_active) begin 
        map_col_prev <= map_col_curr; 
        if (map_col_x_cnt == COL_WIDTH - 1) begin     // 64 pixels, increment to next column 
            if(map_col_curr == 10) begin
                map_col_curr <= 0;
            end   
            else begin
              map_col_curr <= map_col_curr + 1;
            end
        end
    end
    else begin
        if((map_col_prev == 9) && (scroll_dir == 0) && (rvs_en) && (map_x_offset != 0)) begin
            map_col_curr <= 10;
        end
        else begin
            map_col_curr <= 0;                          // reset column counter after screen refresh
        end
    end
end  

    // scrolling offset
always @ (posedge clk_i) begin 
    if(rst_i) begin
        // load default values 
        map_x_offset <= 0;
    end
    else begin
        map_x_offset_prev <= map_x_offset;
        if (fwd && fwd_en) begin     
            if (scrn_refresh) begin    
                map_x_offset <= map_x_offset + 2;//1;     
            end
        end 
        else if (rvs && rvs_en) begin
            if (scrn_refresh) begin         
                map_x_offset <= map_x_offset - 2;//1;     
            end        
        end 
    end    
end 

    // wall collision
always @ (posedge clk_i) begin 
    if(rst_i) begin
        // load default values 
        wall_collision_fwd <= 0; 
        wall_collision_rvs <= 0;         
    end
    else begin
        if(char_body && wall_tile && fwd) begin
            wall_collision_fwd <= 1;
        end
        if(wall_collision_fwd && rvs) begin
            wall_collision_fwd <= 0;
        end    
        if(char_body && wall_tile && rvs) begin
            wall_collision_rvs <= 1;
        end    
        if(wall_collision_rvs && fwd) begin
            wall_collision_rvs <= 0;
        end    
    end
end    
           

//------------------------------------------------ 
assign map_disp_active = (disp_active && (pix_y > (GND_LVL - OFFSET_L2 - OFFSET_L1))) ? 1 : 0; 
assign gnd_active = (disp_active && (pix_y > ht_upper)) ? 1 : 0;

// decode map column byte 
    // map platform heights 
assign ht_upper = (map_ram_data[map_col_curr][6:5] == 0) ? GND_LVL + OFFSET_L2 :
                  (map_ram_data[map_col_curr][6:5] == 1) ? GND_LVL + OFFSET_L1 :
                  (map_ram_data[map_col_curr][6:5] == 3) ? GND_LVL - OFFSET_L1 : 
                   GND_LVL;
assign gnd_upper = (pix_y > ht_upper) && (pix_y <= (ht_upper + TILE_XY));                   
                   
assign ht_lower = (map_ram_data[map_col_curr][4:3] == 0) ? GND_LVL + OFFSET_L2 :
                  (map_ram_data[map_col_curr][4:3] == 1) ? GND_LVL + OFFSET_L1 :
                  (map_ram_data[map_col_curr][4:3] == 3) ? GND_LVL - OFFSET_L1 :
                   GND_LVL;
assign gnd_lower = (pix_y > ht_lower) && (pix_y <= (ht_lower + TILE_XY));                   
                   
assign map_object = map_ram_data[map_col_curr][2:0];                // current object

// assign column regions 
assign edge_left    = (map_col_x_cnt < TILE_XY) && 
                      (pix_y <= ht_lower)  &&
                      (pix_y > ht_upper);
                     //(pix_y <= ht_lower);
assign edge_right   = (map_col_x_cnt > (COL_WIDTH - TILE_XY)) && 
                      (map_col_x_cnt <= (COL_WIDTH - 1))      && 
                      (pix_y <= ht_lower)  &&
                      (pix_y > ht_upper);
                      //(pix_y <= ht_lower);
assign corner_left  = gnd_upper && edge_left;
assign corner_right = gnd_upper && edge_right;
assign dbl_lvl      = map_ram_data[map_col_curr][7];
assign empty        = (map_object == CUBE_PF) && 
                      ((gnd_upper == 0) && (pix_y <= ht_lower));    // flag for empty space below floating platforms 

assign wall_tile = (edge_left  && ((map_object == L_EDGE) || (map_object == HILL))) ||     // left edge (rotate gnd tile left)
                   (edge_right && ((map_object == R_EDGE) || (map_object == HILL)));       // right edge (rotate gnd tile right)

//assign map_active = 1;//(gamestate_Curr == gamestate_LEVEL) ? 1 : 0;
assign fwd_en = (scroll_en && map_mem_addr < 255) && !wall_collision_fwd;
assign rvs_en = (((scroll_cnt == 0) && (map_x_offset == 0)) || wall_collision_rvs) ? 0 : 1;

assign mem_addr_shift_r = ((map_x_offset_prev == COL_WIDTH-2) && (map_x_offset == 0));//((map_x_offset_prev == COL_WIDTH-1) && (map_x_offset == 0)); 
assign mem_addr_shift_l = ((map_x_offset_prev == 0) && (map_x_offset == COL_WIDTH-2));//((map_x_offset_prev == 0) && (map_x_offset == COL_WIDTH-1));    
assign row_x_end = (pix_x == MAX_X_CNT) ? 1 : 0;
//assign map_end = (map_mem_addr <= LEVEL_MAX) ? 1 : 0;

assign scrn_refresh = (pix_x == MAX_X_CNT) && (pix_y == MAX_Y_CNT);

// assign map tile and orientation based on map object
assign tile_y_offset = ((corner_left  && ((map_object == L_EDGE) || (map_object == HILL))) ||
                        (corner_right && ((map_object == R_EDGE) || (map_object == HILL))))  
                                                                            ? 16 :              // -> corner tile
                       ((gnd_upper) && (map_object == CUBE_PF))             ? 48 :              // -> cube platform tile
                       ((gnd_upper) ||                                                          // ground level
                        (gnd_lower && dbl_lvl)  ||                                              // second ground level 
                         wall_tile)       
                                                                            ? 32 :              // -> ground tile
                                                                                0;
                       
assign tile_col = map_col_x_cnt[3:0];
assign tile_row = tile_y_cnt; 

assign bg_tile_col = map_col_x_cnt[4:0];
assign bg_tile_row = bg_tile_y_cnt + bg_y_offset;
assign bg_y_offset = (map_disp_active && (pix_y < ((GND_LVL - OFFSET_L2 - OFFSET_L1) + TILE_XY))) ? 32 : 0;

assign tile_addr_w    = corner_left               ? {(tile_y_offset + tile_row),  tile_col} :               // corner tile   
                        corner_right              ? {(tile_y_offset + tile_row), ~tile_col} :               // mirror the tile 
                        (gnd_upper || gnd_lower)  ? {(tile_y_offset + tile_row),  tile_col} :               // ground tile 
                        edge_left                 ? {(tile_y_offset + {1'b0,  tile_col}), ~tile_row[3:0]} : // rotate 90 left
                        edge_right                ? {(tile_y_offset + {1'b0, ~tile_col}),  tile_row[3:0]} : // rotate 90 right 
                                                    {tile_row, tile_col}; 
assign bg_tile_addr_w = {bg_tile_row, bg_tile_col};


assign color_o = (gnd_active && !empty)? map_tile_color :
                  bg_tile_color;



endmodule
