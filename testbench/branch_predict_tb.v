`timescale 1ns/1ps
`include "branch_predict.v"

module BRA_predict;
gshare_predictor uut(
    .start,update(start,update),
    .rst(rst),
    .branch_address(branch_address),
    .update_address(update_address),  // 分支指令地址的低 8 位
    .branch_taken(branch_taken),          // 實際分支結果
    .opcode(opcode),
    .prediction(prediction)        // 預測結果
);
reg start,update,
reg rst,
reg [7:0] branch_address,update_address,  // 分支指令地址的低 8 位
reg branch_taken,          // 實際分支結果
reg [6:0]opcode,
wire prediction;
initial begin
    update=0;
    forever #5 update=~update;
end
initial begin
$monitor("time:%d prediction:%b" ,
            $time,prediction);
end
initial begin
rst=1;
#5
rst=0;
#4;
    start=0;
    branch_address=8'd4;
    update_address=8'd0;
    branch_taken=0;
    opcode=7'b1100011;//7'b1100011||7'b1100111|| 7'b1101111
#10
end
endmodule