module BPU(
    input clk, 
    input rst_n, 
    input stall, 
    input PreWrong,
    input B, 
    output BrPre
);

/*
0: strong not taken
1: weak not taken
2: weak taken
3: strong taken
*/
reg [1:0] pattern_w, pattern_r;
reg valid_w, valid_r;
/*
reg [1:0] pattern0_w, pattern0_r;
reg [1:0] pattern1_w, pattern1_r;
reg [1:0] pattern2_w, pattern2_r;
reg [1:0] pattern3_w, pattern3_r;
*/

assign BrPre = (B & !PreWrong) ? pattern_r[1] : 1'b0;

always @(*) begin
    valid_w = valid_r;
    if(!stall) begin
        if(B) valid_w = 1'b1;
        else valid_w = 1'b0;
    end
end

always @(*) begin
    pattern_w = pattern_r;
    if(valid_r & !stall)
        case(pattern_r) 
            2'b00: begin
                if(PreWrong) pattern_w = 2'b01;
                else pattern_w = 2'b00;
            end
            2'b01:begin
                if(PreWrong) pattern_w = 2'b10;
                else pattern_w = 2'b00;

            end
            2'b10:begin
                if(PreWrong) pattern_w = 2'b01;
                else pattern_w = 2'b11;
            end
            2'b11:begin
                if(PreWrong) pattern_w = 2'b10;
                else pattern_w = 2'b11;
            end
        endcase
end


always @(posedge clk) begin
    if(!rst_n) begin
        valid_r <= 1'b0;
        pattern_r <= 2'b0;
    end
    else begin
        valid_r <= valid_w;
        pattern_r <= pattern_w;
    end
end
endmodule