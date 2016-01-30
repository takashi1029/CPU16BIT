module CPU16BIT (
	input CLK,RST,
	input [15:0] code
);
//opcode
//wire [15:0] code;
wire [9:0] addr;
wire [4:0] op;
wire flag;
//stack net and registers
wire [9:0] result;
wire [8:0] addr_cont,data_cont;
wire [9:0] stack_addr,stack_data;
reg rden,wren;

//operands
reg SUM_addr,SUB_addr,OR_addr,AND_addr,NO_addr,RSF_addr,LSF_addr,RLF_addr,LLF_addr;
reg SUM_data,SUB_data,OR_data,AND_data,NO_data,RSF_data,LSF_data,RLF_data,LLF_data;
//carry flas
wire carry1,carry2;
reg carry_flag1,carry_flag2;
assign carry1 = carry_flag1;
assign carry2 = carry_flag2;
//ALU's inputs
reg [9:0] imData1,imData2,data1,data2;
wire [9:0] addr_s,addr_d,data_s,data_d;
assign addr_s = imData1;
assign addr_d= data1;
assign data_s = imData2;
assign data_d = data2;
//registers,load signal,outputs signal
reg BP_load,Addr_load,SP_load,AX_load_data,AX_load_stack,IP_load;
reg [9:0] BP = 10'd0;
reg [9:0] Addr = 10'd0;
reg [9:0] SP = 10'd0;
reg [9:0] AX = 10'd0;
reg [9:0] IP = 10'd0;
wire [9:0] BP_data,Addr_data,SP_data,AX_data,IP_data;

assign op = code[15:11];
assign flag = code[10];
assign addr = code[9:0];

/*ROM
opcode	opcode_inst (
	.address ( IP_data ),
	.clock ( CLK ),
	.q ( code )
	);
*/
//ALU
assign addr_cont = {SUM_addr,SUB_addr,OR_addr,AND_addr,NO_addr,RSF_addr,LSF_addr,RLF_addr,LLF_addr};
assign data_cont = {SUM_data,SUB_data,OR_data,AND_data,NO_data,RSF_data,LSF_data,RLF_data,LLF_data};

ALU addr_alu (.CLK(CLK),.RST(RST),.code(addr_cont),.imData(addr_s),.data(addr_d),.out(stack_addr),.carry(carry1));
ALU data_alu (.CLK(CLK),.RST(RST),.code(data_cont),.imData(data_s),.data(data_d),.out(stack_data),.carry(carry2));

