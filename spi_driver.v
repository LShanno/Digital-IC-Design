`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//CPOL=0 CPHL=0的模式1 表示spi_clk初始默认状态为0，在clk的上升沿变化，spi_clk应该是clk的两倍时钟周期

module spi_driver#(
    parameter P_WRITE_DATA_WIDTH    = 8 ,
    parameter P_READ_DATA_WIDTH     = 8 ,
    parameter P_CPOL                = 0 ,//默认电平状态
    parameter P_CPHL                = 0 //在时钟第几个沿采样，包含上升沿和下降沿
)(
    //SPI 对外
    input                               i_clk               ,
    input                               i_rst               ,

    output                              o_spi_clk           ,
    output                              o_spi_cs            ,

    input                               i_spi_miso          ,
    output                              o_spi_mosi          ,

    //SPI 对USER
    input [P_WRITE_DATA_WIDTH - 1 : 0]  i_user_write_data   ,
    input                               i_user_write_valid  ,
    output                              o_user_write_ready  ,//写数据需要握手 读不需要

    output [P_READ_DATA_WIDTH - 1 : 0]  o_user_read_data    ,
    output                              o_user_read_valid   
);

/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
reg                                 ro_spi_clk          ;         
reg                                 ro_spi_cs           ;

reg                                 ro_spi_mosi         ;

reg                                 ro_user_write_ready ;

reg [P_READ_DATA_WIDTH - 1 : 0]     ro_user_read_data   ;  
reg                                 ro_user_read_valid  ;

reg [15 : 0]                        r_cnt               ;
reg                                 r_spi_cnt           ;//1bit 只会是01

reg [P_WRITE_DATA_WIDTH - 1 : 0]    r_user_write_data   ;
/***************wire******************/
wire w_user_active  ;
/***************component*************/

/***************assign****************/
assign o_spi_clk            = ro_spi_clk            ; 
assign o_spi_cs             = ro_spi_cs             ; 
assign o_spi_mosi           = ro_spi_mosi           ; 
assign o_user_write_ready   = ro_user_write_ready   ; 
assign o_user_read_data     = ro_user_read_data     ; 
assign o_user_read_valid    = ro_user_read_valid    ; 

assign w_user_active = i_user_write_valid & o_user_write_ready  ;
/***************always****************/
always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ro_spi_clk <= P_CPOL;
    end
    else if (!ro_user_write_ready) begin
        ro_spi_clk <= ~ro_spi_clk;
    end
    else begin
        ro_spi_clk <= P_CPOL;
    end
end

always@(posedge i_clk, posedge i_rst) 
begin
    if (i_rst) begin
        ro_spi_cs <= 'd1;
    end
    else if (w_user_active) begin
        ro_spi_cs <= 'd0;
    end
    else if (r_cnt == P_WRITE_DATA_WIDTH - 1 && r_spi_cnt) begin
        ro_spi_cs <= 'd1;
    end
    else begin
        ro_spi_cs <= ro_spi_cs;
    end
end

//MOSI
always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ro_user_write_ready <= 'd1;
    end
    else if (w_user_active) begin
        ro_user_write_ready <= 'd0;
    end
    else if (r_cnt == P_WRITE_DATA_WIDTH - 1 && r_spi_cnt) begin
        ro_user_write_ready <= 'd1;
    end
    else begin
        ro_user_write_ready <= ro_user_write_ready;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_cnt <= 'd0;
    end
    else if (r_cnt == P_WRITE_DATA_WIDTH - 1 && r_spi_cnt) begin
        r_cnt <= 'd0;
    end
    else if (!ro_user_write_ready && r_spi_cnt) begin
        r_cnt <= r_cnt + 1;
    end
    else begin
        r_cnt <= r_cnt;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_spi_cnt <= 'd0;
    end
    else if (!ro_user_write_ready) begin
        r_spi_cnt <= r_spi_cnt + 1;
    end
    else begin
        r_spi_cnt <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_user_write_data <= 'd0;
    end
    else if (w_user_active) begin
        r_user_write_data <= i_user_write_data;
    end
    else if (!ro_user_write_ready && r_spi_cnt) begin
        r_user_write_data <= r_user_write_data << 1;//SPI高位先发
    end
    else begin
        r_user_write_data <= r_user_write_data;
    end
end

always@(posedge i_clk, posedge i_rst) 
begin
    if (i_rst) begin
        ro_spi_mosi <= 'd0;
    end
    else if (w_user_active) begin
        ro_spi_mosi <= r_user_write_data[P_WRITE_DATA_WIDTH - 1];
    end
    else if (!ro_user_write_ready && r_spi_cnt) begin
        ro_spi_mosi <= r_user_write_data[P_WRITE_DATA_WIDTH - 2];
    end
    else begin
        ro_spi_mosi <= ro_spi_mosi;
    end
end

//MISO
always@(posedge ro_spi_clk, posedge i_rst) 
begin
    if (i_rst) begin
        ro_user_read_data <= 'd0;
    end
    else begin
        ro_user_read_data <= {ro_user_read_data[P_READ_DATA_WIDTH - 2 :0],i_spi_miso};
    end
end

always@(posedge i_clkm posedge i_rst)
begin
    if (i_rst) begin
        ro_user_read_valid <= 'd0;
    end
    else if (r_cnt == P_READ_DATA_WIDTH - 1 && r_spi_cnt) begin
        ro_user_read_valid <= 'd1;
    end
    else begin
        ro_user_read_valid <= 'd0;
    end
end

endmodule