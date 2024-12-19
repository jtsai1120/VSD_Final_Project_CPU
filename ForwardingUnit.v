module ForwardingUnit(
    input [4:0] ID_EX_rs1,         
    input [4:0] ID_EX_rs2,       
    input [4:0] EX_MEM_rd,         
    input [4:0] MEM_WB_rd, 
    input rst;       
    input EX_MEM_RegWrite,   
    input MEM_WB_RegWrite,  
    input is_load, 
    output reg [1:0] ForwardA,     
    output reg [1:0] ForwardB,
    output reg NOP      
);
    always @(*) begin
        if(rst)
            NOP = 0;
        else if (is_load && ((ID_EX_rs1 == EX_MEM_rd) || (ID_EX_rs2 == EX_MEM_rd)))
            NOP = 1;
        else 
            NOP = 0;
    end
    always @(*) begin
          //ForwardA
        if(rst)
            ForwardA = 2'b00;
        else if (EX_MEM_RegWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs1)) 
            ForwardA = 2'b10; //source : EX/MEM
        else if (MEM_WB_RegWrite && (MEM_WB_rd != 0) && 
        !(EX_MEM_RegWrite && (EX_MEM_rd != 0) &&(EX_MEM_rd == ID_EX_rs1))&&
        (MEM_WB_rd == ID_EX_rs1)) 
            ForwardA = 2'b01; //source : MEM/WB
        else ForwardA = 2'b00; //source : ID/EX
    end
    always @(*) begin
        //ForwardB
        if(rst)
            ForwardB = 2'b00;
        else if (EX_MEM_RegWrite && (EX_MEM_rd != 0) && (EX_MEM_rd == ID_EX_rs2)) 
            ForwardB = 2'b10; //source : EX/MEM
        else if (MEM_WB_RegWrite && (MEM_WB_rd != 0) && 
        !(EX_MEM_RegWrite && (EX_MEM_rd != 0) &&(EX_MEM_rd == ID_EX_rs2))&&
        (MEM_WB_rd == ID_EX_rs2))
            ForwardB = 2'b01; //source : MEM/WB
        else ForwardB = 2'b00; //source : ID/EX
    end
endmodule