//clock count
reg [6:0] count = 7'd0;
wire op_clk;
assign op_clk = (count == 7'd49);
always @(posedge CLK) begin
	if(count==100) begin
		count <= 7'd0;
	end
	else begin
		count <= count + 1;
	end
end


//registers
always @(posedge CLK) begin
	if(BP_load)
		BP <= stack_addr;
	if(Addr_load)
		Addr <= result;
	if(SP_load)
		SP <= stack_addr;
	if(AX_load_stack)
		AX <= result;
	if(AX_load_data)
		AX <= stack_data;
	if(IP_load)
		IP <= stack_data;
end

assign BP_data = BP;
assign Addr_data = Addr;
assign SP_data = SP;
assign AX_data = AX;
assign IP_data = IP;


stack	stack_inst (
	.address ( stack_addr ),
	.clock ( CLK ),
	.data ( stack_data ),
	.rden ( rden ),
	.wren ( wren ),
	.q ( result )
	);

//selector
always @(posedge CLK) begin
	case (op) 
		5'b00001 : begin //ASSIGN
			if(count==1) begin //--SP
				imData1 <= SP_data;
				data1 <= 10'd1;  //SUB
			end
			else if(count==20) begin //stack[SP] to Addr
				data1 <= 10'd0; //SUB or SUM
			end
			else if(count==40) begin //stack[SP+1] to AX
				data1 <= 10'd1; //SUM
			end
			else if(count==60) begin //AX to stack[SP]
				data1 <= 10'd0; //SUM and wren
				imData2 <= AX_data;
				data2 <= 10'b0;
			end
			else if(count==80) begin //AX to stack[~addr]
				imData1 <= Addr_data;
				data1 <= 10'd0;
			end
		end
		5'b00010 : begin //ADD
			if(count==1) begin //stack[sp-1] to AX 
				imData1 <= SP_data;
				data1 <= 10'd1;
			end
			else if(count==25) begin //AX SUM stack[sp] to AX
				data1 <= 10'd0;
				imData2 <= AX_data;
				data2 <= result;
			end
			else if(count==75) begin //AX to stack[sp-1]
				data2 <= 10'd0;
				data1 <= 10'd1;
			end
		end
		5'b00011 : begin //SUB
			if(count==1) begin //stack[sp-1] to AX 
				imData1 <= SP_data;
				data1 <= 10'd1;
			end
			else if(count<=25) begin //AX SUB stack[sp] to AX
				data1 <= 10'd0;
				imData2 <= AX_data;
				data2 <= result;
			end
			else if(count<=75) begin //AX to stack[sp-1]
				data2 <= 10'd0;
				data1 <= 10'd1;
			end
		end
		5'b00100 : begin //NOT
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==50) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
		end
		5'b00101 : begin //CSIGN
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==34) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
			else if(count==67) begin
				data2 <= 10'd1;
			end
		end
		5'b00110 : begin //COPY
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 1'b1;
			end
			else if(count==34) begin
				data1 <= 1'b1;
			end
			else if(count==67) begin
				data1 <= 1'b0;
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
		end
		5'b00111 : begin //PUSH
			if(count==1) begin
				imData1 <= addr;
				data1 <= 10'd0;
			end
			else if(count==34) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
				imData1 <= SP_data;
			end
			else if(count==67) begin
				data1 <= 1'b1;
			end 
		end
		5'b01000 : begin //PUSHI
			if(count==1) begin
				imData2 <= addr;
				data2 <= 10'd0;
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==50) begin
				data1 <= 10'd1;
			end
		end
		5'b01001 : begin //REMOVE
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd1;
			end
		end
		5'b01010 : begin //POP
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==50) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
				imData1 <= addr;
			end
		end
		5'b01011 : begin //INC
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==50) begin
				imData2 <= AX_data;
				data2 <= 10'd1;
			end
		end
		5'b01100 : begin //DEC
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==50) begin
				imData2 <= AX_data;
				data2 <= 10'd1;
			end
		end
		5'b01101 : begin //SETFR
			if(count==1) begin
				imData1 <= addr;
				data1 <= 10'd0;
			end
		end
		5'b01110 : begin //INCFR
			if(count==1) begin
				imData1 <= BP_data;
				data1 <= addr;
			end
		end
		5'b01111 : begin //DECFR
			if(count==1) begin
				imData1 <= BP_data;
				data1 <= addr;
			end
		end
		5'b10000 : begin //JUMP
			if(count==1) begin
				imData2 <= IP_data;
				data2 <= 10'd0;
			end
		end
		5'b10001 : begin //BLT
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==34) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
			else if(count==67) begin
				data1 <= 10'd1;
			end
		end
		5'b10010 : begin //BLE
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==34) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
			else if(count==67) begin
				data1 <= 10'd1;
			end
		end
		5'b10011 : begin //BEQ
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==34) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
			else if(count==67) begin
				data1 <= 10'd1;
			end
		end
		5'b10100 : begin //BNE
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==34) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
			else if(count==67) begin
				data1 <= 10'd1;
			end
		end
		5'b10101 : begin //BGE
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==34) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
			else if(count==67) begin
				data1 <= 10'd1;
			end
		end
		5'b10110 : begin //BGT
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==34) begin
				imData2 <= AX_data;
				data2 <= 10'd0;
			end
			else if(count==67) begin
				data1 <= 10'd1;
			end
		end
		5'b10111 : begin //CALL
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd1;
			end
			else if(count==34) begin
				data1 <= 10'd0;
				imData2 <= IP_data;
				data2 <= 10'd0;
			end
			else if(count==67) begin
				imData2 <= addr;
			end
		end
		5'b11000 : begin //RET
			if(count==1) begin
				imData1 <= SP_data;
				data1 <= 10'd0;
			end
			else if(count==50) begin
				data1 <= 10'd1;
			end
		end
	endcase
