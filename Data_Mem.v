

module Data_Mem(mem_data, clk, rst, mem_rw, addr) 

parameter Size = 1024;

input clk, rst;
input mem_rw;
input [63:0] addr;
inout [63:0] mem_data;

reg [63:0] DM [0:Size-1];

assign mem_data = (mem_rw)? 64'bz : DM[addr];

integer i;

always @(negedge clk or rst) begin
    if (rst) begin
        for (i = 0; i < Size; i = i + 1) begin
            DM[i] = 0;
        end
    end
    else if (mem_rw) begin
        DM[addr] = mem_data;
    end else ;
end


endmodule


