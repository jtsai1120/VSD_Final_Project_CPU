

module EX (pc_branch, is_branch, result, mem_rw, is_load, clk, rst, opcode, data1, data2, func3, func7, imm, pc);

input clk, rst;
input [6:0] opcode;
input [2:0] func3;
input [6:0] func7;
input [63:0] imm;
input [63:0] data1, data2;
input [31:0] pc;

output [31:0] pc_branch;
output is_branch;
output [63:0] result;
output mem_rw; // 0:read, 1:write
output is_load; // 1: load, 0: others


// 把 pc 加上 imm 傳到 pc_branch (用你們實作的加法器)



// 1. 用 case 將 opcode 分類，然後個別寫出相對應的運算，並將結果存入 result
// 2. 如果 branch 類型指令要跳，則 is_branch 改為 1，反之則 0
// 3. 如果是 Store 類型指令的話，將 mem_rw 改為 1，反之其他指令都將 mem_rw 設為 0
// 4. 如果是 Load 類型指令的話，將 is_load 改為 1，反之其他指令都將 is_load 設為 0
// 若有其他有問題或想補充的部分，請跟Foby、承希討論！

endmodule