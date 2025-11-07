`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module uart_TOP(
    input   i_clk       ,
    input   i_rst       ,
    input   i_uart_rx   ,
    output  o_uart_tx
);

/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/

/***************wire******************/
wire w_clk_100MHz           ;
wire w_clk_rst              ;
wire w_system_pll_locked    ;
/***************component*************/
system_pll system_pll_u0(
    .clk_out1   (w_clk_100MHz           ), 
    .locked     (w_system_pll_locked    ),
    .clk_in1    (i_clk                  )
);

uart_driver# (
    .P_SYSTEM_CLK       (100000000      ),
    .P_UART_BUADRATE    (115200         ),
    .P_UART_START_WIDTH (1              ),
    .P_UART_DATA_WIDTH  (8              ),
    .P_UART_STOP_WIDTH  (1              ),
    .P_UART_CHECK_WIDTH (1              ),
    .P_UART_CHECK       (1              )
)
uart_driver_u0
(
    .i_clk              (w_clk_100MHz   ),
    .i_rst              (w_clk_rst      ),

//TX
    .o_uart_tx          (o_uart_tx      ),

    .i_user_tx_data     (               ),
    .i_user_tx_valid    (               ),

    .o_user_tx_ready    (               ),

//RX
    .i_uart_rx          (i_uart_rx      ),

    .o_user_rx_data     (               ),
    .o_user_rx_valid    (               )

);
/***************assign****************/
assign w_clk_rst = ~w_system_pll_locked;
/***************always****************/

endmodule