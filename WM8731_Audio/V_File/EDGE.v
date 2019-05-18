
/*====================================================*/
/*				Document description
文件名	: EDGE.v
作者	: 冯星
时间	: 2019-05-18
描述	: 	边沿检测模块
			使用输入时钟进行同步，输出信号的边沿，保持一个时钟周期
            边沿、上升沿、下降沿
历史版本	: 
当前版本	: V1.0
邮箱	: 1073804283@qq.com
*/
/*====================================================*/

/*====================================================*/
/*
// Module instantiation
//边沿检测模块
EDGE    U_EDGE_?
(
	//input
    .clk_in(),         //输入时钟50MHz
    .rst_n(),          //复位信号输入
    .in(),             //需要进行边缘检测的信号
	//ouput
    .out_posedge(),    //输出上升沿
    .out_negedge(),    //输出下降沿信号
    .out_edge()        //输出边沿信号
);
*/
/*====================================================*/

module EDGE 
(
	//input
    clk_in,         //输入时钟50MHz
    rst_n,          //复位信号输入
    in,             //需要进行边缘检测的信号
	//ouput
    out_posedge,    //输出上升沿
    out_negedge,    //输出下降沿信号
    out_edge        //输出边沿信号
);


//-------------------------------------------------------
//				`define definition
//-------------------------------------------------------

//-------------------------------------------------------
//				reg / wire definition
//-------------------------------------------------------

input  wire     clk_in;
input  wire     rst_n;
input  wire     in;
output wire     out_posedge;
output wire     out_negedge;
output wire     out_edge;

reg             in_d0;
reg             in_d1;

//-------------------------------------------------------
//				Structural coding
//-------------------------------------------------------

/*****采样in的上升沿*******/

assign  out_posedge = in_d0 && (~in_d1);
assign  out_negedge = in_d1 && (~in_d0);
assign  out_edge 	  = in_d1 ^ in_d0;


always @ (posedge clk_in or negedge rst_n) begin
    if(!rst_n) begin
        in_d0 <= 1'd0;
        in_d1 <= 1'd0;
    end
    else begin
        in_d0 <= in;
        in_d1 <= in_d0;
    end
end



endmodule
