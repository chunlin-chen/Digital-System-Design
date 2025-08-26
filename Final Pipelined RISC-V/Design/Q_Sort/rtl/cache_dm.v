module cache_I(
    clk,
    proc_reset,
    proc_read,
    proc_write,
    proc_addr,
    proc_rdata,
    proc_wdata,
    proc_stall,
    mem_read,
    mem_write,
    mem_addr,
    mem_rdata,
    mem_wdata,
    mem_ready
);
    
//==== input/output definition ============================
    input              clk;
    // processor interface
    input              proc_reset;
    input              proc_read, proc_write;
    input       [29:0] proc_addr;
    input       [31:0] proc_wdata;
    output  reg        proc_stall;
    output  reg [31:0] proc_rdata;
    // memory interface
    input      [127:0] mem_rdata;
    input              mem_ready;
    output             mem_read, mem_write;
    output      [27:0] mem_addr;
    output     [127:0] mem_wdata;
    
//==== state definition ===================================
    parameter READY = 1'b0; 
    parameter MISS  = 1'b1; 

//==== wire/reg definition ================================
    reg          valid;
    reg          mem_ready_r;
    reg          mem_read_w, mem_read_r;
    reg  [27:0]  mem_addr_w, mem_addr_r;
    reg          state_w, state_r;
    reg  [127:0] cache_w[0:7], cache_r[0:7];
    // reg          valid_w[0:7], valid_r[0:7];
    reg  [24:0]  tag_w[0:7], tag_r[0:7];
    wire [2:0]   index;
    wire [127:0] data;
    // wire         valid;
    wire [24:0]  tag;
    wire         hit;
    integer i;

//==== combinational circuit ==============================
assign mem_read = mem_read_r;
assign mem_write = 1'b0;
assign mem_wdata = 128'b0;
assign index = proc_addr[4:2];
assign {tag, data} = {tag_r[index], cache_r[index]};
assign hit = (tag == proc_addr[29:5]);
assign mem_addr = mem_addr_r;
// assign mem_addr = dirty ? {tag, index} : proc_addr[29:2];

always @(*) begin
    case(proc_addr[1:0])
        2'b00: proc_rdata = data[31:0];
        2'b01: proc_rdata = data[63:32];
        2'b10: proc_rdata = data[95:64];
        2'b11: proc_rdata = data[127:96];
    endcase
end

always @(*) begin
    state_w = state_r;
    mem_read_w = mem_read_r;
    mem_addr_w = mem_addr_r;
    proc_stall = 1'b1;
    case(state_r)
        READY: begin
            if(hit || !valid) proc_stall = 1'b0;
            else begin
                state_w = MISS;
                mem_read_w = 1'b1;
                mem_addr_w = proc_addr[29:2];
            end
        end
        MISS: begin
            mem_read_w = mem_read_r & !mem_ready;
            if(mem_ready_r) begin
                state_w = READY;
            end
        end
    endcase
end

always @(*) begin
    for(i=0;i<8;i=i+1) begin
        cache_w[i] = cache_r[i];
        // valid_w[i] = valid_r[i];
        tag_w[i] = tag_r[i];
    end
    case(state_r)
        MISS: begin
            if(mem_ready_r) begin
                cache_w[index] = mem_rdata;
                // valid_w[index] = 1'b1;
                tag_w[index] = mem_addr[27:3];
            end
        end
    endcase
end
//==== sequential circuit =================================
always@( posedge clk ) begin
    if( proc_reset ) begin
        valid <= 1'b0;
        mem_ready_r <= 1'b0;
        state_r <= READY;
        mem_read_r <= 1'b0;
        mem_addr_r <= 28'b0;
        for(i=0;i<8;i=i+1) begin
            cache_r[i] <= 128'b0;
            // valid_r[i] <= 1'b0;
            tag_r[i] <= 25'h1ffffff;
        end
    end
    else begin
        valid <= 1'b1;
        mem_ready_r <= mem_ready;
        state_r <= state_w;
        mem_read_r <= mem_read_w;
        mem_addr_r <= mem_addr_w;
        for(i=0;i<8;i=i+1) begin
            cache_r[i] <= cache_w[i];
            // valid_r[i] <= valid_w[i];
            tag_r[i] <= tag_w[i];
        end
    end
end

endmodule
