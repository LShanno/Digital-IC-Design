`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module uart_tx #(
    parameter P_UART_BUADRATE       = 115200    ,
    parameter P_SYSTEM_CLK          = 100000000 ,
    parameter P_UART_START_WIDTH    = 1         ,
    parameter P_UART_DATA_WIDTH     = 8         ,
    parameter P_UART_STOP_WIDTH     = 1         ,
    parameter P_UART_CHECK_WIDTH    = 1         ,
    parameter P_UART_CHECK          = 1
)(
    input                               i_clk           ,
    input                               i_rst           ,

    output                              o_uart_tx       ,

    input [P_UART_DATA_WIDTH - 1 : 0]   i_user_tx_data  ,
    input                               i_user_tx_valid ,

    output                              o_user_tx_ready //给user的数据有效信号,表示可以从user接收数据再发送出去,user在接收到ready信号后的下一个时钟周期再发入数据
);

/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
reg                             ro_uart_tx          ;
reg                             ro_user_tx_ready    ;

reg [15:0]                      r_cnt               ;

reg [P_UART_DATA_WIDTH - 1 : 0] r_tx_data           ;

reg                             r_check             ;
/***************wire******************/

/***************component*************/

/***************assign****************/
assign o_uart_tx        = ro_uart_tx                        ;
assign o_user_tx_ready  = ro_user_tx_ready                  ;

assign w_tx_active      = i_user_tx_valid & o_user_tx_ready ;//握手信号 
/***************always****************/
always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ro_user_tx_ready <='d1;
    end
    else if (w_tx_active) begin
        ro_user_tx_ready <= 'd0;
    end
    else if (r_cnt == P_UART_START_WIDTH + P_UART_DATA_WIDTH - 1 && P_UART_CHECK == 0) begin//停止位拉高，将停止位和空闲态重叠，增加传输效率
        ro_user_tx_ready <= 'd1;
    end
    else if (r_cnt == P_UART_START_WIDTH + P_UART_DATA_WIDTH + P_UART_CHECK_WIDTH - 1 && P_UART_CHECK > 0) begin
        ro_user_tx_ready <= 'd1;
    end
    else begin
        ro_user_tx_ready <= ro_user_tx_ready;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_cnt <= 'd0;
    end
    else if (r_cnt == P_UART_START_WIDTH + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH - 1 && P_UART_CHECK == 0) begin
        r_cnt <= 'd0;
    end
    else if (r_cnt == P_UART_START_WIDTH + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH + P_UART_CHECK_WIDTH - 1 && P_UART_CHECK > 0) begin
        r_cnt <= 'd0;
    end
    else if (!ro_user_tx_ready) begin
        r_cnt <= r_cnt + 1;
    end
    else begin
        r_cnt <= r_cnt;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_tx_data <= 'd0;
    end
    else if (w_tx_active) begin
        r_tx_data <= i_user_tx_data;
    end
    else if (!ro_user_tx_ready) begin
        r_tx_data <= r_tx_data >> 1;
    end
    else begin
        r_tx_data <= r_tx_data;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ro_uart_tx <= 'd0;
    end
    else if (w_tx_active) begin//起始位输出
        ro_uart_tx <= 'd0;
    end
    else if (r_cnt == P_UART_START_WIDTH + P_UART_DATA_WIDTH - 1 && P_UART_CHECK > 0) begin//校验位输出
        ro_uart_tx <= P_UART_CHECK == 1 ? r_check : ~ r_check;
    end
    else if (r_cnt == P_UART_START_WIDTH + P_UART_DATA_WIDTH - 1 && P_UART_CHECK == 0) begin//无校验位输出停止位
        ro_uart_tx <= 'd1;
    end
    else if (r_cnt == P_UART_START_WIDTH + P_UART_DATA_WIDTH  + P_UART_CHECK_WIDTH - 1 && P_UART_CHECK >= 0) begin//有校验位输出停止位
        ro_uart_tx <= 'd1;
    end
    else if (!ro_user_tx_ready) begin
        ro_uart_tx <= r_tx_data[0];
    end
    else begin
        ro_uart_tx <= ro_uart_tx;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        r_check <= 'd0;
    end
    else if(r_cnt >= P_UART_START_WIDTH && r_cnt <= (P_UART_DATA_WIDTH + P_UART_START_WIDTH -1) && P_UART_CHECK == 1) begin
        r_check <= r_check ^ r_tx_data[0];
    end
    else if(r_cnt >= P_UART_START_WIDTH && r_cnt <= (P_UART_DATA_WIDTH + P_UART_START_WIDTH -1) && P_UART_CHECK == 2) begin
        r_check <= ~(r_check ^ r_tx_data[0]);
    end
    else begin
        r_check <= 'd0;
    end
end

endmodule