`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module spi_TOP#(
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
    output                              o_spi_mosi          
);

/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/

/***************wire******************/
wire                                w_clk_100MHz            ;
wire                                w_system_pll_locked     ;

wire [P_WRITE_DATA_WIDTH - 1 : 0]   w_user_write_data       ;
wire                                w_user_write_valid      ;
wire                                w_user_write_ready      ;
wire [P_READ_DATA_WIDTH - 1 : 0]    w_user_read_data        ;
wire                                w_user_read_valid       ;

/***************component*************/
system_pll system_pll_u0(
    .clk_out1          (w_clk_100MHz            ), 
    .locked             (w_system_pll_locked    ),
    .clk_in1            (i_clk                  )
);

spi_driver#(
    .P_WRITE_DATA_WIDTH (P_WRITE_DATA_WIDTH     ),
    .P_READ_DATA_WIDTH  (P_READ_DATA_WIDTH      ),
    .P_CPOL             (P_CPOL                 ),
    .P_CPHL             (P_CPHL                 )
)
spi_driver_u0
(
    .i_clk              (w_clk_100MHz           ),
    .i_rst              (~w_system_pll_locked   ),

    .o_spi_clk          (o_spi_clk              ),
    .o_spi_cs           (o_spi_cs               ),

    .i_spi_miso         (i_spi_miso             ),
    .o_spi_mosi         (o_spi_mosi             ),

    .i_user_write_data  (w_user_write_data      ),
    .i_user_write_valid (w_user_write_valid     ),
    .o_user_write_ready (w_user_write_ready     ),

    .o_user_read_data   (w_user_read_data       ),
    .o_user_read_valid  (w_user_read_valid      ) 
);
/***************assign****************/

/***************always****************/
endmodule
