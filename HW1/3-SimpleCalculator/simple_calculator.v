module simple_calculator(
    Clk,
    WEN,
    RW,
    RX,
    RY,
    DataIn,
    Sel,
    Ctrl,
    busY,
    Carry
);

    input        Clk;
    input        WEN;
    input  [2:0] RW, RX, RY;
    input  [7:0] DataIn;
    input        Sel;
    input  [3:0] Ctrl;
    output [7:0] busY;
    output       Carry;

// declaration of wire/reg
wire [7:0] alu_out;   
wire [7:0] mux_in;
wire [7:0] mux_out;

// submodule instantiation
register_file res(.Clk(Clk),.WEN(WEN),.RW(RW),.busW(alu_out),.RX(RX),.RY(RY),.busX(mux_in),.busY(busY));
alu_assign alu(.ctrl(Ctrl),.x(mux_out),.y(busY),.carry(Carry),.out(alu_out));

assign mux_out = (Sel)? mux_in:DataIn;
    
endmodule

module alu_assign(
    ctrl,
    x,
    y,
    carry,
    out  
);
    
    input  [3:0] ctrl;
    input  [7:0] x;
    input  [7:0] y;
    output       carry;
    output [7:0] out;

    wire [8:0] out_add,out_sub;

    add adder(.x(x),.y(y),.out(out_add));
    sub subtract(.x(x),.y(y),.out(out_sub));

    assign carry = (ctrl == 4'b0000) ? out_add[8]:
                   (ctrl == 4'b0001) ? out_sub[8]:1'b0;

    assign out = (ctrl == 4'b0000) ? out_add[7:0]:
                 (ctrl == 4'b0001) ? out_sub[7:0]:
                 (ctrl == 4'b0010) ? x&y:
                 (ctrl == 4'b0011) ? x|y:
                 (ctrl == 4'b0100) ? ~x:
                 (ctrl == 4'b0101) ? x^y:
                 (ctrl == 4'b0110) ? ~(x|y):
                 (ctrl == 4'b0111) ? y<<x[2:0]:
                 (ctrl == 4'b1000) ? y>>x[2:0]:
                 (ctrl == 4'b1001) ? {x[7],x[7:1]}:
                 (ctrl == 4'b1010) ? {x[6:0],x[7]}:
                 (ctrl == 4'b1011) ? {x[0],x[7:1]}:
                 (ctrl == 4'b1100) ? x==y:8'b00000000;
                
                   
endmodule


module add(
    x,
    y,
    out  
);
    
    input  [7:0] x;
    input  [7:0] y;
    output [8:0] out ;
    wire [8:0] signed_x,signed_y;
    assign signed_x = {x[7],x[7:0]};
    assign signed_y = {y[7],y[7:0]};
    assign out = signed_x + signed_y;

endmodule

module sub(
    x,
    y,
    out  
);
    
    input  [7:0] x;
    input  [7:0] y;
    output [8:0] out;
    wire [8:0] signed_x,signed_y;
    assign signed_x = {x[7],x[7:0]};
    assign signed_y = {y[7],y[7:0]};
    assign out = signed_x - signed_y;

endmodule


module register_file(
    Clk  ,
    WEN  ,
    RW   ,
    busW ,
    RX   ,
    RY   ,
    busX ,
    busY
);
input        Clk, WEN;
input  [2:0] RW, RX, RY;
input  [7:0] busW;
output [7:0] busX, busY;
    
// write your design here, you can delcare your own wires and regs. 
// The code below is just an eaxmple template
reg [7:0] r0, r1, r2, r3, r4, r5, r6, r7;





/*   
always@(*) begin
    r0_w <= 8'b00000000;
end
*/

always@(posedge Clk) begin
    if(WEN) begin
        case(RW)
            3'b000: r0 = 8'b0;
            3'b001: r1 = busW; 
            3'b010: r2 = busW;
            3'b011: r3 = busW;
            3'b100: r4 = busW;
            3'b101: r5 = busW;
            3'b110: r6 = busW;
            3'b111: r7 = busW;
        endcase
    end
end

assign busX = (RX==3'b0)?8'b0:
              (RX==3'b001)?r1:
              (RX==3'b010)?r2:
              (RX==3'b011)?r3:
              (RX==3'b100)?r4:
              (RX==3'b101)?r5:
              (RX==3'b110)?r6:
              (RX==3'b111)?r7:8'b0;

assign busY = (RY==3'b0)?8'b0:
              (RY==3'b001)?r1:
              (RY==3'b010)?r2:
              (RY==3'b011)?r3:
              (RY==3'b100)?r4:
              (RY==3'b101)?r5:
              (RY==3'b110)?r6:
              (RY==3'b111)?r7:8'b0;
              



endmodule



