`timescale 1ns/1ps
//`include "ID.v"
module ID_tb;

ID ID (rs1_data_control,opcode, data1, data2, rd, func3, func7, imm_ext, clk, rst, inst, wdata, wrd, wopcode,rs1_addr_control,flush);
reg clk, rst,flush;
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
    flush=0;
    #4
    inst ='b00000000001000001000001010000011;//add x5, x1, x2
    wdata = 0;
    wrd =5'd0   ;
    wopcode ='b11101111;
    rs1_addr_control=5'd0;
    #10
    inst ='b00000000101000001000001010010011;//addi x5, x1, 10
    wdata = 0;
    wrd =5'd0   ;
    wopcode ='b11101111;
    rs1_addr_control=5'd0;
    #10
    inst ='b00000000010100001010000000100011;//sw x5, 0(x1)
    wdata = 0;
    wrd =5'd0   ;
    wopcode ='b11101111;
    rs1_addr_control=5'd0;
    #10
    inst ='b00000000000000100000001010110111;//lui x5, 32
    wdata = 0;
    wrd =5'd0   ;
    wopcode ='b11101111;
    rs1_addr_control=5'd0;
    #10
    inst ='b11111110001000001000100011100011;//beq x1, x2, start
    wdata = 0;
    wrd =5'd0   ;
    wopcode ='b11101111;
    rs1_addr_control=5'd3;
    #10
    inst ='b11111110110111111111000011101111;//jal x1, start
    wdata = 5;
    wrd =5'd1   ;
    wopcode ='b0000011;
    rs1_addr_control=5'd1;
    #10
    inst ='b00000000001000001000001010000011;//add x5, x1, x2
    wdata = 0;
    wrd =5'd0;
    wopcode ='b11101111;
    rs1_addr_control=5'd0;
    #20
    $finish;
    
end

endmodule