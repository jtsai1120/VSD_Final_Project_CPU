`define NOP_opcode 7'b0010011
`define NOP_rs1 5'b00000
`define NOP_rs2 5'b00000
`define NOP_rd 5'b00000
`define NOP_func7 7'b0000000
`define NOP_func3 3'b000
`define NOP_imm 12'b000000000000
`include "IF.v"
`include "ID.v"
`include "EX.v"
`include "WB.v"
`include "Controller.v"

module top (halt,mem_data, EX_MEM_mem_rw, out_result, pc, clk, rst, inst);

inout [63:0] mem_data;
input clk, rst;
input [31:0] inst;
output [31:0] pc;
output EX_MEM_mem_rw;
output [63:0]out_result;
output halt;

//ID  I/O signal
wire [63:0]data1, data2;
wire [4:0] rd,rs1,rs2;
wire [2:0] func3;
wire [6:0] func7;
wire [63:0] imm;
wire [31:0] pc_branch;
wire is_branch;
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
reg        halt_happen;

// Pipelined Registers for IF/ID
reg [31:0] IF_ID_pc;
reg [31:0] IF_ID_inst;
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
reg [4:0]  ID_EX_rs1,ID_EX_rs2;
reg        ID_EX_prediction;

// Pipelined Registers for EX/MEM
wire[63:0] result;
reg [6:0]  EX_MEM_opcode;
reg [31:0] EX_MEM_pc_branch;
reg [31:0] EX_MEM_pc;
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



IF IF(pc, clk, rst, pc_branch,NOP,flush,predictin,control_pc,halt_happen);
ID ID(rs1,rs2,rs1_data_control,opcode,data1, data2, rd, func3, func7, imm, clk, rst,IF_ID_inst, wdata, MEM_WB_rd, MEM_WB_opcode,rs1_addr_control,flush);
EX EX(
    .clk(clk),
    .rst(rst),
    .opcode(ID_EX_opcode),
    .func3(ID_EX_func3),
    .func7(ID_EX_func7),
    .imm(ID_EX_imm),
    .data1(for_ID_EX_data1),
    .data2(for_ID_EX_data2),
    .pc(ID_EX_pc),
    .pc_branch(pc_branch),
    .is_branch(is_branch),
    .result(result),
    .mem_rw(mem_rw),
    .is_load(is_load)
);
// MEM Stage
assign mem_data = (EX_MEM_mem_rw)?  EX_MEM_data2 : 64'bz ;
assign out_result=(EX_MEM_result<=8185)?EX_MEM_result:0;
WB WB(wdata, MEM_WB_is_load, MEM_WB_result, MEM_WB_mem_data);    

//controller
Controller Controller(ForwardA,ForwardB,control_pc,rs1_addr_control,predictin,NOP,clk,rst,EX_MEM_is_load,ID_EX_opcode,EX_MEM_opcode,MEM_WB_opcode,
                                inst,ID_EX_rs1,ID_EX_rs2,EX_MEM_rd,MEM_WB_rd,is_branch,pc,EX_MEM_pc,rs1_data_control);