end
//decoder
always @(posedge CLK) begin
	if (count==0) begin
		BP_load <= 1'b0;
		Addr_load <= 1'b0;
		SP_load <= 1'b0;
		AX_load_data <= 1'b0;
		AX_load_stack <= 1'b0;
		IP_load <= 1'b0;
		wren <= 1'b0;
		SUM_addr <= 1'b0;
		SUB_addr <= 1'b0;
		OR_addr <= 1'b0;
		AND_addr <= 1'b0;
		NO_addr <= 1'b0;
		SUM_data <= 1'b0;
		SUB_data <= 1'b0;
		OR_data <= 1'b0;
		AND_data <= 1'b0;
		NO_data <= 1'b0;
	end
	case (op)
		5'b00001 : begin //ASSIGN
			if(count==1) begin
				SUB_addr <= 1'b1;
			end
			else if(count==19) begin
				SP_load <= 1'b1;
			end
			else if(count==20) begin
				SP_load <= 1'b0;
				rden <= 1'b1;
			end
			else if(count==39) begin
				Addr_load <= 1'b1;
			end
			else if(count==40) begin
				SUB_addr <= 1'b0;
				SUM_addr <= 1'b1;
				Addr_load <= 1'b0;
			end
			else if(count==59) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==60) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==79) begin
				wren <= 1'b1;
			end
			else if(count==80) begin
				SUM_addr <= 1'b0;
				wren <= 1'b0;
				NO_addr <= 1'b1;
			end
			else if(count==99) begin
				wren <= 1'b1;
			end
		end
		5'b00010 : begin
			if(count==1) begin
				SUB_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==24) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==25) begin
				AX_load_stack <= 1'b0;
				SUB_addr <= 1'b0;
				SUM_addr <= 1'b1;
				SUM_data <= 1'b1;
			end
			else if(count==49) begin
				AX_load_data <= 1'b1;
			end
			else if(count==50) begin
				AX_load_data <= 1'b0;
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==74) begin
				wren <= 1'b1;
			end
			else if(count==75) begin
				wren <= 1'b0;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b00011 : begin
			if(count==1) begin
				SUB_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==24) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==25) begin
				AX_load_stack <= 1'b0;
				SUB_addr <= 1'b0;
				SUM_addr <= 1'b1;
				SUB_data <= 1'b1;
			end
			else if(count==49) begin
				AX_load_data <= 1'b1;
			end
			else if(count==50) begin
				AX_load_data <= 1'b0;
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==74) begin
				wren <= 1'b1;
			end
			else if(count==75) begin
				wren <= 1'b0;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b00100 : begin
			if(count==1) begin
				rden <= 1'b1;
				SUM_addr <= 1'b1;
			end
			else if(count==49) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==50) begin
				AX_load_stack <= 1'b0;
				NO_data <= 1'b1;
			end
			else if(count==99) begin
				wren <= 1'b1;
			end
		end
		5'b00101 : begin //CSIGN
			if(count==1) begin
				rden <= 1'b1;
				SUM_addr <= 1'b1;
			end
			else if(count==33) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==34) begin
				AX_load_stack <= 1'b0;
				SP_load <= 1'b0;
				NO_data <= 1'b1;
			end
			else if(count==66) begin
				AX_load_data <= 1'b1;
			end
			else if(count==67) begin
				AX_load_data <= 1'b0;
				NO_data <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==99) begin
				wren <= 1'b1;
			end
		end
		5'b00110 : begin //COPY
			if(count==1) begin
				SUM_addr <= 1'b1;
			end
			else if(count==33) begin
				SP_load <= 1'b1;
			end
			if(count==34) begin
				rden <= 1'b1;
				SP_load <= 1'b0;
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==66) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==67) begin
				AX_load_stack <= 1'b0;
				SUM_addr <= 1'b1;
				SUB_addr <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==99) begin
				wren <= 1'b1;
			end
		end
		5'b00111 : begin
			if(count==1) begin
				NO_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==33) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==34) begin
				AX_load_stack <= 1'b0;
				NO_addr <= 1'b0;
				SUM_addr <= 1'b1;
			end
			else if(count==66) begin
				wren <= 1'b1;
			end
			else if(count==67) begin
				wren <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b01000 : begin
			if(count==1) begin
				SUM_addr <= 1'b1;
				SUM_data <= 1'b1;
			end
			else if(count==49) begin
				wren <= 1'b1;
			end
			else if(count==50) begin
				wren <= 1'b0;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b01001 : begin
			if(count==1) begin
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b01010 : begin
			if(count==1) begin
				SUM_addr <= 1'b0;
				rden <= 1'b1;
			end
			else if(count==49) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==50) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
				SUM_addr <= 1'b0;
				NO_addr <= 1'b1;
			end
			else if(count==99) begin
				wren <= 1'b1;
			end
		end
		5'b01011 : begin 
			if(count==1) begin
				SUM_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==49) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==50) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==99) begin
				wren <= 1'b1;
			end
		end
		5'b01100 : begin 
			if(count==1) begin
				SUM_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==49) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==50) begin
				AX_load_stack <= 1'b0;
				SUB_data <= 1'b1;
			end
			else if(count==99) begin
				wren <= 1'b1;
			end
		end
		5'b01101 : begin
			if(count==1) begin
				SUM_addr <= 1'b1;
			end
			else if(count==99) begin
				BP_load <= 1'b1;
			end
		end
		5'b01110 : begin
			if(count==1) begin
				SUM_addr <= 1'b1;
			end
			else if(count==99) begin
				BP_load <= 1'b1;
			end
		end
		5'b01111 : begin
			if(count==1) begin
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				BP_load <= 1'b1;
			end
		end
		5'b10000 : begin 
			if(count==1) begin
				SUM_data <= 1'b1;
			end
			else if(count==99) begin
				IP_load <= 1'b1;
			end
		end
		5'b10001 : begin
			if(count==1) begin
				SUM_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==33) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==34) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==66) begin
				if(AX[9]) begin
					IP_load <= 1'b1;
				end
			end
			else if(count==67) begin
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b10010 : begin
			if(count==1) begin
				SUM_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==33) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==34) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==66) begin
				if(AX==10'd0||AX[9]) begin
					IP_load <= 1'b1;
				end
			end
			else if(count==67) begin
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b10011 : begin 
			if(count==1) begin
				SUM_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==33) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==34) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==66) begin
				if(AX==10'd0) begin
					IP_load <= 1'b1;
				end
			end
			else if(count==67) begin
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b10100 : begin 
			if(count==1) begin
				SUM_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==33) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==34) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==66) begin
				if(AX!=10'd0) begin
					IP_load <= 1'b1;
				end
			end
			else if(count==67) begin
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b10101 : begin 
			if(count==1) begin
				SUM_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==33) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==34) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==66) begin
				if(AX[9]==0) begin
					IP_load <= 1'b1;
				end
			end
			else if(count==67) begin
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b10110 : begin 
			if(count==1) begin
				SUM_addr <= 1'b1;
				rden <= 1'b1;
			end
			else if(count==33) begin
				AX_load_stack <= 1'b1;
			end
			else if(count==34) begin
				AX_load_stack <= 1'b0;
				SUM_data <= 1'b1;
			end
			else if(count==66) begin
				if(AX[9]==0||AX!=0) begin
					IP_load <= 1'b1;
				end
			end
			else if(count==67) begin
				SUM_addr <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
		5'b10111 : begin 
			if(count==1) begin
				SUM_addr <= 1'b1;
				SUM_data <= 1'b1;
			end
			else if(count==33) begin
				SP_load <= 1'b1;
			end
			else if(count==34) begin
				SP_load <= 1'b0;
			end
			else if(count==66) begin
				wren <= 1'b1;
			end
			else if(count==67) begin
				wren <= 1'b0;
			end
			else if(count==99) begin
				IP_load <= 1'b1;
			end
		end
		5'b11000 : begin
			if(count==1) begin
				SUM_addr <= 1'b1;
			end
			else if(count==49) begin
				IP_load <= 1'b1;
			end
			else if(count==50) begin
				IP_load <= 1'b0;
				SUB_addr <= 1'b1;
			end
			else if(count==99) begin
				SP_load <= 1'b1;
			end
		end
	endcase
end

endmodule // CPU16BIT

