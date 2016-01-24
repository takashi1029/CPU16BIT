module CPU16BIT (
	input CLK,RST,
);

wire [15:0] code;
reg  [9:0] imData,data;
wire [9:0] out;
reg SUM,SUB,OR,AND,NO,RSF,LSF,RLF,LLF;

ALU alu(.CLK(CLK),.RST(RST),.imData(imData),.data(data),.SUM(SUM),.SUB(SUB),.OR(OR),.AND(AND),.NO(NO),.RSF(RSF),
	    .LSF(LSF),.RLF(RLF),.LLF(LLF),.out(out));

endmodule // CPU16BIT

