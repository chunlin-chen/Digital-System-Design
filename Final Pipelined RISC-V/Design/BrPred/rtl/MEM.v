module MEM(
		// control interface
	input         clk, 
	input         rst_n,
    input         stall,
//----------D cache interface-------
	output        DCACHE_ren,
	output        DCACHE_wen,
	output [29:0] DCACHE_addr,
	output [31:0] DCACHE_wdata,
	input  [31:0] DCACHE_rdata,
//---------------EX/MEM------------
    input         memread_ex,
    input         memwrite_ex,
    input  [4:0]  rd_ex,
    input         RegWrite_ex,
    input         MemToReg_ex,
    input  [31:0] mem_addr_D,
    input  [31:0] mem_wdata_D,
//---------------MEM/WB------------
    output [4:0]  rd_mem,
    output        RegWrite_mem,
    output        MemToReg_mem,
    output [31:0] alu_data,
    output [31:0] mem_data
);

reg [4:0] rd_mem_w, rd_mem_r;
reg RegWrite_mem_w, RegWrite_mem_r; 
reg MemToReg_mem_w, MemToReg_mem_r;
reg [31:0] alu_data_w, alu_data_r;
reg [31:0] mem_data_w, mem_data_r;

assign DCACHE_ren = memread_ex;
assign DCACHE_wen = memwrite_ex;
assign DCACHE_addr = mem_addr_D[31:2];
assign DCACHE_wdata = {mem_wdata_D[7:0],mem_wdata_D[15:8],mem_wdata_D[23:16],mem_wdata_D[31:24]};
assign rd_mem = rd_mem_r;
assign RegWrite_mem = RegWrite_mem_r;
assign MemToReg_mem = MemToReg_mem_r;
assign alu_data = alu_data_r;
assign mem_data = mem_data_r;

always@(*) begin
	if(stall) begin
		rd_mem_w = rd_mem_r;
		RegWrite_mem_w = RegWrite_mem_r;
		MemToReg_mem_w = MemToReg_mem_r;
		alu_data_w = alu_data_r;
		mem_data_w = mem_data_r;
	end else begin
		rd_mem_w = rd_ex;
		RegWrite_mem_w = RegWrite_ex;
		MemToReg_mem_w = MemToReg_ex;
		alu_data_w = mem_addr_D;
		mem_data_w = {DCACHE_rdata[7:0],DCACHE_rdata[15:8],DCACHE_rdata[23:16],DCACHE_rdata[31:24]};
    end
end

always @(posedge clk) begin
	if(!rst_n) begin
		alu_data_r <= 32'b0;
		mem_data_r <= 32'b0;
		rd_mem_r <= 0;
		RegWrite_mem_r <= 0;
		MemToReg_mem_r <= 0;
	end
	else begin
		alu_data_r <= alu_data_w;
		mem_data_r <= mem_data_w;
		rd_mem_r <= rd_mem_w;
		RegWrite_mem_r <= RegWrite_mem_w;
		MemToReg_mem_r <= MemToReg_mem_w;
	end
end
endmodule