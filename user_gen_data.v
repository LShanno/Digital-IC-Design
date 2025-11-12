`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module user_gen_data(
    input           i_clk               ,
    input           i_rst               ,

    output [1:0]    o_operation_type    ,
    output [23:0]   o_operation_addr    ,
    output [8:0]    o_operation_num     ,
    output          o_operation_valid   ,//和SPI driver相对应反
    input           i_operation_ready   ,

    output [7:0]    o_write_data        ,
    output          o_write_sop         ,
    output          o_write_eop         ,
    output          o_write_valid       ,

    input [7:0]     i_read_data         ,
    input           i_read_sop          ,
    input           i_read_eop          ,
    input           i_read_valid
);

/***************function**************/

/***************parameter*************/
localparam  P_ST_IDLE       = 0     ,
            P_ST_CLEAR      = 1     ,
            P_ST_WRITE      = 2     ,
            P_ST_READ       = 3     ;

localparam  P_OP_CLEAR      = 0     ,
            P_OP_WRITE      = 1     ,
            P_OP_READ       = 2     ;

localparam  P_DATA_NUMBER   = 256   ;
/***************port******************/             

/***************mechine***************/
reg [7:0]   r_st_current        ;
reg [7:0]   r_st_next           ;
/***************reg*******************/
reg [1:0]   ro_operation_type   ;   
reg [23:0]  ro_operation_addr   ;   
reg [8:0]   ro_operation_num    ;   
reg         ro_operation_valid  ;

reg [7:0]   ro_write_data       ;   
reg         ro_write_sop        ;   
reg         ro_write_eop        ;   
reg         ro_write_valid      ;   

reg [7:0]   ri_read_data        ;        
reg         ri_read_sop         ;        
reg         ri_read_eop         ;        
reg         ri_read_valid       ;

reg [15:0]  r_write_cnt         ;

reg         r_operation_active  ;
reg         ri_operation_ready  ;
/***************wire******************/
wire w_operation_active     ;
wire w_operation_ready_pos  ;
/***************component*************/

/***************assign****************/
assign  o_operation_type        = ro_operation_type                     ; 
assign  o_operation_addr        = ro_operation_addr                     ; 
assign  o_operation_num         = ro_operation_num                      ; 
assign  o_operation_valid       = ro_operation_valid                    ;

assign  o_write_data            = ro_write_data                         ; 
assign  o_write_sop             = ro_write_sop                          ; 
assign  o_write_eop             = ro_write_eop                          ; 
assign  o_write_valid           = ro_write_valid                        ; 

assign w_operation_active       = i_operation_ready & o_operation_valid ;
assign w_operation_ready_pos    = !ri_operation_ready i_operation_ready ;
/***************always****************/
//状态机
always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_st_current <= 'd0;
    end
    else begin
        r_st_current <= r_st_next;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ri_operation_ready <= 'd0;
    end
    else begin
        ri_operation_ready <= i_operation_ready;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_operation_active <= 'd0;
    end
    else begin
        r_operation_active <= w_operation_active;
    end
end
        
always@(*)
begin
    case(r_st_current)
        P_ST_IDLE   : r_st_next = P_ST_CLEAR;
        P_ST_CLEAR  : r_st_next = w_operation_ready_pos ? P_ST_WRITE : P_ST_CLEAR;
        P_ST_WRITE  : r_st_next = w_operation_ready_pos ? P_ST_READ : P_ST_WRITE;
        P_ST_READ   : r_st_next = w_operation_ready_pos ? P_ST_IDLE : P_ST_READ;
        default     : r_st_next = P_ST_IDLE;
    endcase
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ro_operation_valid <= 'd0;
    end
    else if (w_operation_active) begin
        ro_operation_valid <= 'd0;
    end
    else if (r_st_current != P_ST_CLEAR && r_st_next == P_ST_CLEAR) begin//启动握手
        ro_operation_valid <= 'd1;
    end
    else if (r_st_current != P_ST_WRITE && r_st_next == P_ST_WRITE) begin
        ro_operation_valid <= 'd1;
    end
    else if (r_st_current != P_ST_READ && r_st_next == P_ST_READ) begin
        ro_operation_valid <= 'd1;
    end
    else begin
        ro_operation_valid <= ro_operation_valid;
    end
end

always@(posedge i_clk, posedge i_rst) 
begin
    if (i_rst) begin
        ro_operation_type   <= 'd0;
        ro_operation_addr   <= 'd0;
        ro_operation_num    <= 'd0;
    end
    else if (r_st_current == P_ST_CLEAR) begin
        ro_operation_type   <= P_OP_CLEAR   ;
        ro_operation_addr   <= 'd256        ;
        ro_operation_num    <= 'd0          ;
    end
    else if (r_st_current == P_ST_WRITE) begin
        ro_operation_type   <= P_OP_WRITE   ;
        ro_operation_addr   <= 'd256        ;
        ro_operation_num    <= P_DATA_NUMBER;
    end
    else if (r_st_current == P_ST_READ) begin
        ro_operation_type   <= P_OP_READ    ;
        ro_operation_addr   <= 'd256        ;
        ro_operation_num    <= P_DATA_NUMBER;
    end
    else begin
        ro_operation_type   <= ro_operation_type    ;
        ro_operation_addr   <= ro_operation_addr    ;
        ro_operation_num    <= ro_operation_num     ;
    end
end

//写
always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        r_write_cnt <= 'd0;
    end
    else if (r_write_cnt == P_DATA_NUMBER - 1) begin
        r_write_cnt <= 'd0;
    end
    else if (r_st_current == P_ST_WRITE && (r_operation_active || r_write_cnt)) begin
        r_write_cnt <= r_write_cnt + 1;
    end
    else begin
        r_write_cnt <= r_write_cnt;
    end
end

always@(posedge i_clk, posedge i_rst) 
begin
    if (i_rst) begin
        ro_write_sop <= 'd0;
    end
    else if (w_operation_active && r_st_current == P_ST_WRITE) begin
        ro_write_sop <= 'd1;
    end
    else begin
        ro_write_sop <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ro_write_eop <= 'd0;
    end
    else if (r_write_cnt == P_DATA_NUMBER - 2) begin
        ro_write_eop <= 'd1;
    end
    else begin
        ro_write_eop <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if (i_rst) begin
        ro_write_valid <= 'd0;
    end
    else if (ro_write_eop) begin
        ro_write_valid <= 'd0;
    end
    else if (w_operation_active && r_st_current == P_ST_WRITE) begin
        ro_write_valid <= 'd1;
    end
    else begin
        ro_write_valid <= 'd0;
    end
end

always@(posedge i_clk, posedge i_rst) 
begin
    if (i_rst) begin
        ro_write_data <= 'd0;
    end
    else if (ro_write_valid && ro_write_data < 255) begin
        ro_write_data <= ro_write_data + 1;
    end
    else begin
        ro_write_data <= ro_write_data;
    end
end

endmodule
