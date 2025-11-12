`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module flash_TOP(
    input   i_clk       ,
    output  o_spi_clk   ,
    output  o_spi_cs    ,
    output  o_spi_mosi  ,
    input   i_spi_miso  
);

/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/

/***************wire******************/
wire w_clk_10MHz        ;
wire w_clk_10MHz_lock   ;

wire w_operation_type   ;  
wire w_operation_addr   ;  
wire w_operation_num    ;  
wire w_operation_valid  ;  
wire w_operation_ready  ;  

wire w_write_data       ;      
wire w_write_sop        ;      
wire w_write_eop        ;      
wire w_write_valid      ;      
             
wire w_read_data        ;       
wire w_read_sop         ;       
wire w_read_eop         ;       
wire w_read_valid       ;       
/***************component*************/
SYSTEM_CLK SYSTEM_CLK_U0
(
    .clk_in1    (i_clk              ),
    .clk_out1   (w_clk_10MHz        ),  
    .locked     (w_clk_10MHz_lock   ) 
);

user_gen_data user_gen_data_u0(
    .i_clk              (w_clk_10MHz        ),
    .i_rst              (~w_clk_10MHz_lock  ),

    .o_operation_type   (w_operation_type   ),
    .o_operation_addr   (w_operation_addr   ),
    .o_operation_num    (w_operation_num    ),
    .o_operation_valid  (w_operation_valid  ),
    .i_operation_ready  (w_operation_ready  ),

    .o_write_data       (w_write_data       ),
    .o_write_sop        (w_write_sop        ),
    .o_write_eop        (w_write_eop        ),
    .o_write_valid      (w_write_valid      ),

    .i_read_data        (w_read_data        ),
    .i_read_sop         (w_read_sop         ),
    .i_read_eop         (w_read_eop         ),
    .i_read_valid       (w_read_valid       )
);
/***************assign****************/

/***************always****************/
endmodule
