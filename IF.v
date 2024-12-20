//到時候pc_branch只有在flush時才要傳回來，要把正確的pc傳過來。
//flush訊號為EX_MEM and is_branch^EX_MEM_prediction)(應該)

module IF (cpc, clk, rst, pc_branch,NOP,flush,prediction,control_pc,halt_happen);

input [31:0] pc_branch;
input clk, rst;
input NOP,flush,prediction,halt_happen;
input [31:0] control_pc;
output reg [31:0] cpc;

wire [31:0] npc;
assign npc = cpc + 4;

always @(posedge clk or posedge rst) begin
    if (rst) begin
        cpc <= 0;
    end
    else if (flush) begin
        cpc <= pc_branch;
    end
    else if(NOP||halt_happen) begin
        cpc <= cpc;
    end
    else if(prediction) begin
        cpc<=control_pc;
    end
    else begin
        cpc <= npc;
    end
end 

endmodule