assign for_ID_EX_data1=(ForwardA==2'b10)?EX_MEM_result:
                       (ForwardA==2'b01)?wdata:
                       ID_EX_data1;
assign for_ID_EX_data2=(ForwardB==2'b10)?EX_MEM_result:
                       (ForwardB==2'b01)?wdata:
                       ID_EX_data2;

assign flush=is_branch^ID_EX_prediction;

assign halt=(MEM_WB_opcode==7'b0000000);

always@(posedge rst or posedge clk)begin
    if(rst/*||flush*/)
        halt_happen<=0;
    else if (flush)
	 halt_happen<=0;
    else if(opcode==7'b0000000)
        halt_happen<=1;
end

always@(posedge clk  or posedge rst  )begin
    if(rst)
        IF_ID_inst<={25'b0,`NOP_opcode};
    else if(NOP)
        IF_ID_inst<=IF_ID_inst;
    else if(flush || halt_happen)
        IF_ID_inst<={25'b0,`NOP_opcode};
    else
        IF_ID_inst<=inst;
end

//pipeline
always @(posedge clk or posedge rst) begin
    if (rst) begin
        // clear all registers for pipeline
        //?���???�???�???????�???nst???���?? addi x0 x0 0

         // IF -> ID
        IF_ID_pc <= 0;
        IF_ID_prediction<=0;
        // ID -> EX
        ID_EX_rs1<=5'b0;
        ID_EX_rs2<=5'b0;
        ID_EX_pc <= 0;
        ID_EX_opcode <= `NOP_opcode;
        ID_EX_imm <= `NOP_imm;
        ID_EX_data1 <= 0;
        ID_EX_data2 <= 0;
        ID_EX_rd <= 0;
        ID_EX_func3 <= 0;
        ID_EX_func7 <= 0;
        ID_EX_prediction <= 0;
        // EX -> MEM
        EX_MEM_opcode <= `NOP_opcode;
        EX_MEM_pc_branch <= 0;
        EX_MEM_rd <= 0;
        EX_MEM_result <= 0;
        EX_MEM_data2 <= 0;
        EX_MEM_mem_rw <= 0;
        EX_MEM_is_load <= 0;
        EX_MEM_pc<=0;
        // MEM -> WB
        MEM_WB_opcode <= `NOP_opcode;
        MEM_WB_rd <= 0;
        MEM_WB_result <= 0;
        MEM_WB_is_load <= 0;
        MEM_WB_mem_data <= 0;
        
    end
    else if(NOP) begin
        // IF -> ID
        IF_ID_pc <= IF_ID_pc;
        IF_ID_prediction<=IF_ID_prediction;
        // ID -> EX
        ID_EX_rs1<=ID_EX_rs1;
        ID_EX_rs2<=ID_EX_rs2;
        ID_EX_pc <= ID_EX_pc;
        ID_EX_opcode <= ID_EX_opcode;
        ID_EX_imm <= ID_EX_imm;
        ID_EX_data1 <= for_ID_EX_data1;
        ID_EX_data2 <= for_ID_EX_data2;
        ID_EX_rd <= ID_EX_rd;
        ID_EX_func3 <= ID_EX_func3;
        ID_EX_func7 <= ID_EX_func7;
        ID_EX_prediction <= ID_EX_prediction;
        // EX -> MEM
        EX_MEM_opcode <= `NOP_opcode;
        EX_MEM_pc_branch <= 0;
        EX_MEM_rd <= `NOP_rd;
        EX_MEM_result <= 0;
        EX_MEM_data2 <= 0;
        EX_MEM_mem_rw <= 0;
        EX_MEM_is_load <= 0;
        MEM_WB_opcode <= EX_MEM_opcode;
        MEM_WB_rd <= EX_MEM_rd;
        MEM_WB_result <= EX_MEM_result;
        MEM_WB_is_load <= EX_MEM_is_load;
        MEM_WB_mem_data <= mem_data;
        
        end
    else if(flush || halt_happen)begin
        IF_ID_pc<=0;
        IF_ID_prediction<=0;
         // ID -> EX
        ID_EX_rs1<=5'b0;
        ID_EX_rs2<=5'b0;
        ID_EX_pc <= 32'b0;
        ID_EX_opcode <= `NOP_opcode;
        ID_EX_imm <= `NOP_imm;
        ID_EX_data1 <= 64'b0;
        ID_EX_data2 <= 64'b0;
        ID_EX_rd <= `NOP_rd;
        ID_EX_func3 <= `NOP_func3;
        ID_EX_func7 <= `NOP_func7;
        ID_EX_prediction<=0;
        //EX_MEM
        EX_MEM_opcode <= ID_EX_opcode;
        EX_MEM_pc_branch <= pc_branch;
        EX_MEM_rd <= ID_EX_rd;
        EX_MEM_result <= result;
        EX_MEM_data2 <= for_ID_EX_data2;
        EX_MEM_mem_rw <= mem_rw;
        EX_MEM_is_load <= is_load;
        EX_MEM_pc <= ID_EX_pc;
        // MEM -> WB
        MEM_WB_opcode <= EX_MEM_opcode;
        MEM_WB_rd <= EX_MEM_rd;
        MEM_WB_result <= EX_MEM_result;
        MEM_WB_is_load <= EX_MEM_is_load;
        MEM_WB_mem_data <= mem_data;
        
    end 
    else begin
        // IF -> ID
        IF_ID_pc <= pc;
        IF_ID_prediction<=predictin;
        // ID -> EX
        ID_EX_rs1<=rs1;
        ID_EX_rs2<=rs2;
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
        EX_MEM_rd <= ID_EX_rd;
        EX_MEM_result <= result;
        EX_MEM_data2 <= for_ID_EX_data2;
        EX_MEM_mem_rw <= mem_rw;
        EX_MEM_is_load <= is_load;
        EX_MEM_pc <= ID_EX_pc;
        // MEM -> WB
        MEM_WB_opcode <= EX_MEM_opcode;
        MEM_WB_rd <= EX_MEM_rd;
        MEM_WB_result <= EX_MEM_result;
        MEM_WB_is_load <= EX_MEM_is_load;
        MEM_WB_mem_data <= mem_data;
        
        
    end
end

endmodule
