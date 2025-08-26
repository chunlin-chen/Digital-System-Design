module id_stage(
    input clk,
    input rst_n,
    input [4:0] rd_wb,
    input [31:0] wdata_wb,
    input wen,
    input [31:0] ins, pc, pc_4,
    input BrPre_if,
    input load_use,
    input beq, bne, jal, jalr,
    input stall,
    //input RegWrite_id,
    input RegWrite_ex,
    //input [4:0] rd_id,
    input [4:0] rd_ex,
    output jump, PreWrong,
    output [4:0] rs1_id, rs2_id, rd_id,
    output [31:0] rs1_data_id, rs2_data_id,
    output [31:0] imm_id, pc_jump, 
    output reg funct7, 
    output reg [2:0] funct3,
    output reg opcode_5, 
    //output reg [31:0] ins_out,
    output if_stall,
    //EX
    input alusrc,
    input [1:0] aluop,
    output reg alusrc_id,
    output reg [1:0] aluop_id,
    //MEM
    input memread,
    input memwrite,
    output reg memread_id,
    output reg memwrite_id,
    //WB
    input MemToReg,
    input RegWrite,
    output reg MemToReg_id,
    output reg RegWrite_id
);

    reg [31:0] rs1_data_r, rs2_data_r, imm_jump, imm_r, rs1_data_w, rs2_data_w;//, ins_w;
    reg [4:0] rs1_r, rs2_r, rd_r, rs1_w, rs2_w, rd_w;
    reg funct7_w, opcode_5_w;
    reg [2:0] funct3_w;
    wire same;
    wire [31:0] rs1_data_file, rs2_data_file, pc_mux, PC_plusimm;//, imm_w;
    reg alusrc_w, memread_w, memwrite_w, MemToReg_w, RegWrite_w;
    reg [1:0] aluop_w;
    wire [31:0] imm_wire;
    reg [31:0] imm_w;
    wire hazard, jalr_hazard, branch_hazard;
    wire Ctrl_Br;

    assign hazard = (RegWrite_id & (rd_id == ins[19:15])) | (RegWrite_ex & (rd_ex == ins[19:15]));
    assign jalr_hazard = jalr & hazard;
    assign branch_hazard = hazard | (RegWrite_id & (rd_id == ins[24:20])) | (RegWrite_ex & (rd_ex == ins[24:20]));
    assign if_stall = jalr_hazard | load_use | ((beq | bne) & branch_hazard);
    assign Ctrl_Br = (beq & same) | (bne & !same);
    assign jump = (if_stall)? 0 : (jal | jalr | PreWrong)? 1:0;
    assign PreWrong = Ctrl_Br ^ BrPre_if;
    assign same = (rs1_data_file == rs2_data_file)? 1:0;
    assign pc_jump = (jal | jalr | Ctrl_Br) ? PC_plusimm : pc_4;
    assign PC_plusimm = imm_jump + pc_mux;
    assign pc_mux = (jalr)? rs1_data_file : pc;

    assign rs1_id = rs1_r;
    assign rs2_id = rs2_r;
    assign rd_id = rd_r;
    assign rs1_data_id = rs1_data_r;
    assign rs2_data_id = rs2_data_r;
    // assign rs1_data = rs1_data_r;
    //assign imm = (jal | jalr)? pc_4 : imm_r;

    assign imm_wire[31:5] = {{20{ins[31]}},ins[31:25]};
    assign imm_wire[4:0] = (ins[5])? ins[11:7] : ins[24:20];
    assign imm_id = imm_r;

    always@(*) begin
        if(jal) imm_jump = {{12{ins[31]}},ins[19:12],ins[20],ins[30:21],1'b0};
        else if(jalr) imm_jump = {{20{ins[31]}},ins[31:20]};
        else imm_jump = {{20{ins[31]}},ins[7],ins[30:25],ins[11:8],1'b0};
    end
    always@(*) begin
        if(stall) begin
            rs1_data_w = rs1_data_r;
            rs2_data_w = rs2_data_r;
            rs1_w = rs1_r;
            rs2_w = rs2_r;
            rd_w = rd_r;
            imm_w = imm_r;

            alusrc_w = alusrc_id;
            aluop_w = aluop_id;
            memread_w = memread_id;
            memwrite_w = memwrite_id;
            MemToReg_w = MemToReg_id;
            RegWrite_w = RegWrite_id;
            funct7_w = funct7;
            funct3_w = funct3;
            opcode_5_w = opcode_5;
            //ins_w = ins_out;
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
            funct7_w = funct7;
            funct3_w = funct3;
            opcode_5_w = opcode_5;
            //ins_w = ins_out;
        end else begin
            rs1_data_w = (jal | jalr)? 32'd0 : rs1_data_file;
            rs2_data_w = rs2_data_file;
            rs1_w = ins[19:15];
            rs2_w = ins[24:20];
            rd_w = ins[11:7];
            imm_w = (jal | jalr)? pc_4 : imm_wire; 

            alusrc_w = alusrc;
            aluop_w = aluop;
            memread_w = memread;
            memwrite_w = memwrite;
            MemToReg_w = MemToReg;
            RegWrite_w = RegWrite;
            funct7_w = ins[30];
            funct3_w = ins[14:12];
            opcode_5_w = ins[5];
            //ins_w = ins;
        end
    end
    reg_file reg0(
        .clk(clk),
        .rst_n(rst_n),
        .wen(wen),
        .rs1(ins[19:15]),
        .rs2(ins[24:20]),
        .rd(rd_wb),
        .rd_data(wdata_wb),
        .rs1_data(rs1_data_file),
        .rs2_data(rs2_data_file)
    );
    always@(posedge clk) begin
        if(!rst_n) begin
            rs1_r <= 0;
            rs2_r <= 0;
            rd_r  <= 0;
            rs1_data_r <= 0;
            rs2_data_r <= 0;
            imm_r <= 0;
            alusrc_id <= 0;
            aluop_id <= 0;
            memread_id <= 0;
            memwrite_id <= 0;
            MemToReg_id <= 0;
            RegWrite_id <= 0;
            funct7 <= 0;
            funct3 <= 0;
            opcode_5 <= 0;
            //ins_out <= 0;

        end else begin
            rs1_r <= rs1_w;
            rs2_r <= rs2_w;
            rd_r <= rd_w;
            rs1_data_r <= rs1_data_w;
            rs2_data_r <= rs2_data_w;
            imm_r <= imm_w;
            alusrc_id <= alusrc_w;
            aluop_id <= aluop_w;
            memread_id <= memread_w;
            memwrite_id <= memwrite_w;
            MemToReg_id <= MemToReg_w;
            RegWrite_id <= RegWrite_w;
            funct7 <= funct7_w;
            funct3 <= funct3_w;
            opcode_5 <= opcode_5_w;
            //ins_out <= ins_w;
        end
    end
endmodule

module hazard_unit(
    input memread_id,
    input [4:0] rd_id, rs1_if, rs2_if,
    output load_use
);
    assign load_use = (memread_id & (rd_id == rs1_if | rd_id == rs2_if))? 1:0;
endmodule

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

    always @(negedge clk) begin
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