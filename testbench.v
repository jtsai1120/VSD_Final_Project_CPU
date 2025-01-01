`timescale 1ns/1ps

/*`ifdef syn
    `include "top_syn.v"
    `include "tsmc18.v"
`else
    `include "top.v"
`endif

`include "Inst_Mem.v"
`include "Data_Mem.v"*/

`define HALF_CLK_TIME 10

module testbench;

reg clk, rst;
wire [31:0] inst;
wire [31:0] pc;
wire [63:0] mem_data;
wire [63:0] addr;
wire mem_rw;
wire halt;
reg [63:0] tb_read_addr;
wire [63:0] tb_read_data;

top top(halt, mem_data, mem_rw, addr, pc, clk, rst, inst);
Inst_Mem Inst_Mem(inst, pc);
Data_Mem Data_Mem(mem_data, clk, rst, mem_rw, addr);

/*`ifdef syn
    initial $sdf_annotate("top_syn.sdf", CPU);
`endif

/*initial begin : waveform
    $dumpfile("tb.fsdb");
    $dumpvars(0, testbench);
end*/

initial begin : clk_gen
    clk = 0;
    forever #`HALF_CLK_TIME clk = ~clk;
end

initial begin : terminal_display
    $display("---Simulation Start---");
    $monitor("t0=%d,t1=%d,t2=%d,t3=%d,t4=%d,t5=%d,t6=%d",top.ID.RF[5],top.ID.RF[6],top.ID.RF[7],top.ID.RF[28],top.ID.RF[29],top.ID.RF[30],top.ID.RF[31]);
    //$monitor("clk=%b, rst=%b, inst=%h, pc=%h, mem_data=%h, addr=%h, mem_rw=%b,NOP=%b,flush=%b", clk, rst, inst, pc, mem_data, addr, mem_rw,top.NOP,top.flush);
end

integer i;
integer error_flag;
integer f_prv2, f_prv1, f_cur;

initial begin : execute
    rst = 1;
    $readmemb("sorting.prog", Inst_Mem.IM);
     
    #(`HALF_CLK_TIME * 20) rst = 0;
    
    // Load Test Program
   /* `ifdef sorting
        $readmemb("./test_prog/sort_Mnemonic.prog", Inst_Mem.IM);
        //$readmemb("./test_prog/sort_data.prog", Data_Mem.DM);
    `elsif single
        $readmemb("./test_prog/single_inst_Mnemonic.prog", Inst_Mem.IM);
    `else 
        //$readmemb("./test_prog/fibo_Mnemonic.prog", Inst_Mem.IM);\
        $readmemb("fibo_Mnemonic.prog", Inst_Mem.IM);
    `endif*/
end

always @(posedge halt) begin
    $display("Halt ... ");
   /* `ifdef sorting
        error_flag = 0;
        for (i = 1; i <= 10; i = i + 1) begin
            if (Data_Mem.DM[i+10] != i - 4) begin // -3 ~ 6
                error_flag = 1;
                i = 11;
            end
        end
        if (error_flag == 0) 
            $display("Passed Sorting!");
        else 
            $display("Failed Sorting!");

        $display("Before: %d, %d, %d, %d, %d, %d, %d, %d, %d, %d", 
                Data_Mem.DM[1], Data_Mem.DM[2], Data_Mem.DM[3], 
                Data_Mem.DM[4], Data_Mem.DM[5], Data_Mem.DM[6], 
                Data_Mem.DM[7], Data_Mem.DM[8], Data_Mem.DM[9], Data_Mem.DM[10]);
        $display("After: %d, %d, %d, %d, %d, %d, %d, %d, %d, %d",
                Data_Mem.DM[11], Data_Mem.DM[12], Data_Mem.DM[13], 
                Data_Mem.DM[14], Data_Mem.DM[15], Data_Mem.DM[16], 
                Data_Mem.DM[17], Data_Mem.DM[18], Data_Mem.DM[19], Data_Mem.DM[20]);
    `elsif single
        if (Data_Mem.DM[0] == 0) 
            $display("Passed All Testcases!");
        else 
            $display("Failed at Section %d!", Data_Mem.DM[0]);
    `else*/
        if (Data_Mem.comb_DM[1] != 1) error_flag = 1;
        else if (Data_Mem.comb_DM[2] != 1) error_flag = 2;
        else begin
            f_prv2 = 1;
            f_prv1 = 1;
            for (i = 3; i <= 20; i = i + 1) begin
                f_cur = f_prv1 + f_prv2;
                if (Data_Mem.comb_DM[i] != f_cur) begin
                    error_flag = i;
                    i = 21;
                end
                f_prv2 = f_prv1;
                f_prv1 = f_cur;
            end
        end

        if (error_flag == 0) 
            $display("Passed Fibo!\n");
        else 
            $display("Failed Fibo at f(%2d)!\n", error_flag);

        for (i = 1; i <= ((error_flag)? error_flag : 20); i = i + 1)
            $display("f(%2d) = %6d", i, Data_Mem.comb_DM[i]);
    //`endif

    $display("---Simulation End---");
    $finish;
end

endmodule