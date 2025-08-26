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
    output  reg        mem_read;
    output             mem_write;
    output      [27:0] mem_addr;
    output     [127:0] mem_wdata;
    
//==== state definition ===================================
    parameter READY = 1'b0; 
    parameter MISS  = 1'b1; 

//==== wire/reg definition ================================
    reg  [27:0]  mem_addr_w, mem_addr_r;
    reg          state_w, state_r;
    reg  [255:0] cache_w[0:3], cache_r[0:3];
    // reg  [1:0]   valid_w[0:3], valid_r[0:3];
    reg  [51:0]  tag_w[0:3], tag_r[0:3];
    reg          lru_w[0:3], lru_r[0:3];
    wire [1:0]   index;
    wire [255:0] data;
    // wire [1:0]   valid;
    wire [51:0]  tag;
    wire         lru;
    wire         hit1, hit0;
    wire         hit;
    integer i;

//==== combinational circuit ==============================
assign mem_write = 1'b0;
assign mem_wdata = 128'b0;
assign index = proc_addr[3:2];
assign tag = tag_r[index];
assign data = cache_r[index];
assign lru = lru_r[index];
// assign {tag, data, lru} = {tag_r[index], cache_r[index], lru_r[index]};
assign hit1 = (tag[51:26] == proc_addr[29:4]);
assign hit0 = (tag[25:0] == proc_addr[29:4]);
assign hit = hit1 || hit0;
assign mem_addr = mem_addr_r;
// assign mem_addr = dirty ? (lru ? {tag[51:26], index} : {tag[25:0], index}) : proc_addr[29:2];

always @(*) begin
    case(hit1)
        1'b0: begin
            case(proc_addr[1:0])
                2'b00: proc_rdata = data[31:0];
                2'b01: proc_rdata = data[63:32];
                2'b10: proc_rdata = data[95:64];
                2'b11: proc_rdata = data[127:96];
            endcase
        end
        1'b1: begin
            case(proc_addr[1:0])
                2'b00: proc_rdata = data[159:128];
                2'b01: proc_rdata = data[191:160];
                2'b10: proc_rdata = data[223:192];
                2'b11: proc_rdata = data[255:224];
            endcase
        end
    endcase
end

always @(*) begin
    state_w = state_r;
    mem_read = 1'b0;
    mem_addr_w = mem_addr_r;
    proc_stall = 1'b1;
    case(state_r)
        READY: begin
            if(hit || !proc_read) proc_stall = 1'b0;
            else begin
                    state_w = MISS;
                    mem_read = 1'b1;
                    mem_addr_w = proc_addr[29:2];
            end
        end
        MISS: begin
            mem_read = 1'b1;
            if(mem_ready) begin
                state_w = READY;
                mem_read = 1'b0;
            end
        end
    endcase
end

always @(*) begin
    for(i=0;i<4;i=i+1) begin
        cache_w[i] = cache_r[i];
        // valid_w[i] = valid_r[i];
        tag_w[i] = tag_r[i];
        lru_w[i] = lru_r[i];
    end
    case(state_r)
        READY: begin
            if(hit) lru_w[index] = hit1 ? 1'b0 : 1'b1;
        end
        MISS: begin
            if(mem_ready) begin
                // valid_w[index][lru] = 1'b1;
                if(lru) begin
                    cache_w[index][255:128] = mem_rdata;
                    tag_w[index][51:26] = proc_addr[29:4];
                end
                else begin
                    cache_w[index][127:0] = mem_rdata;
                    tag_w[index][25:0] = proc_addr[29:4];
                end
            end
        end
    endcase
end
//==== sequential circuit =================================
always@( posedge clk ) begin
    if( proc_reset ) begin
        state_r <= READY;
        mem_addr_r <= 28'b0;
        for(i=0;i<4;i=i+1) begin
            cache_r[i] <= 256'b0;
            // valid_r[i] <= 1'b0;
            tag_r[i] <= 52'hf_ffff_ffff_ffff;
            lru_r[i] <= 1'b0;
        end
    end
    else begin
        state_r <= state_w;
        mem_addr_r <= mem_addr_w;
        for(i=0;i<4;i=i+1) begin
            cache_r[i] <= cache_w[i];
            // valid_r[i] <= valid_w[i];
            tag_r[i] <= tag_w[i];
            lru_r[i] <= lru_w[i];
        end
    end
end

endmodule
