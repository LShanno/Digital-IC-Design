`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module eeprom_ctrl(
    input           i_clk                   ,
    input           i_rst                   ,

    input [2:0]     i_ctrl_eeprom_addr      ,
    input [15:0]    i_ctrl_operation_addr   ,
    input [7:0]     i_ctrl_operation_len    ,
    input           i_ctrl_operation_type   ,
    input           i_ctrl_operation_valid  ,
    output          o_ctrl_operation_ready  ,

    input [7:0]     i_ctrl_write_data       ,
    input           i_ctrl_write_sop        ,
    input           i_ctrl_write_eop        ,
    input           i_ctrl_write_valid      ,

    output [7:0]    o_ctrl_read_data        ,
    output          o_ctrl_read_valid       ,

    //IIC driver
    output [6:0]    o_driver_addr           ,//用户输入设备地址 7bit
    output [15:0]   o_operation_addr        ,//用户输入存储地址 10bit 高位补零
    output [7:0]    o_operation_len         ,//用户输入读写长度
    output          o_operation_type        ,//用户输入操作类型
    output          o_operation_valid       ,//用户输入有效信号
    input           i_operation_ready       ,//用户输出准备信号

    output [7:0]    o_write_data            ,//用户输入写数据
    input           i_write_req             ,//用户输出写请求

    input [7:0]     i_read_data             ,//输出IIC读到的数据
    input           i_read_valid             //输出IIC读数据有效
);

/***************function**************/

/***************parameter*************/
localparam  P_ST_IDLE       = 0 ,
            P_ST_WRITE      = 1 ,
            P_ST_WAIT       = 2 ,
            P_ST_READ       = 3 ,
            P_ST_REREAD     = 4 ,
            P_ST_ENDREAD    = 5 ;

localparam  P_WRITE     = 0 ,
            P_READ      = 1 ;
/***************port******************/             

/***************mechine***************/
reg [7:0]   r_st_current                ;
reh [7:0]   r_st_next                   ;
/***************reg*******************/
//输出端口
reg         ro_ctrl_operation_ready     ; 

reg [7:0]   ro_ctrl_read_data           ; 
reg         ro_ctrl_read_valid          ; 

reg [6:0]   ro_driver_addr              ; 
reg [15:0]  ro_operation_addr           ; 
reg [7:0]   ro_operation_len            ; 
reg         ro_operation_type           ; 
reg         ro_operation_valid          ; 

reg [7:0]   ro_write_data               ; 

//输入端口
reg [2:0]   ri_ctrl_eeprom_addr         ;  
reg [15:0]  ri_ctrl_operation_addr      ;  
reg [7:0]   ri_ctrl_operation_len       ;  
reg         ri_ctrl_operation_type      ;  
reg         ri_ctrl_operation_valid     ;

reg [7:0]   ri_ctrl_write_data          ; 
reg         ri_ctrl_write_sop           ; 
reg         ri_ctrl_write_eop           ; 
reg         ri_ctrl_write_valid         ;

reg         ri_operation_ready          ;

reg         ri_write_req                ;

reg [7:0]   ri_read_data                ; 
reg         ri_read_valid               ;

//控制页读地址 因为iic driver里读只能一个地址一个字节读取
reg [15:0]  r_read_addr                 ;

//判断页读字节数是否足够的寄存器
reg [7:0]   r_read_cnt                  ;

reg         r_fifo_read_en              ;
/***************wire******************/
//EEPROM和EEPROM顶层握手
wire w_ctrl_operation_active            ;

//EEMROM和IIC driver握手
wire w_driver_active                    ;

//需要区分IIC driver里的状态和EEPROM的状态是独立的
wire w_driver_end                       ;

//从IIC读上来的数据过fifo后出的数据
wire w_fifo_read_data                   ;

//fifo空信号
wire w_fifo_empty                       ;
/***************component*************/
FIFO_8X1024  FIFO_8X1024_WRITE_U0(
    .clk          (i_clk                ),                 
    .srst         (i_rst                ),               
    .din          (ri_ctrl_write_data   ),                 
    .wr_en        (ri_ctrl_write_valid  ),             
    .rd_en        (i_write_req          ),             
    .dout         (o_write_data         ),               
    .full         (                     ),               
    .empty        (                     ),             
    .wr_rst_busy  (                     ), 
    .rd_rst_busy  (                     )  
);

//从IIC读到的数据先进fifo 再在使能时读出来
//如果不使用 FIFO，会出现以下风险：
///上层逻辑没在正确时刻接住 i_read_valid → 漏数据
///如果主机消耗速度比 IIC 来数据快 → 读空
///如果 IIC 连续来数据，但主机没准备好 → 覆盖丢数据
//FIFO 隔离不同时钟域/不同时序
FIFO_8X1024  FIFO_8X1024_READ_U0(
    .clk          (i_clk                ),                 
    .srst         (i_rst                ),               
    .din          (ri_read_data         ),                 
    .wr_en        (ri_read_valid        ),             
    .rd_en        (r_fifo_read_en       ),             
    .dout         (w_fifo_read_data     ),               
    .full         (                     ),               
    .empty        (w_fifo_empty         ),             
    .wr_rst_busy  (                     ), 
    .rd_rst_busy  (                     )  
);
/***************assign****************/
assign o_ctrl_operation_ready   = ro_ctrl_operation_ready                           ; 
assign o_ctrl_read_data         = ro_ctrl_read_data                                 ; 
assign o_ctrl_read_valid        = ro_ctrl_read_valid                                ; 
assign o_driver_addr            = ro_driver_addr                                    ; 
assign o_operation_addr         = ro_operation_addr                                 ; 
assign o_operation_len          = ro_operation_len                                  ; 
assign o_operation_type         = ro_operation_type                                 ; 
assign o_operation_valid        = ro_operation_valid                                ; 
assign o_write_data             = ro_write_data                                     ; 

assign w_ctrl_operation_active  = i_ctrl_operation_valid & o_ctrl_operation_ready   ;

assign w_driver_active          = i_operation_ready & o_opeartion_valid             ;

assign w_driver_end             = i_operation_ready & !ri_operation_ready           ;
/***************always****************/
//状态机
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_st_current <= P_ST_IDLE;
    end
    else begin
        r_st_current <= r_st_next;
    end
end

always @(*) begin
    case (r_st_current)
        P_ST_IDLE       : r_st_next = w_ctrl_operation_active ? 
                                        i_ctrl_operation_type == P_WRITE ? P_ST_WRITE : P_ST_READ
                                        : P_ST_IDLE;  
        P_ST_WRITE      : r_st_next = w_driver_end ? P_ST_WAIT : P_ST_WRITE;
        P_ST_WAIT       : r_st_next = P_ST_READ;
        P_ST_READ       : r_st_next = w_driver_end ? 
                                        r_read_cnt == ri_ctrl_operation_len - 1 ? P_ST_ENDREAD :P_ST_REREAD
                                        : P_ST_READ;
        P_ST_REREAD     : r_st_next = P_ST_READ;
        P_ST_ENDREAD    : r_st_next = w_fifo_empty ? P_ST_IDLE : P_ST_ENDREAD;
        default         : r_st_next = P_ST_IDLE;
    endcase
end

//控制
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ri_ctrl_eeprom_addr     <= 'd0;    
        ri_ctrl_operation_addr  <= 'd0;    
        ri_ctrl_operation_len   <= 'd0;    
        ri_ctrl_operation_type  <= 'd0;    
        ri_ctrl_operation_valid <= 'd0; 
    end
    else if (w_ctrl_operation_active) begin
        ri_ctrl_eeprom_addr     <= i_ctrl_eeprom_addr       ;       
        ri_ctrl_operation_addr  <= i_ctrl_operation_addr    ;       
        ri_ctrl_operation_len   <= i_ctrl_operation_len     ;       
        ri_ctrl_operation_type  <= i_ctrl_operation_type    ;       
        ri_ctrl_operation_valid <= i_ctrl_operation_valid   ; 
    end
    else begin
        ri_ctrl_eeprom_addr     <= ri_ctrl_eeprom_addr      ;    
        ri_ctrl_operation_addr  <= ri_ctrl_operation_addr   ;    
        ri_ctrl_operation_len   <= ri_ctrl_operation_len    ;    
        ri_ctrl_operation_type  <= ri_ctrl_operation_type   ;    
        ri_ctrl_operation_valid <= ri_ctrl_operation_valid  ;
    end    
end         

///写数据给iic
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ri_ctrl_write_data  <= 'd0;
        ri_ctrl_write_sop   <= 'd0;
        ri_ctrl_write_eop   <= 'd0;
        ri_ctrl_write_valid <= 'd0;
    end
    else begin
        ri_ctrl_write_data  <= i_ctrl_write_data    ;
        ri_ctrl_write_sop   <= i_ctrl_write_sop     ;
        ri_ctrl_write_eop   <= i_ctrl_write_eop     ;
        ri_ctrl_write_valid <= i_ctrl_write_valid   ;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ctrl_operation_ready <= 'd1;
    end
    else if (w_ctrl_operation_active) begin
        ro_ctrl_operation_ready <= 'd0;
    end
    else if (r_st_current == P_ST_IDLE) begin
        ro_ctrl_operation_ready <= 'd1;
    end
    else begin
        ro_ctrl_operation_ready <= ro_ctrl_operation_ready;
    end
end

///从iic读数据
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ctrl_read_data <= 'd0;
    end
    else begin
        ro_ctrl_read_data <= w_fifo_read_data;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_ctrl_read_valid <= 'd0;
    end
    else if (w_fifo_empty) begin
        ro_ctrl_read_valid <= 'd0;
    end
    else if (r_fifo_read_en) begin
        ro_ctrl_read_valid <= 'd1;
    end
    else begin
        ro_ctrl_read_valid <= ro_ctrl_read_valid;
    end
end

always @(posedge i_clk，posedge i_rst) begin
    if (i_rst) begin
        r_fifo_read_en <= 'd0;
    end
    else if (w_fifo_empty) begin
        r_fifo_read_en <= 'd0;
    end
    else if (r_st_next == P_ST_ENDREAD && r_st_current != P_ST_ENDREAD) begin
        r_fifo_read_en <= 'd1;
    end
    else begin
        r_fifo_read_en <= r_fifo_read_en;
    end
end


//IIC driver
always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ro_driver_addr      <= 'd0;
        ro_operation_addr   <= 'd0;
        ro_operation_len    <= 'd0;
        ro_operation_type   <= 'd0;
        ro_operation_valid  <= 'd0;
    end
    else if (w_driver_active) begin
        ro_driver_addr      <= 'd0;
        ro_operation_addr   <= 'd0;
        ro_operation_len    <= 'd0;
        ro_operation_type   <= 'd0;
        ro_operation_valid  <= 'd0;  
    end
    else if (ri_ctrl_write_eop) begin
        ro_driver_addr      <= {4'b1010,ri_ctrl_eeprom_addr};
        ro_operation_addr   <= ri_ctrl_operation_addr       ;
        ro_operation_len    <= ri_ctrl_operation_len        ;
        ro_operation_type   <= ri_ctrl_operation_type       ;
        ro_operation_valid  <= ri_ctrl_operation_valid      ;      
    end
    else if (r_st_next == P_ST_READ && r_st_current != P_ST_READ) begin
        ro_driver_addr      <= {4'b1010,ri_ctrl_eeprom_addr};
        ro_operation_addr   <= r_read_addr                  ;
        ro_operation_len    <= 1                            ;
        ro_operation_type   <= ri_ctrl_operation_type       ;
        ro_operation_valid  <= 'd1                          ; 
    end
    else begin
        ro_driver_addr      <= ro_driver_addr       ;  
        ro_operation_addr   <= ro_operation_addr    ;     
        ro_operation_len    <= ro_operation_len     ;   
        ro_operation_type   <= ro_operation_type    ;   
        ro_operation_valid  <= ro_operation_valid   ;  
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_read_addr <= 'd0;
    end
    else if (w_ctrl_operation_active) begin
        r_read_addr <= i_ctrl_operation_addr;
    end
    else if (r_st_current == P_ST_READ && w_driver_end) begin
        r_read_addr <= r_read_addr + 1;
    end
    else begin
        r_read_addr <= r_read_addr;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ri_operation_ready <= 'd0;
    end
    else begin
        ri_operation_ready <= i_operation_ready;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        ri_read_data    <= 'd0;
        ri_read_valid   <= 'd0;
    end
    else begin
        ri_read_data    <= i_read_data  ;
        ri_read_valid   <= i_read_valid ;
    end
end

always @(posedge i_clk,posedge i_rst) begin
    if (i_rst) begin
        r_read_cnt <= 'd0;
    end
    else if (r_st_current == P_ST_IDLE) begin
        r_read_cnt <= 'd0;
    end
    else if (r_st_current == P_ST_READ && w_driver_end) begin
        r_read_cnt <= r_read_cnt + 1;
    end
    else begin
        r_read_cnt <= r_read_cnt;
    end
end

endmodule