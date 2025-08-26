//RT �Vlevel (event-driven) 
module alu_always(
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
    
    reg [7:0] out;
    reg carry;

    always@(*) begin

    case(ctrl)      
    
        4'b0000: {carry,out} = $signed(x) + $signed(y);  
        4'b0001: {carry,out} = $signed(x) - $signed(y);      
        4'b0010: begin 
                 out = x&y; 
                 carry = 1'b0;
                 end
        4'b0011: begin 
                 out = x|y;  
                 carry = 1'b0;
                 end       
        4'b0100: begin 
                 out = ~x;  
                 carry = 1'b0;
                 end        
        4'b0101: begin 
                 out = x^y;
                 carry = 1'b0;
                 end      
        4'b0110: begin 
                 out = ~(x|y); 
                 carry = 1'b0;
                 end           
        4'b0111: begin 
                 out = (y<<x[2:0]); 
                 carry = 1'b0;
                 end   
        4'b1000: begin 
                 out = (y>>x[2:0]);  
                 carry = 1'b0;
                 end
        4'b1001: begin 
                 out = ({x[7],x[7:1]});  
                 carry = 1'b0;
                 end
        4'b1010: begin 
                 out = {x[6:0],x[7]};  
                 carry = 1'b0;
                 end
        4'b1011: begin 
                 out = {x[0],x[7:1]};  
                 carry = 1'b0;
                 end
        4'b1100: begin 
                 out = (x==y); 
                 carry = 1'b0;
                 end
        4'b1101: begin 
                 out = 8'b0;  
                 carry = 1'b0;
                 end
        4'b1110: begin 
                 out = 8'b0;  
                 carry = 1'b0;
                 end
        4'b1111: begin 
                 out = 8'b0;  
                 carry = 1'b0;
                 end
        default: begin 
                 out = 8'b0;  
                 carry = 1'b0;
                 end 
    endcase

    end
    

endmodule
