module cache_D(
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
    output  reg        mem_read, mem_write;
    output      [27:0] mem_addr;
    output     [127:0] mem_wdata;
    
//==== state definition ===================================
    parameter READY = 2'd0; 
    parameter WRITE = 2'd1; 
    parameter READ  = 2'd2; 

//==== wire/reg definition ================================
    reg          mem_ready_r;
    reg  [1:0]   state_w, state_r;
    reg  [255:0] cache_w[0:3], cache_r[0:3];
    reg  [1:0]   valid_w[0:3], valid_r[0:3];
    reg  [1:0]   dirty_w[0:3], dirty_r[0:3];
    reg  [51:0]  tag_w[0:3], tag_r[0:3];
    reg          lru_w[0:3], lru_r[0:3];
    wire [1:0]   index;
    wire [255:0] data;
    wire [1:0]   valid;
    wire         dirty;
    wire [51:0]  tag;
    wire         lru;
    wire         hit1, hit0;
    wire         hit;
    integer i;

//==== combinational circuit ==============================
assign index = proc_addr[3:2];
assign {valid, dirty, tag, data, lru} = {valid_r[index], dirty_r[index][lru], tag_r[index], cache_r[index], lru_r[index]};
assign hit1 = (tag[51:26] == proc_addr[29:4]) && valid[1];
assign hit0 = (tag[25:0] == proc_addr[29:4]) && valid[0];
assign hit = hit1 || hit0;
assign mem_addr = dirty ? (lru ? {tag[51:26], index} : {tag[25:0], index}) : proc_addr[29:2];
assign mem_wdata = lru ? data[255:128] : data[127:0];

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
    mem_write = 1'b0;
    proc_stall = 1'b1;
    case(state_r)
        READY: begin
            proc_stall = 1'b0;
            if(proc_read || proc_write) begin
                if(!hit) begin
                    proc_stall = 1'b1;
                    if(dirty) begin
                        state_w = WRITE;
                        mem_write = 1'b1;
                    end
                    else begin
                        state_w = READ;
                        mem_read = 1'b1;
                    end
                end
            end
        end
        WRITE: begin
            mem_write = 1'b1;
            if(mem_ready_r) begin
                state_w = READ;
                mem_write = 1'b0;
                mem_read = 1'b1;
            end
        end
        READ: begin
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
        valid_w[i] = valid_r[i];
        dirty_w[i] = dirty_r[i];
        tag_w[i] = tag_r[i];
        lru_w[i] = lru_r[i];
    end
    case(state_r)
        READY: begin
            if(hit) begin
                case(hit1)
                    1'b0: begin
                        lru_w[index] = 1'b1;
                        if(proc_write) begin
                            dirty_w[index][0] = 1'b1;
                            case(proc_addr[1:0])
                                2'b00: cache_w[index] = {data[255:128], data[127:96], data[95:64], data[63:32], proc_wdata};
                                2'b01: cache_w[index] = {data[255:128], data[127:96], data[95:64], proc_wdata , data[31:0]};
                                2'b10: cache_w[index] = {data[255:128], data[127:96], proc_wdata , data[63:32], data[31:0]};
                                2'b11: cache_w[index] = {data[255:128], proc_wdata  , data[95:64], data[63:32], data[31:0]};
                            endcase
                        end
                    end
                    1'b1: begin
                        lru_w[index] = 1'b0;
                        if(proc_write) begin
                            dirty_w[index][1] = 1'b1;
                            case(proc_addr[1:0])
                                2'b00: cache_w[index] = {data[255:224], data[223:192], data[191:160], proc_wdata   , data[127:0]};
                                2'b01: cache_w[index] = {data[255:224], data[223:192], proc_wdata   , data[159:128], data[127:0]};
                                2'b10: cache_w[index] = {data[255:224], proc_wdata   , data[191:160], data[159:128], data[127:0]};
                                2'b11: cache_w[index] = {proc_wdata   , data[223:192], data[191:160], data[159:128], data[127:0]};
                            endcase
                        end
                    end
                endcase
            end
        end
        WRITE: begin
            if(mem_ready) begin
                valid_w[index][lru] = 1'b0;
                dirty_w[index][lru] = 1'b0;
            end
        end
        READ: begin
            if(mem_ready) begin
                valid_w[index][lru] = 1'b1;
                // lru_w[index] = ~lru_r[index];
                if(lru) begin
                    cache_w[index][255:128] = mem_rdata;
                    tag_w[index][51:26] = mem_addr[27:2];
                end
                else begin
                    cache_w[index][127:0] = mem_rdata;
                    tag_w[index][25:0] = mem_addr[27:2];
                end
            end
        end
    endcase
end
//==== sequential circuit =================================
always@( posedge clk ) begin
    if( proc_reset ) begin
        mem_ready_r <= 1'b0;
        state_r <= READY;
        for(i=0;i<4;i=i+1) begin
            cache_r[i] <= 128'b0;
            valid_r[i] <= 1'b0;
            dirty_r[i] <= 1'b0;
            tag_r[i] <= 25'b0;
            lru_r[i] <= 1'b0;
        end
    end
    else begin
        mem_ready_r <= mem_ready;
        state_r <= state_w;
        for(i=0;i<4;i=i+1) begin
            cache_r[i] <= cache_w[i];
            valid_r[i] <= valid_w[i];
            dirty_r[i] <= dirty_w[i];
            tag_r[i] <= tag_w[i];
            lru_r[i] <= lru_w[i];
        end
    end
end

endmodule
