
/*====================================================*/
/*				Document description
文件名	: IIC.v
作者	: 冯星
时间	: 2019-05-18
描述	: 	IIC接口
			标准IIC通信接口
历史版本	: 
当前版本	: V1.0
邮箱	: 1073804283@qq.com
*/
/*====================================================*/

/*====================================================*/
/*
// Module instantiation
//IIC接口
IIC		U_IIC_?
(
	//input
	.clk_in(),		//输入时钟50MHz
	.rst_n(),		//复位信号输入
	.data(),		//IIC发送的数据输入,[23:0]
	.start(),		//IIC开始发送信号
	
	//inout
	.SDA(),			//双向IO，IIC总线的数据线
	
	//ouput
	.idle(),		//模块空闲状态指示
	.ACK_n(),		//IIC通信应答信号
	.SCL()			//IIC总线的时钟输出
);
*/
/*====================================================*/

module IIC
(
	//input
	clk_in,		//输入时钟50MHz
	rst_n,		//复位信号输入
	data,		//IIC发送的数据输入,[23:0]
	start,		//IIC开始发送信号
	
	//inout
	SDA,		//双向IO，IIC总线的数据线
	
	//ouput
	idle,		//模块空闲状态指示
	ACK_n,		//IIC通信应答信号
	SCL			//IIC总线的时钟输出
);

//-------------------------------------------------------
//				`define definition
//-------------------------------------------------------

//-------------------------------------------------------
//				reg / wire definition
//-------------------------------------------------------

input wire 			clk_in;
input wire 			rst_n;
input wire 	[23:0]	data;
input wire 			start;

inout wire 			SDA;

output reg 			SCL 			= 1'b1;
output reg 			idle 			= 1'b0;
output wire 		ACK_n ;

reg 				SDA_reg 		= 1'b1;

reg 				ACK_Temp 		= 1'b1;
reg 				ACK1 			= 1'b1;
reg 				ACK2 			= 1'b1;
reg 				ACK3 			= 1'b1;

reg     			start_d0;
reg     			start_d1;
wire    			start_posedge;

//IIC发送状态
reg 		[4:0] 	State 			= S_IDLE;
parameter 			S_IDLE 			= 5'd0,
					S_Start 		= 5'd1,
					S_Write			= 5'd2,
					S_Read			= 5'd3,
					S_ACK 			= 5'd4,
					S_Stop	 		= 5'd5;

reg 		[23:0] 	IIC_DATA 		= 24'd0;
reg 		[4:0]	Send_Num_Count 	= 5'd0;	//高位先发送

/*-------------------------------------------------------
//					IIC时钟速率控制
	IIC支持三种速度模式,根据需要进行注释可以配置不同速率
	1、普通模式：100Kbps
	2、快速模式：400Kbps
	3、高速模式：3.4Mbps
	代码对应的数据率为近似时间，并不精确
-------------------------------------------------------*/

//普通模式100K,系统时钟50MHz
reg [7:0] CLK_Count = 8'd0;
parameter 	CLK_Count_Num1 = 8'd1,
			CLK_0_4 = 8'd0,
			CLK_1_4 = 8'd62,
			CLK_2_4 = 8'd125,
			CLK_3_4 = 8'd187,
			CLK_4_4 = 8'd249;

/*
//快速模式400K,系统时钟50MHz
reg [5:0] 	CLK_Count = 6'd0;
parameter 	CLK_Count_Num1 = 6'd1,
			CLK_0_4 = 6'd0,
			CLK_1_4 = 6'd15,
			CLK_2_4 = 6'd30,
			CLK_3_4 = 6'd46,
			CLK_4_4 = 6'd61;
*/

//-------------------------------------------------------
//				Structural coding
//-------------------------------------------------------

/*
SDA做输入时，将SDA_reg置一，输出高阻态，此时端口电压只与外部有关，
			直接读取SDA的值即可
SDA做输出时，将SDA_reg当做信号线处理，为0时输出SDA为0
			为1时，输出高阻，外部上拉电阻将信号上拉到高电平为1
*/
assign SDA = SDA_reg?1'bz:0;

/*应答信号*/
assign ACK_n = ACK1 | ACK2 | ACK3;


/*****采样start的上升沿*******/
assign  start_posedge = start_d0 && (~start_d1);
always @ (posedge clk_in or negedge rst_n) begin
    if(!rst_n) begin
        start_d0 <= 1'd0;
        start_d1 <= 1'd0;
    end
    else begin
        start_d0 <= start;
        start_d1 <= start_d0;
    end
end

