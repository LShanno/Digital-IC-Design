`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

//该UART的RX功能未对输入信号进行打拍，可能造成亚稳态，最好对输入信号打两拍来消除亚稳态
//https://blog.csdn.net/weixin_42279450/article/details/124199039?spm=1001.2101.3001.6650.3&utm_medium=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-3-124199039-blog-139739322.235%5Ev43%5Epc_blog_bottom_relevance_base8&depth_1-utm_source=distribute.pc_relevant.none-task-blog-2%7Edefault%7EBlogCommendFromBaidu%7ERate-3-124199039-blog-139739322.235%5Ev43%5Epc_blog_bottom_relevance_base8&utm_relevant_index=6

module uart_rx #(
    parameter P_UART_BUADRATE       = 115200    ,
    parameter P_SYSTEM_CLK          = 100000000 ,
    parameter P_UART_START_WIDTH    = 1         ,
    parameter P_UART_DATA_WIDTH     = 8         ,
    parameter P_UART_STOP_WIDTH     = 1         ,
    parameter P_UART_CHECK_WIDTH    = 1         ,
    parameter P_UART_CHECK          = 1
)(
    input i_clk                                         ,
    input i_rst                                         ,

    input i_uart_rx                                     ,

    output [P_UART_DATA_WIDTH - 1 : 0]  o_user_rx_data  ,
    output o_user_rx_valid
);

/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
reg [P_UART_DATA_WIDTH - 1 : 0] ro_user_rx_data     ; 
reg                             ro_user_rx_valid    ;

reg [15:0]                      r_cnt               ;

reg                             r_check             ;
reg                             r_check_1r          ;
reg                             r_check_2r          ;
/***************wire******************/

/***************component*************/

/***************assign****************/
assign o_user_rx_data   = ro_user_rx_data   ;    
assign o_user_rx_valid  = ro_user_rx_valid  ;    
/***************always****************/
always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        r_cnt <= 'd0;
    end
    else if(r_cnt == P_UART_START_WIDTH + P_UART_DATA_WIDTH + P_UART_STOP_WIDTH + P_UART_CHECK_WIDTH -1) begin
        r_cnt <= 'd0;
    end
    else if(i_uart_rx == 0 || r_cnt > 0) begin
        r_cnt <= r_cnt + 1;
    end
    else begin
        r_cnt <= r_cnt;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        ro_user_rx_data <= 'd0;
    end
    else if(r_cnt >= P_UART_START_WIDTH && r_cnt <= (P_UART_DATA_WIDTH + P_UART_START_WIDTH -1)) begin
        ro_user_rx_data <= {i_uart_rx,ro_user_rx_data[P_UART_DATA_WIDTH - 1:1]};
    end
    else begin
        ro_user_rx_data <= ro_user_rx_data;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        ro_user_rx_valid <= 'd0;
    end
    else if(r_cnt == (P_UART_DATA_WIDTH + P_UART_START_WIDTH + P_UART_CHECK_WIDTH -1) && P_UART_CHECK == 0) begin
        ro_user_rx_valid <= 'd1;
    end
    else if(r_cnt == (P_UART_DATA_WIDTH + P_UART_START_WIDTH + P_UART_CHECK_WIDTH - 1) && P_UART_CHECK == 1 && i_uart_rx == r_check_2r) begin
        ro_user_rx_valid <= 'd1;
    end
    else if(r_cnt == (P_UART_DATA_WIDTH + P_UART_START_WIDTH + P_UART_CHECK_WIDTH - 1) && P_UART_CHECK == 2 && i_uart_rx == !r_check_2r) begin
        ro_user_rx_valid <= 'd1;
    end
    else begin
        ro_user_rx_valid <='d0;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        r_check <= 'd0;
    end
    else if(r_cnt >= P_UART_START_WIDTH && r_cnt <= (P_UART_DATA_WIDTH + P_UART_START_WIDTH -1) && P_UART_CHECK == 1) begin
        r_check <= r_check ^ i_uart_rx;
    end
    else if(r_cnt >= P_UART_START_WIDTH && r_cnt <= (P_UART_DATA_WIDTH + P_UART_START_WIDTH -1) && P_UART_CHECK == 2) begin
        r_check <= ~(r_check ^ i_uart_rx);
    end
    else begin
        r_check <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        r_check_1r <= 'd0; 
        r_check_2r <= 'd0; 
    end
    else begin 
        r_check_1r <= r_check; 
        r_check_2r <= r_check_1r; 
    end
end

endmodule



