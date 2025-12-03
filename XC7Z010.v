`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2025/06/10 11:35:10
// Design Name: 
// Module Name: XC7Z010
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


module XC7Z010(
    input   i_clk       ,
    output  o_iic_scl   ,
    inout   io_iic_sda  
    );

localparam  P_WRITE_NUMBER  = 8     ;

reg [2:0]   ri_ctrl_eeprom_addr     ; 
reg [15:0]  ri_ctrl_operation_addr  ; 
reg [1:0]   ri_ctrl_operation_len   ; 
reg [7:0]   ri_ctrl_operation_type  ; 
reg         ri_ctrl_operation_valid ; 
wire        wo_ctrl_operation_ready ; 

reg [7:0]   ri_ctrl_write_data      ;
reg         ri_ctrl_write_sop       ;
reg         ri_ctrl_write_eop       ;
reg         ri_ctrl_write_valid     ;

wire [7:0]  wo_ctrl_read_data       ;
wire        wo_ctrl_read_valid      ;

reg [7 :0]  r_write_cnt             ;
wire        w_active                ;
wire        w_rst                   ;
reg         r_wr_st                 ;
wire        w_pll_lock              ; 
wire        w_clk_10MHz             ;
wire        w_clk_125kHz            ;
wire        w_clk_125k_rst          ;

assign w_active = ri_ctrl_operation_valid & wo_ctrl_operation_ready ;

SYSTEM_CLK SYSTEM_CLK_U0
(
    .clk_out1                   (w_clk_10MHz            ),     
    .locked                     (w_pll_lock             ),    
    .clk_in1                    (i_clk                  )
); 

CLK_DIV_module#(                
    .P_CLK_DIV_CNT              (80                     )    
)               
CLK_DIV_module_U0               
(               
    .i_clk                      (w_clk_10MHz            ),
    .i_rst                      (~w_pll_lock            ),
    .o_clk_div                  (w_clk_125kHz           ) 
);  

rst_gen_module#(                
    .P_RST_CYCLE                (10                     )   
)       
rst_gen_module_u0       
(       
    .i_clk                      (w_clk_125kHz           ),
    .o_rst                      (w_clk_125k_rst         )
);

eeprom_driver eeprom_driver_u0(

    .i_clk                  (w_clk_125kHz               ),
    .i_rst                  (w_clk_125k_rst             ),
    
    /*------EEPROM控制------*/
    .i_ctrl_eeprom_addr     (ri_ctrl_eeprom_addr        ),
    .i_ctrl_operation_addr  (ri_ctrl_operation_addr     ),
    .i_ctrl_operation_len   (ri_ctrl_operation_len      ),
    .i_ctrl_operation_type  (ri_ctrl_operation_type     ),
    .i_ctrl_operation_valid (ri_ctrl_operation_valid    ),
    .o_ctrl_operation_ready (wo_ctrl_operation_ready    ),

    .i_ctrl_write_data      (ri_ctrl_write_data         ),
    .i_ctrl_write_sop       (ri_ctrl_write_sop          ),
    .i_ctrl_write_eop       (ri_ctrl_write_eop          ),
    .i_ctrl_write_valid     (ri_ctrl_write_valid        ),

    .o_ctrl_read_data       (wo_ctrl_read_data          ),
    .o_ctrl_read_valid      (wo_ctrl_read_valid         ), 

    /*------IIC接口------*/
    .o_iic_scl              (o_iic_scl                  ),//IIC时钟
    .io_iic_sda             (io_iic_sda                 )//IIC双向数据

);

always@(posedge w_clk_125kHz, posedge w_clk_125k_rst)
begin
    if(w_clk_125k_rst) 
    begin
        ri_ctrl_eeprom_addr     <= 'd0;
        ri_ctrl_operation_addr  <= 'd0;
        ri_ctrl_operation_type  <= 'd0;
        ri_ctrl_operation_len   <= 'd0;
        ri_ctrl_operation_valid <= 'd0;
    end 
    else if(wo_ctrl_operation_ready && r_wr_st == 0) 
    begin
        ri_ctrl_eeprom_addr     <= 'd0;
        ri_ctrl_operation_addr  <= 'd0;
        ri_ctrl_operation_type  <= 'd1;
        ri_ctrl_operation_len   <= P_WRITE_NUMBER;
        ri_ctrl_operation_valid <= 'd1;
    end 
    else if(wo_ctrl_operation_ready && r_wr_st == 1) 
    begin
        ri_ctrl_eeprom_addr     <= 'd0;
        ri_ctrl_operation_addr  <= 'd0;
        ri_ctrl_operation_type  <= 'd2;
        ri_ctrl_operation_len   <= 8;
        ri_ctrl_operation_valid <= 'd1;
    end 
    else 
    begin
        ri_ctrl_eeprom_addr     <= 'd0;
        ri_ctrl_operation_addr  <= 'd0;
        ri_ctrl_operation_type  <= 'd0;
        ri_ctrl_operation_len   <= 'd0;
        ri_ctrl_operation_valid <= 'd0;
    end
end

always@(posedge w_clk_125kHz, posedge w_clk_125k_rst)
begin
    if(w_clk_125k_rst)
        ri_ctrl_write_data <= 'd0;
    else if(ri_ctrl_write_valid)
        ri_ctrl_write_data <= ri_ctrl_write_data + 1;
    else 
        ri_ctrl_write_data <= ri_ctrl_write_data;
end

always@(posedge w_clk_125kHz, posedge w_clk_125k_rst)
begin
    if(w_clk_125k_rst)
        ri_ctrl_write_sop <= 'd0;
    else if(w_active && r_wr_st == 0)
        ri_ctrl_write_sop <= 'd1;
    else 
        ri_ctrl_write_sop <= 'd0;
end

always@(posedge w_clk_125kHz, posedge w_clk_125k_rst)
begin
    if(w_clk_125k_rst)
        ri_ctrl_write_valid <= 'd0;
    else if(ri_ctrl_write_eop)
        ri_ctrl_write_valid <= 'd0;
    else if(w_active && r_wr_st == 0)
        ri_ctrl_write_valid <= 'd1;
    else 
        ri_ctrl_write_valid <= ri_ctrl_write_valid;
end


always@(posedge w_clk_125kHz, posedge w_clk_125k_rst)
begin
    if(w_clk_125k_rst)
        ri_ctrl_write_eop <= 'd0;
    else if((w_active || ri_ctrl_write_valid) && r_write_cnt == P_WRITE_NUMBER - 2)
        ri_ctrl_write_eop <= 'd1;
    else 
        ri_ctrl_write_eop <= 'd0;
end

always@(posedge w_clk_125kHz, posedge w_clk_125k_rst)
begin
    if(w_clk_125k_rst)
        r_write_cnt <= 'd0;
    else if(r_write_cnt == P_WRITE_NUMBER - 1)
        r_write_cnt <= 'd0;
    else if(ri_ctrl_write_valid)
        r_write_cnt <= r_write_cnt + 1;
    else 
        r_write_cnt <= r_write_cnt;
end


always@(posedge w_clk_125kHz, posedge w_clk_125k_rst)
begin
    if(w_clk_125k_rst)
        r_wr_st <= 'd0;
    else if(w_active)
        r_wr_st <= r_wr_st + 1;
    else 
        r_wr_st <= r_wr_st;
end

endmodule
