`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

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
wire                                w_clk               ;
wire                                w_rst               ;
wire                                w_uart_rx_clk       ;
reg                                 r_uart_rx_clk_rst   ;
reg  [2:0]                          r_rx_overvalue      ;
reg  [2:0]                          r_rx_overvalue_1d   ;
reg                                 r_rx_overlock       ;
reg                                 r_user_rx_valid     ;
wire [P_UART_DATA_WIDTH - 1 : 0]    w_user_rx_data      ;
wire                                w_user_rx_valid     ;
reg  [P_UART_DATA_WIDTH - 1 : 0]    r_user_rx_data_1    ;
reg  [P_UART_DATA_WIDTH - 1 : 0]    r_user_rx_data_2    ;  
reg                                 r_user_rx_valid_1   ;
reg                                 r_user_rx_valid_2   ;

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

CLK_DIV_module#(
    .P_CLK_DIV_CNT  (P_CLK_DIV_NUMBER   )
)               
CLK_DIV_module_u1               
(               
    .i_clk          (i_clk              ),
    .i_rst          (r_uart_rx_clk_rst  ),
    .o_clk_div      (w_uart_rx_clk      )
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
    .i_clk              (w_uart_rx_clk      ),
    .i_rst              (w_uart_buadclk_rst ),

    .i_uart_rx          (i_uart_rx          ),

    .o_user_rx_data     (w_user_rx_data     ),
    .o_user_rx_valid    (w_user_rx_valid    )
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
assign o_user_rx_data   = r_user_rx_data_2      ;
assign o_user_rx_valid  = r_user_rx_valid_2     ;
/***************always****************/
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_rx_overvalue <= 'd0;
    else if(!r_rx_overlock)
        r_rx_overvalue <= {r_rx_overvalue[1:0],i_uart_rx};
    else 
        r_rx_overvalue <= 3'b111;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_rx_overvalue_1d <= 'd0;
    else 
        r_rx_overvalue_1d <= r_rx_overvalue;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_rx_overlock <= 'd0;
    else if(!w_user_rx_valid && r_user_rx_valid)
        r_rx_overlock <= 'd0;
    else if(r_rx_overvalue == 3'b000 && r_rx_overvalue_1d != 3'b000)
        r_rx_overlock <= 'd1;
    else 
        r_rx_overlock <= r_rx_overlock;
end


always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_user_rx_valid <= 'd0;
    else 
        r_user_rx_valid <= w_user_rx_valid;
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst)
        r_uart_rx_clk_rst <= 'd1;
    else if(!w_user_rx_valid && r_user_rx_valid)
        r_uart_rx_clk_rst <= 'd1;
    else if(r_rx_overvalue == 3'b000 && r_rx_overvalue_1d != 3'b000)
        r_uart_rx_clk_rst <= 'd0;
    else 
        r_uart_rx_clk_rst <= r_uart_rx_clk_rst;
end

always@(posedge w_clk,posedge w_rst)
begin
    if(w_uart_buadclk_rst) begin
        r_user_rx_data_1  <= 'd0;
        r_user_rx_data_2  <= 'd0;
        r_user_rx_valid_1 <= 'd0;
        r_user_rx_valid_2 <= 'd0;
    end else begin
        r_user_rx_data_1  <= w_user_rx_data;
        r_user_rx_data_2  <= r_user_rx_data_1;
        r_user_rx_valid_1 <= w_user_rx_valid;
        r_user_rx_valid_2 <= r_user_rx_valid_1;
    end
end

endmodule
