`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////

module rst_gen_module#(
    parameter   P_RST_CYCLE = 10    
)(
    input   i_clk,
    input   i_rst,
    output  o_rst
);


/***************function**************/

/***************parameter*************/

/***************port******************/             

/***************mechine***************/

/***************reg*******************/
reg ro_rst;
reg [15:0] r_cnt;
/***************wire******************/

/***************component*************/

/***************assign****************/
assign o_rst = ro_rst;
/***************always****************/
always@(posedge i_clk, posedge i_rst)
begin
    if(i_rst) begin
        r_cnt <= 'd0;
    end
    else if(r_cnt == P_RST_CYCLE - 1 || P_RST_CYCLE == 0) begin
        r_cnt <= r_cnt;
    end
    else begin
        r_cnt <= r_cnt + 1;
    end
end

always@(posedge i_clk,posedge i_rst)
begin
    if(i_rst) begin
        ro_rst <= 'd1;
    end
    else if(r_cnt == P_RST_CYCLE - 1 || P_RST_CYCLE == 0) begin
        ro_rst <= 'd0;
    end
    else begin
        ro_rst <= 'd1;
    end
end

endmodule

