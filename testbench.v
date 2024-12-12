`timescale 1ns/1ps
`include "top.v"
`include "Inst_Mem.v"
`include "Data_Mem.v"

module testbench ()

reg clk, rst;
wire [31:0] inst;
wire [31:0] pc;
wire [63:0] mem_data;
wire [63:0] addr;
wire mem_rw;

top top(mem_data, mem_rw, addr, pc, clk, rst, inst);
Inst_Mem Inst_Mem(inst, pc);
Data_Mem Data_Mem(mem_data, clk, rst, mem_rw, addr);

$readmemb(asfasd);
$readmemb(asfasd);

endmodule