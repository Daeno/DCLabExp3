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

parameter S_POWER_ON 	= 6'd0;
parameter S_FNC_SET1 	= 6'd1;
parameter S_FNC_SET2 	= 6'd2;
parameter S_FNC_SET3 	= 6'd3;
parameter S_WRITE_CMD	= 6'd4;
parameter S_CHECK_BF		= 6'd5;
parameter S_FIN			= 6'd9;
parameter S_WAIT 			= 6'd10;

wire clk,reset;
reg LCD_BLON,LCD_EN,LCD_ON,LCD_RS,LCD_RW;
reg [7:0]	LCD_DATA;
wire [7:0]	DB;
reg [3:0]	state;
reg [3:0]	target;
reg [3:0]	next_state;

reg [31:0]	clk_ctr;
wire [31:0]	next_clk_ctr;
reg [31:0]	wait_c;

reg [3:0] command_pointer = 0;
wire [3:0] next_command_pointer;
reg [9:0] command_list[0:9];  // RS RW DB7~DB0
reg cmd_go = 0;

reg Ready = 1;

reg	reset_ctr=0;
assign next_clk_ctr = reset_ctr?0:clk_ctr + 1;
assign DB = LCD_DATA;
assign next_command_pointer = cmd_go?command_pointer + 1:command_pointer;
always @(*) begin
	case(state)
		S_POWER_ON:begin
			wait_c = 750010;
			target = S_FNC_SET1;
			reset_ctr = 1;
			next_state = S_WAIT;
		end
		S_FNC_SET1:begin
			LCD_RS = 0;
			LCD_RW = 0;
			LCD_DATA = 8'b000011000;
			wait_c = 205010;
			target = S_FNC_SET2;
			reset_ctr = 1;
			next_state = S_WAIT;
			
		end
		S_FNC_SET2:begin
			LCD_RS = 0;
			LCD_RW = 0;
			LCD_DATA = 8'b000011000;
			wait_c = 5050;
			target = S_FNC_SET3;
			reset_ctr = 1;
			next_state = S_WAIT;
			
		end
		S_FNC_SET3:begin
			LCD_RS = 0;
			LCD_RW = 0;
			LCD_DATA = 8'b000011000;
			wait_c = 30;
			target = S_WRITE_CMD;
			reset_ctr = 1;
			next_state = S_WAIT;
		end
		S_WRITE_CMD: begin
			cmd_go = 0;
			LCD_RS = command_list[command_pointer][9];
			LCD_RW = command_list[command_pointer][8];
			LCD_DATA = command_list[command_pointer][7:0];
			wait_c = 30;
			target = S_CHECK_BF;
			reset_ctr = 1;
			next_state = S_WAIT;
		end
		S_CHECK_BF: begin
			LCD_RS = 0;
			LCD_RW = 1;
			LCD_DATA = 8'bzzzzzzzz;
			if(DB[7] == 1) next_state = S_CHECK_BF;
			else begin
				cmd_go = 1;
				if(command_pointer==4) next_state = S_FIN;
				else next_state = S_WRITE_CMD;
			end
		end
		S_FIN: begin
		end
		S_WAIT: begin
			reset_ctr = 0;
			if(clk_ctr == wait_c) next_state = target;
			else next_state = S_WAIT;
		end
	endcase
end

always @(posedge clk) begin
	if(!reset) begin
		state <= S_POWER_ON;
		clk_ctr <= 0;
		command_pointer = 0;
		command_list[1] = 10'b0000111000;
		command_list[2] = 10'b0000001100;
		command_list[3] = 10'b0000000001;
		command_list[4] = 10'b0000000110;
	end
	else begin
		state <= next_state;
		command_pointer = next_command_pointer;
		clk_ctr <= next_clk_ctr;
	end
end

endmodule
