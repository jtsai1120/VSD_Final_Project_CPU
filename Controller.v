`include "branch_predict.v"
`include "ForwardingUnit.v"

module Controller (ForwardA,ForwardB,new_pc,rs1_addr,prediction,NOP,clk,rst,is_load,ID_EX_opcode,EX_MEM_opcode,MEM_WB_opcode,
                                inst,ID_EX_rs1,ID_EX_rs2,EX_MEM_rd,MEM_WB_rd,is_branch,pc,EX_MEM_pc,rs1_data);
input [6:0]ID_EX_opcode,EX_MEM_opcode,MEM_WB_opcode;
input [4:0]ID_EX_rs1,ID_EX_rs2,EX_MEM_rd,MEM_WB_rd;
input [31:0]inst,pc,EX_MEM_pc;
input       is_branch;
input clk,rst;
input [63:0]rs1_data;
input is_load;

output [4:0]rs1_addr;
output prediction;
output NOP;
output reg [31:0]new_pc;
output [1:0]ForwardA,ForwardB;
wire into_predic,update;
wire EX_MEM_RegWrite,MEM_WB_RegWrite;
wire branch_taken;
assign EX_MEM_RegWrite=(EX_MEM_opcode != 7'b0100011 && EX_MEM_opcode != 7'b1100011);
assign MEM_WB_RegWrite=(MEM_WB_opcode != 7'b0100011 && MEM_WB_opcode != 7'b1100011);

//forwarding
ForwardingUnit FU(
.ID_EX_rs1(ID_EX_rs1),         
.ID_EX_rs2(ID_EX_rs2),       
.EX_MEM_rd(EX_MEM_rd),         
.MEM_WB_rd(MEM_WB_rd),
.rst(rst),        
.EX_MEM_RegWrite(EX_MEM_RegWrite),   
.MEM_WB_RegWrite(MEM_WB_RegWrite),  
.is_load(is_load), 
.ForwardA(ForwardA),     
.ForwardB(ForwardB),
.NOP(NOP) 
);


//branch prediction
//input instruction pc EX_MEM_pc  is_branch NOP rs1_data EX_MEM_opcode clk rst 
//output new_pc prediction rs1_addr 
assign into_predic=((inst[6:0]==7'b1100011)||(inst[6:0]==7'b1100111)||(inst[6:0]== 7'b1101111))?1:0;
assign update=((EX_MEM_opcode==7'b1100011)||(EX_MEM_opcode==7'b1100111)||(EX_MEM_opcode== 7'b1101111))&&clk?1:0;
assign rs1_addr=inst[19:15];
assign branch_taken=(is_branch&~NOP);
gshare_predictor predict(
    .start(into_predic),
    .update(update),
    .update_address({EX_MEM_pc[31],EX_MEM_pc[24],EX_MEM_pc[16],EX_MEM_pc[8],EX_MEM_pc[4],EX_MEM_pc[3],EX_MEM_pc[2],EX_MEM_pc[1]}),
    .rst(rst),
    .branch_address({pc[31],pc[24],pc[16],pc[8],pc[4],pc[3],pc[2],pc[1]}),
    .opcode(inst[6:0]),
    .EX_MEM_opcode(EX_MEM_opcode[6:0]),
    .branch_taken(branch_taken),
    .prediction(prediction)
);

/*initial begin
    $monitor("into_predic:%b pc:%d",into_predic,pc);
end*/
always@(pc or inst or rs1_data)begin
        case(inst[6:0])
            7'b1100011:new_pc=pc+{{19{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8],1'b0}; //branch
            7'b1101111:new_pc=pc+{{11{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};//jal
            7'b1100111:new_pc=rs1_data[31:0]+{{20{inst[31]}}, inst[31:20]};//jalr
            default:new_pc=pc;
        endcase
    
end



endmodule