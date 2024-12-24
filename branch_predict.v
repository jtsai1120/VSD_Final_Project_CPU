/*
GHR?òØ??Ëø?8Ê¨°Á?ÑÂà§?ñ∑
address?òØPC??ÑÊ?‰ΩéÂÖ´‰ΩçÂ?ÉÔ??
?Ö©?ãË?äË?üXORÂæåÂ?óÂà∞‰∏??ãindex
ÁøªBHT‰∏≠index‰ΩçÂ???ÑÁ?êÊ?úÊòØÂ§öÂ??
?Ñ∂ÂæåÊ?äÈ?ôÂ?ãÂØ¶??õÁ?êÊ?ú‰?üÈ?≤ÂéªGHR??ÑÊ??è≥??äÔ?åÊ?Â∑¶È?äÁ?Ñ‰?üÊ??
*/
module gshare_predictor (
    input start,update,
    input rst,
    input [7:0] branch_address,update_address,  // ??ÜÊîØ??á‰ª§?ú∞????Ñ‰?? 8 ‰Ω?
    input branch_taken,          // ÂØ¶È?õÂ?ÜÊîØÁµêÊ??
    input [6:0]opcode,
    input [31:0]EX_MEM_pc,
    output reg prediction        // ??êÊ∏¨ÁµêÊ??
);
    parameter GHR_BITS = 8;      // ?Ö®Â±?Ê≠∑Âè≤ÂØÑÂ?òÂô®‰ΩçÊï∏
    parameter BHT_SIZE = 256;    // ??ÜÊîØÊ≠∑Âè≤Ë°®Â§ßÂ∞?

    reg [GHR_BITS-1:0] GHR;      // ?Ö®Â±???ÜÊîØÊ≠∑Âè≤ÂØÑÂ?òÂô®
    reg [1:0] BHT[BHT_SIZE-1:0]; // ??ÜÊîØÊ≠∑Âè≤Ë°®Ô??2 ‰ΩçÈ£Ω??åË?àÊï∏?ô®Ôº?

    wire [7:0] index;            // BHT Á¥¢Â??
    wire [7:0] update_index;
    // XOR ??ç‰?úÁ?üÊ?êÁ¥¢Âº?
    assign index = branch_address ^ GHR;
    assign update_index = update_address ^ GHR;
    integer i;
    // ??êÊ∏¨??èËºØ
    always @(*) begin
        if(rst) prediction=0;
        else if (start) prediction = ((BHT[index] >= 2'b10)||(opcode==7'b1100111)|| (opcode == 7'b1101111))?1:0; // 10 ??? 11 ??êÊ∏¨Ë∑≥Ë??
        else prediction = 0;
    end
    
    // ?õ¥?ñ∞??èËºØ
    always @(EX_MEM_pc or posedge rst) begin
        if (rst) begin
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                BHT[i] = 2'b01; // ??ùÂ?ãÂ?ñÁÇ∫?åÂº±‰∏çË∑≥ËΩâ„??
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
        // ?õ¥?ñ∞ GHR
        if(rst) GHR = 0;
        else if(update)   GHR = {GHR[GHR_BITS-2:0], branch_taken};
        else GHR = GHR;
    end
endmodule