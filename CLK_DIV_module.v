`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module CLK_DIV_module#(
    parameter   P_CLK_DIV_CNT   = 2
)(
    input   i_clk   ,
    input   i_rst   ,
    output  o_clk
);

/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
reg         ro_clk  ;
reg [15:0]  r_cnt   ;
/***************wire******************/

/***************component*************/

/***************assign****************/
assign o_clk    = ro_clk   ;
/***************always****************/
always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        r_cnt <= 'd0;
    end
    else if(r_cnt == (P_CLK_DIV_CNT >> 1) - 1) begin //直接加一到P_CLK_DIV_CNT,然后将翻转条件设为>=应该也可以
        r_cnt <= 'd0;
    end
    else begin
        r_cnt <= r_cnt + 1;
    end
end

always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        ro_clk <= 'd0;
    end
    else if(r_cnt == (P_CLK_DIV_CNT >> 1) - 1) begin
        ro_clk <= ~ro_clk;
    end
    else begin
        ro_clk <= ro_clk;
    end
end

endmodule