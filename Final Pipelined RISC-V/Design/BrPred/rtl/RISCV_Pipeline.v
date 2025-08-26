`include "./IF.v"
`include "./MEM.v"
`include "./control.v"
`include "./EX.v"
`include "./ID_HAZARD.v"

module RISCV_Pipeline (
		// control interface
		input         clk, 
		input         rst_n,
//----------I cache interface-------		
		output        ICACHE_ren,
		output        ICACHE_wen,
		output [29:0] ICACHE_addr,
		output [31:0] ICACHE_wdata,
		input         ICACHE_stall,
		input  [31:0] ICACHE_rdata,
//----------D cache interface-------
		output        DCACHE_ren,
		output        DCACHE_wen,
		output [29:0] DCACHE_addr,
		output [31:0] DCACHE_wdata,
		input         DCACHE_stall,
		input  [31:0] DCACHE_rdata
//--------------PC-----------------
		// output [31:0] PC
	);

//------------STALL-----------------
    wire stall, stall2, load_use, if_stall;
    assign stall = stall2 | if_stall;
    assign stall2 = ICACHE_stall | DCACHE_stall;

//--------------IF------------------
    wire [31:0] pc_if, pc_4_if;
    wire [31:0] instr_if;
	wire BrPre_if;
//-----------CONTROL----------------
	wire alusrc, MemToReg, RegWrite, memread, memwrite, bne, beq, jal, jalr, flush;
    wire [1:0] aluop;
//--------------ID------------------
    wire        pc_sel, PreWrong;
	wire [4:0]  rs1_id, rs2_id, rd_id;
    wire [31:0] rs1_data_id, rs2_data_id, imm_id;
    wire [31:0] pc_jump;
	wire funct7, opcode_5;
	wire [2:0] funct3;
    	// wire [31:0] ins_out;
    // EX
    wire alusrc_id;
    wire [1:0] aluop_id;
    // MEM
    wire memread_id, memwrite_id;
    // WB
    wire MemToReg_id, RegWrite_id;
//--------------EX------------------
    wire RegWrite_ex, MemToReg_ex;
    wire memread_ex, memwrite_ex;
    wire [31:0] mem_addr_D, mem_wdata_D;
    wire [4:0]  rd_ex;
//-------------MEM------------------
    wire [4:0]  rd_mem;
    wire        MemToReg_mem, RegWrite_mem;
    wire [31:0] mem_data, alu_data;
    wire [31:0] wdata_wb;
    assign wdata_wb = (MemToReg_mem) ? mem_data : alu_data;

    IF IF0(
        .clk(clk), 
        .rst_n(rst_n),
        .stall(stall),
        .ICACHE_ren(ICACHE_ren),
        .ICACHE_wen(ICACHE_wen),
        .ICACHE_addr(ICACHE_addr),
        .ICACHE_wdata(ICACHE_wdata),
        .ICACHE_rdata(ICACHE_rdata),
        .pc_sel(pc_sel),
        .pc_jump(pc_jump),
        .pc_if(pc_if),
		.pc_4_if(pc_4_if),
        //.PC(PC),
        .instr_if(instr_if),
		.PreWrong(PreWrong),
		.BrPre_if(BrPre_if)
    );

	control control0(
		.opcode(instr_if[6:0]),
		.funct3_0(instr_if[12]),
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

	hazard_unit hazard_unit0(
		.memread_id(memread_id),
		.rd_id(rd_id),
		.rs1_if(instr_if[19:15]),
		.rs2_if(instr_if[24:20]),
    	.load_use(load_use)
	);

	id_stage id0(
		.clk(clk),
		.rst_n(rst_n),
		.rd_wb(rd_mem),
		.wdata_wb(wdata_wb),
		.wen(RegWrite_mem),
		.ins(instr_if),
		.pc(pc_if),
		.pc_4(pc_4_if),
		.BrPre_if(BrPre_if),
		.load_use(load_use),
		.beq(beq),
		.bne(bne),
		.jal(jal),
		.jalr(jalr),
		.stall(stall2),
			//.RegWrite_id(RegWrite_id),
    	.RegWrite_ex(RegWrite_ex),
    		//.rd_id(rd_id),
    	.rd_ex(rd_ex),
		.jump(pc_sel),
		.PreWrong(PreWrong),
		.rs1_id(rs1_id), 
		.rs2_id(rs2_id), 
		.rd_id(rd_id),
		.rs1_data_id(rs1_data_id), 
		.rs2_data_id(rs2_data_id),
		.imm_id(imm_id),
		.pc_jump(pc_jump),
		.funct7(funct7),
		.funct3(funct3),
		.opcode_5(opcode_5),
			//.ins_out(ins_out),
		.if_stall(if_stall),
		//EX
		.alusrc(alusrc),
		.aluop(aluop),
		.alusrc_id(alusrc_id),
		.aluop_id(aluop_id),
		//MEM
		.memread(memread),
		.memwrite(memwrite),
		.memread_id(memread_id),
		.memwrite_id(memwrite_id),
		//WB
		.MemToReg(MemToReg),
		.RegWrite(RegWrite),
		.MemToReg_id(MemToReg_id),
		.RegWrite_id(RegWrite_id)
	);

	EX EX0(
		.clk(clk),
		.rst_n(rst_n),
		.stall(stall2),
		.alusrc_id(alusrc_id),
			//.ex_mem_addr(mem_addr_D),	
		.wdata_wb(wdata_wb),
		.imm_id(imm_id),
		.rs1_data_id(rs1_data_id),
		.rs2_data_id(rs2_data_id),
		.rd_id(rd_id),
		.mem_addr_D(mem_addr_D),  
		.mem_wdata_D(mem_wdata_D),
		.rd_ex(rd_ex),
    	// ALU Control
		.aluop_id(aluop_id),
		.funct7(funct7),
		.funct3(funct3),
		.opcode_5(opcode_5),
    	// Forwarding
		.RegWrite_mem(RegWrite_mem),
		.rd_mem(rd_mem),
			//.EX_MEM_regwrite(RegWrite_ex),
			//.EX_MEM_Rd(rd_ex),
		.rs1_id(rs1_id),
		.rs2_id(rs2_id),
    	// MEM
		.memread_id(memread_id),
		.memwrite_id(memwrite_id),
		.memread_ex(memread_ex),
		.memwrite_ex(memwrite_ex),
    	// WB
		.RegWrite_id(RegWrite_id),
		.MemToReg_id(MemToReg_id),
		.RegWrite_ex(RegWrite_ex),
		.MemToReg_ex(MemToReg_ex)
    );

    MEM MEM0(
        .clk(clk), 
        .rst_n(rst_n),
        .stall(stall2),
        .DCACHE_ren(DCACHE_ren),
        .DCACHE_wen(DCACHE_wen),
        .DCACHE_addr(DCACHE_addr),
        .DCACHE_wdata(DCACHE_wdata),
        .DCACHE_rdata(DCACHE_rdata),
        .memread_ex(memread_ex),
        .memwrite_ex(memwrite_ex),
        .rd_ex(rd_ex),
        .RegWrite_ex(RegWrite_ex),
        .MemToReg_ex(MemToReg_ex),
        .mem_addr_D(mem_addr_D),
        .mem_wdata_D(mem_wdata_D),
        .rd_mem(rd_mem),
        .RegWrite_mem(RegWrite_mem),
        .MemToReg_mem(MemToReg_mem),
        .alu_data(alu_data),
        .mem_data(mem_data)
    );

endmodule