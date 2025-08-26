//always block tb
`timescale 1ns/10ps
`define CYCLE	10
`define HCYCLE	5

module alu_always_tb;
    reg  [3:0] ctrl;
    reg  [7:0] x;
    reg  [7:0] y;
    wire       carry;
    wire [7:0] out;
    
    alu_always alu_always(
        ctrl     ,
        x        ,
        y        ,
        carry    ,
        out  
    );

   initial begin
       $fsdbDumpfile("alu_always.fsdb");
       $fsdbDumpvars;
   end

    initial begin
        ctrl = 4'b1101;
        x    = 8'd0;
        y    = 8'd0;
        
        #(`CYCLE);
        // 0100 boolean not
        x = 8'b1001_0110;
        y = 8'b0010_1101;
        ctrl = 4'b0000;
        #(`CYCLE);
        ctrl = 4'b0001;
        #(`CYCLE);
        ctrl = 4'b0010;
        #(`CYCLE);
        ctrl = 4'b0011;
        #(`CYCLE);
        ctrl = 4'b0100;
        #(`CYCLE);
        ctrl = 4'b0101;
        #(`CYCLE);
        ctrl = 4'b0110;
        #(`CYCLE);
        ctrl = 4'b0111;
        #(`CYCLE);
        ctrl = 4'b1000;
        #(`CYCLE);
        ctrl = 4'b1001;
        #(`CYCLE);
        ctrl = 4'b1010;
        #(`CYCLE);
        ctrl = 4'b1011;
        #(`CYCLE);
        ctrl = 4'b1100;
        #(`CYCLE);
        ctrl = 4'b1101;
        #(`CYCLE);
        ctrl = 4'b1110;
        #(`CYCLE);
        ctrl = 4'b1111;
        
        #(`HCYCLE);
        /*
        if( out == 8'b1111_1111 ) $display( "PASS --- 0100 boolean not" );
        else $display( "FAIL --- 0100 boolean not" );
        */
        
        // finish tb
        #(`CYCLE) $finish;
    end
endmodule
