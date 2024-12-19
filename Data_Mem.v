
/*
00001100_00111100_00111110_10101010_11110000_00001111_11001100_00110011
addr+7   addr+6   addr+5   addr+4   addr+3   addr+2   addr+1   addr
read
mem_data = {DM[addr+7],DM[addr+6],DM[addr+5],DM[addr+4],DM[addr+3],DM[addr+2],DM[addr+1],DM[addr]};
write
DM[addr]=mem_data[7:0];
DM[addr+1] = mem_data[15:8];
DM[addr+2] = mem_data[23:16];
DM[addr+3] = mem_data[31:24];
DM[addr+4] = mem_data[39:32];
DM[addr+5] = mem_data[47:40];
DM[addr+6] = mem_data[55:48];
DM[addr+7] = mem_data[63:56];
*/
module Data_Mem(mem_data, clk, rst, mem_rw, addr);

parameter Size = 9192;
input clk, rst;
input mem_rw;
input [63:0] addr;
inout [63:0] mem_data;

reg [7:0] DM [0:Size-1];

assign mem_data = (mem_rw)? 64'bz : {DM[addr+7],DM[addr+6],DM[addr+5],DM[addr+4],DM[addr+3],DM[addr+2],DM[addr+1],DM[addr]};

integer i;

always @(negedge clk or rst) begin
    if (rst) begin
        for (i = 0; i < Size; i = i + 1) begin
            DM[i] <= 0;
        end
    end
    else if (mem_rw) begin
        DM[addr]=mem_data[7:0];
        DM[addr+1] = mem_data[15:8];
        DM[addr+2] = mem_data[23:16];
        DM[addr+3] = mem_data[31:24];
        DM[addr+4] = mem_data[39:32];
        DM[addr+5] = mem_data[47:40];
        DM[addr+6] = mem_data[55:48];
        DM[addr+7] = mem_data[63:56];
    end else ;
end


endmodule


