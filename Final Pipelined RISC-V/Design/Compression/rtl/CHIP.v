// Top module of your design, you cannot modify this module!!
`include "ID_HAZARD_v2.v"
`include "cache_2way.v"
`include "cache_dm.v"
`include "EX.v"
`include "control_v1.v"
module CHIP (	clk,
				rst_n,
//----------for slow_memD------------
				mem_read_D,
				mem_write_D,
				mem_addr_D,
				mem_wdata_D,
				mem_rdata_D,
				mem_ready_D,
//----------for slow_memI------------
				mem_read_I,
				mem_write_I,
				mem_addr_I,
				mem_wdata_I,
				mem_rdata_I,
				mem_ready_I,
//----------for TestBed--------------				
				DCACHE_addr, 
				DCACHE_wdata,
				DCACHE_wen,
				PC   
			);
input			clk, rst_n;
//--------------------------

output			mem_read_D;
output			mem_write_D;
output	[31:4]	mem_addr_D;
output	[127:0]	mem_wdata_D;
input	[127:0]	mem_rdata_D;
input			mem_ready_D;
//--------------------------
output			mem_read_I;
output			mem_write_I;
output	[31:4]	mem_addr_I;
output	[127:0]	mem_wdata_I;
input	[127:0]	mem_rdata_I;
input			mem_ready_I;
//----------for TestBed--------------
output	[29:0]	DCACHE_addr;
output	[31:0]	DCACHE_wdata;
output			DCACHE_wen;
output	[31:0]	PC;
//--------------------------

// wire declaration
wire        ICACHE_ren;
wire        ICACHE_wen;
wire [29:0] ICACHE_addr;
wire [31:0] ICACHE_wdata;
wire        ICACHE_stall;
wire [31:0] ICACHE_rdata;

wire        DCACHE_ren;
wire        DCACHE_wen;
wire [29:0] DCACHE_addr;
wire [31:0] DCACHE_wdata;
wire        DCACHE_stall;
wire [31:0] DCACHE_rdata;
wire [31:0] PC;

reg         en;
wire        pc_sel;
reg  [31:0] pc_w, pc_r;
reg  [31:0] pc_id_w, pc_id_r;
//reg  [31:0] PC_plus4_w, PC_plus4_r;
wire [31:0] PC_plusimm;
reg  [31:0] instr_w, instr_r;
wire  [31:0] alu_out_w, alu_out_r;
wire  [31:0] in_B_w, in_B_r;
reg  [31:0] alu_data, mem_data;
wire stall, stall2, load_use, if_stall;
wire memread_ex, memwrite_ex;

assign PC = pc_r;
assign ICACHE_ren = 1'b1;
assign ICACHE_wen = 1'b0;
assign ICACHE_addr = PC[31:2];
assign ICACHE_wdata = 32'b0;
assign DCACHE_ren = memread_ex;
assign DCACHE_wen = memwrite_ex;
assign DCACHE_addr = alu_out_r[31:2];
assign DCACHE_wdata = {in_B_r[7:0],in_B_r[15:8],in_B_r[23:16],in_B_r[31:24]};
assign stall = stall2 | if_stall;
assign stall2 = ICACHE_stall | DCACHE_stall;

//=========================================
	// Note that the overall design of your RISCV includes:
	// 1. pipelined RISCV processor
	// 2. data cache
	// 3. instruction cache

/*
	RISCV_Pipeline i_RISCV(
		// control interface
		.clk            (clk)           , 
		.rst_n          (rst_n)         ,
//----------I cache interface-------		
		.ICACHE_ren     (ICACHE_ren)    ,
		.ICACHE_wen     (ICACHE_wen)    ,
		.ICACHE_addr    (ICACHE_addr)   ,
		.ICACHE_wdata   (ICACHE_wdata)  ,
		.ICACHE_stall   (ICACHE_stall)  ,
		.ICACHE_rdata   (ICACHE_rdata)  ,
//----------D cache interface-------
		.DCACHE_ren     (DCACHE_ren)    ,
		.DCACHE_wen     (DCACHE_wen)    ,
		.DCACHE_addr    (DCACHE_addr)   ,
		.DCACHE_wdata   (DCACHE_wdata)  ,
		.DCACHE_stall   (DCACHE_stall)  ,
		.DCACHE_rdata   (DCACHE_rdata)	,
//--------------PC-----------------
		.PC(PC)
	);
*/
	cache_D D_cache(
        .clk        (clk)         ,
        .proc_reset (~rst_n)      ,
        .proc_read  (DCACHE_ren)  ,
        .proc_write (DCACHE_wen)  ,
        .proc_addr  (DCACHE_addr) ,
        .proc_rdata (DCACHE_rdata),
        .proc_wdata (DCACHE_wdata),
        .proc_stall (DCACHE_stall),
        .mem_read   (mem_read_D)  ,
        .mem_write  (mem_write_D) ,
        .mem_addr   (mem_addr_D)  ,
        .mem_wdata  (mem_wdata_D) ,
        .mem_rdata  (mem_rdata_D) ,
        .mem_ready  (mem_ready_D)
	);

	cache_I I_cache(
        .clk        (clk)         ,
        .proc_reset (~rst_n)      ,
        .proc_read  (ICACHE_ren)  ,
        .proc_write (ICACHE_wen)  ,
        .proc_addr  (ICACHE_addr) ,
        .proc_rdata (ICACHE_rdata),
        .proc_wdata (ICACHE_wdata),
        .proc_stall (ICACHE_stall),
        .mem_read   (mem_read_I)  ,
        .mem_write  (mem_write_I) ,
        .mem_addr   (mem_addr_I)  ,
        .mem_wdata  (mem_wdata_I) ,
        .mem_rdata  (mem_rdata_I) ,
        .mem_ready  (mem_ready_I)
	);
	wire beq, bne, jal, jalr, alusrc, alusrc_id, memread, memwrite, flush;
	wire memread_id, memwrite_id, MemToReg_id, RegWrite_id;
	wire MemToReg_ex, RegWrite_ex;
	reg  RegWrite_mem, MemToReg_mem;
	wire [4:0] rs1, rs2, rd_id, rd_ex, write_reg;
	reg [4:0] rd_mem;
	wire [4:0] rd_mem_wire;
	wire [31:0] write_data, rs1_data, rs2_data, imm, ins_out;
	wire [1:0] aluop, aluop_id;
	//wire alusrc, alusrc_id;
	//wire [31:0] write_back
	assign write_data = (MemToReg_mem)? mem_data : alu_data;
	assign rd_mem_wire = rd_mem;

	control control0(
		.opcode(instr_r[6:0]),
		.funct3_0(instr_r[12]),
		.alusrc(alusrc),
		.memtoreg(MemToReg),
		.regwrite(RegWrite),
		.memread(memread),
		.memwrite(memwrite),
		.bne(bne),
		.beq(beq),
		.jal(jal),
		.jalr(jalr),
		.aluop(aluop)
		//.if_flush(flush)  
);

	id_stage id0(
		.clk(clk),
		.rst_n(rst_n),
		.write_reg(rd_mem_wire),
		.write_data(write_data),
		.write_enable(RegWrite_mem),
		.ins(instr_r),
		.pc(pc_id_r),
		//.pc_4(next_pc_r),
		.pc_4(PC),
		.load_use(load_use),
		.beq(beq),
		.bne(bne),
		.jal(jal),
		.jalr(jalr),
		.stall(stall2),
		.RegWrite_id(RegWrite_id),
    	.RegWrite_ex(RegWrite_ex),
    	.rd_id(rd_id),
    	.rd_ex(rd_ex),
		.memread_ex(memread_ex),
		.alu_out(alu_out_r),
		.jump(pc_sel),
		.rs1(rs1), 
		.rs2(rs2), 
		.rd(rd_id),
		.rs1_data(rs1_data), 
		.rs2_data(rs2_data),
		.imm(imm),
		.new_pc(PC_plusimm),
		.ins_out(ins_out),
		.if_stall(if_stall),
		//EX
		.alusrc(alusrc),
		.aluop(aluop),
		.alusrc_reg(alusrc_id),
		.aluop_reg(aluop_id),
		//MEM
		.memread(memread),
		.memwrite(memwrite),
		.memread_reg(memread_id),
		.memwrite_reg(memwrite_id),
		//WB
		.MemToReg(MemToReg),
		.RegWrite(RegWrite),
		.MemToReg_reg(MemToReg_id),
		.RegWrite_reg(RegWrite_id)
	);

	hazard_unit hazard_unit0(
		.IDEX_memread(memread_id),
		.IDEX_rd(rd_id),
		.IFID_rs1(instr_r[19:15]),
		.IFID_rs2(instr_r[24:20]),
    	.load_use(load_use)
	);

	EX EX0(
		.ex_mem_addr(alu_out_r),	
		.wb_data(write_data),
		.clk(clk),
		.rst_n(rst_n),
		.stall(stall2),
		.instr(ins_out),
		.Imm_gen(imm),
		.ID_EX_Rs1(rs1_data),
		.ID_EX_Rs2(rs2_data),
		.IF_ID_Rs1(rs1),
		.IF_ID_Rs2(rs2),
		.IF_ID_Rd(rd_id),
		.ID_EX_regwrite(RegWrite_id),
		.ID_EX_memtoreg(MemToReg_id),
		.ID_EX_memread(memread_id),
		.ID_EX_memwrite(memwrite_id),

		.EX_MEM_Rd(rd_ex),
		.MEM_WB_Rd(rd_mem_wire),
		.EX_MEM_regwrite(RegWrite_ex),
		.MEM_WB_regwrite(RegWrite_mem),
		//output
		.regwrite(RegWrite_ex),
		.memtoreg(MemToReg_ex),
		.memread(memread_ex),
		.memwrite(memwrite_ex),
			
		.alusrc(alusrc_id),
		.aluop(aluop_id),
		.mem_addr_D(alu_out_r),  
		.mem_wdata_D(in_B_r),
		.EX_Rd(rd_ex)        
    );

	wire [31:0] original_ins, pc_plus, real_ins, decomp_out;
	wire [15:0] decomp_in;
	reg [31:0] next_pc_w, next_pc_r;
	reg [15:0] upper16_w, upper16_r;
	wire [1:0] op2;
	wire [2:0] plus_num;
	reg flag_w, flag_r;//, already_w, already_r;	//whether instruction over 2 blocks
	//wire stall3;
	//assign stall3 = DCACHE_stall | if_stall;
	assign original_ins = {ICACHE_rdata[7:0],ICACHE_rdata[15:8],ICACHE_rdata[23:16],ICACHE_rdata[31:24]};
	assign pc_plus = pc_r + plus_num;
	assign plus_num = (op2 != 2'b11 | flag_w | flag_r)? 3'd2 : 3'd4;
	assign op2 = pc_r[1]? original_ins[17:16] : original_ins[1:0];
	assign real_ins = (flag_r)? {original_ins[15:0], upper16_r} : (op2 != 2'b11)? decomp_out : original_ins;
	assign decomp_in = pc_r[1]? original_ins[31:16] : original_ins[15:0];
	decompressor decomp0(
		.in(decomp_in),
		.out(decomp_out)
	);
	always @(*) begin
		upper16_w = (stall)? upper16_r : original_ins[31:16];
		//upper16_w = (flag_w)? original_ins[31:16] : upper16_r;
		flag_w = stall? flag_r : (op2 == 2'b11 & pc_r[1] & !pc_sel)? 1 : 0;
		//PC_plus4_w = pc_r + 3'd4;
		next_pc_w = stall ? next_pc_r : (pc_sel ? PC_plusimm : pc_plus);
		pc_w = stall ? pc_r : (pc_sel ? PC_plusimm : pc_plus);
		//pc_w = (ICACHE_stall | (stall3 & already_r))? pc_r : (pc_sel ? PC_plusimm : pc_plus);
		pc_id_w = (stall | flag_r ) ? pc_id_r : pc_r;
		if(stall) instr_w = instr_r;
		else if(pc_sel | flag_w) instr_w = 32'b0;
		else instr_w = real_ins;
		//else instr_w = {ICACHE_rdata[7:0],ICACHE_rdata[15:8],ICACHE_rdata[23:16],ICACHE_rdata[31:24]};
	end
	reg [4:0] rd_mem_w;
	reg RegWrite_mem_w, MemToReg_mem_w;
	reg [31:0] alu_data_w, mem_data_w;
	always@(*) begin
		if(stall2) begin
			rd_mem_w = rd_mem;
			RegWrite_mem_w = RegWrite_mem;
			MemToReg_mem_w = MemToReg_mem;
			alu_data_w = alu_data;
			mem_data_w = mem_data;
		end else begin
			rd_mem_w = rd_ex;
			RegWrite_mem_w = RegWrite_ex;
			MemToReg_mem_w = MemToReg_ex;
			alu_data_w = alu_out_r;
			mem_data_w = {DCACHE_rdata[7:0],DCACHE_rdata[15:8],DCACHE_rdata[23:16],DCACHE_rdata[31:24]};
		end
	end
	
	always @(posedge clk) begin
		if(!rst_n) begin
			// en <= 1'b0;
			upper16_r <= 0;
			flag_r <= 0;
			pc_r <= 32'b0;
			pc_id_r <= 32'b0;
			//PC_plus4_r <= 32'b0;
			next_pc_r <= 0;
			instr_r <= 32'b0;
			//alu_out_r <= 32'b0;
			//in_B_r <= 32'b0;
			alu_data <= 32'b0;
			mem_data <= 32'b0;
			rd_mem <= 0;
			RegWrite_mem <= 0;
			MemToReg_mem <= 0;
		end
		else begin
			// en <= 1'b1;
			upper16_r <= upper16_w;
			flag_r <= flag_w;
			pc_r <= pc_w;
			pc_id_r <= pc_id_w;
			//PC_plus4_r <= PC_plus4_w;
			next_pc_r <= next_pc_w;
			instr_r <= instr_w;
			//alu_out_r <= alu_out_w;
			//in_B_r <= in_B_w;
			// alu_data <= alu_out_r;
			// mem_data <= {DCACHE_rdata[7:0],DCACHE_rdata[15:8],DCACHE_rdata[23:16],DCACHE_rdata[31:24]};
			alu_data <= alu_data_w;
			mem_data <= mem_data_w;
			rd_mem <= rd_mem_w;
			RegWrite_mem <= RegWrite_mem_w;
			MemToReg_mem <= MemToReg_mem_w;
		end
	end
endmodule

module decompressor(
	input [15:0] in,
	output reg [31:0] out
);
	always @(*) begin
		case(in[1:0])
			2'b00: begin
				if(in[15]) begin
					out = {5'd0, in[5], in[12], 2'b01, in[4:2], 2'b01, in[9:7], 3'b010, in[11:10], in[6], 2'b00, 7'h23};
				end else begin
					out = {5'd0, in[5], in[12:10], in[6], 2'b00, 2'b01, in[9:7], 3'b010, 2'b01, in[4:2], 7'h03};
				end
			end
			2'b01: begin
				case(in[15:13])
					3'b100: begin
						out[25:15] = {in[12], in[6:2], 2'b01, in[9:7]};
						out[11:0] = {2'b01, in[9:7], 7'h13};
						case(in[11:10])
							2'b00: begin
								out[31:26] = 6'h0;
								out[14:12] = 3'b101;
							end
							2'b01: begin
								out[31:26] = 6'h10;
								out[14:12] = 3'b101;
							end
							default: begin
								out[31:26] = {6{in[12]}};
								out[14:12] = 3'b111;
							end
						endcase
					end
					3'b000: begin
						out = {{7{in[12]}}, in[6:2], in[11:7], 3'd0, in[11:7], 7'h13};
					end
					3'b001: begin
						out = {in[12], in[8], in[10:9], in[6], in[7], in[2], in[11], in[5:3], {9{in[12]}}, 5'd1, 7'h6f};
					end
					3'b101: begin
						out = {in[12], in[8], in[10:9], in[6], in[7], in[2], in[11], in[5:3], {9{in[12]}}, 5'd0, 7'h6f};
					end
					default: begin
						out = {{4{in[12]}}, in[6:5], in[2], 5'd0, 2'b01, in[9:7], 2'b00, in[13], in[11:10], in[4:3], in[12], 7'h63};
					end
				endcase
			end
			2'b10: begin
				if(in[15]) begin
					if(in[6:2] == 0) begin
						out[31:12] = {12'd0, in[11:7], 3'd0};
						out[6:0] = 7'h67;
						out[11:7] = (in[12])? 5'd1 : 5'd0;
					end else begin
						out[31:20] = {7'd0, in[6:2]};
						out[19:15] = (in[12])? in[11:7] : 5'd0;
						out[14:0] = {3'd0, in[11:7], 7'h33};
					end
				end else begin
					out = {6'd0, in[12], in[6:2], in[11:7], 3'b001, in[11:7], 7'h13};
				end
			end
			default: out = 0;
		endcase
	end
endmodule