`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//CPOL=0 CPHL=0的模式1 表示spi_clk初始默认状态为0，在clk的上升沿变化，spi_clk应该是clk的两倍时钟周期

module spi_flash_driver#(
    parameter P_OPERATION_WIDTH     = 32,
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
    input [P_OPERATION_WIDTH - 1 : 0]   i_user_op_data      ,//操作数据（指令8bit+地址24bit）
    input [1 : 0]                       i_user_op_type      ,//操作类型（读、写、指令）
    input [15 : 0]                      i_user_op_data_len  ,//操作数据的长度32、8
    input [15 : 0]                      i_user_op_clk_len   ,//时钟周期
    input                               i_user_op_valid     ,//用户的有效信号
    output                              o_user_op_ready     ,//用户的准备信号

    input [P_WRITE_DATA_WIDTH - 1 : 0]  i_user_write_data   ,
    output                              o_user_write_req    ,//握手在flash_ctrl里实现

    output [P_READ_DATA_WIDTH - 1 : 0]  o_user_read_data    ,
    output                              o_user_read_valid   
);

/***************function**************/

/***************parameter*************/
localparam  P_OP_TYPE_CMD   = 0 ,
            P_OP_TYPE_READ  = 1 ,
            P_OP_TYPE_WRITE = 2 ;
/***************port******************/             

/***************mechine***************/

/***************reg*******************/
reg                                 ro_spi_clk          ;         
reg                                 ro_spi_cs           ;

reg                                 ro_spi_mosi         ;

reg                                 ro_user_op_ready    ;

reg [P_READ_DATA_WIDTH - 1 : 0]     ro_user_read_data   ;  
reg                                 ro_user_read_valid  ;

reg [15 : 0]                        r_cnt               ;//SPI总的运行时钟周期，和r_user_op_clk_len对应
reg [15 : 0]                        r_write_cnt         ;
reg [15 : 0]                        r_read_cnt          ;
reg                                 r_spi_cnt           ;//1bit 只会是01

reg [P_WRITE_DATA_WIDTH - 1 : 0]    r_user_write_data   ;
reg                                 ro_user_write_req   ;
reg                                 ro_user_write_req_1r;

reg [P_OPERATION_WIDTH - 1 : 0]     r_user_op_data      ;  
reg [1 : 0]                         r_user_op_type      ;  
reg [15 : 0]                        r_user_op_data_len  ;  
reg [15 : 0]                        r_user_op_clk_len   ;   

reg                                 r_run               ;
reg                                 r_run_1r            ;

/***************wire******************/
wire w_user_active  ;
wire w_run_negedge  ;
/***************component*************/

/***************assign****************/
assign o_spi_clk            = ro_spi_clk                            ; 
assign o_spi_cs             = ro_spi_cs                             ; 
assign o_spi_mosi           = ro_spi_mosi                           ; 
assign o_user_op_ready      = ro_user_op_ready                      ; 
assign o_user_read_data     = ro_user_read_data                     ; 
assign o_user_read_valid    = ro_user_read_valid                    ; 
assign o_user_write_req     = ro_user_write_req                     ;

assign w_user_active        = i_user_op_valid & o_user_op_ready     ;
assign w_run_negedge        = !r_run & r_run_1r                     ;  
/***************always****************/
//User
always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ro_user_op_ready <= 'd1;
    end
    else if (w_user_active) begin
        ro_user_op_ready <= 'd0;
    end
    else if (w_run_negedge) begin
        ro_user_op_ready <= 'd1;
    end
    else begin
        ro_user_op_ready <= ro_user_op_ready;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_user_op_type      <= 'd0; 
        r_user_op_data_len  <= 'd0; 
        r_user_op_clk_len   <= 'd0; 
    end
    else if (w_user_active) begin
        r_user_op_type      <= i_user_op_type       ;  
        r_user_op_data_len  <= i_user_op_data_len   ;  
        r_user_op_clk_len   <= i_user_op_clk_len    ; 
    end
    else begin
        r_user_op_type      <= r_user_op_type       ;  
        r_user_op_data_len  <= r_user_op_data_len   ;  
        r_user_op_clk_len   <= r_user_op_clk_len    ; 
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_user_op_data <= 'd0;
    end
    else if (w_user_active) begin
        r_user_op_data <= i_user_op_data;
    end
    else if (r_spi_cnt) begin
        r_user_op_data <= r_user_op_data << 1;
    end
    else begin
        r_user_op_data <= r_user_op_data;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_run <= 'd0;
    end
    else if (r_spi_cnt && r_cnt == r_user_op_clk_len - 1) begin
        r_run <= 'd0;
    end
    else if (w_user_active) begin
        r_run <= 'd1;
    end
    else begin
        r_run <= r_run;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_run_1r <= 'd0;
    end
    else begin 
        r_run_1r <= r_run;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ro_spi_clk <= P_CPOL;
    end
    else if (r_run) begin
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
    else if (!r_run) begin
        ro_spi_cs <= 'd1;
    end
    else begin
        ro_spi_cs <= ro_spi_cs;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_cnt <= 'd0;
    end
    else if (r_cnt == r_user_op_clk_len - 1 && r_spi_cnt) begin
        r_cnt <= 'd0;
    end
    else if (r_spi_cnt) begin
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
    else if (r_run) begin
        r_spi_cnt <= r_spi_cnt + 1;
    end
    else begin
        r_spi_cnt <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ro_user_write_req <= 'd0;
    end
    else if(((!r_spi_cnt && r_cnt == P_OPERATION_WIDTH - 2) || r_write_cnt == P_WRITE_DATA_WIDTH + P_WRITE_DATA_WIDTH - 1) && r_user_op_type == P_OP_TYPE_WRITE) begin//请求信号和最后一个比特的指令数据同时拉高，这里用P_OPERATION_WIDTH-2和用r_user_op_data_len一样，因为在读请求时必然需要寄存器地址，r_user_op_data_len和P_OPERATION_WIDTH必然都是32
        ro_user_write_req <= 'd1;
    end
    else begin 
        ro_user_write_req <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if(i_rst) begin
        ro_user_write_req_1r <= 'd0;
    end
    else begin
        ro_user_write_req_1r <= ro_user_write_req;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_user_write_data <= 'd0;
    end
    else if (ro_user_write_req_1p) begin
        r_user_write_data <= i_user_write_data;
    end
    else if (r_spi_cnt) begin
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
        ro_spi_mosi <= i_user_op_data[P_OPERATION_WIDTH - 1];
    end
    else if (r_cnt < r_user_op_data_len - 1 && r_spi_cnt) begin//操作长度内执行操作数据，包含指令类型和地址
        ro_spi_mosi <= r_user_write_data[P_OPERATION_WIDTH - 2];
    end
    else if (r_user_op_type == P_OP_TYPE_WRITE && r_spi_cnt) begin//数据长度内执行读写数据
        ro_spi_mosi <= r_user_write_data[7];
    end
    else begin
        ro_spi_mosi <= ro_spi_mosi;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_write_cnt <= 'd0;
    end
    else if (r_write_cnt == P_WRITE_DATA_WIDTH + P_WRITE_DATA_WIDTH - 1 || ro_spi_cs) begin//这里是因为r_write_cnt和r_spi_cnt周期一致，是r_cnt周期的一半
        r_write_cnt <= 'd0;
    end
    else if(ro_user_write_req || r_write_cnt) begin
        r_write_cnt <= r_write_cnt + 1;
    end
    else begin
        r_write_cnt <= r_write_cnt;
    end
end


always@(posedge ro_spi_clk, posedge i_rst) 
begin
    if (i_rst) begin
        ro_user_read_data <= 'd0;
    end
    else if (r_cnt >= r_user_op_data_len - 1) begin
        ro_user_read_data <= {ro_user_read_data[P_READ_DATA_WIDTH - 2 :0],i_spi_miso};
    end
    else begin
        ro_user_read_data <= ro_user_read_data;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_read_cnt <= 'd0;
    end
    else if (r_read_cnt == P_READ_DATA_WIDTH - 1 || ro_spi_cs) begin
        r_read_cnt <= 'd0;
    end
    else if (r_spi_cnt && r_cnt >= r_user_op_data_len - 1 && r_user_op_type == P_OP_TYPE_READ) begin//r_read_cnt周期和r_cnt周期一致
        r_read_cnt <= r_read_cnt + 1;
    end
    else begin
        r_read_cnt <= r_read_cnt;
    end
end

always@(posedge i_clkm posedge i_rst)
begin
    if (i_rst) begin
        ro_user_read_valid <= 'd0;
    end
    else if (r_read_cnt == P_READ_DATA_WIDTH - 1 && r_spi_cnt) begin
        ro_user_read_valid <= 'd1;
    end
    else begin
        ro_user_read_valid <= 'd0;
    end
end

endmodule