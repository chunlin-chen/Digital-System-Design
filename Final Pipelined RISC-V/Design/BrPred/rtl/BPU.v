module BPU(
    input clk, 
    input rst_n, 
    input stall, 
    input PreWrong,
    input B, 
    output BrPre
);

reg [2:0] history_w, history_r;
reg pattern_w[0:3], pattern_r[0:3];
wire [1:0] term;
integer i;

assign term = PreWrong ? history_r[1:0] : history_r[2:1];
assign BrPre = (B & !PreWrong) ? pattern_r[term] : 1'b0;

always @(*) begin
    history_w = history_r;
    for (i=0; i<4; i=i+1)
        pattern_w[i] = pattern_r[i];

    if(PreWrong & !stall) begin
        history_w = {~history_r[2], history_r[1:0]};
        pattern_w[term] = ~history_r[2];
    end
    else if(B & !stall) history_w = {BrPre, history_r[2:1]};
end

always @(posedge clk) begin
    if(!rst_n) begin
        history_r <= 3'b0;
        for (i=0; i<4; i=i+1)
            pattern_r[i] <= 1'b0;
    end
    else begin
        history_r <= history_w;
        for (i=0; i<4; i=i+1)
            pattern_r[i] <= pattern_w[i];
    end
end
endmodule