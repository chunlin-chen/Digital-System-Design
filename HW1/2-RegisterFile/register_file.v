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



