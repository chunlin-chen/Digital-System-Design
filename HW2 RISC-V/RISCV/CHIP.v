// Your SingleCycle RISC-V code

module CHIP(clk,
            rst_n,
            // for mem_D
            mem_wen_D,
            mem_addr_D,
            mem_wdata_D,
            mem_rdata_D,
            // for mem_I
            mem_addr_I,
            mem_rdata_I
    );

    input         clk, rst_n ;
    // for mem_D
    output        mem_wen_D  ;  // mem_wen_D is high, CHIP writes data to D-mem; else, CHIP reads data from D-mem
    output [31:0] mem_addr_D ;  // the specific address to fetch/store data 
    output [31:0] mem_wdata_D;  // data writing to D-mem 
    input  [31:0] mem_rdata_D;  // data reading from D-mem
    // for mem_I
    output [31:0] mem_addr_I ;  // the fetching address of next instruction
    input  [31:0] mem_rdata_I;  // instruction reading from I-mem


//---------------------------------------//

    // PC
    reg signed [31:0] PC,PC_nxt; 
    wire signed [31:0] PC_imm;

//---------------------------------------//   

    // Control
    wire jalr,jal,branch,memread,memtoreg,memwrite,alusrc,regwrite;
    wire [1:0] aluop;

//---------------------------------------//  
    
    // register                        
    reg    [4:0] rs1, rs2, rd;    
    reg signed   [31:0] rd_data;         
    wire signed  [31:0] rs1_data,rs2_data;                          

//---------------------------------------//

    // ALU_control
    wire [3:0]  ALUcontrol;
    reg [2:0] func3;
    reg func7;

//---------------------------------------//

    // ALU
    reg signed [31:0] in_2;
    wire signed [31:0] ALUout; 
    wire zero;

//---------------------------------------//

    reg        mem_wen_D  ;
    reg [31:0] mem_addr_D ;
    reg [31:0] mem_wdata_D;
    reg [31:0] mem_addr_I ;  
    reg [31:0] rdata_D;

/////////////////////////////////////////////////

    register_file rf(.Clk(clk), .Rst(rst_n), .WEN(regwrite), .RW(rd), .busW(rd_data), .RX(rs1), .RY(rs2), .busX(rs1_data), .busY(rs2_data));  
    Control ctrl(.instruction({mem_rdata_I[7:0], mem_rdata_I[15:8], mem_rdata_I[23:16], mem_rdata_I[31:24]}),.jalr(jalr),.jal(jal),.branch(branch),.memread(memread),.memtoreg(memtoreg),.aluop(aluop),.memwrite(memwrite),.alusrc(alusrc),.regwrite(regwrite),.instruc_out(PC_imm));
    ALU_control alu_ctrl(.ALUcontrol(ALUcontrol),.func3(func3),.func7(func7),.alu_ctrl2(aluop));  
    ALU alu(.input_1(rs1_data),.input_2(in_2),.ALUcontrol(ALUcontrol),.Zero(zero),.result(ALUout));  

//==== Combinational Part =====================


always @(*) 
begin

    rs1 = {mem_rdata_I[11:8], mem_rdata_I[23]};
    rs2 = {mem_rdata_I[0], mem_rdata_I[15:12]};
    rd = {mem_rdata_I[19:16], mem_rdata_I[31]};
    func7 = mem_rdata_I[6];
    func3 = mem_rdata_I[22:20];
end

always @(*) 
begin
    rdata_D[31:0] = {mem_rdata_D[7:0], mem_rdata_D[15:8], mem_rdata_D[23:16], mem_rdata_D[31:24]};

end

always @(*) 
begin  
    mem_addr_D = ALUout;
end

always @(*) 
begin  
    mem_wdata_D[31:0] = {rs2_data[7:0], rs2_data[15:8], rs2_data[23:16], rs2_data[31:24]};
end


