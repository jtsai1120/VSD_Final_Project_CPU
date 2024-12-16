`timescale 1ns/1ps

`ifdef syn
    `include "top_syn.v"
    `include "tsmc18.v"
`else
    `include "top.v"
`endif

`include "Inst_Mem.v"
`include "Data_Mem.v"

`define HALF_CLK_TIME 10

module testbench;

reg clk, rst;
wire [31:0] inst;
wire [31:0] pc;
wire [63:0] mem_data;
wire [63:0] addr;
wire mem_rw;

top top(mem_data, mem_rw, addr, pc, clk, rst, inst);
Inst_Mem Inst_Mem(inst, pc);
Data_Mem Data_Mem(mem_data, clk, rst, mem_rw, addr);

initial begin : Read_Inst
    `ifdef sorting
        $readmemb("./test_prog/sort.prog", Inst_Mem.IM);
    `elsif fibo
        $readmemb("./test_prog/fibo.prog", Inst_Mem.IM);
    `else 
        $readmemb("./test_prog/single_inst.prog", Inst_Mem.IM);
    `endif
end

`ifdef syn
    initial $sdf_annotate("top_syn.sdf", CPU);
`endif

initial begin : waveform
    $dumpfile("tb.fsdb");
    $dumpvars(0, testbench);
end

initial begin : clk_gen
    clk = 0;
    forever #`HALF_CLK_TIME clk = ~clk;
end

initial begin : terminal_display
    $display("---Simulation Start---");
    $monitor("clk=%b, rst=%b, inst=%h, pc=%h, mem_data=%h, addr=%h, mem_rw=%b", clk, rst, inst, pc, mem_data, addr, mem_rw);
end

initial begin : execute
    rst = 1;
    #(`HALF_CLK_TIME * 20) rst = 0;
    @(halt) begin
        $display("Halt ... ");
        if (Data_Mem.DM[0] == 0) 
            $display("All Testcase Passed!");
        else 
            $display("Failed at Section %d!", Data_Mem.DM[0]);
    end
    $display("---Simulation End---");
    $finish;
end

endmodule