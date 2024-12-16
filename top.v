`include "IF.v"
`include "ID.v"
`include "EX.v"
`include "WB.v"
`include "Controller.v"

module top (halt, mem_data, EX_MEM_mem_rw, EX_MEM_result, pc, clk, rst, inst);

inout [63:0] mem_data;
input clk, rst;
input [31:0] inst;

output halt;
output [31:0] pc;
output EX_MEM_mem_rw;
output EX_MEM_result;

wire [63:0] imm;
wire [63:0] wdata;

// Pipelined Registers for IF/ID
reg [31:0] IF_ID_pc;

// Pipelined Registers for ID/EX
reg [6:0]  ID_EX_opcode;
reg [31:0] ID_EX_pc;
reg [63:0] ID_EX_data1;
reg [63:0] ID_EX_data2;
reg [4:0]  ID_EX_rd;
reg [2:0]  ID_EX_func3;
reg [6:0]  ID_EX_func7;
reg [63:0] ID_EX_imm;
 
// Pipelined Registers for EX/MEM
reg [6:0]  EX_MEM_opcode;
reg [31:0] EX_MEM_pc_branch;
reg        EX_MEM_is_branch; // called Zero in ALU
reg [4:0]  EX_MEM_rd;
reg [63:0] EX_MEM_result;
reg [63:0] EX_MEM_data2;
reg        EX_MEM_mem_rw;
reg        EX_MEM_is_load;
  
// Pipelined Registers for MEM/WB
reg [6:0]  MEM_WB_opcode;
reg [4:0]  MEM_WB_rd;
reg [63:0] MEM_WB_result;
reg        MEM_WB_is_load;
reg [63:0] MEM_WB_mem_data;
reg        MEM_WB_mem_rw;

IF IF(pc, clk, rst, EX_MEM_pc_branch, EX_MEM_is_branch);
ID ID(opcode, data1, data2, rd, func3, func7, imm, clk, rst, inst, wdata, MEM_WB_rd, MEM_WB_opcode);
EX EX(pc_branch, is_branch, result, mem_rw, is_load, clk, rst, ID_EX_opcode, ID_EX_data1, ID_EX_data2, ID_EX_func3, ID_EX_func7, ID_EX_imm, ID_EX_pc);

// MEM Stage
assign mem_data = (EX_MEM_mem_rw)?  EX_MEM_data2 : 64'bz ;

WB WB(wdata, MEM_WB_is_load, MEM_WB_result, MEM_WB_mem_data);

Controller Controller();

always @(posedge clk or rst) begin
    if (rst) begin // clear all registers for pipeline
        // IF -> ID
        IF_ID_pc <= 0;

        // ID -> EX
        ID_EX_pc <= 0;
        ID_EX_opcode <= 0;
        ID_EX_imm <= 0;
        ID_EX_data1 <= 0;
        ID_EX_data2 <= 0;
        ID_EX_rd <= 0;
        ID_EX_func3 <= 0;
        ID_EX_func7 <= 0;

        // EX -> MEM
        EX_MEM_opcode <= 0;
        EX_MEM_pc_branch <= 0;
        EX_MEM_is_branch <= 0;
        EX_MEM_rd <= 0;
        EX_MEM_result <= 0;
        EX_MEM_data2 <= 0;
        EX_MEM_mem_rw <= 0;
        EX_MEM_is_load <= 0;

        // MEM -> WB
        MEM_WB_opcode <= 0;
        MEM_WB_rd <= 0;
        MEM_WB_result <= 0;
        MEM_WB_is_load <= 0;
        MEM_WB_mem_data <= 0;
        MEM_WB_mem_rw <= 0;
    end 
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

        // EX -> MEM
        EX_MEM_opcode <= ID_EX_opcode;
        EX_MEM_pc_branch <= pc_branch;
        EX_MEM_is_branch <= is_branch;
        EX_MEM_rd <= ID_EX_rd;
        EX_MEM_result <= result;
        EX_MEM_data2 <= ID_EX_data2;
        EX_MEM_mem_rw <= mem_rw;
        EX_MEM_is_load <= is_load;

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