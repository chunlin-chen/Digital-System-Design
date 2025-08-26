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
    parameter READ_STALL2 = 3'd6;
    parameter WRITE_MISS3 = 3'd7;
//==== wire/reg definition ================================
    reg [309:0] cache [3:0]; //1+25+128
    reg [309:0] cache_nxt [3:0]; //1+25+128
    reg hit;
    reg [2:0] state,next_state;
    reg [1:0] index;
    reg set;
    reg [3:0] stack;
    reg [3:0] stack_nxt;
    reg proc_stall_r;
    reg [31:0] proc_rdata_r;
    reg mem_read_r, mem_write_r;
    reg [27:0] mem_addr_r;
    reg [127:0] mem_wdata_r;
    reg [29:0] proc_addr_nxt;
    reg [31:0] proc_wdata_nxt;
    reg [5:0] counter,counter_nxt;

//==== combinational circuit ==============================
always@(*) begin
    index = proc_addr[3:2];
    if((state==IDLE) && (proc_addr[29:4] == cache[index][308:283]) && (cache[index][309] == 1)) begin
         hit = 1;
         set = 0;
         stack_nxt[index] = 1;
    end
    else if((state==IDLE) && (proc_addr[29:4] == cache[index][153:128]) && (cache[index][154] == 1)) begin
         hit = 1;
         set = 1;
         stack_nxt[index] = 0;
    end
    else begin
        hit = 0;
        set = 0;
        stack_nxt[index] = stack[index];
    end

    if( proc_reset ) begin
        cache_nxt[0] = 0;
        cache_nxt[1] = 0;
        cache_nxt[2] = 0;
        cache_nxt[3] = 0;
        stack_nxt = 0;
        counter_nxt = 0;
    end
    else begin
        if(state == READ_STALL && mem_ready) begin
            // read miss
            counter_nxt = counter +1;
            case(index)
            0:begin 
                if(stack[0]==0)begin
                    cache_nxt[0][282:251] = mem_rdata[31:0];
                    cache_nxt[0][250:219] = mem_rdata[63:32];
                    cache_nxt[0][218:187] = mem_rdata[95:64];
                    cache_nxt[0][186:155] = mem_rdata[127:96];
                    cache_nxt[0][308:283] = proc_addr[29:4];
                    cache_nxt[0][309] = 1;           
                    cache_nxt[1] = cache[1];
                    cache_nxt[2] = cache[2];
                    cache_nxt[3] = cache[3];
                    stack_nxt[0] = 1;
                
                end
                else begin
                    cache_nxt[0][127:96] = mem_rdata[31:0];
                    cache_nxt[0][95:64] = mem_rdata[63:32];
                    cache_nxt[0][63:32] = mem_rdata[95:64];
                    cache_nxt[0][31:0] = mem_rdata[127:96];
                    cache_nxt[0][153:128] = proc_addr[29:4];
                    cache_nxt[0][154] = 1;           
                    cache_nxt[1] = cache[1];
                    cache_nxt[2] = cache[2];
                    cache_nxt[3] = cache[3];
                    stack_nxt[0] = 0;
    
                end
            end
            
            1:begin 
                if(stack[1]==0)begin
                    cache_nxt[1][282:251] = mem_rdata[31:0];
                    cache_nxt[1][250:219] = mem_rdata[63:32];
                    cache_nxt[1][218:187] = mem_rdata[95:64];
                    cache_nxt[1][186:155] = mem_rdata[127:96];
                    cache_nxt[1][308:283] = proc_addr[29:4];
                    cache_nxt[1][309] = 1;           
                    cache_nxt[0] = cache[0];
                    cache_nxt[2] = cache[2];
                    cache_nxt[3] = cache[3];
                    stack_nxt[1] = 1;
                
                end
                else begin
                    cache_nxt[1][127:96] = mem_rdata[31:0];
                    cache_nxt[1][95:64] = mem_rdata[63:32];
                    cache_nxt[1][63:32] = mem_rdata[95:64];
                    cache_nxt[1][31:0] = mem_rdata[127:96];
                    cache_nxt[1][153:128] = proc_addr[29:4];
                    cache_nxt[1][154] = 1;           
                    cache_nxt[0] = cache[0];
                    cache_nxt[2] = cache[2];
                    cache_nxt[3] = cache[3];
                    stack_nxt[1] = 0;
                end
            end
            2:begin 
                if(stack[2]==0)begin
                    cache_nxt[2][282:251] = mem_rdata[31:0];
                    cache_nxt[2][250:219] = mem_rdata[63:32];
                    cache_nxt[2][218:187] = mem_rdata[95:64];
                    cache_nxt[2][186:155] = mem_rdata[127:96];
                    cache_nxt[2][308:283] = proc_addr[29:4];
                    cache_nxt[2][309] = 1;           
                    cache_nxt[1] = cache[1];
                    cache_nxt[0] = cache[0];
                    cache_nxt[3] = cache[3];
                    stack_nxt[2] = 1;
                
                end
                else begin
                    cache_nxt[2][127:96] = mem_rdata[31:0];
                    cache_nxt[2][95:64] = mem_rdata[63:32];
                    cache_nxt[2][63:32] = mem_rdata[95:64];
                    cache_nxt[2][31:0] = mem_rdata[127:96];
                    cache_nxt[2][153:128] = proc_addr[29:4];
                    cache_nxt[2][154] = 1;           
                    cache_nxt[1] = cache[1];
                    cache_nxt[0] = cache[0];
                    cache_nxt[3] = cache[3];
                    stack_nxt[2] = 0;
    
                end
            end
        
            3:begin 
                if(stack[3]==0)begin
                    cache_nxt[3][282:251] = mem_rdata[31:0];
                    cache_nxt[3][250:219] = mem_rdata[63:32];
                    cache_nxt[3][218:187] = mem_rdata[95:64];
                    cache_nxt[3][186:155] = mem_rdata[127:96];
                    cache_nxt[3][308:283] = proc_addr[29:4];
                    cache_nxt[3][309] = 1;           
                    cache_nxt[1] = cache[1];
                    cache_nxt[2] = cache[2];
                    cache_nxt[0] = cache[0];
                    stack_nxt[3] = 1;
                
                end
                else begin
                    cache_nxt[3][127:96] = mem_rdata[31:0];
                    cache_nxt[3][95:64] = mem_rdata[63:32];
                    cache_nxt[3][63:32] = mem_rdata[95:64];
                    cache_nxt[3][31:0] = mem_rdata[127:96];
                    cache_nxt[3][153:128] = proc_addr[29:4];
                    cache_nxt[3][154] = 1;           
                    cache_nxt[1] = cache[1];
                    cache_nxt[2] = cache[2];
                    cache_nxt[0] = cache[0];
                    stack_nxt[3] = 0;
    
                end
            end
        endcase
        end

        else if(state==IDLE && ~proc_read && proc_write && hit) begin
            // write hit
            case(index)
            0:begin
                if(set==0) begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[0][282:251] = proc_wdata;
                    cache_nxt[0][309:283] = cache[0][309:283];
                    cache_nxt[0][250:0] = cache[0][250:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[0][250:219] = proc_wdata;
                    cache_nxt[0][309:251] = cache[0][309:251];
                    cache_nxt[0][218:0] = cache[0][218:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[0][218:187] = proc_wdata;
                    cache_nxt[0][309:219] = cache[0][309:219];
                    cache_nxt[0][186:0] = cache[0][186:0];
                end
                else begin
                    cache_nxt[0][186:155] = proc_wdata;
                    cache_nxt[0][309:187] = cache[0][309:187];
                    cache_nxt[0][154:0] = cache[0][154:0];
                end
                end
                else begin
                    if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[0][127:96] = proc_wdata;
                    cache_nxt[0][309:128] = cache[0][309:128];
                    cache_nxt[0][95:0] = cache[0][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[0][95:64] = proc_wdata;
                    cache_nxt[0][309:96] = cache[0][309:96];
                    cache_nxt[0][63:0] = cache[0][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[0][63:32] = proc_wdata;
                    cache_nxt[0][309:64] = cache[0][309:64];
                    cache_nxt[0][31:0] = cache[0][31:0];
                end
                else begin
                    cache_nxt[0][31:0] = proc_wdata;
                    cache_nxt[0][309:32] = cache[0][309:32];
                end
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
            end
            1:begin
                if(set==0) begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[1][282:251] = proc_wdata;
                    cache_nxt[1][309:283] = cache[1][309:283];
                    cache_nxt[1][250:0] = cache[1][250:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[1][250:219] = proc_wdata;
                    cache_nxt[1][309:251] = cache[1][309:251];
                    cache_nxt[1][218:0] = cache[1][218:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[1][218:187] = proc_wdata;
                    cache_nxt[1][309:219] = cache[1][309:219];
                    cache_nxt[1][186:0] = cache[1][186:0];
                end
                else begin
                    cache_nxt[1][186:155] = proc_wdata;
                    cache_nxt[1][309:187] = cache[1][309:187];
                    cache_nxt[1][154:0] = cache[1][154:0];
                end
                end
                else begin
                    if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[1][127:96] = proc_wdata;
                    cache_nxt[1][309:128] = cache[1][309:128];
                    cache_nxt[1][95:0] = cache[1][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[1][95:64] = proc_wdata;
                    cache_nxt[1][309:96] = cache[1][309:96];
                    cache_nxt[1][63:0] = cache[1][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[1][63:32] = proc_wdata;
                    cache_nxt[1][309:64] = cache[1][309:64];
                    cache_nxt[1][31:0] = cache[1][31:0];
                end
                else begin
                    cache_nxt[1][31:0] = proc_wdata;
                    cache_nxt[1][309:32] = cache[1][309:32];
                end
                end
                cache_nxt[0] = cache[0];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
            end
            2:begin
                if(set==0) begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[2][282:251] = proc_wdata;
                    cache_nxt[2][309:283] = cache[2][309:283];
                    cache_nxt[2][250:0] = cache[2][250:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[2][250:219] = proc_wdata;
                    cache_nxt[2][309:251] = cache[2][309:251];
                    cache_nxt[2][218:0] = cache[2][218:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[2][218:187] = proc_wdata;
                    cache_nxt[2][309:219] = cache[2][309:219];
                    cache_nxt[2][186:0] = cache[2][186:0];
                end
                else begin
                    cache_nxt[2][186:155] = proc_wdata;
                    cache_nxt[2][309:187] = cache[2][309:187];
                    cache_nxt[2][154:0] = cache[2][154:0];
                end
                end
                else begin
                    if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[2][127:96] = proc_wdata;
                    cache_nxt[2][309:128] = cache[2][309:128];
                    cache_nxt[2][95:0] = cache[2][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[2][95:64] = proc_wdata;
                    cache_nxt[2][309:96] = cache[2][309:96];
                    cache_nxt[2][63:0] = cache[2][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[2][63:32] = proc_wdata;
                    cache_nxt[2][309:64] = cache[2][309:64];
                    cache_nxt[2][31:0] = cache[2][31:0];
                end
                else begin
                    cache_nxt[2][31:0] = proc_wdata;
                    cache_nxt[2][309:32] = cache[2][309:32];
                end
                end
                cache_nxt[0] = cache[0];
                cache_nxt[1] = cache[1];
                cache_nxt[3] = cache[3];
            end
            3:begin
                if(set==0) begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[3][282:251] = proc_wdata;
                    cache_nxt[3][309:283] = cache[3][309:283];
                    cache_nxt[3][250:0] = cache[3][250:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[3][250:219] = proc_wdata;
                    cache_nxt[3][309:251] = cache[3][309:251];
                    cache_nxt[3][218:0] = cache[3][218:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[3][218:187] = proc_wdata;
                    cache_nxt[3][309:219] = cache[3][309:219];
                    cache_nxt[3][186:0] = cache[3][186:0];
                end
                else begin
                    cache_nxt[3][186:155] = proc_wdata;
                    cache_nxt[3][309:187] = cache[3][309:187];
                    cache_nxt[3][154:0] = cache[3][154:0];
                end
                end
                else begin
                    if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[3][127:96] = proc_wdata;
                    cache_nxt[3][309:128] = cache[3][309:128];
                    cache_nxt[3][95:0] = cache[3][95:0];
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[3][95:64] = proc_wdata;
                    cache_nxt[3][309:96] = cache[3][309:96];
                    cache_nxt[3][63:0] = cache[3][63:0];
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[3][63:32] = proc_wdata;
                    cache_nxt[3][309:64] = cache[3][309:64];
                    cache_nxt[3][31:0] = cache[3][31:0];
                end
                else begin
                    cache_nxt[3][31:0] = proc_wdata;
                    cache_nxt[3][309:32] = cache[3][309:32];
                end
                end
                cache_nxt[0] = cache[0];
                cache_nxt[2] = cache[2];
                cache_nxt[1] = cache[1];
            end
            endcase
        end

        else if(state == WRITE_MISS2 && mem_ready) begin
            case(index)
            0:begin
                if(stack[0]==0)begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[0][250:219] = mem_rdata[63:32];
                    cache_nxt[0][218:187] = mem_rdata[95:64];
                    cache_nxt[0][186:155] = mem_rdata[127:96];
                    cache_nxt[0][308:283] = proc_addr[29:4];
                    cache_nxt[0][309] = 1;
                    cache_nxt[0][282:251] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[0][250:219] = proc_wdata;
                    cache_nxt[0][282:251] = mem_rdata[31:0];
                    cache_nxt[0][218:187] = mem_rdata[95:64];
                    cache_nxt[0][186:155] = mem_rdata[127:96];
                    cache_nxt[0][308:283] = proc_addr[29:4];
                    cache_nxt[0][309] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[0][250:219] = mem_rdata[63:32];
                    cache_nxt[0][282:251] = mem_rdata[31:0];
                    cache_nxt[0][186:155] = mem_rdata[127:96];
                    cache_nxt[0][308:283] = proc_addr[29:4];
                    cache_nxt[0][309] = 1;
                    cache_nxt[0][218:187] = proc_wdata;
                end
                else begin
                    cache_nxt[0][186:155] = proc_wdata;
                    cache_nxt[0][250:219] = mem_rdata[63:32];
                    cache_nxt[0][282:251] = mem_rdata[31:0];
                    cache_nxt[0][218:187] = mem_rdata[95:64];
                    cache_nxt[0][308:283] = proc_addr[29:4];
                    cache_nxt[0][309] = 1;
                end
                stack_nxt[0] = 1;
                end
                else begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[0][95:64] = mem_rdata[63:32];
                    cache_nxt[0][63:32] = mem_rdata[95:64];
                    cache_nxt[0][31:0] = mem_rdata[127:96];
                    cache_nxt[0][153:128] = proc_addr[29:4];
                    cache_nxt[0][154] = 1;
                    cache_nxt[0][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[0][95:64] = proc_wdata;
                    cache_nxt[0][127:96] = mem_rdata[31:0];
                    cache_nxt[0][63:32] = mem_rdata[95:64];
                    cache_nxt[0][31:0] = mem_rdata[127:96];
                    cache_nxt[0][153:128] = proc_addr[29:4];
                    cache_nxt[0][154] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[0][95:64] = mem_rdata[63:32];
                    cache_nxt[0][127:96] = mem_rdata[31:0];
                    cache_nxt[0][31:0] = mem_rdata[127:96];
                    cache_nxt[0][153:128] = proc_addr[29:4];
                    cache_nxt[0][154] = 1;
                    cache_nxt[0][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[0][31:0] = proc_wdata;
                    cache_nxt[0][95:64] = mem_rdata[63:32];
                    cache_nxt[0][127:96] = mem_rdata[31:0];
                    cache_nxt[0][63:32] = mem_rdata[95:64];
                    cache_nxt[0][153:128] = proc_addr[29:4];
                    cache_nxt[0][154] = 1;
                end
                stack_nxt[0] = 0;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
            end
            1:begin
                if(stack[1]==0)begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[1][250:219] = mem_rdata[63:32];
                    cache_nxt[1][218:187] = mem_rdata[95:64];
                    cache_nxt[1][186:155] = mem_rdata[127:96];
                    cache_nxt[1][308:283] = proc_addr[29:4];
                    cache_nxt[1][309] = 1;
                    cache_nxt[1][282:251] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[1][250:219] = proc_wdata;
                    cache_nxt[1][282:251] = mem_rdata[31:0];
                    cache_nxt[1][218:187] = mem_rdata[95:64];
                    cache_nxt[1][186:155] = mem_rdata[127:96];
                    cache_nxt[1][308:283] = proc_addr[29:4];
                    cache_nxt[1][309] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[1][250:219] = mem_rdata[63:32];
                    cache_nxt[1][282:251] = mem_rdata[31:0];
                    cache_nxt[1][186:155] = mem_rdata[127:96];
                    cache_nxt[1][308:283] = proc_addr[29:4];
                    cache_nxt[1][309] = 1;
                    cache_nxt[1][218:187] = proc_wdata;
                end
                else begin
                    cache_nxt[1][186:155] = proc_wdata;
                    cache_nxt[1][250:219] = mem_rdata[63:32];
                    cache_nxt[1][282:251] = mem_rdata[31:0];
                    cache_nxt[1][218:187] = mem_rdata[95:64];
                    cache_nxt[1][308:283] = proc_addr[29:4];
                    cache_nxt[1][309] = 1;
                end
                stack_nxt[1] = 1;
                end
                else begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[1][95:64] = mem_rdata[63:32];
                    cache_nxt[1][63:32] = mem_rdata[95:64];
                    cache_nxt[1][31:0] = mem_rdata[127:96];
                    cache_nxt[1][153:128] = proc_addr[29:4];
                    cache_nxt[1][154] = 1;
                    cache_nxt[1][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[1][95:64] = proc_wdata;
                    cache_nxt[1][127:96] = mem_rdata[31:0];
                    cache_nxt[1][63:32] = mem_rdata[95:64];
                    cache_nxt[1][31:0] = mem_rdata[127:96];
                    cache_nxt[1][153:128] = proc_addr[29:4];
                    cache_nxt[1][154] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[1][95:64] = mem_rdata[63:32];
                    cache_nxt[1][127:96] = mem_rdata[31:0];
                    cache_nxt[1][31:0] = mem_rdata[127:96];
                    cache_nxt[1][153:128] = proc_addr[29:4];
                    cache_nxt[1][154] = 1;
                    cache_nxt[1][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[1][31:0] = proc_wdata;
                    cache_nxt[1][95:64] = mem_rdata[63:32];
                    cache_nxt[1][127:96] = mem_rdata[31:0];
                    cache_nxt[1][63:32] = mem_rdata[95:64];
                    cache_nxt[1][153:128] = proc_addr[29:4];
                    cache_nxt[1][154] = 1;
                end
                stack_nxt[1] = 0;
                end
                cache_nxt[0] = cache[0];
                cache_nxt[2] = cache[2];
                cache_nxt[3] = cache[3];
            end
            2:begin
                if(stack[2]==0)begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[2][250:219] = mem_rdata[63:32];
                    cache_nxt[2][218:187] = mem_rdata[95:64];
                    cache_nxt[2][186:155] = mem_rdata[127:96];
                    cache_nxt[2][308:283] = proc_addr[29:4];
                    cache_nxt[2][309] = 1;
                    cache_nxt[2][282:251] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[2][250:219] = proc_wdata;
                    cache_nxt[2][282:251] = mem_rdata[31:0];
                    cache_nxt[2][218:187] = mem_rdata[95:64];
                    cache_nxt[2][186:155] = mem_rdata[127:96];
                    cache_nxt[2][308:283] = proc_addr[29:4];
                    cache_nxt[2][309] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[2][250:219] = mem_rdata[63:32];
                    cache_nxt[2][282:251] = mem_rdata[31:0];
                    cache_nxt[2][186:155] = mem_rdata[127:96];
                    cache_nxt[2][308:283] = proc_addr[29:4];
                    cache_nxt[2][309] = 1;
                    cache_nxt[2][218:187] = proc_wdata;
                end
                else begin
                    cache_nxt[2][186:155] = proc_wdata;
                    cache_nxt[2][250:219] = mem_rdata[63:32];
                    cache_nxt[2][282:251] = mem_rdata[31:0];
                    cache_nxt[2][218:187] = mem_rdata[95:64];
                    cache_nxt[2][308:283] = proc_addr[29:4];
                    cache_nxt[2][309] = 1;
                end
                stack_nxt[2] = 1;
                end
                else begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[2][95:64] = mem_rdata[63:32];
                    cache_nxt[2][63:32] = mem_rdata[95:64];
                    cache_nxt[2][31:0] = mem_rdata[127:96];
                    cache_nxt[2][153:128] = proc_addr[29:4];
                    cache_nxt[2][154] = 1;
                    cache_nxt[2][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[2][95:64] = proc_wdata;
                    cache_nxt[2][127:96] = mem_rdata[31:0];
                    cache_nxt[2][63:32] = mem_rdata[95:64];
                    cache_nxt[2][31:0] = mem_rdata[127:96];
                    cache_nxt[2][153:128] = proc_addr[29:4];
                    cache_nxt[2][154] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[2][95:64] = mem_rdata[63:32];
                    cache_nxt[2][127:96] = mem_rdata[31:0];
                    cache_nxt[2][31:0] = mem_rdata[127:96];
                    cache_nxt[2][153:128] = proc_addr[29:4];
                    cache_nxt[2][154] = 1;
                    cache_nxt[2][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[2][31:0] = proc_wdata;
                    cache_nxt[2][95:64] = mem_rdata[63:32];
                    cache_nxt[2][127:96] = mem_rdata[31:0];
                    cache_nxt[2][63:32] = mem_rdata[95:64];
                    cache_nxt[2][153:128] = proc_addr[29:4];
                    cache_nxt[2][154] = 1;
                end
                stack_nxt[2] = 0;
                end
                cache_nxt[1] = cache[1];
                cache_nxt[0] = cache[0];
                cache_nxt[3] = cache[3];
            end
            3:begin
                if(stack[3]==0)begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[3][250:219] = mem_rdata[63:32];
                    cache_nxt[3][218:187] = mem_rdata[95:64];
                    cache_nxt[3][186:155] = mem_rdata[127:96];
                    cache_nxt[3][308:283] = proc_addr[29:4];
                    cache_nxt[3][309] = 1;
                    cache_nxt[3][282:251] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[3][250:219] = proc_wdata;
                    cache_nxt[3][282:251] = mem_rdata[31:0];
                    cache_nxt[3][218:187] = mem_rdata[95:64];
                    cache_nxt[3][186:155] = mem_rdata[127:96];
                    cache_nxt[3][308:283] = proc_addr[29:4];
                    cache_nxt[3][309] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[3][250:219] = mem_rdata[63:32];
                    cache_nxt[3][282:251] = mem_rdata[31:0];
                    cache_nxt[3][186:155] = mem_rdata[127:96];
                    cache_nxt[3][308:283] = proc_addr[29:4];
                    cache_nxt[3][309] = 1;
                    cache_nxt[3][218:187] = proc_wdata;
                end
                else begin
                    cache_nxt[3][186:155] = proc_wdata;
                    cache_nxt[3][250:219] = mem_rdata[63:32];
                    cache_nxt[3][282:251] = mem_rdata[31:0];
                    cache_nxt[3][218:187] = mem_rdata[95:64];
                    cache_nxt[3][308:283] = proc_addr[29:4];
                    cache_nxt[3][309] = 1;
                end
                stack_nxt[3] = 1;
                end
                else begin
                if(proc_addr[1:0] == 2'b00) begin
                    cache_nxt[3][95:64] = mem_rdata[63:32];
                    cache_nxt[3][63:32] = mem_rdata[95:64];
                    cache_nxt[3][31:0] = mem_rdata[127:96];
                    cache_nxt[3][153:128] = proc_addr[29:4];
                    cache_nxt[3][154] = 1;
                    cache_nxt[3][127:96] = proc_wdata;
                end
                else if(proc_addr[1:0] == 2'b01) begin
                    cache_nxt[3][95:64] = proc_wdata;
                    cache_nxt[3][127:96] = mem_rdata[31:0];
                    cache_nxt[3][63:32] = mem_rdata[95:64];
                    cache_nxt[3][31:0] = mem_rdata[127:96];
                    cache_nxt[3][153:128] = proc_addr[29:4];
                    cache_nxt[3][154] = 1;
                end
                else if(proc_addr[1:0] == 2'b10) begin
                    cache_nxt[3][95:64] = mem_rdata[63:32];
                    cache_nxt[3][127:96] = mem_rdata[31:0];
                    cache_nxt[3][31:0] = mem_rdata[127:96];
                    cache_nxt[3][153:128] = proc_addr[29:4];
                    cache_nxt[3][154] = 1;
                    cache_nxt[3][63:32] = proc_wdata;
                end
                else begin
                    cache_nxt[3][31:0] = proc_wdata;
                    cache_nxt[3][95:64] = mem_rdata[63:32];
                    cache_nxt[3][127:96] = mem_rdata[31:0];
                    cache_nxt[3][63:32] = mem_rdata[95:64];
                    cache_nxt[3][153:128] = proc_addr[29:4];
                    cache_nxt[3][154] = 1;
                end
                stack_nxt[3] = 0;
                cache_nxt[1] = cache[1];
                cache_nxt[2] = cache[2];
                cache_nxt[0] = cache[0];
                end
            end
            endcase
        end
        else begin
        cache_nxt[0] = cache[0];
        cache_nxt[1] = cache[1];
        cache_nxt[2] = cache[2];
        cache_nxt[3] = cache[3];
        stack_nxt = stack;
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
                        // read hit
                        proc_stall_r = 0;
                        if(set==0) begin
                            if(proc_addr[1:0] == 2'b00) proc_rdata_r = cache_nxt[index][282:251];
                            else if(proc_addr[1:0] == 2'b01) proc_rdata_r = cache_nxt[index][250:219];
                            else if(proc_addr[1:0] == 2'b10) proc_rdata_r = cache_nxt[index][218:187];
                            else proc_rdata_r = cache_nxt[index][186:155];
                        end
                        else begin
                            if(proc_addr[1:0] == 2'b00) proc_rdata_r = cache_nxt[index][127:96];
                            else if(proc_addr[1:0] == 2'b01) proc_rdata_r = cache_nxt[index][95:64];
                            else if(proc_addr[1:0] == 2'b10) proc_rdata_r = cache_nxt[index][63:32];
                            else proc_rdata_r = cache_nxt[index][31:0];
                        end
                        mem_read_r = 0;
                        mem_write_r = 0;
                        mem_addr_r = 0;
                        mem_wdata_r = 0;
                        next_state = IDLE;
                    end
                    else if(~proc_read && proc_write && hit)begin
                        // write hit
                        proc_stall_r = 1;
                        proc_rdata_r = 0;
                        mem_read_r = 0;
                        mem_write_r = 0;
                        mem_addr_r = 0;
                        mem_wdata_r = 0;
                        next_state = WRITE;
                    end
                    else if(proc_read && ~proc_write && ~hit)begin
                        // read miss
                            proc_stall_r = 1;
                            proc_rdata_r = 0;
                            mem_read_r = 1;
                            mem_write_r = 0;
                            mem_addr_r = proc_addr[29:2];
                            mem_wdata_r = 0;
                            next_state = READ_STALL;
                        end

                    else begin
                        // write miss
                        proc_stall_r = 1;
                        proc_rdata_r = 0;
                        mem_read_r = 0;
                        mem_write_r = 1;
                        if(stack[index]==0) begin
                            mem_addr_r = {cache_nxt[index][308:283],index};                  
                            mem_wdata_r[127:96] = cache_nxt[index][186:155];
                            mem_wdata_r[95:64] = cache_nxt[index][218:187];
                            mem_wdata_r[63:32] = cache_nxt[index][250:219];
                            mem_wdata_r[31:0] = cache_nxt[index][282:251];
                        end
                        else begin
                            mem_addr_r = {cache_nxt[index][153:128],index};                  
                            mem_wdata_r[127:96] = cache_nxt[index][31:0];
                            mem_wdata_r[95:64] = cache_nxt[index][63:32];
                            mem_wdata_r[63:32] = cache_nxt[index][95:64];
                            mem_wdata_r[31:0] = cache_nxt[index][127:96];
                        end
                        next_state = WRITE_MISS;
                    end       
            end
        READ_STALL: begin
            // read miss
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
                    if(proc_addr[1:0] == 2'b00) proc_rdata_r = mem_rdata[31:0];
                    else if(proc_addr[1:0] == 2'b01)proc_rdata_r = mem_rdata[63:32];
                    else if(proc_addr[1:0] == 2'b10)proc_rdata_r = mem_rdata[95:64];
                    else proc_rdata_r = mem_rdata[127:96];
                    mem_read_r = 0;
                    mem_write_r = 0;
                    mem_addr_r = 0;
                    mem_wdata_r = 0;
                    next_state = IDLE;
                    end
                    end
        WRITE:      begin
            //write hit
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 1;
                    mem_addr_r = proc_addr[29:2];
                    if(set==0) begin
                        mem_wdata_r[127:96] = cache_nxt[index][186:155];
                        mem_wdata_r[95:64] = cache_nxt[index][218:187];
                        mem_wdata_r[63:32] = cache_nxt[index][250:219];
                        mem_wdata_r[31:0] = cache_nxt[index][282:251];
                    end
                    else begin
                        mem_wdata_r[127:96] = cache_nxt[index][31:0];
                        mem_wdata_r[95:64] = cache_nxt[index][63:32];
                        mem_wdata_r[63:32] = cache_nxt[index][95:64];
                        mem_wdata_r[31:0] = cache_nxt[index][127:96];
                    end
                    next_state = WRITE_HIT;
                    end
        WRITE_HIT:begin
            // write hit
                    if(~mem_ready) begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 1;
                    mem_addr_r = proc_addr[29:2];
                    if(set==0) begin
                        mem_wdata_r[127:96] = cache_nxt[index][186:155];
                        mem_wdata_r[95:64] = cache_nxt[index][218:187];
                        mem_wdata_r[63:32] = cache_nxt[index][250:219];
                        mem_wdata_r[31:0] = cache_nxt[index][282:251];
                    end
                    else begin
                        mem_wdata_r[127:96] = cache_nxt[index][31:0];
                        mem_wdata_r[95:64] = cache_nxt[index][63:32];
                        mem_wdata_r[63:32] = cache_nxt[index][95:64];
                        mem_wdata_r[31:0] = cache_nxt[index][127:96];
                    end
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
            // write miss
                    if(~mem_ready) begin
                    proc_stall_r = 1;
                    proc_rdata_r = 0;
                    mem_read_r = 0;
                    mem_write_r = 1;
                    if(stack[index]==0) begin
                        mem_addr_r = {cache_nxt[index][308:283],index};
                        mem_wdata_r[127:96] = cache_nxt[index][186:155];
                        mem_wdata_r[95:64] = cache_nxt[index][218:187];
                        mem_wdata_r[63:32] = cache_nxt[index][250:219];
                        mem_wdata_r[31:0] = cache_nxt[index][282:251];
                    end
                    else begin
                        mem_addr_r = {cache_nxt[index][153:128],index};
                        mem_wdata_r[127:96] = cache_nxt[index][31:0];
                        mem_wdata_r[95:64] = cache_nxt[index][63:32];
                        mem_wdata_r[63:32] = cache_nxt[index][95:64];
                        mem_wdata_r[31:0] = cache_nxt[index][127:96];
                    end
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
            // write miss
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
            //write miss
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
        state <= IDLE;
        stack <=0;
        counter<=0;
    end
    else begin
        state <= next_state;
        cache[0] <= cache_nxt[0];
        cache[1] <= cache_nxt[1];
        cache[2] <= cache_nxt[2];
        cache[3] <= cache_nxt[3];
        stack <= stack_nxt;
        counter <= counter_nxt;
      
       
    end
end

endmodule
