/*
GHR是最近8次的判斷
address是PC的最低八位元，
兩個訊號XOR後得到一個index
翻BHT中index位址的結果是多少
然後把這個實際結果丟進去GHR的最右邊，最左邊的丟掉
*/
module gshare_predictor (
    input start,update,
    input rst,
    input [7:0] branch_address,update_address,  // 分支指令地址的低 8 位
    input branch_taken,          // 實際分支結果
    input [6:0]opcode;
    output reg prediction        // 預測結果
);
    parameter GHR_BITS = 8;      // 全局歷史寄存器位數
    parameter BHT_SIZE = 256;    // 分支歷史表大小

    reg [GHR_BITS-1:0] GHR;      // 全局分支歷史寄存器
    reg [1:0] BHT[BHT_SIZE-1:0]; // 分支歷史表（2 位飽和計數器）

    wire [7:0] index;            // BHT 索引
    wire [7:0] update_index;
    // XOR 操作生成索引
    assign index = branch_address ^ GHR;
    assign update_index = update_address ^ GHR;
    integer i;
    // 預測邏輯
    always @(*) begin
        if(rst) prediction=0;
        else if (start) prediction = ((BHT[index] >= 2'b10)||(opcode==1100111|| 1101111)); // 10 或 11 預測跳轉
        else 
        prediction = 0;
    end
    
    // 更新邏輯
    always @(posedge update or rst) begin
        if (rst) begin
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                BHT[i] <= 2'b01; // 初始化為「弱不跳轉」
            end 
        end
        else if (branch_taken) begin
            if (BHT[update_index] < 2'b11) BHT[update_index] <= BHT[update_index] + 1;
            else BHT[update_index] <= BHT[update_index];
        end 
        else begin
            if (BHT[update_index] > 2'b00) BHT[update_index] <= BHT[update_index] - 1;
            else BHT[update_index] <= BHT[update_index];
        end
    end
    always@(posedge update or rst)begin
        // 更新 GHR
        if(rst) GHR <= 0;
        else    GHR <= {GHR[GHR_BITS-2:0], branch_taken};
    end
endmodule