`timescale 1ns/10ps
`define CYCLE  10
`define HCYCLE  5

module register_file_tb;
    // port declaration for design-under-test
    reg Clk, WEN;
    reg  [2:0] RW, RX, RY;
    reg  [7:0] busW;
    wire [7:0] busX, busY;
    
    // instantiate the design-under-test
    register_file rf(
        Clk  ,
        WEN  ,
        RW   ,
        busW ,
        RX   ,
        RY   ,
        busX ,
        busY
    );

    // write your test pattern here

    initial begin
       $fsdbDumpfile("register_file.fsdb");
       $fsdbDumpvars;
    end
    
    always#(`HCYCLE) Clk = ~Clk;
    
    initial begin
        
        busW = 8'b0;
        RW = 3'b0;
        RX = 3'b0;
        RY = 3'b0;
        WEN = 1'b0;
        Clk = 1'b0;
    

        #100;        

        WEN = 1'b1;
        busW = 8'b0110_0100;
        RW = 3'b011;
    

        #20;

        busW = 8'b1001_1110;
        RW = 3'b001;
      
    
        #10;

        WEN = 1'b0;
        RX  = 3'b011;
        RY  = 3'b001;

    #100$finish;
 
    end       
        
    

endmodule



