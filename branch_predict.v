/*
翻BHT中index位址的結果是多少
然後把這個實際結果丟進去GHR的最右邊，最左邊的丟掉
*/
module gshare_predictor (
    input start,update,
    input rst,
    input [7:0] branch_address,update_address, 
    input branch_taken,         
    input [6:0]opcode,
    output reg prediction        
);
    parameter GHR_BITS = 8;     
    parameter BHT_SIZE = 256;   

    reg [GHR_BITS-1:0] GHR;      
    reg [1:0] BHT[BHT_SIZE-1:0]; 

    wire [7:0] index;           
    wire [7:0] update_index;
   
    assign index = branch_address ^ GHR;
    assign update_index = update_address ^ GHR;
    integer i;

    always @(*) begin
        if(rst) prediction=0;
        else if (start) prediction = ((BHT[index] >= 2'b10)||(opcode==7'b1100111)|| (opcode == 7'b1101111))?1:0; // 10 ??? 11 ??�測跳�??
        else prediction = 0;
    end
    
    // update logic
    always @(posedge update or posedge rst) begin
        if (rst) begin
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                BHT[i] <= 2'b01; // //preset weak not jump
            end 
        end
        else if(update) begin 
            if (branch_taken) begin
                if (BHT[update_index] < 2'b11) BHT[update_index] = BHT[update_index] + 1;
                else BHT[update_index] <= BHT[update_index];
            end 
            else begin
                if (BHT[update_index] > 2'b00) BHT[update_index] = BHT[update_index] - 1;
                else BHT[update_index] <= BHT[update_index];
            end
        end
        else begin
            for (i = 0; i < BHT_SIZE; i = i + 1) begin
                BHT[i] <= BHT[i]; // keep value
            end 
        end
    end
    always@( posedge update or posedge rst)begin
        // update GHR
        if(rst) GHR <= 0;
        else if(update)   GHR <= {GHR[GHR_BITS-2:0], branch_taken};
        else GHR <= GHR;
    end
endmodule