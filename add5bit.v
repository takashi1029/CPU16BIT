module ADD5BIT(
	input CLK,RST,
	input c,
	input [4:0] imData,data,
	output reg [4:0] s,
	output reg c2
);

wire [4:0] c1;
wire [9:0] xo,an;

assign xo = imData^data;
assign an = imData&data;

assign c1[0] = an[0]|(xo[0]&c);
assign c1[1] = an[1]|(xo[1]&an[0])|(xo[1]&xo[0]&c);
assign c1[2] = an[2]|(xo[2]&an[1])|(xo[2]&xo[1]&an[0])|(xo[2]&xo[1]&xo[0]&c);
assign c1[3] = an[3]|(xo[3]&an[2])|(xo[3]&xo[2]&an[1])|(xo[3]&xo[2]&xo[1]&an[0])|(xo[3]&xo[2]&xo[1]&xo[0]&c);
assign c1[4] = an[4]|(xo[4]&an[3])|(xo[4]&xo[3]&an[2])|(xo[4]&xo[3]&xo[2]&an[1])|(xo[4]&xo[3]&xo[2]&xo[1]&an[0])|
               (xo[4]&xo[3]&xo[2]&xo[1]&xo[0]&c);

//各ビットの出力
always @(posedge CLK,posedge RST) begin
	if(RST) begin
		s <= 5'd0;
		c2 <= 1'd0;
	end // if(RST)
	else begin
		s[0] <= (imData[0]^data[0])^c;
		s[4:1] <= (imData[4:1]^data[4:1])^c1[3:0];
		c2 <= c1[4];
	end // else
end // always @(posedge CLK,posedge RST)

endmodule // ADD5BIT