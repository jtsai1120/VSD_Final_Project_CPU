/*
GHR?��??�?8次�?�判?��
address?��PC??��?低八位�?��??
?��?��?��?�XOR後�?�到�??�index
翻BHT中index位�???��?��?�是多�??
?��後�?��?��?�實??��?��?��?��?�去GHR??��??��??��?��?左�?��?��?��??
*/
module gshare_predictor (
    input start,update,
    input rst,
    input [7:0] branch_address,update_address,  // ??�支??�令?��????��?? 8 �?
    input branch_taken,          // 實�?��?�支結�??
    input [6:0]opcode,
    input [31:0]EX_MEM_pc,
    output reg prediction        // ??�測結�??
);
    parameter GHR_BITS = 8;      // ?���?歷史寄�?�器位數
    parameter BHT_SIZE = 256;    // ??�支歷史表大�?

    reg [GHR_BITS-1:0] GHR;      // ?���???�支歷史寄�?�器
    reg [1:0] BHT[BHT_SIZE-1:0]; // ??�支歷史表�??2 位飽??��?�數?���?

    wire [7:0] index;            // BHT 索�??
    wire [7:0] update_index;
    // XOR ??��?��?��?�索�?
    assign index = branch_address ^ GHR;
    assign update_index = update_address ^ GHR;
    integer i;
    // ??�測??�輯
    always @(*) begin
        if(rst) prediction=0;
        else if (start) prediction = ((BHT[index] >= 2'b10)||(opcode==7'b1100111)|| (opcode == 7'b1101111))?1:0; // 10 ??? 11 ??�測跳�??
        else prediction = 0;
    end
    
    // ?��?��??�輯
    always @(EX_MEM_pc or posedge rst) begin
        if (rst) begin
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                BHT[i] = 2'b01; // ??��?��?�為?�弱不跳轉�??
            end 
        end
        else if(update) begin 
            if (branch_taken) begin
                if (BHT[update_index] < 2'b11) BHT[update_index] = BHT[update_index] + 1;
                else BHT[update_index] = BHT[update_index];
            end 
            else begin
                if (BHT[update_index] > 2'b00) BHT[update_index] = BHT[update_index] - 1;
                else BHT[update_index] = BHT[update_index];
            end
        end
        else begin
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                BHT[i] = BHT[i]; // keep value
            end 
        end

    end
    always@( EX_MEM_pc or posedge rst)begin
        // ?��?�� GHR
        if(rst) GHR = 0;
        else if(update)   GHR = {GHR[GHR_BITS-2:0], branch_taken};
        else GHR = GHR;
    end
endmodule