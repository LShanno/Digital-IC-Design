`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module iic_driver#(
    parameter       P_ADDR_WIDTH   = 16
)(
    input           i_clk               ,//模块输入时钟
    input           i_rst               ,//模块输入复位（高有效）

    //用户接口
    input [6:0]     i_driver_addr       ,//用户输入设备地址 7bit
    input [15:0]    i_operation_addr    ,//用户输入存储地址 10bit 高位补零
    input [7:0]     i_operation_len     ,//用户输入读写长度
    input           i_operation_type    ,//用户输入操作类型
    input           i_operation_valid   ,//用户输入有效信号
    output          o_operation_ready   ,//用户输出准备信号

    input [7:0]     i_write_data        ,//用户输入写数据
    output          o_write_req         ,//用户输出写请求

    output [7:0]    o_read_data         ,//输出IIC读到的数据
    output          o_read_valid        ,//输出IIC读数据有效

    //IIC接口
    output          o_iic_scl           ,//IIC时钟
    inout           io_iic_sda           //IIC双向数据
);
/***************function**************/

/***************parameter*************/
localparam      P_ST_IDLE       = 0     ,//空闲态
                P_ST_START      = 1     ,//起始态
                P_ST_UADDR      = 2     ,//设备地址
                P_ST_DADDR1     = 3     ,//存储地址高位
                P_ST_DADDR2     = 4     ,//存储地址低位
                P_ST_WRITE      = 5     ,//写数据
                P_ST_RESTART    = 6     ,//DUMMY WRITE给地址后重启动
                P_ST_READ       = 7     ,//读数据
                P_ST_WAIT       = 8     ,
                P_ST_STOP       = 9     ,
                P_ST_EMPTY      = 10    ;

localparam      P_WRITE         = 0     ,//写标志位
                P_READ          = 1     ;//读标志位

/***************port******************/             

/***************mechine***************/
reg [7:0]       r_st_current        ;
reg [7:0]       r_st_next           ;
reg [7:0]       r_st_cnt            ;

wire            w_st_turn           ;//状态跳转条件,可以不加

reg             r_st_restart        ;//判断是DUMMY WRITE之前还是之后

reg             r_st_ack            ;
/***************reg*******************/
//输入寄存器
reg [6:0]       ri_driver_addr      ;  
reg [15:0]      ri_operation_addr   ;  
reg [7:0]       ri_operation_len    ;  
reg             ri_operation_type   ;  
reg             ri_operation_valid  ;  

reg [7:0]       ri_write_data       ;  

//输出寄存器
reg             ro_operation_ready  ;  

reg             ro_write_req        ;
reg             ro_write_req_1d     ;

reg [7:0]       ro_read_data        ;  
reg             ro_read_valid       ;

reg             ro_iic_scl          ;  
reg             rio_iic_sda         ; 

reg             r_iic_st            ;//SCL的反

//三态门控制
reg             r_iic_sda_ctrl      ;

//写数据量
reg [7:0]       r_write_cnt         ;

//第9bit从机应答
reg             r_ack               ;
/***************wire******************/
//握手信号
wire            w_operation_active  ;

//三态门输入信号
wire            w_iic_sda           ;
/***************component*************/

/***************assign****************/
assign o_operation_ready    = ro_operation_ready                    ;  
assign o_write_req          = ro_write_req                          ;  
assign o_read_data          = ro_read_data                          ;  
assign o_read_valid         = ro_read_valid                         ;  
assign o_iic_scl            = ro_iic_scl                            ;  
assign io_iic_sda           = r_iic_sda_ctrl ? rio_iic_sda : 1'bz   ;//只有三态门控制信号为高时输出，其余为高阻态输出    

assign w_operation_active   = i_operation_valid & o_operation_ready ;

assign w_st_turn            = (r_st_cnt == 8) && r_iic_st           ;

assign w_iic_sda            = !r_iic_sda_ctrl ? io_iic_sda : 1'd0   ;//三态门控制信号为低时接收输入信号
/***************always****************/
//状态机
always @(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_st_current <= P_ST_IDLE;
    end
    else begin
        r_st_current <= r_st_next;
    end
end

always @(*) begin
    case (r_st_current)
        P_ST_IDLE       : r_st_next = w_operation_active ? P_ST_START : P_ST_IDLE;
        P_ST_START      : r_st_next = P_ST_UADDR;
        P_ST_UADDR      : r_st_next = w_st_turn ? 
                                        r_st_restart ? P_ST_READ : P_ST_DADDR1
                                        : P_ST_UADDR;
        P_ST_DADDR1     : r_st_next = w_st_turn ? P_ST_DADDR2 : P_ST_DADDR1;
        P_ST_DADDR2     : r_st_next = w_st_turn ?
                                        ri_operation_type == P_WRITE ? P_ST_WRITE : P_ST_RESTART
                                        : P_ST_DADDR2;
        P_ST_WRITE      : r_st_next = w_st_turn && r_write_cnt == ri_operation_len - 1 ? P_ST_WAIT : P_ST_WRITE;
        P_ST_RESTART    : r_st_next = P_ST_STOP;
        P_ST_READ       : r_st_next = w_st_turn ? P_ST_WAIT : P_ST_READ;
        P_ST_WAIT       : r_st_next = P_ST_STOP;//应答位
        P_ST_STOP       : r_st_next = r_st_cnt == 1 ? P_ST_EMPTY : P_ST_STOP;//停止位
        P_ST_EMPTY      : r_st_next = r_st_restart ? P_ST_START : P_ST_IDLE;
        default         : r_st_next = P_ST_IDLE;
    endcase
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_st_cnt <= 'd0;
    end
    else if (r_st_current != r_st_next || ro_write_req_1d || ro_read_valid) begin//转状态、写完一字节、读完清零
        r_st_cnt <= 'd0;
    end
    else if (r_st_current == P_ST_STOP) begin//停止转空闲
        r_st_cnt <= r_st_cnt + 1;
    end
    else if (r_iic_st) begin//一个状态内计数
        r_st_cnt <= r_st_cnt + 1;
    end
    else begin
        r_st_cnt <= r_st_cnt;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_st_restart <= 'd0;
    end
    else if (r_st_current == P_ST_READ) begin//DUMMY WRITE
        r_st_restart <= 'd0;
    end
    else if (r_st_current == P_ST_RESTART) begin
        r_st_restart <= 'd1;
    end
    else begin
        r_st_restart <= r_st_restart;
    end
end

//用户接口
///握手
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_operation_ready <= 'd1;
    end
    else if (w_operation_active) begin
        ro_operation_ready <= 'd0;
    end
    else if (r_st_current == P_ST_IDLE) begin
        ro_operation_ready <= 'd1;
    end
    else begin
        ro_operation_ready <= ro_operation_ready;
    end
end

///用户接口初始化
always @(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ri_driver_addr      <= 'd0;  
        ri_operation_addr   <= 'd0;  
        ri_operation_len    <= 'd0;  
        ri_operation_type   <= 'd0;  
        ri_operation_valid  <= 'd0;  
    end
    else if (w_operation_active) begin
        ri_driver_addr      <= {i_driver_addr,i_operation_type} ;  
        ri_operation_addr   <= i_operation_addr                 ;  
        ri_operation_len    <= i_operation_len                  ;  
        ri_operation_type   <= i_operation_type                 ;  
        ri_operation_valid  <= i_operation_valid                ;  
    end
    else begin
        ri_driver_addr      <= ri_driver_addr       ;  
        ri_operation_addr   <= ri_operation_addr    ;  
        ri_operation_len    <= ri_operation_len     ;  
        ri_operation_type   <= ri_operation_type    ;  
        ri_operation_valid  <= ri_operation_valid   ;  
    end
end

///写操作
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_write_req <= 'd0;
    end
    else if (r_st_current == P_ST_DADDR2 && ri_operation_type == P_WRITE && r_st_cnt == 7 && r_iic_st) begin//8bit数据结束后
        ro_write_req <= 'd1;
    end
        else if (r_st_current >= P_ST_DADDR2 && ri_operation_type == P_WRITE && r_st_cnt == 7 && r_iic_st) begin//8bit数据结束后
        ro_write_req <= r_write_cnt < ri_operation_len - 1 ? 1'b1 : 1'b0;
    end
    else begin
        ro_write_req <= 'd0;
    end
end

///ro_write_req打一拍穿过ack位
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_write_req_1d <= 'd0;
    end
    else begin
        ro_write_req_1d <= ro_write_req;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_write_cnt <= 'd0;
    end
    else if (r_st_current == P_ST_IDLE) begin
        r_write_cnt <= 'd0;
    end
    else if (r_st_current == P_ST_WRITE && w_st_turn) begin//字节计数
        r_write_cnt <= r_write_cnt + 1;
    end
    else begin
        r_write_cnt <= r_write_cnt;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ri_write_data <= 'd0;
    end
    else if (ro_write_req_1d) begin
        ri_write_data <= i_write_data;
    end
    else begin
        ri_write_data <= ri_write_data;
    end
end

///读操作
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_read_valid <= 'd0;
    end
    else if (r_st_current == P_ST_READ && r_st_cnt == 8 && !r_iic_st) begin//在最后的scl低电平时拉高一个时钟周期 scl周期是时钟的两倍
        ro_read_valid <= 'd1;
    end
    else begin
        ro_read_valid <= 'd0;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_read_data <= 'd0;
    end
    else if (r_st_current == P_ST_READ && r_st_cnt >= 1 && r_st_cnt <= 8 && !r_iic_st) begin//低电平变化，表现在scl下降沿跳变
        ro_read_data <= {ro_read_data[6:0],w_iic_sda};
    end
    else begin
        ro_read_data <= ro_read_data;
    end
end

//IIC接口
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_iic_scl <= 'd1;
    end
    else if (r_st_current >= P_ST_UADDR && r_st_current <= P_ST_WAIT) begin
        ro_iic_scl <= ~ro_iic_scl;
    end
    else begin
        ro_iic_scl <= 'd1;
    end
end

always @(posedge i_clk,posedge i_rst) begin//不直接使用时钟是因为防止时钟负载能力减弱和时钟偏斜
    if (i_rst) begin
        r_iic_st <= 'd0;
    end
    else if (r_st_current <= P_ST_WAIT && r_st_current >= P_ST_UADDR) begin//这里和o_iic_scl的一样，因为iic是高电平采样、低电平改变数据
        r_iic_st <= ~r_iic_st;
    end
    else begin
        r_iic_st <= 'd0;
    end
end

///SDA三态门控制
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_iic_sda_ctrl <= 'd0;
    end
    else if (r_st_cnt == 8 || r_st_next == P_ST_IDLE) begin
        r_iic_sda_ctrl <= 'd0;
    end
    else if (r_st_current >= P_ST_START && r_st_current <= P_ST_WRITE || r_st_current == P_ST_STOP) begin
        r_iic_sda_ctrl <= 'd1;
    end
    else begin
        r_iic_sda_ctrl <= r_iic_sda_ctrl;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        rio_iic_sda <= 'd0;
    end
    else if (r_st_current == P_ST_START) begin
        rio_iic_sda <= 'd0;
    end
    else if (r_st_current == P_ST_UADDR) begin
        rio_iic_sda <= ri_driver_addr[7 - r_st_cnt];
    end
    else if (r_st_current == P_ST_DADDR1) begin
        rio_iic_sda <= ri_operation_addr[15 - r_st_cnt];
    end
    else if (r_st_current == P_ST_DADDR2) begin
        rio_iic_sda <= ri_operation_addr[7 - r_st_cnt];
    end
    else if (r_st_current == P_ST_WRITE) begin
        rio_iic_sda <= ri_write_data[7 - r_st_cnt];
    end
    else if (r_st_current == P_ST_STOP) begin
        rio_iic_sda <= 'd1;
    end
    else begin
        rio_iic_sda <= 'd0;
    end
end

//ACK
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_ack <= 'd0;
    end
    else if (w_st_turn) begin
        r_ack <= w_iic_sda;
    end
    else begin
        r_ack <= 'd0;
    end
end

endmodule