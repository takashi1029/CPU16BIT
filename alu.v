module ALU(
	input CLK,RST,
    input [9:0] imData,data,
    input SUM,SUB,OR,AND,NO,RSF,LSF,RLF,LLF,
    output reg [9:0] out,
    output reg carry
);

wire [9:0] net1,net2,result;
reg [9:0] data1,data2;
wire net_z,net_p,net_f;
reg c_z; //キャリーイン、5bitキャリ、オーバーフロー

assign net1 = data1;
assign net2 = data2;
assign net_z = c_z;

ADD5BIT add1 (.CLK(CLK),.RST(RST),.c(net_z),.imData(net1[4:0]),.data(net2[4:0]),.s(result[4:0]),.c2(net_p));
ADD5BIT add2 (.CLK(CLK),.RST(RST),.c(net_p),.imData(net1[9:5]),.data(net2[9:5]),.s(result[9:5]),.c2(net_f));

//正負の判定


always @(posedge CLK,posedge RST) begin
	if(RST) begin
		data1 <= 10'd0;
		data2 <= 10'd0;
	end
 	else if(SUM) begin
		data1 <= imData;
		data2 <= data;
		c_z <= 1'b0;
	end // if(SUM)
	else if(SUB) begin
		data1 <= imData;
		data2 <= ~data;
		c_z <= 1'b1;
	end // if(SUB)
end

always @(posedge CLK) begin
	carry <= net_f;
	if(SUM|SUB) begin
		out[8:0] <= result[8:0];
		if((~imData[9]&~data[9])&SUM)
			out[9] <= 1'b0;
		if((imData[9]&data[9])&SUM)
			out[9] <= 1'b0;
		if((imData[9]&~data[9])&SUB)
			out[9] <= 1'b0;
		if((~imData[9]&data[9])&SUB)
			out[9] <= 1'b1;
		else 
			out[9] <= result[9];
	end
	else if(AND)
		out <= imData&data;
	else if(OR)
		out <= imData|data;
	else if(NO)
		out <= ~data;
	else if(RSF)
		out <= (data >> imData);
	else if(LSF)
		out <= (data << imData);
	else if(RLF)
		out <= (data >>> imData);
	else if(LLF)
		out <= (data <<< imData);
end // always @(posedge CLK,posedge RST)
endmodule // ALU