module id_stage(
    input clk,
    input rst_n,
    input [4:0] write_reg,
    input [31:0] write_data,
    input write_enable,
    input [31:0] ins, pc, pc_4,
    input load_use,
    input beq, bne, jal, jalr,
    input stall,
    input RegWrite_id,
    input RegWrite_ex,
    input [4:0] rd_id,
    input [4:0] rd_ex,
    input memread_ex,
    input [31:0] alu_out,
    output jump,
    output reg [4:0] rs1, rs2, rd,
    output [31:0] rs1_data, rs2_data,
    output [31:0] imm, new_pc, 
    output reg [31:0] ins_out,
    output if_stall,
    //EX
    input alusrc,
    input [1:0] aluop,
    output reg alusrc_reg,
    output reg [1:0] aluop_reg,
    //MEM
    input memread,
    input memwrite,
    output reg memread_reg,
    output reg memwrite_reg,
    //WB
    input MemToReg,
    input RegWrite,
    output reg MemToReg_reg,
    output reg RegWrite_reg
);

    reg [31:0] rs1_data_r, rs2_data_r, imm_jump, imm_r, rs1_data_w, rs2_data_w, ins_w, rs1_data_file, rs2_data_file;
    reg [4:0] rs1_w, rs2_w, rd_w;
    wire same;
    wire [31:0] pc_mux;//, imm_w;
    wire [31:0] rs1_data_original, rs2_data_original;
    reg alusrc_w, memread_w, memwrite_w, MemToReg_w, RegWrite_w;
    reg [1:0] aluop_w;
    wire [31:0] imm_wire;
    reg [31:0] imm_w;
    wire hazard, jalr_hazard, branch_hazard, rs1_forward, rs2_forward;


    assign rs1_forward = RegWrite_ex & (rd_ex == ins[19:15]);
    assign rs2_forward = RegWrite_ex & (rd_ex == ins[24:20]);
    assign hazard = (RegWrite_id & (rd_id == ins[19:15])) | (RegWrite_ex & (rd_ex == ins[19:15]) & memread_ex);
    assign jalr_hazard = jalr & hazard;
    assign branch_hazard = hazard | (RegWrite_id & (rd_id == ins[24:20])) | (RegWrite_ex & (rd_ex == ins[24:20]) & memread_ex);
    assign if_stall = jalr_hazard | load_use | ((beq | bne) & branch_hazard);
    assign jump = (if_stall)? 0 : (jal | jalr | (beq & same) | (bne & !same))? 1:0;
    assign same = (rs1_data_file == rs2_data_file)? 1:0;
    assign new_pc = imm_jump + pc_mux;
    assign pc_mux = (jalr)? rs1_data_file : pc;
    assign rs1_data = rs1_data_r;
    assign rs2_data = rs2_data_r;
    // assign rs1_data = rs1_data_r;
    //assign imm = (jal | jalr)? pc_4 : imm_r;

    assign imm_wire[31:5] = {{20{ins[31]}},ins[31:25]};
    assign imm_wire[4:0] = (ins[5])? ins[11:7] : ins[24:20];
    assign imm = imm_r;
    always@(*) begin
        if(!if_stall & rs1_forward) rs1_data_file = alu_out;
        else if(ins[19:15] == write_reg & write_enable) rs1_data_file = write_data;
        else rs1_data_file = rs1_data_original;
    end
    always@(*) begin
        if(!if_stall & rs2_forward) rs2_data_file = alu_out;
        else if(ins[24:20] == write_reg & write_enable) rs2_data_file = write_data;
        else rs2_data_file = rs2_data_original;
    end

    always@(*) begin
        if(jal) imm_jump = {{12{ins[31]}},ins[19:12],ins[20],ins[30:21],1'b0};
        else if(jalr) imm_jump = {{20{ins[31]}},ins[31:20]};
        else imm_jump = {{20{ins[31]}},ins[7],ins[30:25],ins[11:8],1'b0};
    end
    always@(*) begin
        if(stall) begin
            rs1_data_w = rs1_data_r;
            rs2_data_w = rs2_data_r;
            rs1_w = rs1;
            rs2_w = rs2;
            rd_w = rd;
            imm_w = imm_r;

            alusrc_w = alusrc_reg;
            aluop_w = aluop_reg;
            memread_w = memread_reg;
            memwrite_w = memwrite_reg;
            MemToReg_w = MemToReg_reg;
            RegWrite_w = RegWrite_reg;
            ins_w = ins_out;
        end else if (if_stall)begin
            rs1_data_w = 0;
            rs2_data_w = 0;
            rs1_w = 0;
            rs2_w = 0;
            rd_w = 0;
            imm_w = 0;

            alusrc_w = 0;
            aluop_w = 0;
            memread_w = 0;
            memwrite_w = 0;
            MemToReg_w = 0;
            RegWrite_w = 0;
            ins_w = ins_out;
        end else begin
            rs1_data_w = (jal | jalr)? 32'd0 : rs1_data_file;
            rs2_data_w = rs2_data_file;
            rs1_w = (jalr)? 0 : ins[19:15];
            rs2_w = ins[24:20];
            rd_w = ins[11:7];
            imm_w = (jal | jalr)? pc_4 : imm_wire; 

            alusrc_w = alusrc;
            aluop_w = aluop;
            memread_w = memread;
            memwrite_w = memwrite;
            MemToReg_w = MemToReg;
            RegWrite_w = (ins[11:7] == 0)? 0 : RegWrite;
            ins_w = ins;
        end
    end
    reg_file reg0(
        .clk(clk),
        .rst_n(rst_n),
        .wen(write_enable),
        .rs1(ins[19:15]),
        .rs2(ins[24:20]),
        .rd(write_reg),
        .rd_data(write_data),
        .rs1_data(rs1_data_original),
        .rs2_data(rs2_data_original)
    );
    always@(posedge clk) begin
        if(!rst_n) begin
            rs1 <= 0;
            rs2 <= 0;
            rd  <= 0;
            rs1_data_r <= 0;
            rs2_data_r <= 0;
            imm_r <= 0;
            alusrc_reg <= 0;
            aluop_reg <= 0;
            memread_reg <= 0;
            memwrite_reg <= 0;
            MemToReg_reg <= 0;
            RegWrite_reg <= 0;
            ins_out <= 0;

        end else begin
            rs1 <= rs1_w;
            rs2 <= rs2_w;
            rd <= rd_w;
            rs1_data_r <= rs1_data_w;
            rs2_data_r <= rs2_data_w;
            imm_r <= imm_w;
            alusrc_reg <= alusrc_w;
            aluop_reg <= aluop_w;
            memread_reg <= memread_w;
            memwrite_reg <= memwrite_w;
            MemToReg_reg <= MemToReg_w;
            RegWrite_reg <= RegWrite_w;
            ins_out <= ins_w;
        end
    end
endmodule

module hazard_unit(
    input IDEX_memread,
    input [4:0] IDEX_rd, IFID_rs1, IFID_rs2,
    output load_use
);
    assign load_use = (IDEX_memread & (IDEX_rd == IFID_rs1 | IDEX_rd == IFID_rs2))? 1:0;
endmodule
/*
module imm_generator(
    input [31:0] ins,
    output [31:0] imm
);
    assign imm[31:5] = {{20{ins[31]}},ins[31:25]};
    assign imm[4:0] = (ins[5])? ins[11:7] : ins[24:0];
endmodule
*/
module reg_file(clk, rst_n, wen, rs1, rs2, rd, rd_data, rs1_data, rs2_data);

    parameter BITS = 32;
    parameter word_depth = 32;
    parameter addr_width = 5; // 2^addr_width >= word_depth

    input clk, rst_n, wen; // wen: 0:read | 1:write
    input [BITS-1:0] rd_data;
    input [addr_width-1:0] rs1, rs2, rd;

    output [BITS-1:0] rs1_data, rs2_data;

    reg [BITS-1:0] mem [0:word_depth-1];
    reg [BITS-1:0] mem_nxt [0:word_depth-1];

    integer i;

    assign rs1_data = mem[rs1];
    assign rs2_data = mem[rs2];

    always @(*) begin
        for (i=0; i<word_depth; i=i+1)
            mem_nxt[i] = (wen && (rd == i)) ? rd_data : mem[i];
    end

    always @(posedge clk) begin
        if (!rst_n) begin
            for (i=0; i<word_depth; i=i+1)
                mem[i] <= 0;
        end
        else begin
            mem[0] <= 0;
            for (i=1; i<word_depth; i=i+1)
                mem[i] <= mem_nxt[i];
        end
    end
endmodule