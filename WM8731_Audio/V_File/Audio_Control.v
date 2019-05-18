
/*====================================================*/
/*				Document description
文件名	: Audio_Control.v
作者	: 冯星
时间	: 2019-05-18
描述	: 	音频芯片控制模块
			配置音频芯片WM8731的寄存器
			按键调整音量
历史版本	: 
当前版本	: V1.0
邮箱	: 1073804283@qq.com
*/
/*====================================================*/

/*====================================================*/
/*
// Module instantiation
// 音频芯片控制模块
Audio_Control	U_Audio_Control_?
(
	//input
    .clk_in(),		//输入时钟50MHz
    .rst_n(),		//复位信号输入，低电平有效
    .key_in(),		//音量调整信号输入

	//output
    .SCL(),			//IIC_SCL输出
    .SDA(),			//IIC_SDA输出
    .led()			//LED指示灯
);
*/
/*====================================================*/

module Audio_Control
(
	//input
    clk_in,		//输入时钟50MHz
    rst_n,		//复位信号输入，低电平有效
    key_in,		//音量调整信号输入

	//output
    SCL,		//IIC_SCL输出
    SDA,		//IIC_SDA输出
    led			//LED指示灯
);

//-------------------------------------------------------
//				`define definition
//-------------------------------------------------------

//-------------------------------------------------------
//				reg / wire definition
//-------------------------------------------------------

input wire 			clk_in;
input wire 			rst_n;
input wire 			key_in;

inout wire 			SDA;

output wire 		SCL;
output wire [9:0] 	led;

wire      			IIC_IS_IDLE;
wire 				ACK;

reg			[3:0]	Reg_Count 		= 4'd0;
reg 		[15:0]	reg_data 		= 16'd0;
reg 		[23:0]	IIC_Data 		= 24'd0;
reg 				start 			= 1'b0;

reg 		[1:0]	State 			= S_IDLE;
parameter 			S_IDLE 			= 2'd0,
					S_Wait 			= 2'd1,
					S_Send 			= 2'd2,
					S_Next 			= 2'd3;

reg			[3:0]	Wait_Count 		= 4'd0;
parameter			Wait_Num 		= 4'd10;

/*------------*******************************************--------------
					WM8731器件地址、寄存器定义
--------------*******************************************-------------*/

