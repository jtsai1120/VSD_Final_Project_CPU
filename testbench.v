`timescale 1ns/1ps

`ifdef syn
    `include "top_syn.v"
    `include "tsmc18.v"
`else
    `include "top.v"
`endif

`include "Inst_Mem.v"
`include "Data_Mem.v"

module testbench;

reg clk, rst;
wire [31:0] inst;
wire [31:0] pc;
wire [63:0] mem_data;
wire [63:0] addr;
wire mem_rw;
wire halt;
top top_module(halt,mem_data, mem_rw, addr, pc, clk, rst, inst);
Inst_Mem Inst_Memory(inst, pc);
Data_Mem Data_Memory(mem_data, clk, rst, mem_rw, addr);

initial begin
    $readmemb("./Data.prog", Data_Mem.DM);
    $readmemb("./Inst.prog", Inst_Mem.IM);
end



endmodule