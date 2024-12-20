`timescale 1ns/1ps
//`include "ID.v"
module ID_tb;

ID ID(rs1_data_control,opcode, data1, data2, rd, func3, func7, imm_ext, clk, rst, inst, wdata, wrd, wopcode,rs1_addr,control);
reg clk, rst;
reg [31:0] inst;
reg [63:0] wdata; // write back data
reg [4:0]  wrd; // write back rd 
reg [6:0]  wopcode; // write back opcode
reg [4:0]  rs1_addr_control;

wire[6:0] opcode;
wire[63:0] data1, data2;
wire[4:0] rd;
wire[2:0] func3;
wire[6:0] func7;
wire[63:0]imm_ext;
wire[63:0]rs1_data_control;

initial begin
    clk=0;
    forever #5 clk = ~clk;
end
initial begin
$monitor("time:%d opcode:%b data1:%d  data2:%d rd:%b func3:%b func7:%d imm_ext:%d rs1_data_control:%d",
            $time,opcode,data1,data2,rd,func3,func7,imm_ext,rs1_data_control);
end
initial begin
    rst=1;
    #5
    rst =0;
    #5
    
end

endmodule