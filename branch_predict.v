module gshare_predictor (
    input start,update,
    input rst,
    input [7:0] branch_address,  // 分支指令地址的低 8 位
    input branch_taken,          // 實際分支結果
    input [6:0]opcode;
    output reg prediction        // 預測結果
);
    parameter GHR_BITS = 8;      // 全局歷史寄存器位數
    parameter BHT_SIZE = 256;    // 分支歷史表大小

    reg [GHR_BITS-1:0] GHR;      // 全局分支歷史寄存器
    reg [1:0] BHT[BHT_SIZE-1:0]; // 分支歷史表（2 位飽和計數器）

    wire [7:0] index;            // BHT 索引

    // XOR 操作生成索引
    assign index = branch_address ^ GHR;

    // 初始化
    integer i;
    always @(rst) begin
        GHR <= 0;
        for (i = 0; i < BHT_SIZE; i = i + 1) begin
            BHT[i] <= 2'b01; // 初始化為「弱不跳轉」
        end
    end

    // 預測邏輯
    always @(posedge start or rst) begin
        if(rst) prediction<=0;
        else prediction <= ((BHT[index] >= 2'b10)||(opcode==1100111|| 1101111)); // 10 或 11 預測跳轉
    end
    
    // 更新邏輯
    always @(posedge start) begin
        if (branch_taken) begin
            if (BHT[index] < 2'b11) BHT[index] <= BHT[index] + 1;
            else BHT[index] <= BHT[index];
        end 
        else begin
            if (BHT[index] > 2'b00) BHT[index] <= BHT[index] - 1;
            else BHT[index] <= BHT[index];
        end
    end
    always@(posedge update)begin
        // 更新 GHR
        GHR <= {GHR[GHR_BITS-2:0], branch_taken};
    end
endmodule