`define Device_Address 								{ 7'b0011_010 , 1'b0 }

/*-------------------------------线输入控制寄存器---------00-------02-----------*/

//默认设置左右输入声道同步控制
/*
reg 		 Line_Input_Mute							= 	1'b1;				//线输入静音控制	1：使能
reg [4:0] Line_Input_Volume						= 	5'b10111;		//线输入音量控制,默认 5'b10111

`define Line_in_ADDR 								7'b0000_000
`define Line_in_DATA 								{ 1'b1 , Line_Input_Mute , 2'b00 , Line_Input_Volume }
*/

//左右输入声道分别控制

reg			Line_Input_Left_Mute					= 	1'b1;				//线输入静音控制	1：使能
reg [4:0] 	Line_Input_Left_Volume					= 	5'b10111;		//线输入音量控制

reg 		Line_Input_Right_Mute					= 	1'b1;				//线输入静音控制	1：使能
reg [4:0] 	Line_Input_Right_Volume					= 	5'b10111;		//线输入音量控制

`define Left_Line_in_ADDR 							7'b0000_000
`define Left_Line_in_DATA 							{ 1'b0 , Line_Input_Left_Mute , 2'b00 , Line_Input_Left_Volume }
`define Right_Line_in_ADDR 							7'b0000_001
`define Right_Line_in_DATA 							{ 1'b0 , Line_Input_Right_Mute , 2'b00 , Line_Input_Right_Volume }

/*-------------------------------耳机输出控制寄存器--------04-------06-------------*/

//默认设置左右输出声道同步控制
/*
reg 		 Headphone_Out_ZCD						= 	1'b1;				//耳机输出音量只在信号处于低电平时改变，可以减小咔咔声		1：使能
reg [6:0] 	Headphone_Out_Volume					= 	7'b1111_111;		//线输入音量控制,默认 7'b1111_001,0~47:静音 47~127:音量调节

`define Headphone_Out_ADDR 							7'b0000_010
`define Headphone_Out_DATA 							{ 1'b1 , Headphone_Out_ZCD , Headphone_Out_Volume }
*/

//左右输入声道分别控制

reg 		Left_Headphone_Out_ZCD					= 	1'b1;				//耳机输出音量只在信号处于低电平时改变，可以减小咔咔声		1：使能
reg [6:0] 	Left_Headphone_Out_Volume				= 	7'd57;		//线输入音量控制,默认 7'b1111_001,0~47:静音 47~127:音量调节

reg 		Right_Headphone_Out_ZCD					= 	1'b1;				//耳机输出音量只在信号处于低电平时改变，可以减小咔咔声		1：使能
reg [6:0] 	Right_Headphone_Out_Volume				= 	7'd57;		//线输入音量控制,默认 7'b1111_001,0~47:静音 47~127:音量调节

`define Left_Headphone_Out_ADDR 					7'b0000_010
`define Left_Headphone_Out_DATA 					{ 1'b0 , Left_Headphone_Out_ZCD , Left_Headphone_Out_Volume }
`define Right_Headphone_Out_ADDR 					7'b0000_011
`define Right_Headphone_Out_DATA 					{ 1'b0 , Right_Headphone_Out_ZCD , Right_Headphone_Out_Volume }

/*-------------------------------模拟音频信号路径控制寄存器----08------------------------*/

reg [1:0]	Side_Tone_Att 							= 2'b00;			//侧音模式衰减系数
reg 		Side_Tone_En	 						= 1'b0;			//侧音模式，将输出麦克风信号输送给线输出		1：打开
reg 		DACSEL	 								= 1'b1;			//将DAC的输出信号输送给线输出 	1：选择DAC作为输出
reg 		BYPASS	 								= 1'b0;			//旁路线输入信号：直接将线输入信号输送至线输出	1：使能旁路
reg 		INSEL	 								= 1'b0;			//选择麦克风/线输入至ADC	1选择麦克风，0选择线输入
reg 		MIC_MUTE	 							= 1'b0;			//麦克风到ADC的通道静音	1：使能静音
reg 		MIC_BOOST	 							= 1'b0;			//麦克风增益是否打开	1：打开

`define Analogue_Audio_Path_Control_ADDR 			7'b0000_100
`define Analogue_Audio_Path_Control_DATA 			{ 1'b0 , Side_Tone_Att , Side_Tone_En , DACSEL , BYPASS , INSEL , MIC_MUTE , MIC_BOOST }

/*-------------------------------数字音频信号路径控制寄存器-----0A-----------------------*/

reg 		HPOR	 								= 1'b0;			//当高通滤波器禁用时存储直流偏移量，1：store   0：clear
reg 		DAC_MUTE	 							= 1'b0;			//DAC输出软件静音	1：开启软件静音
reg [1:0]	DEEMP	 								= 2'b00;			//去加重控制选择		00：不使用
reg 		ADC_HPD	 								= 1'b0;			//ADC高通滤波器使能 0：使能  1：禁用

`define Digital_Audio_Path_Control_ADDR 			7'b0000_101
`define Digital_Audio_Path_Control_DATA 			{ 4'b0000 , HPOR , DAC_MUTE , DEEMP , ADC_HPD }

/*-------------------------------电源管理控制寄存器------------0C----------------*/

reg 		POWER_OFF	 							= 1'b0;			//关机模式
reg 		CLKOUT_PD	 							= 1'b0;			//休眠模式，时钟输出休眠
reg 		OSC_PD	 								= 1'b0;			//休眠模式，晶振休眠
reg 		OUTPUT_PD	 							= 1'b0;			//休眠模式，音频输出部分休眠
reg 		DAC_PD	 								= 1'b0;			//休眠模式，DAC休眠
reg 		ADC_PD	 								= 1'b0;			//休眠模式，ADC休眠
reg 		MIC_PD	 								= 1'b0;			//休眠模式，麦克风休眠
reg 		LINE_IN_PD	 							= 1'b0;			//休眠模式，线输入部分休眠

`define Power_Down_Control_ADDR 					7'b0000_110
`define Power_Down_Control_DATA 					{ 1'b0 , POWER_OFF , CLKOUT_PD , OSC_PD , OUTPUT_PD , DAC_PD , ADC_PD , MIC_PD , LINE_IN_PD }

/*-------------------------------数字音频接口格式控制寄存器-----0E-----------------------*/

reg 		BCLKINV	 								= 1'b0;			//Bit CLK 位时钟翻转 	1：使能
reg 		MS	 									= 1'b0;			//主机、从机模式选择	1：主机	0：从机
reg 		LRSWAP	 								= 1'b0;			//DAC左右时钟选择， 	1：交换	0：不交换
reg			LRP	 									= 1'b1;			//DACLRC信号的相位控制		1：DACLRC为高时为右声道数据	0：DACLRC为高时为左声道数据（IIS模式）
reg [1:0]	IWL	 									= 2'b11;			//输入的音频数据的位宽		00:16位	01:20位	10:24位	11:32位
reg [1:0]	FORMAT	 								= 2'b10;			//模式选择					10：IIS模式

`define Digital_Audio_Interface_Format_ADRR 		7'b0000_111
`define Digital_Audio_Interface_Format_DATA 		{ 1'b0 , BCLKINV , MS , LRSWAP , LRP , IWL , FORMAT }

/*-------------------------------音频采样控制寄存器------------10----------------*/

reg 		CLK_O_DIV2	 							= 1'b0;		//输出时钟分频	1：二分频
reg 		CLK_I_DIV2	 							= 1'b0;		//输入时钟分频	1：二分频
reg [3:0] 	SR	 									= 4'b0000;	//ADC和DAC的采样速率控制
reg 		BOSR	 								= 1'b0;		//基本过采样速率	1:384fs		0:256fs
reg 		USB_NORMAL	 							= 1'b0;		//模式选择		1：USB模式，0：正常模式

`define Sampling_Control_ADDR 						7'b0001_000
`define Sampling_Control_DATA 						{ 1'b0 , CLK_O_DIV2 , CLK_I_DIV2 , SR , BOSR , USB_NORMAL }

/*-------------------------------芯片激活控制寄存器------------12----------------*/

reg			ACT										= 1'b1;			//激活数字音频接口状态	1：激活	0：不激活
`define Active_Control_ADRR 						7'b0001_001
`define Active_Control_DATA							{ 8'h0 , ACT }

/*-------------------------------芯片复位控制寄存器------------1E----------------*/

reg			RESET_n									= 1'b1;			//复位信号，写入任意值芯片复位
`define Reset_Register_ADRR 						7'b0001_111
`define Reset_Register_DATA 						{ 8'h0 , RESET_n }

//-------------------------------------------------------
//				Structural coding
//-------------------------------------------------------

//WM8731的寄存器赋值
always @ ( Reg_Count ) begin
	case ( Reg_Count )
		0: reg_data <= { `Left_Line_in_ADDR , `Left_Line_in_DATA };
		1: reg_data <= { `Right_Line_in_ADDR , `Right_Line_in_DATA };
		2: reg_data <= { `Left_Headphone_Out_ADDR , `Left_Headphone_Out_DATA };
		3: reg_data <= { `Right_Headphone_Out_ADDR , `Right_Headphone_Out_DATA  };
		4: reg_data <= { `Analogue_Audio_Path_Control_ADDR , `Analogue_Audio_Path_Control_DATA };
		5: reg_data <= { `Digital_Audio_Path_Control_ADDR , `Digital_Audio_Path_Control_DATA };
		6: reg_data <= { `Power_Down_Control_ADDR , `Power_Down_Control_DATA };
		7: reg_data <= { `Digital_Audio_Interface_Format_ADRR , `Digital_Audio_Interface_Format_DATA };
		8: reg_data <= { `Sampling_Control_ADDR , `Sampling_Control_DATA };
		9: reg_data <= { `Active_Control_ADRR , `Active_Control_DATA };
		default:reg_data <= { `Reset_Register_ADRR , `Reset_Register_DATA };
	endcase
end

always @ ( posedge clk_in or negedge rst_n ) begin
	if( !rst_n ) begin
		Reg_Count <= 4'd0;
		start <= 1'b0;
		State <= S_IDLE;
	end
	else begin
		if( Reg_Count <= 4'd9 ) begin
			case ( State )
				S_IDLE: begin
					IIC_Data <= { `Device_Address , reg_data };
					start <= 1'b1;
					State <= S_Wait;
				end
				S_Wait: begin
					if( Wait_Count >= Wait_Num ) begin
						Wait_Count <= 0;
						State <= S_Send;
					end
					else
						Wait_Count <= Wait_Count + 1;
				end
				S_Send: begin
					if( IIC_IS_IDLE ) begin
						if( !ACK )
							State <= S_Next;
						else
							State <= S_IDLE;
						start <= 1'b0;
					end
				end
				S_Next: begin
					Reg_Count <= Reg_Count + 4'd1;
					State <= S_IDLE;
				end
			endcase
		end
		else begin
			if( key_in ) 
				Reg_Count <= 4'd0;
		end
	end
end	


/*-----------------
按键控制音量有无
------------------*/

always @ ( posedge key_in ) begin
	Left_Headphone_Out_Volume =  Left_Headphone_Out_Volume + 5;
	Right_Headphone_Out_Volume =  Right_Headphone_Out_Volume + 5;
	if( Right_Headphone_Out_Volume <  47 ) Right_Headphone_Out_Volume <= 47;
	if( Left_Headphone_Out_Volume <  47 ) Left_Headphone_Out_Volume <= 47;
end



assign led[0] = ( State == S_IDLE );
assign led[1] = ( State == S_Send );
assign led[2] = ( State == S_Next );

// Module instantiation
//IIC接口
IIC		U_IIC_1
(
	//input
	.clk_in(clk_in),		//输入时钟50MHz
	.rst_n(rst_n),		//复位信号输入
	.data(IIC_Data),		//IIC发送的数据输入,[23:0]
	.start(start),		//IIC开始发送信号
	
	//inout
	.SDA(SDA),			//双向IO，IIC总线的数据线
	
	//ouput
	.idle(IIC_IS_IDLE),		//模块空闲状态指示
	.ACK_n(ACK),		//IIC通信应答信号
	.SCL(SCL)			//IIC总线的时钟输出
);

endmodule
