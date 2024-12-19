`timescale 1ns/1ps
`include "WB.v"
module WB_tb;

reg  is_load;
reg  [63:0] result, mem_data;
wire  [63:0] wdata;

WB WB(wdata, is_load, result, mem_data);
initial begin
$monitor("time:%d wdata:%d mem_data:%d result:%d is_load:%b",$time,wdata,mem_data,result,is_load);
end
initial begin
is_load=1;
result = 64'd20;
mem_data = 64'd30;
#10  
is_load=1;
result = 64'd40;
mem_data = 64'd50;
#10  
is_load=0;
result = 64'd40;
mem_data = 64'd50;
#10  
is_load=0;
result = 64'd30;
mem_data = 64'd100;
$finish;
end

endmodule