
module Inst_Mem (inst, pc);

parameter Size = 8192;

input [31:0] pc;
output [31:0] inst;

reg [7:0] IM [0:(Size)*4-1];

assign inst = {IM[pc], IM[pc+1], IM[pc+2], IM[pc+3]};


endmodule