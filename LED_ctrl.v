module LED_ctrl(
		clk,				//50MHz, 20ns
		reset,
		LCD_BLON,
		LCD_DATA,
		LCD_EN,
		LCD_ON,
		LCD_RS,
		LCD_RW,
		Ready
	);
input								clk;
input								reset;
output		          		LCD_BLON;
inout 		     [7:0]		LCD_DATA;
output		          		LCD_EN;
output		          		LCD_ON;
output		          		LCD_RS;
output		          		LCD_RW;
output			  [3:0]		Ready;

parameter S_POWER_ON 		= 4'd0;
parameter S_FNC_SET_ONE 	= 4'd1;
parameter S_FNC_SET_TWO		= 4'd2;
parameter S_FNC_SET_THREE	= 4'd3;
parameter S_WRITE_CMD		= 4'd4;
parameter S_CHECK_BF_SET	= 4'd5;
parameter S_CHECK_BF_CH		= 4'd6;
parameter S_FIN				= 4'd9;
parameter S_WAIT 				= 4'd10;

wire clk,reset;
reg LCD_BLON,LCD_EN,LCD_ON,LCD_RS,LCD_RW;
reg next_BLON,next_EN,next_ON,next_RS,next_RW;
reg [7:0]	LCD_DATA;
reg [7:0]	next_DATA;
wire [7:0]	DB;

reg [3:0]	state;
reg [3:0]	target;
reg [3:0]	next_target;
reg [3:0]	next_state;

reg [31:0]	clk_ctr;
wire [31:0]	next_clk_ctr;
reg [31:0]	wait_c;
reg [31:0]	next_wait_c;

reg [3:0] command_pointer = 0;
wire [3:0] next_command_pointer;
reg [9:0] command_list[0:9];  // RS RW DB7~DB0
reg cmd_go = 0;

wire [31:0] Ready;

reg	reset_ctr=0;
assign next_clk_ctr = reset_ctr?0:clk_ctr + 1;
assign DB = LCD_DATA;
assign next_command_pointer = cmd_go?command_pointer + 1:command_pointer;
assign Ready = {clk_ctr,LCD_EN,LCD_DATA,command_pointer,state};
always @(*) begin
	case(state)
		S_POWER_ON:begin
			next_wait_c = 32'd760020;
			next_target = S_FNC_SET_ONE;
			reset_ctr = 1;
			next_state = S_WAIT;
			next_RS = LCD_RS;
			next_RW = LCD_RW;
			next_DATA = LCD_DATA;
		end
		S_FNC_SET_ONE:begin
			next_RS = 0;
			next_RW = 0;
			next_DATA = 8'b00110000;
			next_wait_c = 215020;
			next_target = S_FNC_SET_TWO;
			reset_ctr = 1;
			next_state = S_WAIT;
			next_EN = 1;
			
		end
		S_FNC_SET_TWO:begin
			next_RS = 0;
			next_RW = 0;
			next_DATA = 8'b00110000;
			next_wait_c = 32'd5120;
			next_target = S_FNC_SET_THREE;
			reset_ctr = 1;
			next_state = S_WAIT;
			next_EN = 1;
		end
		S_FNC_SET_THREE:begin
			next_RS = 0;
			next_RW = 0;
			next_DATA = 8'b00110000;
			next_wait_c = 32'd30;
			next_target = S_WRITE_CMD;
			reset_ctr = 1;
			next_state = S_WAIT;
			next_EN = 1;
		end
		S_WRITE_CMD: begin
			cmd_go = 0;
			next_RS = command_list[command_pointer][9];
			next_RW = command_list[command_pointer][8];
			next_DATA = command_list[command_pointer][7:0];
			next_wait_c = 32'd30;
			next_target = S_CHECK_BF_SET;
			reset_ctr = 1;
			next_state = S_WAIT;
			next_EN = 1;
		end
		S_CHECK_BF_SET: begin
			next_RS = 0;
			next_RW = 1;
			next_DATA = 8'bzzzzzzzz;
			next_wait_c = 32'd30;
			next_state = S_WAIT;
			reset_ctr = 1;
			next_target = S_CHECK_BF_CH;
			next_EN = 1;
		end
		S_CHECK_BF_CH: begin
			next_RS = LCD_RS;
			next_RW = LCD_RW;
			next_DATA = LCD_DATA;
			if(/*DB[7] == 1*/0)begin
				next_state = S_CHECK_BF_CH;
				cmd_go = 0;
				next_target = S_WRITE_CMD;
				reset_ctr = 1;
				next_wait_c = wait_c;
			end
			else begin
				cmd_go = 1;
				if(command_pointer==4'd6) next_state = S_FIN;
				else begin 
					next_target = S_WRITE_CMD;
					reset_ctr = 1;
					next_wait_c = 32'd30;
					next_state = S_WAIT;
				end
			end
		end
		S_FIN: begin
			cmd_go = 0;
			next_state = S_FIN;
			next_RS = LCD_RS;
			next_RW = LCD_RW;
			next_DATA = LCD_DATA;
			next_EN = LCD_EN;
		end
		S_WAIT: begin
			cmd_go = 0;
			reset_ctr = 0;
			if(clk_ctr >= wait_c) next_state = target;
			else next_state = S_WAIT;
			if(clk_ctr >= wait_c/2) next_EN = 0;
			else next_EN = 1;
			next_target = target;
			next_wait_c = wait_c;
			next_RS = LCD_RS;
			next_RW = LCD_RW;
			next_DATA = LCD_DATA;
		end
	endcase
end

always @(posedge clk) begin
	if(!reset) begin
		state <= S_POWER_ON;
		command_list[1] = 10'b00_00111000;
		command_list[2] = 10'b00_00001100;
		command_list[3] = 10'b00_00000001;
		command_list[4] = 10'b00_00000110;
		command_list[5] = 10'b00_10000000;
		command_list[6] = 10'b10_00110000;
	end
	else begin
		state <= next_state;
	end
end
always @(negedge clk) begin
	if(!reset) begin
		clk_ctr <= 0;
		command_pointer = 0;
		target <= 0;
		wait_c <= 0;
		LCD_BLON<=0;
		LCD_EN <= 0;
		LCD_ON <= 1;
		LCD_RS <= 0;
		LCD_RW <= 0;
		LCD_DATA <=0;
	end
	else begin
		command_pointer = next_command_pointer;
		clk_ctr <= reset_ctr? 0: next_clk_ctr;
		target <= next_target;
		wait_c <= next_wait_c;
		LCD_BLON<= next_BLON;
		LCD_EN <=  next_EN;
		LCD_ON <=  1;
		LCD_RS <=  next_RS;
		LCD_RW <=  next_RW;
		LCD_DATA <=next_DATA;
	end
end

endmodule
