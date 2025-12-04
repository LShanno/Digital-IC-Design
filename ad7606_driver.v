`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module ad7606_driver(
    input           i_clk                   ,
    input           i_rst                   ,

    //用户接口
    input           i_user_ctrl             ,//控制CONVST拉低
    output [15:0]   o_user_data_1           ,
    output          o_user_data_valid_1     ,
    output [15:0]   o_user_data_2           ,
    output          o_user_data_valid_2     ,
    output [15:0]   o_user_data_3           ,
    output          o_user_data_valid_3     ,
    output [15:0]   o_user_data_4           ,
    output          o_user_data_valid_4     ,
    output [15:0]   o_user_data_5           ,
    output          o_user_data_valid_5     ,
    output [15:0]   o_user_data_6           ,
    output          o_user_data_valid_6     ,
    output [15:0]   o_user_data_7           ,
    output          o_user_data_valid_7     ,
    output [15:0]   o_user_data_8           ,
    output          o_user_data_valid_8     ,
    
    //ADC接口
    output          o_ad_sel                ,
    output          o_ad_stby               ,
    output          o_ad_convstA            ,
    output          o_ad_convstB            ,
    output          o_ad_reset              ,
    output          o_ad_rd                 ,
    output          o_ad_cs                 ,
    input           i_ad_busy               ,//busy信号在CONVST拉低后输入拉高再拉低
    output          o_ad_firstdata          ,
    input [15:0]    i_ad_data                
    
);

/***************function**************/

/***************parameter*************/
localparam  P_ST_IDLE   = 0 ,
            P_ST_CONSVT = 1 ,
            P_ST_BUSY   = 2 ,
            P_ST_READ   = 3 , 
            P_ST_WAIT   = 4 ;
/***************port******************/             

/***************mechine***************/
reg [7:0]   r_st_current            ;
reg [7:0]   r_st_next               ;
reg [15:0]  r_st_cnt                ;
/***************reg*******************/
reg [15:0]  ro_user_data_1          ;     
reg         ro_user_data_valid_1    ;     
reg [15:0]  ro_user_data_2          ;     
reg         ro_user_data_valid_2    ;     
reg [15:0]  ro_user_data_3          ;     
reg         ro_user_data_valid_3    ;     
reg [15:0]  ro_user_data_4          ;     
reg         ro_user_data_valid_4    ;     
reg [15:0]  ro_user_data_5          ;     
reg         ro_user_data_valid_5    ;     
reg [15:0]  ro_user_data_6          ;     
reg         ro_user_data_valid_6    ;     
reg [15:0]  ro_user_data_7          ;     
reg         ro_user_data_valid_7    ;     
reg [15:0]  ro_user_data_8          ;     
reg         ro_user_data_valid_8    ;     
reg         ro_ad_sel               ;     
reg         ro_ad_stby              ;     
reg         ro_ad_convstA           ;     
reg         ro_ad_convstB           ;     
reg         ro_ad_reset             ;     
reg         ro_ad_rd                ;     
reg         ro_ad_cs                ;     
reg         ro_ad_firstdata         ;  

reg         ri_ad_busy              ;
reg         ri_user_ctrl            ;
// reg [15:0]  ri_ad_data              ; 

reg         ro_ad_rd_1p             ;//RD打拍信号 为了得到RD上升沿

reg [2:0]   r_user_channel          ;//为了区分通道输出
/***************wire******************/
wire        w_ad_rd_posedge         ;//RD下降沿
/***************component*************/

/***************assign****************/
assign o_user_data_1        = ro_user_data_1            ;    
assign o_user_data_valid_1  = ro_user_data_valid_1      ;    
assign o_user_data_2        = ro_user_data_2            ;    
assign o_user_data_valid_2  = ro_user_data_valid_2      ;    
assign o_user_data_3        = ro_user_data_3            ;    
assign o_user_data_valid_3  = ro_user_data_valid_3      ;    
assign o_user_data_4        = ro_user_data_4            ;    
assign o_user_data_valid_4  = ro_user_data_valid_4      ;    
assign o_user_data_5        = ro_user_data_5            ;    
assign o_user_data_valid_5  = ro_user_data_valid_5      ;    
assign o_user_data_6        = ro_user_data_6            ;    
assign o_user_data_valid_6  = ro_user_data_valid_6      ;    
assign o_user_data_7        = ro_user_data_7            ;    
assign o_user_data_valid_7  = ro_user_data_valid_7      ;    
assign o_user_data_8        = ro_user_data_8            ;    
assign o_user_data_valid_8  = ro_user_data_valid_8      ;    
assign o_ad_sel             = ro_ad_sel                 ;    
assign o_ad_stby            = ro_ad_stby                ;    
assign o_ad_convstA         = ro_ad_convstA             ;    
assign o_ad_convstB         = ro_ad_convstB             ;    
assign o_ad_reset           = ro_ad_reset               ;    
assign o_ad_rd              = ro_ad_rd                  ;    
assign o_ad_cs              = ro_ad_cs                  ;    
assign o_ad_firstdata       = ro_ad_firstdata           ;    

assign w_ad_rd_posedge      = ro_ad_rd & !r_ad_rd_1p    ;
/***************always****************/
//状态机
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_st_current <= P_ST_IDLE;
    end
    else begin
        r_st_current <= r_st_next;
    end
end

always @(*) begin
    case(r_st_current)
        P_ST_IDLE   : r_st_next = r_st_cnt == 9 ? P_ST_CONSVT : P_ST_IDLE;
        P_ST_CONSVT : r_st_next = ri_user_ctrl ? P_ST_BUSY : P_ST_CONSVT;
        P_ST_BUSY   : r_st_next = r_st_cnt >= 9 && !ri_ad_busy ? P_ST_READ : P_ST_BUSY;
        P_ST_READ   : r_st_next = r_st_cnt == 15 ? P_ST_WAIT : P_ST_READ;
        P_ST_WAIT   : r_st_next = r_st_cnt == 199 ? P_ST_IDLE : P_ST_WAIT;
        default     : r_st_next = P_ST_IDLE;
    endcase
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_st_cnt <= 'd0;
    end
    else if (r_st_current != r_st_next) begin
        r_st_cnt <= 'd0;
    end
    else begin
        r_st_cnt <= r_st_cnt + 1;
    end
end

//用户接口
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ri_user_ctrl <= 'd0;
    end
    else begin
        ri_user_ctrl <= i_user_ctrl;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_user_channel <= 'd0;
    end
    else if (r_st_next == P_ST_READ) begin
        r_user_channel <= 'd0;
    end
    else if (w_ad_rd_posedge) begin
        r_user_channel <= r_user_channel + 1;
    end
    else begin
        r_user_channel <= r_user_channel;
    end
end

ro_user_data_1          
ro_user_data_valid_1    
ro_user_data_2          
ro_user_data_valid_2    
ro_user_data_3          
ro_user_data_valid_3    
ro_user_data_4          
ro_user_data_valid_4    
ro_user_data_5          
ro_user_data_valid_5    
ro_user_data_6          
ro_user_data_valid_6    
ro_user_data_7          
ro_user_data_valid_7    
ro_user_data_8          
ro_user_data_valid_8  

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_user_data_1 <= 'd0;
        ro_user_data_valid_1 <= 'd0;
    end
    else if (w_ad_rd_posedge && r_user_channel == 0) begin
        ro_user_data_1 <= i_ad_data;
        ro_user_data_valid_1 <= 'd1;
    end
    else begin
        ro_user_data_1 <= 'd0;
        ro_user_data_valid_1 <= 0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_user_data_2 <= 'd0;
        ro_user_data_valid_2 <= 'd0;
    end
    else if (w_ad_rd_posedge && r_user_channel == 1) begin
        ro_user_data_2 <= i_ad_data;
        ro_user_data_valid_2 <= 'd1;
    end
    else begin
        ro_user_data_2 <= 'd0;
        ro_user_data_valid_2 <= 0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_user_data_3 <= 'd0;
        ro_user_data_valid_3 <= 'd0;
    end
    else if (w_ad_rd_posedge && r_user_channel == 2) begin
        ro_user_data_3 <= i_ad_data;
        ro_user_data_valid_3 <= 'd1;
    end
    else begin
        ro_user_data_3 <= 'd0;
        ro_user_data_valid_3 <= 0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_user_data_4 <= 'd0;
        ro_user_data_valid_4 <= 'd0;
    end
    else if (w_ad_rd_posedge && r_user_channel == 3) begin
        ro_user_data_4 <= i_ad_data;
        ro_user_data_valid_4 <= 'd1;
    end
    else begin
        ro_user_data_4 <= 'd0;
        ro_user_data_valid_4 <= 0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_user_data_5 <= 'd0;
        ro_user_data_valid_5 <= 'd0;
    end
    else if (w_ad_rd_posedge && r_user_channel == 4) begin
        ro_user_data_5 <= i_ad_data;
        ro_user_data_valid_5 <= 'd1;
    end
    else begin
        ro_user_data_5 <= 'd0;
        ro_user_data_valid_5 <= 0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_user_data_6 <= 'd0;
        ro_user_data_valid_6 <= 'd0;
    end
    else if (w_ad_rd_posedge && r_user_channel == 5) begin
        ro_user_data_6 <= i_ad_data;
        ro_user_data_valid_6 <= 'd1;
    end
    else begin
        ro_user_data_6 <= 'd0;
        ro_user_data_valid_6 <= 0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_user_data_7 <= 'd0;
        ro_user_data_valid_7 <= 'd0;
    end
    else if (w_ad_rd_posedge && r_user_channel == 6) begin
        ro_user_data_7 <= i_ad_data;
        ro_user_data_valid_7 <= 'd1;
    end
    else begin
        ro_user_data_7 <= 'd0;
        ro_user_data_valid_7 <= 0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_user_data_8 <= 'd0;
        ro_user_data_valid_8 <= 'd0;
    end
    else if (w_ad_rd_posedge && r_user_channel == 7) begin
        ro_user_data_8 <= i_ad_data;
        ro_user_data_valid_8 <= 'd1;
    end
    else begin
        ro_user_data_8 <= 'd0;
        ro_user_data_valid_8 <= 0;
    end
end

//ADC接口
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ri_ad_busy <= 'd0;
    end
    else begin
        ri_ad_busy <= i_ad_busy;
    end
end

// always @(posedge i_clk,posedge i_rst) begin//受读控制信号RD上升沿控制
//     if (i_rst) begin
//         ri_ad_data <= 'd0;
//     end
//     else if (w_ad_rd_posedge) begin
//         ri_ad_data <= i_ad_data;
//     end
//     else begin
//         ri_ad_data <= ri_ad_data;
//     end
// end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_ad_rd_1p <= 'd0;
    end
    else begin
        r_ad_rd_1p <= ro_ad_rd;
    end
end  

//接口类型，选择并行
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ad_sel <= 'd0;
    end
    else begin
        ro_ad_sel <= 'd0;//并行
    end
end

//睡眠信号
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ad_stby <= 'd0;
    end
    else begin
        ro_ad_stby <= 'd0;
    end
end

//通道启动转换 默认高 启动拉低一拍
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ad_convstA   <= 'd1; 
        ro_ad_convstB   <= 'd1;
    end
    else if (r_st_current == P_ST_CONSVT) begin
        ro_ad_convstA   <= 'd0; 
        ro_ad_convstB   <= 'd0;
    end
    else begin
        ro_ad_convstA   <= 'd1; 
        ro_ad_convstB   <= 'd1;
    end
end

//芯片复位 IDLE状态复位
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ad_reset <= 'd0;
    end
    else if (r_st_current == P_ST_IDLE) begin
        ro_ad_reset <= 'd1;
    end
    else begin
        ro_ad_reset <='d0;
    end
end

//读数据控制信号
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ad_rd <= 'd0;  
    end
    else if (r_st_current == P_ST_READ) begin
        ro_ad_rd <= ~ro_ad_rd;//为了区分输出通道r_user_channel 因为每次输出都应该是两个clk周期 类似SPI
    end
    else begin
        ro_ad_rd <= 'd0;
    end
end

//片选信号
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ad_cs <= 'd0;        
    end
    else if (r_st_current == P_ST_READ) begin
        ro_ad_cs <= 'd1;
    end
    else begin
        ro_ad_cs <= 'd0;
    end
end

//第一通道指示信号
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ad_firstdata <= 'd0;
    end
    else begin
        ro_ad_firstdata <= 'd0;
    end
end

endmodule