always @(*) 
begin

    if(jal|jalr)
        rd_data = PC+4;
    else
        if(memtoreg)
            rd_data = rdata_D;
        else
            rd_data = ALUout ;

end

always @(*) 
begin
    mem_wen_D = memwrite;
        
    if(alusrc)
        in_2 = PC_imm;
    else
        in_2 = rs2_data;
end

always @(*) 
begin
    mem_addr_I = PC;

    if(jalr)
        PC_nxt = PC_imm + rs1_data;
    else begin
        if((branch&zero)|jal)
            PC_nxt = PC + PC_imm;
        else
            PC_nxt = PC + 4;
        end
end

    

    

//==== Sequential Part ========================
always @(posedge clk)
begin
    if (!rst_n)
        PC <= 0;
    else  
        PC <= PC_nxt;
end

endmodule

///////////////////////////////////////////////////////

module ALU(
    input_1,
    input_2,
    ALUcontrol,
    Zero,
    result
    );

    input [31:0] input_1,input_2;
    input [3:0] ALUcontrol;
    output Zero;
    output [31:0] result;

    reg signed [31:0] in_1,in_2,result;
    reg Zero;

    always @(*) begin

        in_1 = input_1;
        in_2 = input_2;
        Zero = 0;

        case(ALUcontrol)

            4'b0000:begin //AND
                result = in_1 & in_2;
            end

            4'b0001:begin //OR
                result = in_1 | in_2;
            end

            4'b0010:begin // ADD,SW,LW
                result = in_1 + in_2;
            end

            4'b0110:begin //SUB,BEQ
                result = in_1 - in_2;
                if(result == 32'b0) Zero = 1;
                else Zero = 0;
            end

            4'b1000:begin //SLT
                if (in_1 < in_2) result = 32'b1;
                else result = 32'b0;
            end

            default begin
                result = 0;
            end
        endcase
    end


endmodule

//////////////////////////////////////////////////////

module register_file(
    Clk  ,
    Rst  ,
    WEN  ,
    RW   ,
    busW ,
    RX   ,
    RY   ,
    busX ,
    busY
);
input        Clk, Rst, WEN;
input  [4:0] RW, RX, RY;
input  [31:0] busW;
output [31:0] busX, busY;
    
// write your design here, you can delcare your own wires and regs. 
// The code below is just an eaxmple template
reg [31:0] r0_w, r1_w, r2_w, r3_w, r4_w, r5_w, r6_w, r7_w;
reg [31:0] r0_r, r1_r, r2_r, r3_r, r4_r, r5_r, r6_r, r7_r;
reg [31:0] r8_w, r9_w, r10_w, r11_w, r12_w, r13_w, r14_w, r15_w;
reg [31:0] r8_r, r9_r, r10_r, r11_r, r12_r, r13_r, r14_r, r15_r;
reg [31:0] r16_w, r17_w, r18_w, r19_w, r20_w, r21_w, r22_w, r23_w;
reg [31:0] r16_r, r17_r, r18_r, r19_r, r20_r, r21_r, r22_r, r23_r;
reg [31:0] r24_w, r25_w, r26_w, r27_w, r28_w, r29_w, r30_w, r31_w;
reg [31:0] r24_r, r25_r, r26_r, r27_r, r28_r, r29_r, r30_r, r31_r;

reg [31:0] busX, busY;
    
always@(*) begin

    r0_r = 0;
    r0_w = 0;

    if(WEN) begin

        r0_w = 7'b0;
        r1_w = r1_r;
        r2_w = r2_r;
        r3_w = r3_r;
        r4_w = r4_r;
        r5_w = r5_r;
        r6_w = r6_r;
        r7_w = r7_r;
        r8_w = r8_r;
        r9_w = r9_r;
        r10_w = r10_r;
        r11_w = r11_r;
        r12_w = r12_r;
        r13_w = r13_r;
        r14_w = r14_r;
        r15_w = r15_r;
        r16_w = r16_r;
        r17_w = r17_r;
        r18_w = r18_r;
        r19_w = r19_r;
        r20_w = r20_r;
        r21_w = r21_r;
        r22_w = r22_r;
        r23_w = r23_r;
        r24_w = r24_r;
        r25_w = r25_r;
        r26_w = r26_r;
        r27_w = r27_r;
        r28_w = r28_r;
        r29_w = r29_r;
        r30_w = r30_r;
        r31_w = r31_r;
        
        case(RW)

            5'b00000: r0_w = 7'b0;
            5'b00001: r1_w = busW;
            5'b00010: r2_w = busW;
            5'b00011: r3_w = busW;
            5'b00100: r4_w = busW;
            5'b00101: r5_w = busW;
            5'b00110: r6_w = busW;
            5'b00111: r7_w = busW;
            5'b01000: r8_w = busW;
            5'b01001: r9_w = busW;
            5'b01010: r10_w = busW;
            5'b01011: r11_w = busW;
            5'b01100: r12_w = busW;
            5'b01101: r13_w = busW;
            5'b01110: r14_w = busW;
            5'b01111: r15_w = busW;
            5'b10000: r16_w = busW;
            5'b10001: r17_w = busW;
            5'b10010: r18_w = busW;
            5'b10011: r19_w = busW;
            5'b10100: r20_w = busW;
            5'b10101: r21_w = busW;
            5'b10110: r22_w = busW;
            5'b10111: r23_w = busW;
            5'b11000: r24_w = busW;
            5'b11001: r25_w = busW;
            5'b11010: r26_w = busW;
            5'b11011: r27_w = busW;
            5'b11100: r28_w = busW;
            5'b11101: r29_w = busW;
            5'b11110: r30_w = busW;
            5'b11111: r31_w = busW;
            
        endcase
    end

    else begin

        r0_w = r0_r;
        r1_w = r1_r;
        r2_w = r2_r;
        r3_w = r3_r;
        r4_w = r4_r;
        r5_w = r5_r;
        r6_w = r6_r;
        r7_w = r7_r;
        r8_w = r8_r;
        r9_w = r9_r;
        r10_w = r10_r;
        r11_w = r11_r;
        r12_w = r12_r;
        r13_w = r13_r;
        r14_w = r14_r;
        r15_w = r15_r;
        r16_w = r16_r;
        r17_w = r17_r;
        r18_w = r18_r;
        r19_w = r19_r;
        r20_w = r20_r;
        r21_w = r21_r;
        r22_w = r22_r;
        r23_w = r23_r;
        r24_w = r24_r;
        r25_w = r25_r;
        r26_w = r26_r;
        r27_w = r27_r;
        r28_w = r28_r;
        r29_w = r29_r;
        r30_w = r30_r;
        r31_w = r31_r;

    end

    case(RX)

        5'b00000: busX = r0_r;
        5'b00001: busX = r1_r;
        5'b00010: busX = r2_r;
        5'b00011: busX = r3_r;
        5'b00100: busX = r4_r;
        5'b00101: busX = r5_r;
        5'b00110: busX = r6_r;
        5'b00111: busX = r7_r;
        5'b01000: busX = r8_r;
        5'b01001: busX = r9_r;
        5'b01010: busX = r10_r;
        5'b01011: busX = r11_r;
        5'b01100: busX = r12_r;
        5'b01101: busX = r13_r;
        5'b01110: busX = r14_r;
        5'b01111: busX = r15_r;
        5'b10000: busX = r16_r;
        5'b10001: busX = r17_r;
        5'b10010: busX = r18_r;
        5'b10011: busX = r19_r;
        5'b10100: busX = r20_r;
        5'b10101: busX = r21_r;
        5'b10110: busX = r22_r;
        5'b10111: busX = r23_r;
        5'b11000: busX = r24_r;
        5'b11001: busX = r25_r;
        5'b11010: busX = r26_r;
        5'b11011: busX = r27_r;
        5'b11100: busX = r28_r;
        5'b11101: busX = r29_r;
        5'b11110: busX = r30_r;
        5'b11111: busX = r31_r;

    endcase

    case(RY)

        5'b00000: busY = r0_r;
        5'b00001: busY = r1_r;
        5'b00010: busY = r2_r;
        5'b00011: busY = r3_r;
        5'b00100: busY = r4_r;
        5'b00101: busY = r5_r;
        5'b00110: busY = r6_r;
        5'b00111: busY = r7_r;
        5'b01000: busY = r8_r;
        5'b01001: busY = r9_r;
        5'b01010: busY = r10_r;
        5'b01011: busY = r11_r;
        5'b01100: busY = r12_r;
        5'b01101: busY = r13_r;
        5'b01110: busY = r14_r;
        5'b01111: busY = r15_r;
        5'b10000: busY = r16_r;
        5'b10001: busY = r17_r;
        5'b10010: busY = r18_r;
        5'b10011: busY = r19_r;
        5'b10100: busY = r20_r;
        5'b10101: busY = r21_r;
        5'b10110: busY = r22_r;
        5'b10111: busY = r23_r;
        5'b11000: busY = r24_r;
        5'b11001: busY = r25_r;
        5'b11010: busY = r26_r;
        5'b11011: busY = r27_r;
        5'b11100: busY = r28_r;
        5'b11101: busY = r29_r;
        5'b11110: busY = r30_r;
        5'b11111: busY = r31_r;

    endcase

end

always @(posedge Clk) begin

    if (!Rst)
    begin
        r0_r <= 32'b0;
        r1_r <= 32'b0;
        r2_r <= 32'b0;
        r3_r <= 32'b0;
        r4_r <= 32'b0;
        r5_r <= 32'b0;
        r6_r <= 32'b0;
        r7_r <= 32'b0;
        r8_r <= 32'b0;
        r9_r <= 32'b0;
        r10_r <= 32'b0;
        r11_r <= 32'b0;
        r12_r <= 32'b0;
        r13_r <= 32'b0;
        r14_r <= 32'b0;
        r15_r <= 32'b0;
        r16_r <= 32'b0;
        r17_r <= 32'b0;
        r18_r <= 32'b0;
        r19_r <= 32'b0;
        r20_r <= 32'b0;
        r21_r <= 32'b0;
        r22_r <= 32'b0;
        r23_r <= 32'b0;
        r24_r <= 32'b0;
        r25_r <= 32'b0;
        r26_r <= 32'b0;
        r27_r <= 32'b0;
        r28_r <= 32'b0;
        r29_r <= 32'b0;
        r30_r <= 32'b0;
        r31_r <= 32'b0;
    end
    
    else begin

        r0_r <= r0_w ;
        r1_r <= r1_w ;
        r2_r <= r2_w ;
        r3_r <= r3_w ;
        r4_r <= r4_w ;
        r5_r <= r5_w ;
        r6_r <= r6_w ;
        r7_r <= r7_w ; 
        r8_r <= r8_w ;
        r9_r <= r9_w ;
        r10_r <= r10_w ;
        r11_r <= r11_w ;
        r12_r <= r12_w ;
        r13_r <= r13_w ;
        r14_r <= r14_w ;
        r15_r <= r15_w ;
        r16_r <= r16_w ;
        r17_r <= r17_w ;
        r18_r <= r18_w ;
        r19_r <= r19_w ;
        r20_r <= r20_w ;
        r21_r <= r21_w ;
        r22_r <= r22_w ;
        r23_r <= r23_w ;
        r24_r <= r24_w ;
        r25_r <= r25_w ;
        r26_r <= r26_w ;
        r27_r <= r27_w ;
        r28_r <= r28_w ;
        r29_r <= r29_w ;
        r30_r <= r30_w ;
        r31_r <= r31_w ;

    end 
end	

endmodule


module ALU_control(
    ALUcontrol,
    func3,
    func7,
    alu_ctrl2  
);
input  [2:0] func3;       
input  func7;
input  [1:0] alu_ctrl2;
output [3:0] ALUcontrol;


assign ALUcontrol[0] = alu_ctrl2[1] & func3[2] & func3[1] & (!func3[0]);
assign ALUcontrol[1] = !(alu_ctrl2[1] & (!alu_ctrl2[0]) & func3[1]);
assign ALUcontrol[2] = ((!alu_ctrl2[1]) & (!func3[1])) | (func7 & alu_ctrl2[1]);
assign ALUcontrol[3] = alu_ctrl2[1] & (!func3[2]) & func3[1];

endmodule

module Control(
    instruction,
    jalr,
    jal,
    branch,
    memread,
    memtoreg,
    aluop,
    memwrite,
    alusrc,
    regwrite,
    instruc_out
);
input  [31:0] instruction;       
output [1:0] aluop;
output jalr,jal,branch,memread,memtoreg,memwrite,alusrc,regwrite;
output [31:0] instruc_out;

reg [1:0] aluop;
reg [31:0] instruc_out; 
reg jalr,jal,branch,memread,memtoreg,memwrite,alusrc,regwrite; 

always @(*) begin

case(instruction[6:0])

        7'b0110011:  //Rtype: ADD, SUB, AND, OR, SLT
        begin 
            jalr = 0;
            jal = 0;
            branch = 0;
            memread = 0;
            memtoreg = 0;
            memwrite = 0;
            alusrc = 0;
            regwrite = 1;
            aluop = 2'b10;
            instruc_out = 32'b0;
        end     

        7'b1101111:  //JAL
        begin
            jalr = 0;
            jal = 1;
            branch = 0;
            memread = 0;
            memtoreg = 1;
            memwrite = 0;
            alusrc = 1;
            regwrite = 1;
            aluop = 2'b00;
            instruc_out = {{12{instruction[31]}},instruction[19:12],instruction[20],instruction[30:25],instruction[24:21],1'b0};
        end

        7'b1100111:  //JALR
        begin
            jalr = 1;
            jal = 0;
            branch = 0;
            memread = 0;
            memtoreg = 1;
            memwrite = 0;
            alusrc = 1;
            regwrite = 1;
            aluop = 2'b00;
            instruc_out = {{21{instruction[31]}},instruction[30:20]};
        end

        7'b1100011:  //BEQ
        begin
            jalr = 0;
            jal = 0;
            branch = 1;
            memread = 0;
            memtoreg = 0;
            memwrite = 0;
            alusrc = 0;
            regwrite = 0;
            aluop = 2'b01; 
            instruc_out = {{20{instruction[31]}},instruction[7],instruction[30:25],instruction[11:8],1'b0};     
        end
        
        7'b0000011:  //LW
        begin
            jalr = 0;
            jal = 0;
            branch = 0;
            memread = 1;
            memtoreg = 1;
            memwrite = 0;
            alusrc = 1;
            regwrite = 1;
            aluop = 2'b0;
            instruc_out = {{21{instruction[31]}},instruction[30:20]};
        end
        
        7'b0100011:  //SW
        begin
            jalr = 0;
            jal = 0;
            branch = 0;
            memread = 0;
            memtoreg = 0;
            memwrite = 1;
            alusrc = 1;
            regwrite = 0;
            aluop = 2'b0;
            instruc_out = {{21{instruction[31]}},instruction[30:25],instruction[11:8],instruction[7]};
        end

        default:
        begin
            jalr = 0;
            jal = 0;
            branch = 0;
            memread = 0;
            memtoreg = 0;
            memwrite = 0;
            alusrc = 0;
            regwrite = 0;
            aluop = 2'b0;
            instruc_out = 32'b0;
        end  
    endcase

    end

endmodule

