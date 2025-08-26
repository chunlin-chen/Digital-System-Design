`include "./BPU.v"

module IF(
		// control interface
	input         clk, 
	input         rst_n,
    input         stall,
//----------I cache interface-------		
	output        ICACHE_ren,
	output        ICACHE_wen,
	output [29:0] ICACHE_addr,
	output [31:0] ICACHE_wdata,
	input  [31:0] ICACHE_rdata,
//------------IF/ID-----------------
    input 		  pc_sel,
    input  [31:0] pc_jump,
	output [31:0] pc_if,
	output [31:0] pc_4_if,
	//output [31:0] PC,
	output [31:0] instr_if,
//-------------BPU------------------
	input         PreWrong,
	output		  BrPre_if
);

reg  [31:0] pc_w, pc_r;
reg  [31:0] pc_if_w, pc_if_r;
reg  [31:0] pc_4_if_w, pc_4_if_r;
reg  [31:0] PC_plus4, PC_branch;
reg  [31:0] instr_w, instr_r;
reg         BrPre_if_w, BrPre_if_r;
wire [31:0] instr;
wire        BrPre, B, branch;

assign ICACHE_ren = 1'b1;
assign ICACHE_wen = 1'b0;
assign ICACHE_addr = pc_r[31:2];
assign ICACHE_wdata = 32'b0;
assign pc_if = pc_if_r;
assign pc_4_if = pc_4_if_r;
//assign PC = pc_r;
assign instr_if = instr_r;
assign BrPre_if = BrPre_if_r;

assign instr = {ICACHE_rdata[7:0],ICACHE_rdata[15:8],ICACHE_rdata[23:16],ICACHE_rdata[31:24]};
assign B = instr[6:0] == 7'b1100011;
// assign branch = B & BrPre;

BPU BPU0(
    .clk(clk), 
    .rst_n(rst_n), 
    .stall(stall), 
    .PreWrong(PreWrong),
    .B(B), 
    .BrPre(BrPre)
);

always @(*) begin
	PC_plus4 = pc_r + 3'd4;
	PC_branch = pc_r + {{20{instr[31]}},instr[7],instr[30:25],instr[11:8],1'b0};
	pc_w = stall  ? pc_r      : 
		   pc_sel ? pc_jump   : 
		   BrPre  ? PC_branch : PC_plus4;
	pc_if_w = stall ? pc_if_r : pc_r;
	pc_4_if_w = stall ? pc_4_if_r : PC_plus4;
	BrPre_if_w = stall  ? BrPre_if_r : 
				 pc_sel ? 1'b0       : BrPre;
	if(stall) instr_w = instr_r;
	else if(pc_sel) instr_w = 32'b0;
	else instr_w = instr;
end

always @(posedge clk) begin
	if(!rst_n) begin
		pc_r <= 32'b0;
		pc_if_r <= 32'b0;
		pc_4_if_r <= 32'b0;
		instr_r <= 32'b0;
		BrPre_if_r <= 1'b0;
	end
	else begin
		pc_r <= pc_w;
		pc_if_r <= pc_if_w;
		pc_4_if_r <= pc_4_if_w;
		instr_r <= instr_w;
		BrPre_if_r <= BrPre_if_w;
	end
end

endmodule