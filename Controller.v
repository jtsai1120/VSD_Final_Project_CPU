`include "branch_predict.v"
module Controller (new_pc,rs1_addr,prediction,NOP,flush,clk,rst,ID_EX_opcode,EX_MEM_opcode,MEM_WB_opcode,
                                ID_inst,ID_EX_rs1,ID_EX_rs2,EX_MEM_rd,MEM_WB_rd,is_branch,pc,rs1_data);
input [6:0]ID_EX_opcode,EX_MEM_opcode,MEM_WB_opcode;
input [4:0]ID_EX_rs1,ID_EX_rs2,EX_MEM_rd,MEM_WB_rd;
input [31:0]ID_inst,pc;
input       is_branch;
input clk,rst;
input [63:0]rs1_data;

output [4:0]rs1_addr;
output reg prediction,NOP,flush;
output reg [31:0]new_pc;
wire into_predic,update;
into_predic=(inst[6:0]==(1100011||1100111|| 1101111))?1:0;
update=(EX_MEM_opcode==(1100011||1100111|| 1101111))?1:0;
rs1_addr=inst[19:15];
gshare_predictor predict(
    .start(into_predic),
    .update(update),
    .rst(rst),
    .branch_address(pc[7:0]),
    .opcode(inst[6:0]),
    .branch_taken(is_branch),
    .prediction(prediction)
);
always@(posedge into_predic)begin
    if(inst[6:0]==1100011) //branch
        new_pc<=pc+{{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8],1'b0};
    else if(inst[6:0]==1101111)//jal
        new_pc<=pc+{{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
    else if(inst[6:0]==1100111)//jalr
        new_pc<=rs1_data[31:0]+{{20{inst[31]}}, inst[31:20]};
    else
        new_pc<=pc;
end



endmodule