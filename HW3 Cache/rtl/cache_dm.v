module cache(
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
    input          clk;
    // processor interface
    input          proc_reset;
    input          proc_read, proc_write;
    input   [29:0] proc_addr;
    input   [31:0] proc_wdata;
    output         proc_stall;
    output  [31:0] proc_rdata;
    // memory interface
    input  [127:0] mem_rdata;
    input          mem_ready;
    output         mem_read, mem_write;
    output  [27:0] mem_addr;
    output [127:0] mem_wdata;

// Parameters
    // Definition of states
    parameter IDLE = 3'd0;
    parameter READ_STALL = 3'd1;
    parameter WRITE = 3'd2;
    parameter WRITE_HIT = 3'd3;
    parameter WRITE_MISS = 3'd4;
    parameter WRITE_MISS2 = 3'd5;
    parameter WRITE_MISS0 = 3'd6;
    parameter WRITE_MISS3 = 3'd7;
//==== wire/reg definition ================================
    reg [153:0] cache [7:0]; //1+25+128
    reg [153:0] cache_nxt [7:0]; //1+25+128
    reg hit;
    reg [2:0] state,next_state;
    reg [2:0] index;

    reg proc_stall_r;
    reg [31:0] proc_rdata_r;
    reg mem_read_r, mem_write_r;
    reg [27:0] mem_addr_r;
    reg [127:0] mem_wdata_r;
    reg [29:0] proc_addr_nxt;
    reg [31:0] proc_wdata_nxt;

//==== combinational circuit ==============================
always@(*) begin
    index = proc_addr[4:2];
    if((state==IDLE) && (proc_addr[29:5] == cache[index][152:128]) && (cache[index][153] == 1)) hit = 1;
    else hit = 0;

    if( proc_reset ) begin
        cache_nxt[0] = 0;
        cache_nxt[1] = 0;
        cache_nxt[2] = 0;
        cache_nxt[3] = 0;
        cache_nxt[4] = 0;
        cache_nxt[5] = 0;
        cache_nxt[6] = 0;
        cache_nxt[7] = 0;
    end
    else begin
        if(state == READ_STALL && mem_ready) begin
            case(index)
            0:begin
            
                cache_nxt[0][127:96] = mem_rdata[31:0];
                cache_nxt[0][95:64] = mem_rdata[63:32];
                cache_nxt[0][63:32] = mem_rdata[95:64];
                cache_nxt[0][31:0] = mem_rdata[127:96];
                cache_nxt[0][152:128] = proc_addr[29:5];
                cache_nxt[0][153] = cache[0][153];
                
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            
            1:begin
                cache_nxt[1][127:96] = mem_rdata[31:0];
                cache_nxt[1][95:64] = mem_rdata[63:32];
                cache_nxt[1][63:32] = mem_rdata[95:64];
                cache_nxt[1][31:0] = mem_rdata[127:96];
                cache_nxt[1][152:128] = proc_addr[29:5];
                cache_nxt[1][153] = cache[1][153];
                cache_nxt[0] = cache[0];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            2:begin
                cache_nxt[2][127:96] = mem_rdata[31:0];
                cache_nxt[2][95:64] = mem_rdata[63:32];
                cache_nxt[2][63:32] = mem_rdata[95:64];
                cache_nxt[2][31:0] = mem_rdata[127:96];
                cache_nxt[2][152:128] = proc_addr[29:5];
                cache_nxt[2][153] = cache[2][153];
                cache_nxt[1] = cache[1];
                cache_nxt[0] = cache[0];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
        
            3:begin
                cache_nxt[3][127:96] = mem_rdata[31:0];
                cache_nxt[3][95:64] = mem_rdata[63:32];
                cache_nxt[3][63:32] = mem_rdata[95:64];
                cache_nxt[3][31:0] = mem_rdata[127:96];
                cache_nxt[3][152:128] = proc_addr[29:5];
                cache_nxt[3][153] = cache[3][153];
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[0] = cache[0];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            4:begin
                cache_nxt[4][127:96] = mem_rdata[31:0];
                cache_nxt[4][95:64] = mem_rdata[63:32];
                cache_nxt[4][63:32] = mem_rdata[95:64];
                cache_nxt[4][31:0] = mem_rdata[127:96];
                cache_nxt[4][152:128] = proc_addr[29:5];
                cache_nxt[4][153] = cache[4][153];
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[0] = cache[0];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            5:begin
                cache_nxt[5][127:96] = mem_rdata[31:0];
                cache_nxt[5][95:64] = mem_rdata[63:32];
                cache_nxt[5][63:32] = mem_rdata[95:64];
                cache_nxt[5][31:0] = mem_rdata[127:96];
                cache_nxt[5][152:128] = proc_addr[29:5];
                cache_nxt[5][153] = cache[5][153];
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[0] = cache[0];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            6:begin
                cache_nxt[6][127:96] = mem_rdata[31:0];
                cache_nxt[6][95:64] = mem_rdata[63:32];
                cache_nxt[6][63:32] = mem_rdata[95:64];
                cache_nxt[6][31:0] = mem_rdata[127:96];
                cache_nxt[6][152:128] = proc_addr[29:5];
                cache_nxt[6][153] = cache[6][153];
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[0] = cache[0];
                cache_nxt[7] = cache[7];
            end
            7:begin
                cache_nxt[7][127:96] = mem_rdata[31:0];
                cache_nxt[7][95:64] = mem_rdata[63:32];
                cache_nxt[7][63:32] = mem_rdata[95:64];
                cache_nxt[7][31:0] = mem_rdata[127:96];
                cache_nxt[7][152:128] = proc_addr[29:5];
                cache_nxt[7][153] = cache[7][153];
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[0] = cache[0];
            end
            default:begin
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
                cache_nxt[0] = cache[0];
            end
        endcase
        end

        else if(state==IDLE && ~proc_read && proc_write && hit) begin
            case(index)
            0:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[0][127:96] = proc_wdata;
                    cache_nxt[0][153:128] = cache[0][153:128];
                    cache_nxt[0][95:0] = cache[0][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[0][95:64] = proc_wdata;
                    cache_nxt[0][153:96] = cache[0][153:96];
                    cache_nxt[0][63:0] = cache[0][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[0][63:32] = proc_wdata;
                    cache_nxt[0][153:64] = cache[0][153:64];
                    cache_nxt[0][31:0] = cache[0][31:0];
                end
                else begin
                    cache_nxt[0][31:0] = proc_wdata;
                    cache_nxt[0][153:32] = cache[0][153:32];
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            1:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[1][127:96] = proc_wdata;
                    cache_nxt[1][153:128] = cache[1][153:128];
                    cache_nxt[1][95:0] = cache[1][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[1][95:64] = proc_wdata;
                    cache_nxt[1][153:96] = cache[1][153:96];
                    cache_nxt[1][63:0] = cache[1][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[1][63:32] = proc_wdata;
                    cache_nxt[1][153:64] = cache[1][153:64];
                    cache_nxt[1][31:0] = cache[1][31:0];
                end
                else begin
                    cache_nxt[1][31:0] = proc_wdata;
                    cache_nxt[1][153:32] = cache[1][153:32];
                end
                cache_nxt[0] = cache[0];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            2:begin
               if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[2][127:96] = proc_wdata;
                    cache_nxt[2][153:128] = cache[2][153:128];
                    cache_nxt[2][95:0] = cache[2][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[2][95:64] = proc_wdata;
                    cache_nxt[2][153:96] = cache[2][153:96];
                    cache_nxt[2][63:0] = cache[2][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[2][63:32] = proc_wdata;
                    cache_nxt[2][153:64] = cache[2][153:64];
                    cache_nxt[2][31:0] = cache[2][31:0];
                end
                else begin
                    cache_nxt[2][31:0] = proc_wdata;
                    cache_nxt[2][153:32] = cache[2][153:32];
                end
                cache_nxt[1] = cache[1];
                cache_nxt[0] = cache[0];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            3:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[3][127:96] = proc_wdata;
                    cache_nxt[3][153:128] = cache[3][153:128];
                    cache_nxt[3][95:0] = cache[3][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[3][95:64] = proc_wdata;
                    cache_nxt[3][153:96] = cache[3][153:96];
                    cache_nxt[3][63:0] = cache[3][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[3][63:32] = proc_wdata;
                    cache_nxt[3][153:64] = cache[3][153:64];
                    cache_nxt[3][31:0] = cache[3][31:0];
                end
                else begin
                    cache_nxt[3][31:0] = proc_wdata;
                    cache_nxt[3][153:32] = cache[3][153:32];
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[0] = cache[0];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            4:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[4][127:96] = proc_wdata;
                    cache_nxt[4][153:128] = cache[4][153:128];
                    cache_nxt[4][95:0] = cache[4][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[4][95:64] = proc_wdata;
                    cache_nxt[4][153:96] = cache[4][153:96];
                    cache_nxt[4][63:0] = cache[4][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[4][63:32] = proc_wdata;
                    cache_nxt[4][153:64] = cache[4][153:64];
                    cache_nxt[4][31:0] = cache[4][31:0];
                end
                else begin
                    cache_nxt[4][31:0] = proc_wdata;
                    cache_nxt[4][153:32] = cache[4][153:32];
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[0] = cache[0];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            5:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[5][127:96] = proc_wdata;
                    cache_nxt[5][153:128] = cache[5][153:128];
                    cache_nxt[5][95:0] = cache[5][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[5][95:64] = proc_wdata;
                    cache_nxt[5][153:96] = cache[5][153:96];
                    cache_nxt[5][63:0] = cache[5][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[5][63:32] = proc_wdata;
                    cache_nxt[5][153:64] = cache[5][153:64];
                    cache_nxt[5][31:0] = cache[5][31:0];
                end
                else begin
                    cache_nxt[5][31:0] = proc_wdata;
                    cache_nxt[5][153:32] = cache[5][153:32];
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[0] = cache[0];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            6:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[6][127:96] = proc_wdata;
                    cache_nxt[6][153:128] = cache[6][153:128];
                    cache_nxt[6][95:0] = cache[6][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[6][95:64] = proc_wdata;
                    cache_nxt[6][153:96] = cache[6][153:96];
                    cache_nxt[6][63:0] = cache[6][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[6][63:32] = proc_wdata;
                    cache_nxt[6][153:64] = cache[6][153:64];
                    cache_nxt[6][31:0] = cache[6][31:0];
                end
                else begin
                    cache_nxt[6][31:0] = proc_wdata;
                    cache_nxt[6][153:32] = cache[6][153:32];
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[0] = cache[0];
                cache_nxt[7] = cache[7];
            end
            7:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[7][127:96] = proc_wdata;
                    cache_nxt[7][153:128] = cache[7][153:128];
                    cache_nxt[7][95:0] = cache[7][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[7][95:64] = proc_wdata;
                    cache_nxt[7][153:96] = cache[7][153:96];
                    cache_nxt[7][63:0] = cache[7][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[7][63:32] = proc_wdata;
                    cache_nxt[7][153:64] = cache[7][153:64];
                    cache_nxt[7][31:0] = cache[7][31:0];
                end
                else begin
                    cache_nxt[7][31:0] = proc_wdata;
                    cache_nxt[7][153:32] = cache[7][153:32];
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[0] = cache[0];
            end
            endcase
        end

        else if(state == WRITE_MISS2 && mem_ready) begin
            case(index)
            0:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[0][95:64] = mem_rdata[63:32];
                    cache_nxt[0][63:32] = mem_rdata[95:64];
                    cache_nxt[0][31:0] = mem_rdata[127:96];
                    cache_nxt[0][152:128] = proc_addr[29:5];
                    cache_nxt[0][153] = 1;
                    cache_nxt[0][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[0][95:64] = proc_wdata;
                    cache_nxt[0][127:96] = mem_rdata[31:0];
                    cache_nxt[0][63:32] = mem_rdata[95:64];
                    cache_nxt[0][31:0] = mem_rdata[127:96];
                    cache_nxt[0][152:128] = proc_addr[29:5];
                    cache_nxt[0][153] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[0][95:64] = mem_rdata[63:32];
                    cache_nxt[0][127:96] = mem_rdata[31:0];
                    cache_nxt[0][31:0] = mem_rdata[127:96];
                    cache_nxt[0][152:128] = proc_addr[29:5];
                    cache_nxt[0][153] = 1;
                    cache_nxt[0][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[0][31:0] = proc_wdata;
                    cache_nxt[0][95:64] = mem_rdata[63:32];
                    cache_nxt[0][127:96] = mem_rdata[31:0];
                    cache_nxt[0][63:32] = mem_rdata[95:64];
                    cache_nxt[0][152:128] = proc_addr[29:5];
                    cache_nxt[0][153] = 1;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            1:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[1][95:64] = mem_rdata[63:32];
                    cache_nxt[1][63:32] = mem_rdata[95:64];
                    cache_nxt[1][31:0] = mem_rdata[127:96];
                    cache_nxt[1][152:128] = proc_addr[29:5];
                    cache_nxt[1][153] = 1;
                    cache_nxt[1][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[1][95:64] = proc_wdata;
                    cache_nxt[1][127:96] = mem_rdata[31:0];
                    cache_nxt[1][63:32] = mem_rdata[95:64];
                    cache_nxt[1][31:0] = mem_rdata[127:96];
                    cache_nxt[1][152:128] = proc_addr[29:5];
                    cache_nxt[1][153] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[1][95:64] = mem_rdata[63:32];
                    cache_nxt[1][127:96] = mem_rdata[31:0];
                    cache_nxt[1][31:0] = mem_rdata[127:96];
                    cache_nxt[1][152:128] = proc_addr[29:5];
                    cache_nxt[1][153] = 1;
                    cache_nxt[1][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[1][31:0] = proc_wdata;
                    cache_nxt[1][95:64] = mem_rdata[63:32];
                    cache_nxt[1][127:96] = mem_rdata[31:0];
                    cache_nxt[1][63:32] = mem_rdata[95:64];
                    cache_nxt[1][152:128] = proc_addr[29:5];
                    cache_nxt[1][153] = 1;
                end
                cache_nxt[0] = cache[0];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            2:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[2][95:64] = mem_rdata[63:32];
                    cache_nxt[2][63:32] = mem_rdata[95:64];
                    cache_nxt[2][31:0] = mem_rdata[127:96];
                    cache_nxt[2][152:128] = proc_addr[29:5];
                    cache_nxt[2][153] = 1;
                    cache_nxt[2][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[2][95:64] = proc_wdata;
                    cache_nxt[2][127:96] = mem_rdata[31:0];
                    cache_nxt[2][63:32] = mem_rdata[95:64];
                    cache_nxt[2][31:0] = mem_rdata[127:96];
                    cache_nxt[2][152:128] = proc_addr[29:5];
                    cache_nxt[2][153] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[2][95:64] = mem_rdata[63:32];
                    cache_nxt[2][127:96] = mem_rdata[31:0];
                    cache_nxt[2][31:0] = mem_rdata[127:96];
                    cache_nxt[2][152:128] = proc_addr[29:5];
                    cache_nxt[2][153] = 1;
                    cache_nxt[2][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[2][31:0] = proc_wdata;
                    cache_nxt[2][95:64] = mem_rdata[63:32];
                    cache_nxt[2][127:96] = mem_rdata[31:0];
                    cache_nxt[2][63:32] = mem_rdata[95:64];
                    cache_nxt[2][152:128] = proc_addr[29:5];
                    cache_nxt[2][153] = 1;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[0] = cache[0];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            3:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[3][95:64] = mem_rdata[63:32];
                    cache_nxt[3][63:32] = mem_rdata[95:64];
                    cache_nxt[3][31:0] = mem_rdata[127:96];
                    cache_nxt[3][152:128] = proc_addr[29:5];
                    cache_nxt[3][153] = 1;
                    cache_nxt[3][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[3][95:64] = proc_wdata;
                    cache_nxt[3][127:96] = mem_rdata[31:0];
                    cache_nxt[3][63:32] = mem_rdata[95:64];
                    cache_nxt[3][31:0] = mem_rdata[127:96];
                    cache_nxt[3][152:128] = proc_addr[29:5];
                    cache_nxt[3][153] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[3][95:64] = mem_rdata[63:32];
                    cache_nxt[3][127:96] = mem_rdata[31:0];
                    cache_nxt[3][31:0] = mem_rdata[127:96];
                    cache_nxt[3][152:128] = proc_addr[29:5];
                    cache_nxt[3][153] = 1;
                    cache_nxt[3][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[3][31:0] = proc_wdata;
                    cache_nxt[3][95:64] = mem_rdata[63:32];
                    cache_nxt[3][127:96] = mem_rdata[31:0];
                    cache_nxt[3][63:32] = mem_rdata[95:64];
                    cache_nxt[3][152:128] = proc_addr[29:5];
                    cache_nxt[3][153] = 1;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[0] = cache[0];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            4:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[4][95:64] = mem_rdata[63:32];
                    cache_nxt[4][63:32] = mem_rdata[95:64];
                    cache_nxt[4][31:0] = mem_rdata[127:96];
                    cache_nxt[4][152:128] = proc_addr[29:5];
                    cache_nxt[4][153] = 1;
                    cache_nxt[4][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[4][95:64] = proc_wdata;
                    cache_nxt[4][127:96] = mem_rdata[31:0];
                    cache_nxt[4][63:32] = mem_rdata[95:64];
                    cache_nxt[4][31:0] = mem_rdata[127:96];
                    cache_nxt[4][152:128] = proc_addr[29:5];
                    cache_nxt[4][153] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[4][95:64] = mem_rdata[63:32];
                    cache_nxt[4][127:96] = mem_rdata[31:0];
                    cache_nxt[4][31:0] = mem_rdata[127:96];
                    cache_nxt[4][152:128] = proc_addr[29:5];
                    cache_nxt[4][153] = 1;
                    cache_nxt[4][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[4][31:0] = proc_wdata;
                    cache_nxt[4][95:64] = mem_rdata[63:32];
                    cache_nxt[4][127:96] = mem_rdata[31:0];
                    cache_nxt[4][63:32] = mem_rdata[95:64];
                    cache_nxt[4][152:128] = proc_addr[29:5];
                    cache_nxt[4][153] = 1;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[0] = cache[0];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            5:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[5][95:64] = mem_rdata[63:32];
                    cache_nxt[5][63:32] = mem_rdata[95:64];
                    cache_nxt[5][31:0] = mem_rdata[127:96];
                    cache_nxt[5][152:128] = proc_addr[29:5];
                    cache_nxt[5][153] = 1;
                    cache_nxt[5][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[5][95:64] = proc_wdata;
                    cache_nxt[5][127:96] = mem_rdata[31:0];
                    cache_nxt[5][63:32] = mem_rdata[95:64];
                    cache_nxt[5][31:0] = mem_rdata[127:96];
                    cache_nxt[5][152:128] = proc_addr[29:5];
                    cache_nxt[5][153] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[5][95:64] = mem_rdata[63:32];
                    cache_nxt[5][127:96] = mem_rdata[31:0];
                    cache_nxt[5][31:0] = mem_rdata[127:96];
                    cache_nxt[5][152:128] = proc_addr[29:5];
                    cache_nxt[5][153] = 1;
                    cache_nxt[5][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[5][31:0] = proc_wdata;
                    cache_nxt[5][95:64] = mem_rdata[63:32];
                    cache_nxt[5][127:96] = mem_rdata[31:0];
                    cache_nxt[5][63:32] = mem_rdata[95:64];
                    cache_nxt[5][152:128] = proc_addr[29:5];
                    cache_nxt[5][153] = 1;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[0] = cache[0];
                cache_nxt[6] = cache[6];
                cache_nxt[7] = cache[7];
            end
            6:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[6][95:64] = mem_rdata[63:32];
                    cache_nxt[6][63:32] = mem_rdata[95:64];
                    cache_nxt[6][31:0] = mem_rdata[127:96];
                    cache_nxt[6][152:128] = proc_addr[29:5];
                    cache_nxt[6][153] = 1;
                    cache_nxt[6][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[6][95:64] = proc_wdata;
                    cache_nxt[6][127:96] = mem_rdata[31:0];
                    cache_nxt[6][63:32] = mem_rdata[95:64];
                    cache_nxt[6][31:0] = mem_rdata[127:96];
                    cache_nxt[6][152:128] = proc_addr[29:5];
                    cache_nxt[6][153] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[6][95:64] = mem_rdata[63:32];
                    cache_nxt[6][127:96] = mem_rdata[31:0];
                    cache_nxt[6][31:0] = mem_rdata[127:96];
                    cache_nxt[6][152:128] = proc_addr[29:5];
                    cache_nxt[6][153] = 1;
                    cache_nxt[6][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[6][31:0] = proc_wdata;
                    cache_nxt[6][95:64] = mem_rdata[63:32];
                    cache_nxt[6][127:96] = mem_rdata[31:0];
                    cache_nxt[6][63:32] = mem_rdata[95:64];
                    cache_nxt[6][152:128] = proc_addr[29:5];
                    cache_nxt[6][153] = 1;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[0] = cache[0];
                cache_nxt[7] = cache[7];
            end
            7:begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[7][95:64] = mem_rdata[63:32];
                    cache_nxt[7][63:32] = mem_rdata[95:64];
                    cache_nxt[7][31:0] = mem_rdata[127:96];
                    cache_nxt[7][152:128] = proc_addr[29:5];
                    cache_nxt[7][153] = 1;
                    cache_nxt[7][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[7][95:64] = proc_wdata;
                    cache_nxt[7][127:96] = mem_rdata[31:0];
                    cache_nxt[7][63:32] = mem_rdata[95:64];
                    cache_nxt[7][31:0] = mem_rdata[127:96];
                    cache_nxt[7][152:128] = proc_addr[29:5];
                    cache_nxt[7][153] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[7][95:64] = mem_rdata[63:32];
                    cache_nxt[7][127:96] = mem_rdata[31:0];
                    cache_nxt[7][31:0] = mem_rdata[127:96];
                    cache_nxt[7][152:128] = proc_addr[29:5];
                    cache_nxt[7][153] = 1;
                    cache_nxt[7][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[7][31:0] = proc_wdata;
                    cache_nxt[7][95:64] = mem_rdata[63:32];
                    cache_nxt[7][127:96] = mem_rdata[31:0];
                    cache_nxt[7][63:32] = mem_rdata[95:64];
                    cache_nxt[7][152:128] = proc_addr[29:5];
                    cache_nxt[7][153] = 1;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
                cache_nxt[4] = cache[4];
                cache_nxt[5] = cache[5];
                cache_nxt[6] = cache[6];
                cache_nxt[0] = cache[0];
            end
            endcase
        end
        else begin
        cache_nxt[0] = cache[0];
        cache_nxt[1] = cache[1];
        cache_nxt[2] = cache[2];
        cache_nxt[3] = cache[3];
        cache_nxt[4] = cache[4];
        cache_nxt[5] = cache[5];
        cache_nxt[6] = cache[6];
        cache_nxt[7] = cache[7];
        end
    end
end

assign proc_stall = proc_stall_r;
assign proc_rdata = proc_rdata_r;
assign mem_read = mem_read_r;
assign mem_write = mem_write_r;
assign mem_addr = mem_addr_r;
assign mem_wdata = mem_wdata_r;
//==== FSM ================================================
always @(*) begin
    case(state)
        IDLE:       begin
                    if(proc_read && proc_write) begin
                        proc_stall_r = 0;
                        proc_rdata_r = 0;
                        mem_read_r = 0;
                        mem_write_r = 0;
                        mem_addr_r = 0;
                        mem_wdata_r = 0;
                        next_state = IDLE;
                    end
                    else if(~proc_read && ~proc_write)begin
                        proc_stall_r = 0;
                        proc_rdata_r = 0;
                        mem_read_r = 0;
                        mem_write_r = 0;
                        mem_addr_r = 0;
                        mem_wdata_r = 0;
                        next_state = IDLE;
                    end
                    else if(proc_read && ~proc_write && hit)begin
                        proc_stall_r = 0;
                        if(proc_addr[1:0] == 2'b00) proc_rdata_r = cache_nxt[index][127:96];
                        else if(proc_addr[1:0] == 2'b01) proc_rdata_r = cache_nxt[index][95:64];
                        else if(proc_addr[1:0] == 2'b10) proc_rdata_r = cache_nxt[index][63:32];
                        else proc_rdata_r = cache_nxt[index][31:0];
                        mem_read_r = 0;
                        mem_write_r = 0;
                        mem_addr_r = 0;
                        mem_wdata_r = 0;
                        next_state = IDLE;
                    end
                    else if(~proc_read && proc_write && hit)begin
                        proc_stall_r = 1;
                        proc_rdata_r = 0;
                        mem_read_r = 0;
                        mem_write_r = 0;
                        mem_addr_r = 0;
                        mem_wdata_r = 0;
                        next_state = WRITE;
                    end
                    else if(proc_read && ~proc_write && ~hit)begin
                        proc_stall_r = 1;
                        proc_rdata_r = 0;
                        mem_read_r = 1;
                        mem_write_r = 0;
                        mem_addr_r = proc_addr[29:2];
                        mem_wdata_r = 0;
                        next_state = READ_STALL;
                    end
                    else begin
                        proc_stall_r = 1;
                        proc_rdata_r = 0;
                        mem_read_r = 0;
                        mem_write_r = 1;
                        mem_addr_r = {cache_nxt[index][152:128],index};
                       
                        mem_wdata_r[127:96] = cache_nxt[index][31:0];
                        mem_wdata_r[95:64] = cache_nxt[index][63:32];
                        mem_wdata_r[63:32] = cache_nxt[index][95:64];
                        mem_wdata_r[31:0] = cache_nxt[index][127:96];
                        next_state = WRITE_MISS;
                    end       
            end
        READ_STALL: begin
                    if(~mem_ready) begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 1;
                    mem_write_r = 0;
                    mem_addr_r = proc_addr[29:2];
                    mem_wdata_r = 0;
                    next_state = READ_STALL;
                    end
                    else begin
                    proc_stall_r = 0;
                    if(proc_addr[1:0] == 2'b00) proc_rdata_r = cache_nxt[index][127:96];
                    else if(proc_addr[1:0] == 2'b01) proc_rdata_r = cache_nxt[index][95:64];
                    else if(proc_addr[1:0] == 2'b10) proc_rdata_r = cache_nxt[index][63:32];
                    else proc_rdata_r = cache_nxt[index][31:0];
                    mem_read_r = 0;
                    mem_write_r = 0;
                    mem_addr_r = 0;
                    mem_wdata_r = 0;
                    next_state = IDLE;
                    end
                    end
        WRITE:      begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 1;
                    mem_addr_r = proc_addr[29:2];
                    mem_wdata_r[127:96] = cache_nxt[index][31:0];
                    mem_wdata_r[95:64] = cache_nxt[index][63:32];
                    mem_wdata_r[63:32] = cache_nxt[index][95:64];
                    mem_wdata_r[31:0] = cache_nxt[index][127:96];
                    next_state = WRITE_HIT;
                    end
        WRITE_HIT:begin
                    if(~mem_ready) begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 1;
                    mem_addr_r = proc_addr[29:2];
                    mem_wdata_r[127:96] = cache_nxt[index][31:0];
                    mem_wdata_r[95:64] = cache_nxt[index][63:32];
                    mem_wdata_r[63:32] = cache_nxt[index][95:64];
                    mem_wdata_r[31:0] = cache_nxt[index][127:96];
                    next_state = WRITE_HIT;
                    end
                    else begin
                    proc_stall_r = 0;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 0;
                    mem_addr_r = 0;
                    mem_wdata_r = 0;
                    next_state = IDLE;
                    end
                    end
        WRITE_MISS: begin
                    if(~mem_ready) begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 1;
                    mem_addr_r = {cache_nxt[index][152:128],index};
                    mem_wdata_r[127:96] = cache_nxt[index][31:0];
                    mem_wdata_r[95:64] = cache_nxt[index][63:32];
                    mem_wdata_r[63:32] = cache_nxt[index][95:64];
                    mem_wdata_r[31:0] = cache_nxt[index][127:96];
                    next_state = WRITE_MISS;
                    end
                    else begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 1;
                    mem_write_r = 0;
                    mem_addr_r = proc_addr[29:2];
                    mem_wdata_r = 0;
                    next_state = WRITE_MISS2;
                    end
                    end
        WRITE_MISS2:begin
                    if(~mem_ready) begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 1;
                    mem_write_r = 0;
                    mem_addr_r = proc_addr[29:2];
                    mem_wdata_r = 0;
                    next_state = WRITE_MISS2;
                    end
                    else begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 0;
                    mem_addr_r = 0;
                    mem_wdata_r = 0;
                    next_state = WRITE_MISS3;
                    end
                    end
        WRITE_MISS3:begin
                    proc_stall_r = 0;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 0;
                    mem_addr_r = 0;
                    mem_wdata_r = 0;
                    next_state = IDLE;
                    end
        default:    begin
                    proc_stall_r = 0;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 0;
                    mem_addr_r = 0;
                    mem_wdata_r = 0;
                    next_state = IDLE; 
                    end
    endcase
end
//==== sequential circuit =================================
always@( posedge clk ) begin
    if( proc_reset ) begin
        cache[0] <= 0;
        cache[1] <= 0;
        cache[2] <= 0;
        cache[3] <= 0;
        cache[4] <= 0;
        cache[5] <= 0;
        cache[6] <= 0;
        cache[7] <= 0;
        state <= IDLE;
    end
    else begin
        state <= next_state;
        cache[0] <= cache_nxt[0];
        cache[1] <= cache_nxt[1];
        cache[2] <= cache_nxt[2];
        cache[3] <= cache_nxt[3];
        cache[4] <= cache_nxt[4];
        cache[5] <= cache_nxt[5];
        cache[6] <= cache_nxt[6];
        cache[7] <= cache_nxt[7];
      
       
    end
end

endmodule
