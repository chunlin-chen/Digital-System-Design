module EX(  
    input  clk,
    input  rst_n,
    input  stall,
    input  alusrc_id,
        //input  [31:0] ex_mem_addr,
    input  [31:0] wdata_wb,
    input  [31:0] imm_id,
    input  [31:0] rs1_data_id,
    input  [31:0] rs2_data_id,
    input  [4:0]  rd_id,
    output reg [31:0] mem_addr_D,  
    output reg [31:0] mem_wdata_D,
    output reg [4:0]  rd_ex,
    // ALU Control
    input  [1:0]  aluop_id,
    input         funct7,
    input  [2:0]  funct3,
    input         opcode_5,
    // Forwarding
    input         RegWrite_mem,
    input  [4:0]  rd_mem,
        //input         EX_MEM_regwrite,
        //input  [4:0]  EX_MEM_Rd,
    input  [4:0]  rs1_id,
    input  [4:0]  rs2_id,
    // MEM
    input         memread_id,
    input         memwrite_id,
    output reg    memread_ex,
    output reg    memwrite_ex,
    // WB
    input         RegWrite_id,
    input         MemToReg_id,
    output reg    RegWrite_ex,
    output reg    MemToReg_ex
);

    //==== Reg/Wire Declaration ===================
    reg        memread_w, memwrite_w;
    reg        regwrite_w, memtoreg_w;
    reg [31:0] mem_addr_D_w, mem_wdata_D_w;
    reg [4:0]  rd_ex_w;


    wire [1:0]  f4A,f4B;
    wire [3:0]  ALU_Control;
    wire [31:0] in_A, in_B, in_B2, alu_out;

    //==== Submodule Connection ===================

    ALUControl alu_control_unit(
        .ALUOp(aluop_id), 
        .funct7(funct7), 
        .funct3(funct3),
        .opcode_5(opcode_5), 
        .ALU_Control(ALU_Control)
    );

    ALU alu_unit(
        .ALU_Control(ALU_Control), 
        .in_A(in_A), 
        .in_B(in_B2), 
        .out(alu_out)
    );

    Forwarding_unit forward_unit(
        .ForwardA(f4A), 
        .ForwardB(f4B), 
        .RegWrite_mem(RegWrite_mem), 
        .rd_mem(rd_mem), 
        .RegWrite_ex(RegWrite_ex), 
        .rd_ex(rd_ex), 
        .rs1_id(rs1_id), 
        .rs2_id(rs2_id), 
        .alusrc(alusrc_id)
    );

    //==== Combinational Part =====================

    assign in_A = (f4A == 2'b01) ? wdata_wb :
                  (f4A == 2'b10) ? mem_addr_D : rs1_data_id;

    assign in_B = (f4B == 2'b01) ? wdata_wb :
                  (f4B == 2'b10) ? mem_addr_D : rs2_data_id;

    assign in_B2 = (alusrc_id) ? imm_id : in_B;

	always@(*) begin
		if(stall) begin
		    regwrite_w = RegWrite_ex;
        	memtoreg_w = MemToReg_ex;
        	memread_w = memread_ex;
        	memwrite_w = memwrite_ex;
        	rd_ex_w = rd_ex;
        	mem_addr_D_w = mem_addr_D;
        	mem_wdata_D_w = mem_wdata_D;
		end
	    else begin
		    regwrite_w = RegWrite_id;
        	memtoreg_w = MemToReg_id;
        	memread_w = memread_id;
        	memwrite_w = memwrite_id;
        	rd_ex_w = rd_id;
        	mem_addr_D_w = alu_out;
        	mem_wdata_D_w = in_B;
        end
    end
                    

    //==== Sequential Part ========================
    always @(posedge clk) begin
        if(!rst_n)begin
            RegWrite_ex <= 0;
            MemToReg_ex <= 0;
            memread_ex <= 0;
            memwrite_ex <= 0;
            rd_ex <= 0;
            mem_addr_D <= 0;
            mem_wdata_D <= 0;
        end
        else begin
            RegWrite_ex <= regwrite_w;
            MemToReg_ex <= memtoreg_w;
            memread_ex <= memread_w;
            memwrite_ex <= memwrite_w;
            rd_ex <= rd_ex_w;
            mem_addr_D <= mem_addr_D_w;
            mem_wdata_D <= mem_wdata_D_w;
        end
    end
endmodule



module ALUControl(ALUOp, funct7, funct3, opcode_5, ALU_Control);
    input      [1:0] ALUOp;
    input            funct7, opcode_5;
    input      [2:0] funct3;
    //input      [6:0] opcode;
    output reg [3:0] ALU_Control;

    always @(*) begin
        ALU_Control = 4'b0000;
        case(ALUOp)
            2'b00: ALU_Control = 4'b0010;
            2'b01: ALU_Control = 4'b0110;
            2'b10: begin
                case(funct3)
                    3'b000: begin
                        if(opcode_5) ALU_Control = funct7 ? 4'b0110 : 4'b0010; // sub, add
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

module Forwarding_unit(ForwardA, ForwardB, RegWrite_mem, rd_mem, RegWrite_ex, rd_ex, rs1_id, rs2_id, alusrc);
    input             RegWrite_mem,RegWrite_ex,alusrc;
    input      [4:0] rd_mem,rd_ex,rs1_id,rs2_id;
    output     [1:0]  ForwardA;
    output     [1:0]  ForwardB;


    assign ForwardA = (RegWrite_ex && (rd_ex !=0) && (rd_ex == rs1_id)) ? 2'b10 :
                      (RegWrite_mem && (rd_mem != 0) && ~(RegWrite_ex && (rd_ex != 0) && (rd_ex == rs1_id))&&(rd_mem==rs1_id)) ? 2'b01 : 2'b00;

    assign ForwardB = (RegWrite_ex && (rd_ex !=0) && (rd_ex == rs2_id)) ? 2'b10 :
                      (RegWrite_mem && (rd_mem != 0) && ~(RegWrite_ex && (rd_ex != 0) && (rd_ex == rs2_id))&&(rd_mem==rs2_id)) ? 2'b01 :
                      (alusrc) ? 2'b11 : 2'b00;
    
endmodule
