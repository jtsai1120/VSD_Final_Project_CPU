`define OP inst[6:0]

`define R_func7 inst[31:25]
`define R_rs2 inst[24:20]
`define R_rs1 inst[19:15]
`define R_func3 inst[14:12]
`define R_rd inst[11:7]

`define I_imm_11_0 inst[31:20]
`define I_rs1 inst[19:15]
`define I_func3 inst[14:12]
`define I_rd inst[11:7]

`define S_imm_11_5 inst[31:25]
`define S_rs2 inst[24:20]
`define S_rs1 inst[19:15]
`define S_func3 inst[14:12]
`define S_imm_4_0 inst[11:7]
 
`define B_imm_12 inst[31]
`define B_imm_10_5 inst[30:25]
`define B_rs2 inst[24:20]
`define B_rs1 inst[19:15]
`define B_func3 inst[14:12]
`define B_imm_4_1 inst[11:8]
`define B_imm_11 inst[7]

`define U_imm_31_12 inst[31:12]
`define U_rd inst[11:7]

`define J_imm_20 inst[31]
`define J_imm_10_1 inst[30:21]
`define J_imm_11 inst[20]
`define J_imm_19_12 inst[19:12]
`define J_rd inst[11:7]

`define NOP_opcode 'b0010011
`define NOP_rs1 'b00000
`define NOP_rs2 'b00000
`define NOP_rd 'b00000
`define NOP_func7 'b0000000
`define NOP_func3 'b000
`define NOP_imm 'b000000000000
module ID (rs1_data_control,opcode, data1, data2, rd, func3, func7, imm_ext, clk, rst, inst, wdata, wrd, wopcode,rs1_addr_control,flush);
parameter R_type = 110011;
input clk, rst,flush;
input [31:0] inst;
input [63:0] wdata; // write back data
input [4:0] wrd; // write back rd 
input [6:0] wopcode; // write back opcode
input [4:0] rs1_addr_control;

output reg [6:0] opcode;
output reg [63:0] data1, data2;
output reg [4:0] rd;
output reg [2:0] func3;
output reg [6:0] func7;
output reg [63:0]imm_ext;
output     [63:0]rs1_data_control;

reg [63:0] RF [0:31];
assign rs1_data_control=(wrd==rs1_addr_control)?wdata:RF[rs1_addr_control];
always @(posedge clk or posedge rst or flush) begin
    if (rst || flush) begin
        opcode <= `NOP_opcode;
        data1 <= RF[`NOP_rs1];
        data2 <= RF[`NOP_rs2];
        rd <= `NOP_rd;
        func3 <= `NOP_func3;
        func7 <= `NOP_func7 ;
    end 
    else begin
        opcode <= `OP;
        data1 <= RF[`R_rs1];
        data2 <= RF[`R_rs2];
        rd <= `R_rd;
        func3 <= `R_func3;
        func7 <= `R_func7;
    end
end

always @(posedge clk or posedge rst or flush) begin
    if (rst || flush) begin
        imm_ext <= 0;
    end
    else begin
        case (`OP)
            'b0010011: begin // I Type (operation)
                imm_ext <= {{52{inst[31]}}, inst[31:20]};
            end
            'b0000011: begin // I Type (operation immediate)
                imm_ext <= {{52{inst[31]}}, inst[31:20]};
            end
            'b1100111: begin // I Type (jalr)
                imm_ext <= {{52{inst[31]}}, inst[31:20]};
            end
            'b0100011: begin // S Type (store)
                imm_ext <= {{52{inst[31]}}, inst[31:25], inst[11:7]};
            end
            'b1100011: begin // B Type (branch)
                imm_ext <= {{51{inst[31]}}, inst[31], inst[7], inst[30:25], inst[11:8],1'b0};
            end
            'b0110111: begin // U Type (lui)
                imm_ext <= {{32{inst[31]}}, inst[31:12], 12'b0};
            end
            'b0010111: begin // U Type (auipc)
                imm_ext <= {{32{inst[31]}}, inst[31:12], 12'b0};
            end
            'b1101111: begin // J Type (jal)
                imm_ext <= {{43{inst[31]}}, inst[31], inst[19:12], inst[20], inst[30:21], 1'b0};
            end
            default: begin // Unknown or R Type (no imm)
                imm_ext <= 0;
            end
        endcase
    end
end

always @(negedge clk or posedge rst) begin
    if (rst) begin
        RF[0] <= 64'd0;
        RF[1] <= 64'd0;
        RF[2] <= 64'd0;
        RF[3] <= 64'd0;
        RF[4] <= 64'd0;
        RF[5] <= 64'd0;
        RF[6] <= 64'd0;
        RF[7] <= 64'd0;
        RF[8] <= 64'b0;
        RF[9] <= 64'b0;
        RF[10] <= 64'b0;
        RF[11] <= 64'b0;
        RF[12] <= 64'b0;
        RF[13] <= 64'b0;
        RF[14] <= 64'b0;
        RF[15] <= 64'b0;
        RF[16] <= 64'b0;
        RF[17] <= 64'b0;
        RF[18] <= 64'b0;
        RF[19] <= 64'b0;
        RF[20] <= 64'b0;
        RF[21] <= 64'b0;
        RF[22] <= 64'b0;
        RF[23] <= 64'b0;
        RF[24] <= 64'b0;
        RF[25] <= 64'b0;
        RF[26] <= 64'b0;
        RF[27] <= 64'b0;
        RF[28] <= 64'b0;
        RF[29] <= 64'b0;
        RF[30] <= 64'b0;
        RF[31] <= 64'b0;
    end
    else begin  
        
        // Store �?? Branch 不用 write back
        if(wrd==0) RF[wrd] <=0;
        else if (opcode != 7'b0100011 && opcode != 7'b1100011) RF[wrd] <= wdata;
        else RF[wrd] <= RF[wrd];
    end
end


endmodule