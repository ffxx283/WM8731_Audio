
/*====================================================*/
/*				Document description
文件名	: IIS.v
作者	: 冯星
时间	: 2019-05-18
描述	: 	IIS接口
			使用IIS接口传输正弦信号给WM8731
			同步略有BUG，可以传输，但有时声音频率不同
历史版本	: 
当前版本	: V1.0
邮箱	: 1073804283@qq.com
*/
/*====================================================*/

/*====================================================*/
/*
// Module instantiation
//IIS接口
IIS		U_IIS_?
(
	//input
	.clk_in(),			//输入时钟50MHz
	.rst_n(),			//复位信号输入

	//output
	.AUD_BCLK(),		//位同步时钟
	.AUD_DACLRCK(),		//输出左右声道时钟
	.AUD_DACDAT()		//输出数据线
);
*/
/*====================================================*/

module IIS
(
	//input
	clk_in,			//输入时钟50MHz
	rst_n,			//复位信号输入

	//output
	AUD_BCLK,		//位同步时钟
	AUD_DACLRCK,	//输出左右声道时钟
	AUD_DACDAT		//输出数据线
);

//-------------------------------------------------------
//				`define definition
//-------------------------------------------------------

`define MCLK			18432000
`define DATA_WIDTH 		32
`define SAMPLE_RATE		48000
`define CHANNEL_NUM		2

`define BIT_CLK_NUM 	`MCLK/(`SAMPLE_RATE*`DATA_WIDTH*`CHANNEL_NUM*2)-1
`define LRC_CLK_NUM 	`DATA_WIDTH-1

//-------------------------------------------------------
//				reg / wire definition
//-------------------------------------------------------

input wire			clk_in;
input wire			rst_n;

output reg			AUD_BCLK 		= 1'b0;

output reg			AUD_DACLRCK		= 1'b0;
output wire			AUD_DACDAT;

reg 		[7:0]	BIT_CLK_Count 	= 8'd0;
reg 		[7:0]	LRC_CLK_Count 	= 8'd0;

reg 		[31:0] 	Send_Data_Buff 	= 32'd0;
wire 		[31:0]  Send_Data_Buff2 = Send_Data_Buff<<15;

reg 		[5:0]	SIN_Cont 		= 6'd0;

reg			[4:0]	SEL_Cont;

//-------------------------------------------------------
//				Structural coding
//-------------------------------------------------------

/*
	产生位时钟
*/
always @ ( posedge clk_in or negedge rst_n ) begin
	if(!rst_n) begin
		BIT_CLK_Count <= 8'd0;
		AUD_BCLK <= 1'b0;
	end
	else begin
		if( BIT_CLK_Count >= `BIT_CLK_NUM ) begin
			BIT_CLK_Count <= 8'd0;
			AUD_BCLK <= ~AUD_BCLK;
		end
		else
			BIT_CLK_Count <= BIT_CLK_Count + 8'd1;
	end
end

/*
	产生LRCK的时钟,AUD_BCLK的32分频
*/
always @ ( negedge AUD_BCLK or negedge rst_n ) begin
	if(!rst_n) begin
		LRC_CLK_Count <= 8'd0;
		AUD_DACLRCK <= 1'b0;
	end
	else begin
		if( LRC_CLK_Count >= `LRC_CLK_NUM ) begin
			LRC_CLK_Count <= 8'd0;
			AUD_DACLRCK <= ~ AUD_DACLRCK;
		end
		else
			LRC_CLK_Count <= LRC_CLK_Count + 8'd1;
	end
end

/*
	缓存数据的buff
*/
always@(negedge AUD_DACLRCK or negedge rst_n)
begin
	if(!rst_n)
	SIN_Cont	<=	0;
	else
	begin
		if(SIN_Cont < 6'd47 )
		SIN_Cont	<=	SIN_Cont+1;
		else
		SIN_Cont	<=	0;
	end
end

always@(SIN_Cont)
begin
    case(SIN_Cont)
    0  :  Send_Data_Buff       <=      0       ;
    1  :  Send_Data_Buff       <=      4276    ;
    2  :  Send_Data_Buff       <=      8480    ;
    3  :  Send_Data_Buff       <=      12539   ;
    4  :  Send_Data_Buff       <=      16383   ;
    5  :  Send_Data_Buff       <=      19947   ;
    6  :  Send_Data_Buff       <=      23169   ;
    7  :  Send_Data_Buff       <=      25995   ;
    8  :  Send_Data_Buff       <=      28377   ;
    9  :  Send_Data_Buff       <=      30272   ;
    10  :  Send_Data_Buff      <=      31650   ;
    11  :  Send_Data_Buff      <=      32486   ;
    12  :  Send_Data_Buff      <=      32767   ;
    13  :  Send_Data_Buff      <=      32486   ;
    14  :  Send_Data_Buff      <=      31650   ;
    15  :  Send_Data_Buff      <=      30272   ;
    16  :  Send_Data_Buff      <=      28377   ;
    17  :  Send_Data_Buff      <=      25995   ;
    18  :  Send_Data_Buff      <=      23169   ;
    19  :  Send_Data_Buff      <=      19947   ;
    20  :  Send_Data_Buff      <=      16383   ;
    21  :  Send_Data_Buff      <=      12539   ;
    22  :  Send_Data_Buff      <=      8480    ;
    23  :  Send_Data_Buff      <=      4276    ;
    24  :  Send_Data_Buff      <=      0       ;
    25  :  Send_Data_Buff      <=      61259   ;
    26  :  Send_Data_Buff      <=      57056   ;
    27  :  Send_Data_Buff      <=      52997   ;
    28  :  Send_Data_Buff      <=      49153   ;
    29  :  Send_Data_Buff      <=      45589   ;
    30  :  Send_Data_Buff      <=      42366   ;
    31  :  Send_Data_Buff      <=      39540   ;
    32  :  Send_Data_Buff      <=      37159   ;
    33  :  Send_Data_Buff      <=      35263   ;
    34  :  Send_Data_Buff      <=      33885   ;
    35  :  Send_Data_Buff      <=      33049   ;
    36  :  Send_Data_Buff      <=      32768   ;
    37  :  Send_Data_Buff      <=      33049   ;
    38  :  Send_Data_Buff      <=      33885   ;
    39  :  Send_Data_Buff      <=      35263   ;
    40  :  Send_Data_Buff      <=      37159   ;
    41  :  Send_Data_Buff      <=      39540   ;
    42  :  Send_Data_Buff      <=      42366   ;
    43  :  Send_Data_Buff      <=      45589   ;
    44  :  Send_Data_Buff      <=      49152   ;
    45  :  Send_Data_Buff      <=      52997   ;
    46  :  Send_Data_Buff      <=      57056   ;
    47  :  Send_Data_Buff      <=      61259   ;
	default	:
		   Send_Data_Buff		<=		0		;
	endcase
end

/*
	数据位输出
*/
always@(negedge AUD_BCLK or negedge rst_n)
begin
	if(!rst_n)
	SEL_Cont	<=	0;
	else begin
		if(SEL_Cont >= `DATA_WIDTH)
			SEL_Cont <= 0;
		else
			SEL_Cont	<=	SEL_Cont+1;
	end
end

assign AUD_DACDAT = Send_Data_Buff2[ ~ SEL_Cont ];



endmodule
