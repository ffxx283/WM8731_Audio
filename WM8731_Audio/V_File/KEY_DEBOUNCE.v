
/*====================================================*/
/*				Document description
文件名	: KEY_DEBOUNCE.v
作者	: 冯星
时间	: 2019-05-18
描述	: 	按键消抖模块
			使用100Hz的信号同步按键输入，进行抖动消除
			使用边沿检测获取按键按下的边沿信号
历史版本	: 
当前版本	: V1.0
邮箱	: 1073804283@qq.com
*/
/*====================================================*/

/*====================================================*/
/*
// Module instantiation
//系统复位模块
KEY_DEBOUNCE	U_KEY_DEBOUNCE_?
(
	//input
	.clk_in(),		//输入时钟50MHz
	.rst_n(),		//复位信号输入
	.key_in(),		//按键输入	[2:0]
	
	//ouput
	.key_out()		//消抖后的按键输出	[2:0]
);
*/
/*====================================================*/

module KEY_DEBOUNCE
(
	//input
	clk_in,		//输入时钟50MHz
	rst_n,		//复位信号输入
	key_in,		//按键输入	[2:0]
	
	//ouput
	key_out		//消抖后的按键输出	[2:0]
);

//-------------------------------------------------------
//				`define definition
//-------------------------------------------------------

//-------------------------------------------------------
//				reg / wire definition
//-------------------------------------------------------

input  wire 		clk_in;
input  wire 		rst_n;
input  wire [2:0] 	key_in;
output wire [2:0] 	key_out;

reg					CLK_100Hz 		= 1'b0;
reg			[17:0]	Count_100Hz 	= 18'd0;
parameter 			Num_100Hz 		= 18'd249_999;

reg 		[2:0] 	key_in_100Hz;

//-------------------------------------------------------
//				Structural coding
//-------------------------------------------------------


always @ ( posedge clk_in or negedge rst_n ) begin
	if ( !rst_n ) begin
		CLK_100Hz <= 1'b0;
		Count_100Hz <= 18'd0;
	end
	else begin
		if(Count_100Hz >= Num_100Hz) begin
			Count_100Hz <= 18'd0;
			CLK_100Hz <= ~CLK_100Hz;
		end
		else begin
			Count_100Hz <= Count_100Hz + 18'd1;
		end
	end
end

always @ ( posedge CLK_100Hz ) begin
	key_in_100Hz <= key_in;
end

// Module instantiation
//边沿检测模块
EDGE    U_EDGE_0
(
	//input
    .clk_in(clk_in),        	//输入时钟50MHz
    .rst_n(rst_n),          	//复位信号输入
    .in(key_in_100Hz[0]),		//需要进行边缘检测的信号
	//ouput
    .out_posedge(),    			//输出上升沿
    .out_negedge(key_out[0]),	//输出下降沿信号
    .out_edge()					//输出边沿信号
);

// Module instantiation
//边沿检测模块
EDGE    U_EDGE_1
(
	//input
    .clk_in(clk_in),        	//输入时钟50MHz
    .rst_n(rst_n),          	//复位信号输入
    .in(key_in_100Hz[1]),		//需要进行边缘检测的信号
	//ouput
    .out_posedge(),    			//输出上升沿
    .out_negedge(key_out[1]),	//输出下降沿信号
    .out_edge()					//输出边沿信号
);

// Module instantiation
//边沿检测模块
EDGE    U_EDGE_2
(
	//input
    .clk_in(clk_in),        	//输入时钟50MHz
    .rst_n(rst_n),          	//复位信号输入
    .in(key_in_100Hz[2]),		//需要进行边缘检测的信号
	//ouput
    .out_posedge(),    			//输出上升沿
    .out_negedge(key_out[2]),	//输出下降沿信号
    .out_edge()					//输出边沿信号
);

endmodule
