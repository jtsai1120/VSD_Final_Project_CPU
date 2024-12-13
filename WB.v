
module WB (wdata, is_load, result, mem_data);

input is_load;
input [63:0] result, mem_data;
output [63:0] wdata;

assign wdata = (is_load)? mem_data : result;

endmodule