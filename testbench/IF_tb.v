`timescale 1ns/1ps
`include "IF.v"
module IF_tb;

reg [31:0] pc_branch;
reg clk, rst;
reg NOP,flush,prediction;
reg [31:0] control_pc;
wire [31:0] cpc;

IF IF(cpc, clk, rst, pc_branch,NOP,flush,prediction,control_pc);
initial begin
clk=0;
forever #5 clk = ~clk;
end
initial begin
$monitor("time:%d cpc:%d pc_branch:%d  NOP:%b flush:%b,prediction:%b control_pc:%d",
            $time,cpc,pc_branch,NOP,flush,prediction,control_pc);
end
initial begin
rst=1;
#5;
rst=0;
#4
pc_branch=32'd100;
NOP=0;
flush=0;
prediction=0;
control_pc=32'd200;
#30
pc_branch=32'd100;
NOP=0;
flush=0;
prediction=1;
control_pc=32'd200;
#10
pc_branch=32'd100;
NOP=0;
flush=0;
prediction=0;
control_pc=32'd200;
#20
pc_branch=32'd100;
NOP=1;
flush=0;
prediction=1;
control_pc=32'd200;
#10
pc_branch=32'd50;
NOP=1;
flush=1;
prediction=0;
control_pc=32'd200;
#10
pc_branch=32'd50;
NOP=1;
flush=1;
prediction=1;
control_pc=32'd200;
#10
pc_branch=32'd50;
NOP=0;
flush=0;
prediction=0;
control_pc=32'd200;
#30
$finish;

end

endmodule