`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module CLK_DIV_module#(
    parameter P_CLK_DIV_CNT = 2
)(
    input   i_clk       ,
    input   i_rst       ,
    output  o_clk_div 
);

/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
reg [15 : 0]    r_cnt       ;
reg             ro_clk_div  ;
/***************wire******************/

/***************component*************/

/***************assign****************/
assign o_clk_div    = ro_clk_div    ;
/***************always****************/
always @(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        r_cnt <= 'd0;
    end
    else if (r_cnt == (P_CLK_DIV_CNT >> 1) - 1) begin
        r_cnt <= 'd0;
    end
    else begin 
        r_cnt <= r_cnt + 1;
    end
end

always @(posedge i_clk, posedge i_rst) begin
    if (i_rst) begin
        ro_clk_div <= 'd0;
    end
    else if (r_cnt == (P_CLK_DIV_CNT >> 1) - 1) begin
        ro_clk_div <= ~ro_clk_div;
    end
    else begin
        ro_clk_div <= ro_clk_div;
    end
end

endmodule
