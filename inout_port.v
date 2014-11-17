module inout_port(GO, clk, reset, iDATA, oReady, oDATA, SCL, SDA, ACK, ctr);
input GO; // output enable
input clk;
input reset;
input [23:0] iDATA;
output oReady;
output oDATA;
output SCL;
inout SDA;
output ACK;
output [5:0] ctr;

reg a; // output data
wire a_z;
reg b; // input data
wire next_b;
wire ACK;
reg CLK_Disable;
reg RW;
reg END;

assign a_z = a? 1'b1:0;
assign SDA = RW? a_z: 1'bz;
assign SCL = CLK_Disable | ( ( (SD_Counter >= 4) & (SD_Counter <= 31))? ~clk:0);
assign ACK = b;
assign next_b = RW?1:SDA;
// states
//parameter S_START  	= 2'd0;
//parameter S_SEND 		= 2'd1;
//parameter S_WAIT		= 2'd2;
//parameter S_FIN		= 2'd3;
reg [5:0]	SD_Counter;
wire [5:0] 	next_SD_Counter;
wire [5:0]	ctr;
reg [23:0]	SD;
reg FAIL;
// combinational circuit
assign oReady = END;
assign next_SD_Counter = FAIL?SD_Counter - 9:SD_Counter + 1;
assign ctr = SD_Counter;
//-----------------------------------
always @(negedge reset or negedge clk )
	begin
		if (!reset)
			begin
				SD_Counter = 6'b111111;
			end
		else begin
				if (GO == 1)
					begin
						SD_Counter = 0;
					end
				else begin
						if (SD_Counter < 6'b111111)
							begin
								SD_Counter = next_SD_Counter;
							end
						else
							SD_Counter = 6'b111111;
					 end		
			 end
	end


always @(posedge clk or negedge reset) begin
	if(!reset) begin
		CLK_Disable = 1;
		a = 1;
		//b = 1'bz;
		END = 1;
		RW = 0;
		FAIL = 0;
	end
	else begin
		case(SD_Counter)
			6'd0: begin
				END = 0;
				CLK_Disable = 1;
				a = 1;
				RW = 1;
				FAIL = 0;
			end
			6'd1: begin
				SD = iDATA;
				RW = 1;
				a = 0;
			end
			6'd2: CLK_Disable = 0;
			
			6'd3: begin
				FAIL = 0;
				a = SD[23];
			end
			6'd4: a = SD[22];
			6'd5: a = SD[21];
			6'd6: a = SD[20];
			6'd7: a = SD[19];
			6'd8: a = SD[18];
			6'd9: a = SD[17];
			6'd10: a = SD[16];
			6'd11: RW = 0;
			
			6'd12: begin 
				RW = 1;
				if (b != 0)
					FAIL = 1;
				else FAIL = 0;
				a = SD[15];
			end
			6'd13: a = SD[14];
			6'd14: a = SD[13];
			6'd15: a = SD[12];
			6'd16: a = SD[11];
			6'd17: a = SD[10];
			6'd18: a = SD[9];
			6'd19: a = SD[8];
			6'd20: RW = 0;
			6'd21: begin
				RW = 1;
				if (b != 0)
					FAIL = 1;
				else FAIL = 0;
				a = SD[7];
			end
			6'd22: a = SD[6];
			6'd23: a = SD[5];
			6'd24: a = SD[4];
			6'd25: a = SD[3];
			6'd26: a = SD[2];
			6'd27: a = SD[1];
			6'd28: a = SD[0];
			6'd29: RW = 0;
			
			6'd30: begin
				RW = 1;
				if (b != 0)
					FAIL = 1;
				else FAIL = 0;
				
				a =0;
			end
			6'd31: begin
				a = 0;
				CLK_Disable = 1;
			end
			6'd32: begin
				a = 1;
				END = 1;
				RW = 0;
			end
		endcase
	end
end

always @(negedge clk) begin
	b = RW?next_b:SDA;
end
endmodule
