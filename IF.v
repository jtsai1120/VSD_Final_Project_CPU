
module IF (cpc, clk, rst, pc_branch, is_branch)

input [31:0] pc_branch;
input is_branch;
input clk, rst;

output reg [31:0] cpc;

wire [31:0] npc;
assign npc = cpc + 4;

always @(posedge clk or rst) begin
    if (rst) begin
        cpc <= 0;
    end
    else if (is_branch) begin
        cpc <= pc_branch;
    end
    else begin
        cpc <= npc;
    end
end 

endmodule