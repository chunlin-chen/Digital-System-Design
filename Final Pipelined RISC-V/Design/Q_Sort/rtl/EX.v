// Your SingleCycle RISC-V code
// 82057
module EX(  ex_mem_addr,
            wb_data,
            clk,
            rst_n,
            stall,
            instr,
            Imm_gen,
            ID_EX_Rs1,
            ID_EX_Rs2,
            IF_ID_Rs1,
            IF_ID_Rs2,
            IF_ID_Rd,
            EX_MEM_Rd,
            MEM_WB_Rd,
            regwrite,
            memtoreg,
            memread,
            memwrite,
            ID_EX_regwrite,
            ID_EX_memtoreg,
            ID_EX_memread,
            ID_EX_memwrite,
            EX_MEM_regwrite,
            MEM_WB_regwrite,
            alusrc,
            aluop,
            mem_addr_D,  
            mem_wdata_D,
            EX_Rd           
    );

    input   [31:0] ex_mem_addr, wb_data;
    input         clk,rst_n,stall;
    input  [31:0] instr;
    // IF/ID
    input  [4:0] IF_ID_Rs1,IF_ID_Rs2,IF_ID_Rd;
    // ID/EX
    input  [31:0] ID_EX_Rs1,ID_EX_Rs2;
    input  [31:0] Imm_gen;
    // WB
    input         ID_EX_regwrite,ID_EX_memtoreg;
    //M
    input         ID_EX_memread,ID_EX_memwrite;
    // EX
    input         alusrc;
    input  [1:0]  aluop;
    // EX_MEM
    input         EX_MEM_regwrite;
    input  [4:0] EX_MEM_Rd;
    // MEM_WB
    input         MEM_WB_regwrite;
    input  [4:0] MEM_WB_Rd;



    output        regwrite,memtoreg;
    output        memread,memwrite; 
    output [31:0] mem_addr_D,mem_wdata_D;
    output [4:0] EX_Rd;

   
    
    //==== Reg/Wire Declaration ===================
    reg         regwrite,memtoreg;
    reg         memread,memwrite;
    reg  [31:0] mem_addr_D,mem_wdata_D;
    reg [4:0] EX_Rd;

    reg         regwrite_w,memtoreg_w;
    reg         memread_w,memwrite_w;
    reg  [31:0] mem_addr_D_w,mem_wdata_D_w;
    reg [4:0] EX_Rd_w;


    wire [1:0]  f4A,f4B;
    wire [3:0]  ALU_Control;
    wire [31:0] in_A, in_B, in_B2, alu_out;

    //==== Submodule Connection ===================

    ALUControl alu_control_unit(
        .ALUOp(aluop), 
        .funct7(instr[30]), 
        .funct3(instr[14:12]),
        .opcode(instr[6:0]), 
        .ALU_Control(ALU_Control));

    ALU alu_unit(
        .ALU_Control(ALU_Control), 
        .in_A(in_A), 
        .in_B(in_B2), 
        .out(alu_out));

    Forwarding_unit forward_unit(
        .ForwardA(f4A), 
        .ForwardB(f4B), 
        .MW_regwrite(MEM_WB_regwrite), 
        .MW_regrd(MEM_WB_Rd), 
        .EM_regwrite(EX_MEM_regwrite), 
        .EM_regrd(EX_MEM_Rd), 
        .IE_regrs1(IF_ID_Rs1), 
        .IE_regrs2(IF_ID_Rs2), 
        .alusrc(alusrc));

    //==== Combinational Part =====================

        assign in_A = (f4A == 2'b01)? wb_data:
                      (f4A == 2'b10)? ex_mem_addr:ID_EX_Rs1;

        assign in_B = (f4B == 2'b01)? wb_data:
                      (f4B == 2'b10)? ex_mem_addr:ID_EX_Rs2;

        assign in_B2= (alusrc)? Imm_gen:in_B;

	    always@(*) begin
		if(stall) begin
		    regwrite_w = regwrite;
        	memtoreg_w = memtoreg;
        	memread_w = memread;
        	memwrite_w = memwrite;
        	EX_Rd_w = EX_Rd;
        	mem_addr_D_w = mem_addr_D;
        	mem_wdata_D_w = mem_wdata_D;
		end
		else begin
		    regwrite_w = ID_EX_regwrite;
        	memtoreg_w = ID_EX_memtoreg;
        	memread_w = ID_EX_memread;
        	memwrite_w = ID_EX_memwrite;
        	EX_Rd_w = IF_ID_Rd;
        	mem_addr_D_w = alu_out;
        	mem_wdata_D_w = in_B;
        end

    end
                    

    //==== Sequential Part ========================
    always @(posedge clk) begin
        if(!rst_n)begin
            regwrite <= 0;
            memtoreg <= 0;
            memread <= 0;
            memwrite <= 0;
            EX_Rd <= 0;
            mem_addr_D <= 0;
            mem_wdata_D <= 0;
        end
        else begin
        regwrite <= regwrite_w;
        memtoreg <= memtoreg_w;
        memread <= memread_w;
        memwrite <= memwrite_w;
        EX_Rd <= EX_Rd_w;
        mem_addr_D <= mem_addr_D_w;
        mem_wdata_D <= mem_wdata_D_w;

        end
    end
endmodule



module ALUControl(ALUOp, funct7, funct3, opcode, ALU_Control);
    input      [1:0] ALUOp;
    input            funct7;
    input      [2:0] funct3;
    input      [6:0] opcode;
    output reg [3:0] ALU_Control;

    always @(*) begin
        ALU_Control = 4'b0000;
        case(ALUOp)
            2'b00: ALU_Control = 4'b0010;
            2'b01: ALU_Control = 4'b0110;
            2'b10: begin
                case(funct3)
                    3'b000: begin
                        if(opcode==7'b0110011) ALU_Control = funct7 ? 4'b0110 : 4'b0010; // sub, add
                        else ALU_Control = 4'b0010; 
                    end
                    3'b111: ALU_Control = 4'b0000; // and
                    3'b110: ALU_Control = 4'b0001; // or
                    3'b100: ALU_Control = 4'b1001; // xor
                    3'b010: ALU_Control = 4'b0111; // slt
                    3'b001: ALU_Control = 4'b1010; // sll
                    3'b101: ALU_Control = funct7 ? 4'b1011 : 4'b1100; // sra, srl
                    endcase                  
            end
        endcase
    end
endmodule


module ALU(ALU_Control, in_A, in_B, out);
    input      [3:0]  ALU_Control;
    input      [31:0] in_A, in_B;
    output reg [31:0] out;

    always @(*) begin
        out = 32'b0;
        case(ALU_Control)
            4'b0010: out = in_A + in_B; // add
            4'b0110: out = in_A - in_B; // sub
            4'b0000: out = in_A & in_B; // and
            4'b0001: out = in_A | in_B; // or
            4'b1001: out = in_A ^ in_B; // xor
            4'b1010: out = in_A << in_B[4:0]; // sll
            4'b1011: out = $signed(in_A) >>> in_B[4:0]; // sra
            4'b1100: out = in_A >> in_B[4:0]; // srl
            4'b0111: out = ($signed(in_A) < $signed(in_B)) ? 1 : 0; // slt
        endcase
    end
endmodule

module Forwarding_unit(ForwardA, ForwardB, MW_regwrite, MW_regrd, EM_regwrite, EM_regrd, IE_regrs1, IE_regrs2, alusrc);
    input             MW_regwrite,EM_regwrite,alusrc;
    input      [4:0] MW_regrd,EM_regrd,IE_regrs1,IE_regrs2;
    output     [1:0]  ForwardA;
    output     [1:0]  ForwardB;


    assign ForwardA = (EM_regwrite && (EM_regrd == IE_regrs1))? 2'b10:
                      (MW_regwrite && ~(EM_regwrite && (EM_regrd == IE_regrs1))&&(MW_regrd==IE_regrs1))? 2'b01:2'b00;

    assign ForwardB = (EM_regwrite && (EM_regrd == IE_regrs2))? 2'b10:
                      (MW_regwrite && ~(EM_regwrite && (EM_regrd == IE_regrs2))&&(MW_regrd==IE_regrs2))? 2'b01:
                      (alusrc)? 2'b11:2'b00;
    
endmodule
