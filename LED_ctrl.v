module LED_ctrl(
		clk,				//50MHz, 20ns
		LCD_BLON,
		LCD_DATA,
		LCD_EN,
		LCD_ON,
		LCD_RS,
		LCD_RW
	);
input								clk;
output		          		LCD_BLON;
inout 		     [7:0]		LCD_DATA;
output		          		LCD_EN;
output		          		LCD_ON;
output		          		LCD_RS;
output		          		LCD_RW;

parameter S_POWER_ON = 6'd0;


reg [5:0]	state;
reg [5:0]	next_state;
reg [16:0]	clk_ctr;
wire [16:0]	next_clk_ctr;
assign next_clk_ctr = clk_ctr + 1;

always @(posedge clk) begin
	
end

endmodule
