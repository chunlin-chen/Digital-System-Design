module control(
    input      [6:0] opcode,
    input            funct3_0,
    output reg       alusrc,
    output reg       memtoreg,
    output reg       regwrite,
    output reg       memread,
    output reg       memwrite,
    output reg       bne,
    output reg       beq,
    output reg       jal,
    output reg       jalr,
    output reg [1:0] aluop
    // output reg       if_flush  
);
    
always @(*) begin
        
    case(opcode)
    7'b0110011:begin
        // R-type
        alusrc = 0;
        memtoreg = 0;
        regwrite = 1;
        memread = 0;
        memwrite = 0;
        bne = 0;
        beq = 0;
        jal = 0;
        jalr = 0;
        aluop = 2'b10;
        // if_flush = 0;
    end
    7'b0010011:begin
        // I-type
        alusrc = 1;
        memtoreg = 0;
        regwrite = 1;
        memread = 0;
        memwrite = 0;
        bne = 0;
        beq = 0;
        jal = 0;
        jalr = 0;
        aluop = 2'b10;
        // if_flush = 0;
    end
    7'b0000011:begin
        // lw
        alusrc = 1;
        memtoreg = 1;
        regwrite = 1;
        memread = 1;
        memwrite = 0;
        bne = 0;
        beq = 0;
        jal = 0;
        jalr = 0;
        aluop = 2'b00;
        // if_flush = 0;
    end
    7'b0100011:begin
        // sw
        alusrc = 1;
        memtoreg = 0;
        regwrite = 0;
        memread = 0;
        memwrite = 1;
        bne = 0;
        beq = 0;
        jal = 0;
        jalr = 0;
        aluop = 2'b00;
        // if_flush = 0;
    end
    7'b1100011:begin
        // beq & bne
        alusrc = 0;
        memtoreg = 0;
        regwrite = 0;
        memread = 0;
        memwrite = 0;
        jal = 0;
        jalr = 0;
        aluop = 2'b01;
        // if_flush = 1;
        beq = ~funct3_0;
        bne = funct3_0;
    end
    7'b1101111:begin
        // jal
        alusrc = 1;
        memtoreg = 0;
        regwrite = 1;
        memread = 0;
        memwrite = 0;
        bne = 0;
        beq = 0;
        jal = 1;
        jalr = 0;
        aluop = 2'b00;
        // if_flush = 1;
    end
    7'b1100111:begin
        // jalr
        alusrc = 1;
        memtoreg = 0;
        regwrite = 1;
        memread = 0;
        memwrite = 0;
        bne = 0;
        beq = 0;
        jal = 0;
        jalr = 1;
        aluop = 2'b00;
        // if_flush = 1;
    end
    default:begin
        alusrc = 0;
        memtoreg = 0;
        regwrite = 0;
        memread = 0;
        memwrite = 0;
        bne = 0;
        beq = 0;
        jal = 0;
        jalr = 0;
        aluop = 2'b00;
        // if_flush = 0;
    end
    endcase

end
endmodule


