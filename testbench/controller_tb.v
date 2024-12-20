`timescale 1ns/1ps
//`include "Controller.v"

module Controller_tb;

    reg clk, rst;
    reg [6:0] ID_EX_opcode, EX_MEM_opcode, MEM_WB_opcode;
    reg [4:0] ID_EX_rs1, ID_EX_rs2, EX_MEM_rd, MEM_WB_rd;
    reg [31:0] ID_inst, pc, EX_MEM_pc;
    reg is_branch;
    reg [63:0] rs1_data;
    reg is_load;
    
    wire [4:0] rs1_addr;
    wire prediction;
    wire NOP;
    wire [1:0] ForwardA, ForwardB;
    wire [31:0] new_pc;

    // Instantiate the Controller module
    Controller uut (
        .ForwardA(ForwardA),
        .ForwardB(ForwardB),
        .new_pc(new_pc),
        .rs1_addr(rs1_addr),
        .prediction(prediction),
        .NOP(NOP),
        .clk(clk),
        .rst(rst),
        .is_load(is_load),
        .ID_EX_opcode(ID_EX_opcode),
        .EX_MEM_opcode(EX_MEM_opcode),
        .MEM_WB_opcode(MEM_WB_opcode),
        .ID_inst(ID_inst),
        .ID_EX_rs1(ID_EX_rs1),
        .ID_EX_rs2(ID_EX_rs2),
        .EX_MEM_rd(EX_MEM_rd),
        .MEM_WB_rd(MEM_WB_rd),
        .is_branch(is_branch),
        .pc(pc),
        .EX_MEM_pc(EX_MEM_pc),
        .rs1_data(rs1_data)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Stimulus generation
    initial begin
        // Initialize inputs
        rst = 1;
        ID_EX_opcode = 7'b0010011;  // default opcode: addi
        EX_MEM_opcode = 7'b0010011;  // default opcode: addi
        MEM_WB_opcode = 7'b0010011;  // default opcode: addi
        ID_EX_rs1 = 5'd1;
        ID_EX_rs2 = 5'd2;
        EX_MEM_rd = 5'd3;
        MEM_WB_rd = 5'd4;
        ID_inst = 32'b0;
        pc = 32'd100;  // starting address
        EX_MEM_pc = 32'd104;
        is_branch = 0;
        is_load = 0;
        rs1_data = 64'd10;  // some value for rs1_data

        // Wait for reset to propagate
        #10;
        rst = 0;

        // Apply test cases
        // Example 1: ADDI instruction
        ID_inst = 32'b00000000001000001000001010000011; // addi x5, x1, 10
        #10;

        // Example 2: Branch instruction
        ID_inst = 32'b11111110001000001000100011100011; // beq x1, x2, start
        is_branch = 1;
        #10;

        // Example 3: Jump and link instruction
        ID_inst = 32'b11111110110111111111000011101111; // jal x1, start
        is_branch = 1;
        #10;

        // Example 4: No operation
        ID_inst = 32'b00000000000000000000000000000000; // NOP
        #10;

        $finish;  // End the simulation
    end

    // Monitor outputs
    initial begin
        $monitor("time: %d | ID_inst: %b | rs1_addr: %d | prediction: %b | NOP: %b | ForwardA: %b | ForwardB: %b | new_pc: %d | rst: %b | is_branch: %b | is_load: %b",
                 $time, ID_inst, rs1_addr, prediction, NOP, ForwardA, ForwardB, new_pc, rst, is_branch, is_load);
    end

endmodule