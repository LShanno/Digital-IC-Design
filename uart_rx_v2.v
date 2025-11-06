`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

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

reg [1:0]                       r_uart_rx           ;

reg                             r_check             ;
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
    else if(r_uart_rx[1] == 0 || r_cnt > 0) begin
        r_cnt <= r_cnt + 1;
    end
    else begin
        r_cnt <= r_cnt;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        r_uart_rx <= 'b11;
    end
    else begin
        r_uart_rx <= {r_uart_rx[0],i_uart_rx};
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        ro_user_rx_data <= 'd0;
    end
    else if(r_cnt >= P_UART_START_WIDTH && r_cnt <= (P_UART_DATA_WIDTH + P_UART_START_WIDTH -1)) begin
        ro_user_rx_data <= {r_uart_rx[1],ro_user_rx_data[P_UART_DATA_WIDTH - 1:1]};
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
    else if(r_cnt == (P_UART_DATA_WIDTH + P_UART_START_WIDTH + P_UART_CHECK_WIDTH - 1) && P_UART_CHECK == 1 && r_uart_rx[1] == r_check) begin
        ro_user_rx_valid <= 'd1;
    end
    else if(r_cnt == (P_UART_DATA_WIDTH + P_UART_START_WIDTH + P_UART_CHECK_WIDTH - 1) && P_UART_CHECK == 2 && r_uart_rx[1] == !r_check) begin//在停止位拉高valid
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

// always@(posedge i_clk, posedge i_rst)
// begin
//     if(i_rst) begin
//         r_check_1r <= 'd0; 
//         r_check_2r <= 'd0; 
//     end
//     else begin 
//         r_check_1r <= r_check; 
//         r_check_2r <= r_check_1r; 
//     end
// end

endmodule



