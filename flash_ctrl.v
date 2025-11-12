`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module flash_ctrl#(
    parameter P_OPERATION_WIDTH     = 32,
    parameter P_WRITE_DATA_WIDTH    = 8 ,
    parameter P_READ_DATA_WIDTH     = 8 ,
    parameter P_CPOL                = 0 ,//默认电平状态
    parameter P_CPHL                = 0 //在时钟第几个沿采样，包含上升沿和下降沿
)(
    //用户接口 和user_gen_data对应
    input                               i_clk               ,
    input                               i_rst               ,

    input [1 : 0]                       i_operation_type    ,
    input [23 : 0]                      i_operation_addr    ,
    input [8 : 0]                       i_operation_num     ,
    input                               i_operation_valid   ,
    output                              o_operation_ready   ,

    input [P_WRITE_DATA_WIDTH - 1 : 0]  i_write_data        ,
    input                               i_write_sop         ,
    input                               i_write_eop         ,
    input                               i_write_valid       ,

    output [P_READ_DATA_WIDTH - 1 : 0]  o_read_data         ,
    output                              o_read_sop          ,
    output                              o_read_eop          ,
    output                              o_read_valid        ，

    //驱动接口 和spi_flash_driver对应
    output [P_OPERATION_WIDTH - 1 : 0]  o_user_op_data      ,
    output [1 : 0]                      o_user_op_type      ,
    output [15 : 0]                     o_user_op_data_len  ,
    output [15 : 0]                     o_user_op_clk_len   ,
    output                              o_user_op_valid     ,
    input                               i_user_op_ready     ,

    output [P_WRITE_DATA_WIDTH - 1 : 0] o_user_write_data   ,
    input                               i_user_write_req    ,

    input [P_READ_DATA_WIDTH - 1 : 0]   i_user_read_data    ,
    input                               i_user_read_valid   
);

/***************function**************/

/***************parameter*************/
//用户接口操作类型
localparam  P_USER_TYPE_CLEAR   = 0     ,
            P_USER_TYPE_READ    = 1     ,
            P_USER_TYPE_WRITE   = 2     ;

//SPI驱动操作类型
localparam  P_DRIVER_TYPE_INS   = 0     ,
            P_DRIVER_TYPE_READ  = 1     ,
            P_DRIVER_TYPE_WRITE = 2     ;

//状态机状态
localparam  P_IDLE              = 0     ,
            P_RUN               = 1     ,
            P_W_EN              = 2     ,
            P_W_INS             = 3     ,
            P_W_DATA            = 4     ,
            P_R_INS             = 5     ,
            P_R_DATA            = 6     ,
            P_CLEAR             = 7     ,
            P_BUSY              = 8     ,
            P_BUSY_CHECK        = 9     ;      
/***************port******************/             

/***************mechine***************/
reg [7 : 0] r_st_current    ;
reg [7 : 0] r_st_next       ;
/***************reg*******************/
//用户接口
reg [1 : 0]                         ri_operation_type   ;    
reg [23 : 0]                        ri_operation_addr   ;    
reg [8 : 0]                         ri_operation_num    ;    

reg [P_WRITE_DATA_WIDTH - 1 : 0]    ri_write_data       ;       
reg                                 ri_write_sop        ;       
reg                                 ri_write_eop        ;       
reg                                 ri_write_valid      ;       

reg [P_READ_DATA_WIDTH - 1 : 0]     ro_read_data        ;        
reg                                 ro_read_sop         ;        
reg                                 ro_read_eop         ;        
reg                                 ro_read_valid       ;  

reg                                 ro_operation_ready  ;

//SPI驱动
reg [P_OPERATION_WIDTH - 1 : 0]     ro_user_op_data     ;
reg [1 : 0]                         ro_user_op_type     ;
reg [15 : 0]                        ro_user_op_data_len ;
reg [15 : 0]                        ro_user_op_clk_len  ;
reg                                 ro_user_op_valid    ;

reg                                 ri_user_write_req   ;   
reg [P_READ_DATA_WIDTH - 1 : 0]     ri_user_read_data   ;   
reg                                 ri_user_read_valid  ;   

reg                                 r_fifo_rden         ;
reg                                 r_fifo_rden_1r      ;
reg                                 r_fifo_rden_pos     ;
reg                                 r_fifo_wren         ;
reg                                 r_fifo_empty        ;

/***************wire******************/
wire w_operation_active ;
wire w_user_op_active   ;
wire w_fifo_empty       ;
wire w_read_data        ;
/***************component*************/
//fifo寄存器
FIFO_8X1024 FIFO_8X1024_u0 (
    .clk      (i_clk                ),  
    .srst     (i_rst                ),  
    .din      (ri_write_data        ),  
    .wr_en    (ri_write_valid       ),  
    .rd_en    (i_user_write_req     ),  
    .dout     (o_user_write_data    ),//用o_user_write_data不能用ro_user_write_data，因为fifo直接线出数据，再通过寄存器的话会慢一个时钟出
    .full     (                     ), 
    .empty    (                     )  
);

///fifo使用包含时钟 复位 输入数据 写使能 输出数据 读使能 fifo满信号 fifo空信号
FIFO_8X1024 FIFO_8X1024_u1 (
    .clk      (i_clk                ), 
    .srst     (i_rst                ), 
    .din      (ri_user_read_data    ), 
    .wr_en    (r_fifo_wren          ), 
    .rd_en    (r_fifo_rden          ), 
    .dout     (w_read_data          ), 
    .full     (                     ),    
    .empty    (w_fifo_empty         )  
);
/***************assign****************/
assign o_read_data          = ro_read_data                          ; 
assign o_read_sop           = ro_read_sop                           ; 
assign o_read_eop           = ro_read_eop                           ; 
assign o_read_valid         = ro_read_valid                         ;
assign o_operation_ready    = ro_operation_ready                    ; 
assign o_user_op_data       = ro_user_op_data                       ; 
assign o_user_op_type       = ro_user_op_type                       ; 
assign o_user_op_data_len   = ro_user_op_data_len                   ; 
assign o_user_op_clk_len    = ro_user_op_clk_len                    ;
assign o_user_op_valid      = ro_user_op_valid                      ;  

assign w_operation_active   = i_operation_valid & o_operation_ready ;
assign w_user_op_active     = o_user_op_valid   & i_user_op_ready   ;
/***************always****************/
//状态机
always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_st_current <= P_IDLE;
    end
    else begin
        r_st_current <= r_st_next;
    end
end

always@(*) begin
    case(r_st_current) 
        P_IDLE          : r_st_next = w_operation_active ? P_RUN : P_IDLE;
        P_RUN           : r_st_next = ri_operation_type = P_USER_TYPE_READ ? P_R_INS : P_W_EN;//默认状态为写
        P_W_EN          : r_st_next = w_user_op_active ? 
                                        ri_operation_type = P_USER_TYPE_WRITE ? 
                                        P_W_INS : P_CLEAR 
                                        : P_W_EN;//判断是写数据状态还是擦除状态
        P_W_INS         : r_st_next = w_user_op_active ? P_W_DATA : P_W_INS;
        P_W_DATA        : r_st_next = i_user_op_ready ? P_BUSY : P_W_DATA;
        P_R_INS         : r_st_next = w_user_op_active ? P_R_DATA : P_R_INS;
        P_R_DATA        : r_st_next = i_user_op_ready ? P_BUSY : P_R_DATA;
        P_BUSY          : r_st_next = w_user_op_active ? P_BUSY_CHECK : P_BUSY;///判断是否写完或读完
        P_BUSY_CHECK    : r_st_next = ri_user_read_valid ? P_IDLE : P_BUSY;
        default         : r_st_next = P_W_EN;
    endcase
end

//driver
///三段状态机 状态寄存器阶段：保存当前的状态 状态转移逻辑阶段：根据当前状态和输入信号，计算下一个状态 输出逻辑阶段：根据当前状态，生成输出信号
always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ro_user_op_data     <= 'd0; 
        ro_user_op_type     <= 'd0; 
        ro_user_op_data_len <= 'd0; 
        ro_user_op_clk_len  <= 'd0; 
        ro_user_op_valid    <= 'd0; 
    end
    else if (r_st_current == P_W_EN) begin
        ro_user_op_data     <= {8'h06,8'h00,8'h00,8'h00}; 
        ro_user_op_type     <= P_DRIVER_TYPE_INS; 
        ro_user_op_data_len <= 8; 
        ro_user_op_clk_len  <= 8; 
        ro_user_op_valid    <= 'd1;
    end
    else if (r_st_current == P_W_INS) begin
        ro_user_op_data     <= {8'h02,ri_operation_addr};
        ro_user_op_type     <= P_DRIVER_TYPE_WRITE; 
        ro_user_op_data_len <= 32; 
        ro_user_op_clk_len  <= 32 + 8 *ri_operation_num; 
        ro_user_op_valid    <= 'd1;  
    end
    else if (r_st_current == P_R_INS) begin
        ro_user_op_data     <= {8'h03,ri_operation_addr};
        ro_user_op_type     <= P_DRIVER_TYPE_READ; 
        ro_user_op_data_len <= 32; 
        ro_user_op_clk_len  <= 32 + 8 *ri_operation_num; 
        ro_user_op_valid    <= 'd1;  
    end
    else if (r_st_current = P_CLEAR) begin
        ro_user_op_data     <= {8'h20,ri_operation_addr};
        ro_user_op_type     <= P_DRIVER_TYPE_INS; 
        ro_user_op_data_len <= 32; 
        ro_user_op_clk_len  <= 32 + 8 *ri_operation_num; 
        ro_user_op_valid    <= 'd1;  
    end
    else if (r_st_current = P_BUSY) begin//
        ro_user_op_data     <= {8'h05,24'd0};
        ro_user_op_type     <= P_DRIVER_TYPE_READ; 
        ro_user_op_data_len <= 8; 
        ro_user_op_clk_len  <= 16; 
        ro_user_op_valid    <= 'd1;  
    end
    else begin
        ro_user_op_data     <= ro_user_op_data     ;
        ro_user_op_type     <= ro_user_op_type     ; 
        ro_user_op_data_len <= ro_user_op_data_len ;
        ro_user_op_clk_len  <= ro_user_op_clk_len  ;
        ro_user_op_valid    <= ro_user_op_valid    ;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ri_user_read_data   <= 'd0;
        ri_user_read_valid  <= 'd0;
    end
    else begin
        ri_user_read_data   <= i_user_read_data;
        ri_user_read_valid  <= i_user_read_valid;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ri_user_write_req <= 'd0;
    end
    else begin
        ri_user_write_req <= i_user_write_req;
    end
end

//user
always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ri_operation_type   <= 'd0;  
        ri_operation_addr   <= 'd0;  
        ri_operation_num    <= 'd0; 
    end
    else if (w_operation_active) begin
        ri_operation_type   <= i_operation_type    ;
        ri_operation_addr   <= i_operation_addr    ;
        ri_operation_num    <= i_operation_num     ; 
    end
    else begin
        ri_operation_type   <= ri_operation_type   ; 
        ri_operation_addr   <= ri_operation_addr   ; 
        ri_operation_num    <= ri_operation_num    ; 
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if(i_rst) begin
        ro_operation_ready <= 'd1;
    end
    else if (r_st_next == P_IDLE) begin
        ro_operation_ready <= 'd1;
    end
    else if (w_operation_active) begin
        ro_operation_ready <= 'd0;
    end
    else begin
        ro_operation_ready <= ro_operation_ready;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ri_write_data   <= 'd0;       
        ri_write_sop    <= 'd0;       
        ri_write_eop    <= 'd0;       
        ri_write_valid  <= 'd0;     
    end
    else begin
        ri_write_data   <= i_write_data     ;       
        ri_write_sop    <= i_write_sop      ;       
        ri_write_eop    <= i_write_eop      ;       
        ri_write_valid  <= i_write_valid    ;
    end
end

///fifo信号控制 本质是控制fifo信号 并用fifo信号 如rden和wren等控制接口信号 如sop和eop等 达到需要的时序
always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_fifo_wren <= 'd0;
    end
    else if () begin

    end
    else begin
        r_fifo_wren <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_fifo_rden <= 'd0;
    end
    else if (w_fifo_empty) begin
        r_fifo_rden <= 'd0;
    end
    else if (r_st_current = P_R_DATA && r_st_next != P_R_DATA) begin
        r_fifo_rden <= 'd1;
    end
    else begin 
        r_fifo_rden <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_fifo_rden_1r <= 'd0;
    end
    else begin
        r_fifo_rden_1r <= r_fifo_rden;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_fifo_rden_pos <= 'd0;
    end
    else begin
        r_fifo_rden_pos <= !r_fifo_rden_1r & r_fifo_rden;//用r_fifo_rden_pos而不是w_fifo_rden_pos主要就是为了凑时序
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ro_read_sop <= 'd0;
    end
    else if (r_fifo_rden_1r) begin
        ro_read_sop <= 'd1;
    end
    else begin
        ro_read_sop <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ro_read_eop <= 'd0;
    end
    else if (w_fifo_empty && r_fifo_empty && ro_read_valid) begin
        ro_read_eop <= 'd1;
    end
    else begin
        ro_read_eop <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_fifo_empty <= 'd0;
    end
    else begin
        r_fifo_empty <= w_fifo_empty;
    end
end

always@(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ro_read_valid <= 'd0;
    end
    else if (ro_read_eop) begin
        ro_read_valid <= 'd0;
    end
    else if (r_fifo_rden_pos) begin
        ro_read_valid <= 'd1;
    end
    else begin
        ro_read_valid <= ro_read_valid;
    end
end

always#(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ro_read_data <= 'd0;
    end
    else begin 
        ro_read_data <= w_read_data;
    end
end

endmodule