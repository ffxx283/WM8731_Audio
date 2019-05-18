
/*====================================================*/
/*				Document description
文件名	: RESET.v
作者	: 冯星
时间	: 2019-05-18
描述	: 	系统复位模块
			上电延时delay_time(ms)复位
			按键按下后复位
历史版本	: 
当前版本	: V1.0
邮箱	: 1073804283@qq.com
*/
/*====================================================*/

/*====================================================*/
/*
// Module instantiation
//系统复位模块
RESET	U_RESET_?
(
	//input
	.clk_in(),			//输入时钟50MHz
	.reset_key_in(),	//外部手动复位信号输入，低电平有效
	.delay_time(),		//延时复位的时间，ms为单位，最大为 10'd1024

	//output
	.rst_n()			//复位信号输出
);
*/
/*====================================================*/

module RESET
(
	//input
	clk_in,			//输入时钟50MHz
	reset_key_in,	//外部手动复位信号输入，低电平有效
	delay_time,		//延时复位的时间，ms为单位，最大为 10'd1024

	//output
	rst_n			//复位信号输出
);

//-------------------------------------------------------
//				`define definition
//-------------------------------------------------------

`define CLK_IN 			50_000_000
`define CLK_1MS_Count 	`CLK_IN/1000

//-------------------------------------------------------
//				reg / wire definition
//-------------------------------------------------------

input	wire			clk_in;
input	wire			reset_key_in;
input	wire	[9:0]	delay_time;
output	wire			rst_n ;

reg						delay_rst_n 	= 1'b0;
reg				[23:0]	Count_1Ms 		= 24'd0;
reg				[9:0]	Delay_Count 	= 10'd0;

//-------------------------------------------------------
//				Structural coding
//-------------------------------------------------------

assign rst_n = delay_rst_n && reset_key_in;

always @ (posedge clk_in) begin
	if(Count_1Ms >= `CLK_1MS_Count) begin
		Count_1Ms <= 0;
		if( Delay_Count <= delay_time ) begin
			Delay_Count <= Delay_Count + 1;
		end
		else begin
			Delay_Count <= Delay_Count;
			delay_rst_n <= 1'b1;
		end
	end
	else begin
		Count_1Ms <= Count_1Ms + 1;
	end
end


endmodule
