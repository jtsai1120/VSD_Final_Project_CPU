`include "IF.v"
`include "ID.v"
`include "EX.v"
`include "WB.v"
`include "Controller.v"

`define NOP_opcode 0010011
`define NOP_rs1 00000
`define NOP_rd 00000
`define NOP_func3 000
`define NOP_imm 000000000000
`define NOP_func7 0000000
module top (flush,NOP,mem_data, EX_MEM_mem_rw, EX_MEM_result, pc, clk, rst, inst);

inout [63:0] mem_data;
input clk, rst;
input [31:0] inst;

output [31:0] pc;
output EX_MEM_mem_rw;
output EX_MEM_result;

wire [63:0] imm;
wire [63:0] wdata;
wire [6:0]  opcode;
//controller signal
wire        NOP,flush,predictin;
wire [63:0] rs1_data_control;        
wire [4:0]  rs1_addr_control;
wire [31:0] control_pc;
wire [1:0]  ForwardA,ForwardB;
wire [63:0] for_ID_EX_data1;
wire [63:0] for_ID_EX_data2;


// Pipelined Registers for IF/ID
reg [31:0] IF_ID_pc;
reg [31:0] IF_ID_inst;//present useless
reg        IF_ID_prediction;


// Pipelined Registers for ID/EX
reg [6:0]  ID_EX_opcode;
reg [31:0] ID_EX_pc;
reg [63:0] ID_EX_data1;
reg [63:0] ID_EX_data2;
reg [4:0]  ID_EX_rd;
reg [2:0]  ID_EX_func3;
reg [6:0]  ID_EX_func7;
reg [63:0] ID_EX_imm;
reg        ID_EX_prediction;

// Pipelined Registers for EX/MEM
reg [6:0]  EX_MEM_opcode;
reg [31:0] EX_MEM_pc_branch;
reg        EX_MEM_is_branch; // called Zero in ALU
reg [4:0]  EX_MEM_rd;
reg [63:0] EX_MEM_result;
reg [63:0] EX_MEM_data2;
reg        EX_MEM_mem_rw;
reg        EX_MEM_is_load;
reg        EX_MEM_prediction;

// Pipelined Registers for MEM/WB
reg [6:0]  MEM_WB_opcode;
reg [4:0]  MEM_WB_rd;
reg [63:0] MEM_WB_result;
reg        MEM_WB_is_load;
reg [63:0] MEM_WB_mem_data;
reg        MEM_WB_mem_rw;


IF IF(pc, clk, rst, EX_MEM_pc_branch, EX_MEM_is_branch,NOP,flush,IF_ID_prediction,control_pc);
ID ID(rs1_data_control,opcode,data1, data2, rd, func3, func7, imm, clk, rst,IF_ID_inst, wdata, MEM_WB_rd, MEM_WB_opcode,rs1_addr_control);
EX EX(pc_branch, is_branch, result, mem_rw, is_load, clk, rst, ID_EX_opcode, for_ID_EX_data1, for_ID_EX_data2, ID_EX_func3, ID_EX_func7, ID_EX_imm, ID_EX_pc);

// MEM Stage
assign mem_data = (EX_MEM_mem_rw)?  EX_MEM_data2 : 64'bz ;

WB WB(wdata, MEM_WB_is_load, MEM_WB_result, MEM_WB_mem_data);

//controller
Controller Controller(ForwardA,ForwardB,control_pc,rs1_addr_control,predictino,NOP,clk,rst,is_load,ID_EX_opcode,EX_MEM_opcode,MEM_WB_opcode,
                                ID_inst,ID_EX_rs1,ID_EX_rs2,EX_MEM_rd,MEM_WB_rd,is_branch,pc,rs1_data_control);
assign for_ID_EX_data1=(ForwardA==2'b01)?EX_MEM_result:
                       (ForwardA==2'b10)?MEM_WB_result:
                       ID_EX_data1;
assign for_ID_EX_data2=(ForwardB==2'b01)?EX_MEM_result:
                       (ForwardB==2'b10)?MEM_WB_result:
                       ID_EX_data2;

assign flush=is_branch^ID_EX_prediction;

always@(predictin or rst or flush)begin
    if(rst)
        IF_ID_prediction=0;
    else if(flush)
        IF_ID_prediction=0;
    else
        IF_ID_prediction=predictin;

end

always@(inst or rst or flush)begin
    if(rst)
        IF_ID_inst={25{0},`NOP_opcode};
    else if(flush)
        IF_ID_inst={25{0},`NOP_opcode};
    else
        IF_ID_inst=inst;
end

//pipeline
always @(posedge clk or rst) begin
    if (rst) begin
        // clear all registers for pipeline
        //記得初始值得inst會是 addi x0 x0 0
    end
    else if(flush)begin
         // ID -> EX
        ID_EX_pc <= 0;
        ID_EX_opcode <= `NOP_opcode;
        ID_EX_imm <= `NOP_imm;
        ID_EX_data1 <= 64{0};
        ID_EX_data2 <= 64{0};
        ID_EX_rd <= `NOP_rd;
        ID_EX_func3 <= `NOP_func3;
        ID_EX_func7 <= `NOP_func7;
    end 
    else if(NOP)
        // IF -> ID
        IF_ID_pc <= IF_ID_pc;
        // ID -> EX
        ID_EX_pc <= ID_EX_pc;
        ID_EX_opcode <= ID_EX_opcode;
        ID_EX_imm <= ID_EX_imm;
        ID_EX_data1 <= ID_EX_data1;
        ID_EX_data2 <= ID_EX_data2;
        ID_EX_rd <= ID_EX_rd;
        ID_EX_func3 <= ID_EX_func3;
        ID_EX_func7 <= ID_EX_func7;
        ID_EX_prediction <= ID_EX_prediction;
        // EX -> MEM
        EX_MEM_opcode <= `NOP_opcode;
        EX_MEM_pc_branch <= 0;
        EX_MEM_is_branch <= 0;
        EX_MEM_rd <= `NOP_rd;
        EX_MEM_result <= 0;
        EX_MEM_data2 <= 0;
        EX_MEM_mem_rw <= 0;
        EX_MEM_is_load <= 0;
        ID_EX_prediction <= 0;
    else begin
        // IF -> ID
        IF_ID_pc <= pc;
        
        // ID -> EX
        ID_EX_pc <= IF_ID_pc;
        ID_EX_opcode <= opcode;
        ID_EX_imm <= imm;
        ID_EX_data1 <= data1;
        ID_EX_data2 <= data2;
        ID_EX_rd <= rd;
        ID_EX_func3 <= func3;
        ID_EX_func7 <= func7;
        ID_EX_prediction <= IF_ID_prediction;
        // EX -> MEM
        EX_MEM_opcode <= ID_EX_opcode;
        EX_MEM_pc_branch <= pc_branch;
        EX_MEM_is_branch <= is_branch;
        EX_MEM_rd <= ID_EX_rd;
        EX_MEM_result <= result;
        EX_MEM_data2 <= ID_EX_data2;
        EX_MEM_mem_rw <= mem_rw;
        EX_MEM_is_load <= is_load;
        ID_EX_prediction <= IF_ID_prediction;
        // MEM -> WB
        MEM_WB_opcode <= EX_MEM_opcode;
        MEM_WB_rd <= EX_MEM_rd;
        MEM_WB_result <= EX_MEM_result;
        MEM_WB_is_load <= EX_MEM_is_load;
        MEM_WB_mem_data <= mem_data;
        MEM_WB_mem_rw <= EX_MEM_mem_rw;
        
    end
end

endmodule