//发送状态机模块
always @( posedge clk_in or negedge rst_n ) begin
	if(!rst_n) begin
		SCL <= 1'd1;
		SDA_reg <= 1'd1;
		idle <= 1'd0;

		CLK_Count <= CLK_0_4;
		State <= S_IDLE;
		IIC_DATA <= 24'd0;
		Send_Num_Count <= 5'd0;
		ACK1 <= 1'b1;
		ACK2 <= 1'b1;
		ACK3 <= 1'b1;
		ACK_Temp <= 1'b1;
	end
	else begin
		case ( State )

			S_IDLE : begin	//空闲状态
				if( start_posedge ) begin
					idle <= 1'd0;
					IIC_DATA <= data;
					State <= S_Start;
				end 
				else begin
					SCL <= 1'd1;
					SDA_reg <= 1'd1;

					CLK_Count <= CLK_0_4;
					IIC_DATA <= 24'd0;
					Send_Num_Count <= 5'd0;
					ACK_Temp <= 1'b1;

					idle <= 1'd1;
					State <= S_IDLE;
				end
			end

			S_Start : begin	//开始传输状态
				SDA_reg <= 1'b0;
				if( CLK_Count == CLK_2_4 ) begin
					SCL <= 1'd0;
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_4_4 ) begin
					State <= S_Write;
					CLK_Count <= CLK_0_4;
				end
				else
					CLK_Count <= CLK_Count + CLK_Count_Num1;
			end


			S_Write : begin	//传输状态
				if( CLK_Count == CLK_0_4 ) begin
					SDA_reg <= IIC_DATA[ 5'd23 - Send_Num_Count ];
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_1_4 ) begin
					SCL <= 1'd1;
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_3_4 ) begin
					SCL <= 1'd0;
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_4_4 ) begin
					CLK_Count <= CLK_0_4;
					if( Send_Num_Count == 5'd7 ) begin //器件地址和读写模式发送完毕,进入应答模式
						Send_Num_Count <= Send_Num_Count + 5'b1;
						State <= S_ACK;
					end	
					else if( Send_Num_Count == 5'd15 ) begin //操作寄存器地址写入完成，判断应答信号应答
						Send_Num_Count <= Send_Num_Count + 5'b1;
						State <= S_ACK;
					end	
					else if( Send_Num_Count == 5'd23 ) begin //操作寄存器地址写入完成，判断应答信号应答
						State <= S_ACK;
					end	
					else begin	//发送下一位
						Send_Num_Count <= Send_Num_Count + 5'd1;
					end
				end
				else
					CLK_Count <= CLK_Count + CLK_Count_Num1;
			end

			S_ACK : begin	//接收应答位
				if( CLK_Count == CLK_0_4 ) begin
					SDA_reg <= 1'b1;					//SDA做输入
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_1_4 ) begin
					SCL <= 1'b1;
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_2_4 ) begin
					ACK_Temp <= SDA;							//读取ACK状态,为0为有响应、为1为无响应
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_3_4 ) begin
					SCL <= 1'b0;
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_4_4 ) begin
					CLK_Count <= CLK_0_4;
					if( Send_Num_Count == 5'd8 ) begin			//第一个应答信号
						State <= S_Write;
						ACK1 <= ACK_Temp;
					end
					else if ( Send_Num_Count == 5'd16 ) begin	//第二个应答信号
						ACK2 <= ACK_Temp;
						if( IIC_DATA[ 5'd23 - 5'd7 ] == 1'b0 ) 
							State <= S_Write;
						else
							State <= S_Read;
					end
					else if ( Send_Num_Count == 5'd23 ) begin	//第三个应答信号
						ACK3 <= ACK_Temp;
						State <= S_Stop;
					end
					else 
						State <= S_IDLE;					//出现错误，返回空闲状态
				end
				else
					CLK_Count <= CLK_Count + CLK_Count_Num1;
			end

			S_Read : begin	//IIC读出数据
				State <= S_Stop;
			end

			S_Stop : begin	//停止位状态
				if( CLK_Count == CLK_0_4 ) begin
					SDA_reg <= 1'b0;
					SCL <= 1'b0;
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_1_4 ) begin
					SCL <= 1'b1;
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_2_4 ) begin
					SDA_reg <= 1'b1;
					CLK_Count <= CLK_Count + CLK_Count_Num1;
				end
				else if ( CLK_Count == CLK_4_4 ) begin
					CLK_Count <= CLK_0_4;
					State <= S_IDLE;
				end
				else
					CLK_Count <= CLK_Count + CLK_Count_Num1;
			end

		endcase
	end
end




endmodule
