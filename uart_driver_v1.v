`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
//异步通信两个频率信号即使频率相同，也会存在误差，在多个时钟周期后累计误差过大产生亚稳态，需要对时钟进行动态校正（针对起始位需要进行过采样）
//该代码未进行过采样，可能会导致出现误码

module uart_driver# (
    parameter P_SYSTEM_CLK          = 100000000 ,
    parameter P_UART_BUADRATE       = 115200    ,
    parameter P_UART_START_WIDTH    = 1         ,
    parameter P_UART_DATA_WIDTH     = 8         ,
    parameter P_UART_STOP_WIDTH     = 1         ,
    parameter P_UART_CHECK_WIDTH    = 1         ,
    parameter P_UART_CHECK          = 1
)(
    input                               i_clk           ,
    input                               i_rst           ,

//TX
    output                              o_uart_tx       ,
        
    input [P_UART_DATA_WIDTH - 1 : 0]   i_user_tx_data  ,
    input                               i_user_tx_valid ,

    output                              o_user_tx_ready ,

//RX
    input                               i_uart_rx       ,

    output [P_UART_DATA_WIDTH - 1 : 0]  o_user_rx_data  ,
    output                              o_user_rx_valid

);
/***************function**************/

/***************parameter*************/
localparam P_CLK_DIV_NUM = P_SYSTEM_CLK / P_UART_BUADRATE;
/***************port******************/             

/***************mechine***************/

/***************reg*******************/

/***************wire******************/
wire w_clk;
wire w_rst;

/***************component*************/

CLK_DIV_module#(
    .P_CLK_DIV_CNT  (P_CLK_DIV_NUM  )
)
CLK_DIV_module_u0
(
    .i_clk          (i_clk          ),
    .i_rst          (i_rst          ),
    .o_clk          (w_clk          )
);

rst_gen_module#(
    .P_RST_CYCLE    (10     )    
)
rst_gen_module_u0
(
    .i_clk          (w_clk  ),
    .i_rst          (i_rst  ),
    .o_rst          (w_rst  )
);

uart_rx #(
    .P_UART_BUADRATE    (P_UART_BUADRATE    ),
    .P_SYSTEM_CLK       (P_SYSTEM_CLK       ),
    .P_UART_START_WIDTH (P_UART_START_WIDTH ),
    .P_UART_DATA_WIDTH  (P_UART_DATA_WIDTH  ),
    .P_UART_STOP_WIDTH  (P_UART_STOP_WIDTH  ),
    .P_UART_CHECK_WIDTH (P_UART_CHECK_WIDTH ),
    .P_UART_CHECK       (P_UART_CHECK       )
)
uart_rx_u0
(
    .i_clk              (w_clk              ),
    .i_rst              (w_rst              ),

    .i_uart_rx          (i_uart_rx          ),

    .o_user_rx_data     (o_user_rx_data     ),
    .o_user_rx_valid    (o_user_rx_valid    )
);

uart_tx #(
    .P_UART_BUADRATE    (P_UART_BUADRATE    ),
    .P_SYSTEM_CLK       (P_SYSTEM_CLK       ),
    .P_UART_START_WIDTH (P_UART_START_WIDTH ),
    .P_UART_DATA_WIDTH  (P_UART_DATA_WIDTH  ),
    .P_UART_STOP_WIDTH  (P_UART_STOP_WIDTH  ),
    .P_UART_CHECK_WIDTH (P_UART_CHECK_WIDTH ),
    .P_UART_CHECK       (P_UART_CHECK       )
)
uart_tx_u0
(
    .i_clk              (w_clk              ),
    .i_rst              (w_rst              ),

    .o_uart_tx          (o_uart_tx          ),

    .i_user_tx_data     (i_user_tx_data     ),
    .i_user_tx_valid    (i_user_tx_valid    ),

    .o_user_tx_ready    (o_user_tx_ready    )
);
/***************assign****************/

/***************always****************/

endmodule
