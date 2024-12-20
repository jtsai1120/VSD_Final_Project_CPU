`timescale 1ns/1ps
//`include "branch_predict.v"

module BRA_predict;
gshare_predictor uut(
    .start(start),
    .update(update),
    .rst(rst),
    .branch_address(branch_address),
    .update_address(update_address),  // ����誘������� 8 雿�
    .branch_taken(branch_taken),          // 撖阡��蝯��
    .opcode(opcode),
    .prediction(prediction)        // ��葫蝯��
);
reg start,update;
reg rst;
reg [7:0] branch_address,update_address;  // ����誘������� 8 雿�
reg branch_taken;          // 撖阡��蝯��
reg [6:0]opcode;
wire prediction;

initial begin
$monitor("time:%d prediction:%b" ,
            $time,prediction);
end
initial begin
rst=1;

#5
rst=0;
#4;
    start=1;
    update=0;
    branch_address=8'd4;
    update_address=8'd4;
    branch_taken=1;
    opcode=7'b1100011;//7'b1100011||7'b1100111|| 7'b1101111
#10
    update=1;
#5
    update=0;
#5
    update=1;
#5
    update=0;
#5  
    update=1;
    opcode=7'b1100111;
#5  
    update =0;
    start =0;
#5
    update=1;
#5  
    update=0;
    start=1;
    opcode=7'b1101111;
#5  
    update=1;
    start=1;
    opcode=7'b1100011;
#5;
$finish;


end
endmodule