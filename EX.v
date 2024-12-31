module EX(
        input clk, rst,
        input [6:0] opcode,
        input [2:0] func3,
        input [6:0] func7,
        input [63:0] imm,
        input [63:0] data1, data2,
        input [31:0] pc,

        output reg [31:0] pc_branch,
        output reg is_branch,
        output reg [63:0] result,
        output reg mem_rw ,    // 0:read, 1:write
        output reg is_load   // 1: load, 0: others
    );
    /*opcode type*/
    `define op_64 7'b0110011
    `define OP_32 7'b0111011
    `define OP_imm 7'b0010011
    `define OP_imm_32 7'b0011011
    `define LOAD 7'b0000011
    `define STORE 7'b0100011
    `define BRANCH 7'b1100011
    `define JAL 7'b1101111
    `define JALR 7'b1100111
    `define AUIPC 7'b0010111
    `define LUI 7'b0110111

    /*func3 ARITHMETIC*/
    `define ADD_SUB_MUL 3'b000
    `define SLL 3'b001
    `define SLT 3'b010
    `define SLTU 3'b011
    `define XOR_DIV 3'b100
    `define SRL_SRA 3'b101
    `define OR 3'b110
    `define AND 3'b111

    /*func3 ARITHMETIC RV64 for OP_imm(32)*/



    /*func7 arithmetic RV64 for MUL DIV REM*/
    `define ADD_func7 7'b0000000
    `define SUB_func7 7'b0100000
    `define MUL_func7 7'b0000001
    //------
    `define SLL_func7 7'b0000000
    `define MULH_func7 7'b0000001
    //------
    `define SLT_func7 7'b0000000
    `define MULHSU_func7 7'b0000001
    //------
    `define SLTU_func7 7'b0000000
    `define MULHU_func7 7'b0000001
    //------
    `define XOR_func7 7'b0000000
    `define DIV_func7 7'b0000001
    //------
    `define SRL_func7 7'b0000000
    `define SRA_func7 7'b0100000
    `define DIVU_func7 7'b0000001
    //------
    `define OR_func7 7'b0000000
    `define REM_func7 7'b0000001 
    //------
    `define AND_func7 7'b0000000
    `define REMU_func7 7'b0000001

    /*func7 arithmetic RV32 for MUL DIV REM*/
    `define MULW_func7 7'b0000001
    `define DIVW_func7 7'b0000001
    `define DIVUW_func7 7'b0000001
    `define REMW_func7 7'b0000001
    `define REMUW_func7 7'b0000001


    /*func3 BRANCH*/
    `define BEQ 3'b000
    `define BNE 3'b001
    `define BLT 3'b100
    `define BGE 3'b101
    `define BLTU 3'b110
    `define BGEU 3'b111

    /*func3 LOAD*/
    `define LB 3'b000
    `define LH 3'b001
    `define LW 3'b010
    `define LD 3'b011
    `define LBU 3'b100
    `define LHU 3'b101
    `define LWU 3'b110

    /*func3 STORE*/
    `define SB 3'b000
    `define SH 3'b001
    `define SW 3'b010
    `define SD 3'b011



    wire [63:0]signed_data1,signed_data2,signed_imm;
    wire [31:0]data1_32,data2_32,signed_data1_32,signed_data2_32,imm_32,signed_imm_32;
    
    wire [127:0]mul_result_signed , mul_result , mul_result_hsu , mul_result_signed_hsu ;  /*for multiplier*/
    
    assign data1_32 = data1[31:0];
    assign data2_32 = data2[31:0];
    assign imm_32 = imm[31:0];
    
    assign signed_data1 = $signed(data1); 
    assign signed_data2 = $signed(data2);
    assign signed_data1_32 = $signed(data1_32);
    assign signed_data2_32 = $signed(data2_32);
    assign signed_imm = $signed(imm);
    assign signed_imm_32 = $signed(imm_32);
    
    assign mul_result_signed = $signed(mul_result);
    assign mul_result_signed_hsu = $signed(mul_result);
    
    multiplier m1($signed(data1),data2,mul_result_hsu);
    multiplier m2(data1,data2,mul_result);


//CLA 
//64bits AS
    
    wire [63:0] cla_add_result , cla_sub_result;
    wire cla_add_carry_out , cla_sub_carry_out;
    wire [63:0] cla_data1 , cla_data2 , Tcmp_cla_data2 , Ocmp_cla_data2;

    assign cla_data1 = data1;
    assign cla_data2 = 
    (opcode == `op_64 ) ? data2 : 
    ((opcode == `OP_32) ? {{32{data2[31]}} , data2[31:0]} : 
    ((opcode == `OP_imm) ? imm :
    ((opcode == `OP_imm) ? {{32{imm[31]}} , imm[31:0]}  : data1 ) ) ) ;

    Complement_generator cmp(cla_data2 , Ocmp_cla_data2 , Tcmp_cla_data2);
    CLA cla_add( cla_data1 , cla_data2 , 1'b0 , cla_add_result , cla_add_carry_out);
    CLA cla_sub( cla_data1 , Tcmp_cla_data2 , 1'b0 , cla_sub_result , cla_sub_carry_out);

//DIV
    wire [63:0] div_data1 , div_data2 , quotient , remainder;
    assign div_data1 = data1;
    assign div_data2 = data2;
    divider div(div_data1,div_data2,quotient , remainder);
//branch  count
    wire [63:0]branchcount,jalrcount;
    wire branch_carry,jalr_carry;
    CLA branch_count({32'd0,pc},signed_imm,1'b0,branchcount,branch_carry);
    CLA jalr_count(data1,signed_imm,1'b0,jalrcount,jalr_carry);
//AUIPC
    wire [63:0]AUIPCcount;
    wire AUIPCcarry;
    CLA AUIPC_count({32'd0,pc},{{32{imm[19]}},imm[19:0], 12'b0},1'b0,AUIPCcount,AUIPC_carry);

    wire [63:0] next_pc;
    wire pc_carry;
    CLA PC_ctrl({32'd0,pc},64'd4,1'b0,next_pc,pc_carry);

    always@(posedge clk or posedge rst) begin //posedge clk or rst
        if(rst) begin
	    pc_branch <= 0;
            is_branch <= 0;
            result <= 0;
            mem_rw <= 0;    // 0:read, 1:write
            is_load  <= 0;  // 1: load, 0: others
	end 
	else begin
	    
        case(opcode)
            `op_64 :  begin
                            is_load <= 0;
                            mem_rw <= 0;
                            case(func3)
                                `ADD_SUB_MUL :  begin
                                            case(func7)
                                                `ADD_func7 :  begin
                                                        result <= cla_add_result[63:0];
                                                    end
                                                `SUB_func7 :  begin
                                                        result <= cla_sub_result[63:0];
                                                    end
                                                `MUL_func7 :  begin
                                                        result <= mul_result_signed[63:0]; 
                                                    end
                                                default :   begin

                                                    end

                                            endcase

                                    end
                                `SLL :  begin
                                            case(func7)
                                                `SLL_func7 :  begin
                                                        result <= ((data1) << (data2)); 
                                                    end
                                                `MULH_func7 :  begin
                                                        result <= mul_result_signed[127:64]; 
                                                    end
                                                default :   begin

                                                    end

                                            endcase    

                                    end
                                `SLT :  begin
                                            case(func7)
                                                `SLT_func7 :  begin
                                                        if(signed_data1<signed_data2) begin
                                                            result <= 64'h0000000000000001;
                                                        end
                                                        else begin
                                                            result <= 64'h0000000000000000;
                                                        end
                                                    end
                                                `MULHSU_func7 :  begin
                                                        result <= mul_result_signed_hsu[127:64]; 
                                                    end
                                                default :   begin

                                                    end

                                            endcase  

                                    end
                                `SLTU :  begin
                                            case(func7)
                                                `SLTU_func7 :  begin
                                                        if(data1<data2) begin
                                                            result <= 64'h0000000000000001;
                                                        end
                                                        else begin
                                                            result <= 64'h0000000000000000;
                                                        end
                                                    end
                                                `MULHU_func7 :  begin
                                                        result <= mul_result[127:64]; 
                                                    end
                                                default :   begin

                                                    end

                                            endcase  

                                    end
                                `XOR_DIV :  begin
                                            case(func7)
                                                `XOR_func7 :  begin
                                                        result <= data1 ^ data2;
                                                    end
                                                `DIV_func7 :  begin
                                                        result <= quotient;
                                                    end
                                                default :   begin

                                                    end

                                            endcase

                                    end
                                `SRL_SRA :  begin
                                            case(func7)
                                                `SRL_func7 :  begin
                                                        result <= (data1 >> (data2));
                                                    end
                                                `SRA_func7 :  begin
                                                        result <= signed_data1 >> (data2&64'h000000000000001F);
                                                    end
                                                `DIVU_func7 :  begin
                                                        result <= quotient;
                                                    end
                                                default :   begin

                                                    end

                                            endcase  

                                    end
                                `OR :   begin
                                            case(func7)
                                                `OR_func7 :  begin
                                                        result <= data1 | data2;
                                                    end
                                                `REM_func7 :  begin
                                                        result <= remainder ;
                                                    end
                                                default :   begin

                                                    end

                                            endcase  

                                    end
                                `AND :  begin
                                            case(func7)
                                                `AND_func7 :  begin
                                                        result <= data1 & data2;
                                                    end
                                                `REMU_func7 :  begin
                                                        result <= remainder ;
                                                    end
                                                default :   begin

                                                    end

                                            endcase  

                                    end
                                default :  begin

                                    end

                            endcase
                    end
            `OP_32 :  begin
                            is_load <= 0;
                            mem_rw <= 0;
                            case(func3)
                                `ADD_SUB_MUL :  begin
                                            case(func7)
                                                `ADD_func7 :  begin
                                                        result <= {{32{cla_add_result[31]}},cla_add_result[31:0]};
                                                    end
                                                `SUB_func7 :  begin
                                                        result <= {{32{cla_sub_result[31]}},cla_sub_result[31:0]};
                                                    end
                                                `MULW_func7 :  begin
                                                        result <= {{32{mul_result_signed[31]}},mul_result_signed[31:0]}; 
                                                    end
                                                default :   begin

                                                    end

                                            endcase
                                    end
                                `SLL :  begin
                                        result <= {{32{data1_32[31-data2_32]}},$signed(data1_32 << (data2_32))};
                                    end
                                `SLT :  begin
                                        if(signed_data1_32 < signed_data2_32) begin
                                            result <= 64'h0000000000000001;
                                        end
                                        else begin
                                            result <= 64'h0000000000000000;
                                        end
                                    end
                                `SLTU :  begin
                                        if(data1_32 < data2_32) begin
                                            result <= 64'h0000000000000001;
                                        end
                                        else begin
                                            result <= 64'h0000000000000000;
                                        end
                                    end
                                `XOR_DIV :  begin
                                            case(func7)
                                                `XOR_func7 :  begin
                                                    result <= {{32{signed_data1_32[31]^signed_data2_32[31]}},$signed(signed_data1_32^signed_data2_32)};
                                                    end
                                                `DIVW_func7 :  begin
                                                    result <= {{32{quotient[31]}},quotient[31:0]};
                                                    end
                                                default :   begin

                                                    end

                                            endcase

                                    end
                                `SRL_SRA :  begin
                                            case(func7)
                                                `SRL_func7 :  begin
                                                            result <= {{32{data1_32[31]}},$signed(data1_32 >> (data2_32))};
                                                    end
                                                `SRA_func7 :  begin
                                                            result <= {{32{data1_32[31]}},$signed(signed_data1_32 >> (data2_32 & 32'h0000001F))};
                                                    end
                                                `DIVUW_func7 :  begin
                                                    result <= {{32{quotient[31]}},quotient[31:0]};
                                                    end
                                                default :   begin

                                                    end

                                            endcase  

                                    end
                                `OR :   begin
                                            case(func7)
                                                `OR_func7 :  begin
                                                            result <= {{32{signed_data1_32[31] | signed_data2_32[31]}},$signed(signed_data1_32 | signed_data2_32)};
                                                    end
                                                `REMW_func7 :  begin
                                                    result <= {{32{remainder[31]}},remainder[31:0]};
                                                    end
                                                default :   begin

                                                    end

                                            endcase 

                                    end
                                `AND :  begin
                                            case(func7)
                                                `AND_func7 :  begin
                                                            result <= {{32{signed_data1_32[31] & signed_data2_32[31]}},$signed(signed_data1_32 & signed_data2_32)};
                                                    end
                                                `REMUW_func7 :  begin
                                                    result <= {{32{remainder[31]}},remainder[31:0]};
                                                    end
                                                default :   begin

                                                    end

                                            endcase 

                                    end
                                default :  begin

                                    end

                            endcase
                    end
            `OP_imm :  begin
                        is_load <= 0;
                        mem_rw <= 0;
                        case(func3)
                                `ADD_SUB_MUL :  begin
                                        result <= cla_add_result;
                                    end
                                `SLL :  begin
                                            result <= data1 << imm;
                                    end
                                `SLT :  begin
                                        if(signed_data1 < signed_imm) begin
                                            result <= 64'h0000000000000001;
                                        end
                                        else begin
                                            result <= 64'h0000000000000000;
                                        end
                                    end
                                `SLTU :  begin
                                        if(data1 < imm) begin
                                            result <= 64'h0000000000000001;
                                        end
                                        else begin
                                            result <= 64'h0000000000000000;
                                        end
                                    end
                                `XOR_DIV :  begin
                                        result <= data1 ^ signed_imm;
                                    end
                                `SRL_SRA :  begin
                                            case(func7)
                                                `SRL_func7 :  begin
                                                            result <= data1 >> imm;
                                                    end
                                                `SRA_func7 :  begin
                                                            result <= $unsigned(signed_data1 >> (signed_imm&64'h000000000000003F));
                                                    
                                                    end
                                                default :   begin

                                                    end

                                            endcase  

                                    end
                                `OR :   begin
                                        result <= data1 | signed_imm;
                                    end
                                `AND :  begin
                                        result <= data1 & signed_imm;
                                    end
                                default :  begin

                                    end

                            endcase
                    end
            `OP_imm_32 :  begin
                
                        is_load <= 0;
                        mem_rw <= 0;
                        case(func3)
                                `ADD_SUB_MUL :  begin
                                        result <= {{32{cla_add_result[31]}},cla_add_result[31:0]};
                                    end
                                `SLL :  begin
                                        result <= {{32{signed_data1_32[31-imm_32]}},$signed(signed_data1_32 << imm_32)};
                                        
                                    end
                                `SLT :  begin
                                        if(signed_data1_32 < signed_imm_32) begin
                                            result <= 64'h0000000000000001;
                                        end
                                        else begin
                                            result <= 64'h0000000000000000;
                                        end
                                    end
                                `SLTU :  begin
                                        if(data1_32 < imm_32) begin
                                            result <= 64'h0000000000000001;
                                        end
                                        else begin
                                            result <= 64'h0000000000000000;
                                        end
                                    end
                                `XOR_DIV :  begin
                                        result <= {{32{signed_data1_32[31] | signed_imm_32[31]}},$signed(signed_data1_32 ^ signed_imm_32)};
                                    end
                                `SRL_SRA :  begin
                                            case(func7)
                                                `SRL_func7 :  begin
                                                        result <= {{32{data1_32[31]}},$signed($unsigned(data1_32 >> imm_32))};
                                                    end
                                                `SRA_func7 :  begin
                                                        result <= {{32{signed_data1_32[31]}},$signed(signed_data1_32 >> (imm_32 & 64'h000000000000001F))};
                                                    end
                                                default :   begin

                                                    end

                                            endcase  

                                    end
                                `OR :   begin
                                        result <= {{32{signed_data1_32[31] | signed_imm_32[31]}},$signed(signed_data1_32 | signed_imm_32)};
                                    end
                                `AND :  begin
                                        result <= {{32{signed_data1_32[31] & signed_imm_32[31]}},$signed(signed_data1_32 & signed_imm_32)};
                                    end
                                default :  begin

                                    end

                            endcase
                    end
            `LOAD :  begin
                    case(func3)
                            `LB :  begin
                                is_load <= 1;
                                mem_rw <= 0;
                                end
                            `LH :  begin
                                is_load <= 1;
                                mem_rw <= 0;
                                end
                            `LW :  begin
                                is_load <= 1;
                                mem_rw <= 0;
                                end
                            `LD :  begin
                                is_load <= 1;
                                mem_rw <= 0;
                                end
                            `LBU :  begin
                                is_load <= 1;
                                mem_rw <= 0;
                                end
                            `LHU :  begin
                                is_load <= 1;
                                mem_rw <= 0;
                                end
                            `LWU :   begin
                                is_load <= 1;
                                mem_rw <= 0;
                                end
                            default :  begin
                                end
                                
                        endcase
                end
            `STORE :  begin
                        case(func3)
                                `SD :  begin
                                    is_load <= 0;
                                    mem_rw <= 1;
                                    end
                                `SB :  begin
                                    is_load <= 0;
                                    mem_rw <= 1;
                                    end
                                `SH :  begin
                                    is_load <= 0;
                                    mem_rw <= 1;
                                    end
                                `SW :  begin
                                    is_load <= 0;
                                    mem_rw <= 1;
                                    end
                                default :  begin

                                    end
                                    
                            endcase
                    end
            `BRANCH :  begin
                        is_load <= 0;
                        mem_rw <= 0;
                        case(func3)
                                `BEQ :  begin
                                        if(data1==data2)    begin
                                            is_branch <= 1;
                                            pc_branch <= branchcount[31:0];
                                        end
                                        else begin
                                            is_branch <= 0;
                                            pc_branch <= next_pc[31:0];
                                        end
                                    end
                                `BNE :  begin
                                        if(data1!=data2)    begin
                                            is_branch <= 1;
                                            pc_branch <= branchcount[31:0];
                                        end
                                        else begin
                                            is_branch <= 0;
                                            pc_branch <= next_pc[31:0];
                                        end
                                    end
                                `BLT :  begin
                                        if($signed(data1) < $signed(data2))    begin
                                            is_branch <= 1;
                                            pc_branch <= branchcount[31:0];
                                        end
                                        else begin
                                            is_branch <= 0;
                                            pc_branch <= next_pc[31:0];
                                        end
                                    end
                                `BGE :  begin
                                        if($signed(data1) >= $signed(data2))    begin
                                            is_branch <= 1;
                                            pc_branch <= branchcount[31:0];
                                        end
                                        else begin
                                            is_branch <= 0;
                                            pc_branch <= next_pc[31:0];
                                        end
                                    end
                                `BLTU :  begin
                                        if(data1 < data2)    begin
                                            is_branch <= 1;
                                            pc_branch <= branchcount[31:0];
                                        end
                                        else begin
                                            is_branch <= 0;
                                            pc_branch <= next_pc[31:0];
                                        end
                                    end
                                `BGEU :  begin
                                        if(data1 >= data2)    begin
                                            is_branch <= 1;
                                            pc_branch <= branchcount[31:0];
                                        end
                                        else begin
                                            is_branch <= 0;
                                            pc_branch <= next_pc[31:0];
                                        end
                                    end
                                default :  begin
                                        is_branch <= 0;
                                        pc_branch <= next_pc[31:0];
                                    end
                                    
                            endcase
                    end
            `JAL :  begin
                
                        is_load <= 0;
                        mem_rw <= 0;
                        is_branch <= 1;
                        pc_branch <= pc + $signed( imm[20:0] );
                    end
            `JALR :  begin
                        is_load <= 0;
                        mem_rw <= 0;
                        is_branch <= 1;
                        pc_branch <= $signed( data1 + $signed(imm[11:0]) );
                    end
            `AUIPC :  begin
                        is_load <= 0;
                        mem_rw <= 0;
                        result <=  pc  + $signed({imm[19:0], 12'b0});
                    end
            `LUI :  begin
                        is_load <= 0;
                        mem_rw <= 0;
                        result <= $signed({ imm[19:0] , 12'b0 });
                    end
            default :  begin
                        is_load <= 0;
                        mem_rw <= 0;
                        result <= 0;
                    end
        endcase

	end    
    end

endmodule



module multiplier(
    input [63:0]A,
    input [63:0]B,
    output [127:0]result
);

wire [127:0] product [0:63];
wire [127:0] carry [0:64];
wire [128:0] carry_second [0:64];
wire [127:0] sum [0:65];


genvar i,j; 

/*partial products*/
generate    
        for (j=0; j<64; j = j + 1) begin   : a12
            for (i=0; i<64; i = i + 1) begin  : a1
                assign product[j][i+j] = A[j]&B[i];
            end          
        end
endgenerate

assign result[0] = product[0][0];

/*half adder first 63~1 */
generate
    for (i=1; i<64; i = i + 1) begin  : a2
        ha ha1(product[0][i],product[1][i],sum[1][i],carry[1][i+1]);
    end
endgenerate

/*full adder first 63~2 */
generate
    for (i=2; i<64; i = i + 1) begin   : a13
        for (j=i; j<64; j = j + 1) begin  : a3
          fa fa1(sum[i-1][j],product[i][j],carry[i-1][j],sum[i][j],carry[i][j+1]);  
        end
    end
endgenerate

/*half adder for 64~126 (last carry + top partial product)*/
generate
    for (i=1; i<64; i = i + 1) begin  : a4
        ha ha2(product[i][i+63],carry[i][i+63],sum[i+1][i+63],carry[i+1][i+64]);
    end
endgenerate

/*full adder for 64~126*/
generate
        for (i=2; i<64; i = i + 1) begin  : a5
            fa fa2(product[i][64],sum[i][64],carry[i][64],sum[i+1][64],carry[i+1][65]);
        end
endgenerate

generate
    for (j=65; j<126; j = j + 1) begin  : a14
        for (i=(j-62); i<64; i = i + 1) begin   : a6
            fa fa3(product[i][j],sum[i][j],carry[i][j],sum[i+1][j],carry[i+1][j+1]);
        end
    end
endgenerate

    ha ha3(sum[64][65],carry[64][65],sum[65][65],carry_second[64][66]);

generate
    for (i=66; i<127; i = i + 1) begin  : a7
        fa fa4(sum[64][i],carry[64][i],carry_second[64][i],sum[65][i],carry_second[64][i+1]);
    end
endgenerate

    ha ha4(carry_second[64][127],carry[64][127],sum[65][127],carry_second[64][128]);
/*sum to results*/
generate
    for (i=1; i<65; i = i + 1) begin  : a9
        assign result[i] = sum[i][i];
    end
    for (i=65; i<128; i = i + 1)begin  : a10
        assign result[i] = sum[65][i];
    end
endgenerate

endmodule

module ha(input a, b, output s, c);
    assign s = a^b;
    assign c = a&b;
endmodule

module fa(input a, b, cin, output s, c);

    assign s = a^b^cin;
    assign c = (a & b) | (b & cin) | (a & cin);

endmodule

module CLA (
    input [63:0] add_data1 , add_data2,
    input c0,
    output [63:0] result,
    output c8
);
    wire 
    c1 ,    
    c2 ,
    c3 ,
    c4 ,
    c5 ,
    c6 ,
    c7 ;
    wire [7:0] 
    result1 ,
    result2 , 
    result3 , 
    result4 , 
    result5 , 
    result6 , 
    result7 , 
    result8 ; 

    EIGHT_bits_CLA add1 (add_data1[7:0]   , add_data2[7:0]   , c0 , result1 , c1);
    EIGHT_bits_CLA add2 (add_data1[15:8]  , add_data2[15:8]  , c1 , result2 , c2);
    EIGHT_bits_CLA add3 (add_data1[23:16] , add_data2[23:16] , c2 , result3 , c3);
    EIGHT_bits_CLA add4 (add_data1[31:24] , add_data2[31:24] , c3 , result4 , c4);
    EIGHT_bits_CLA add5 (add_data1[39:32] , add_data2[39:32] , c4 , result5 , c5);
    EIGHT_bits_CLA add6 (add_data1[47:40] , add_data2[47:40] , c5 , result6 , c6);
    EIGHT_bits_CLA add7 (add_data1[55:48] , add_data2[55:48] , c6 , result7 , c7);
    EIGHT_bits_CLA add8 (add_data1[63:56] , add_data2[63:56] , c7 , result8 , c8);

    assign result ={
    result8 ,
    result7 , 
    result6 , 
    result5 , 
    result4 , 
    result3 , 
    result2 , 
    result1 
    };

endmodule

module EIGHT_bits_CLA (
    input [7:0] add_data1 , add_data2,
    input c0,
    output [7:0] result,
    output c8
);
    wire c1 , c2 , c3 , c4 , c5 , c6 , c7;
    wire p0 , p1 , p2 , p3 , p4 , p5 , p6;
    wire g0 , g1 , g2 , g3 , g4 , g5 , g6;
    
    assign p0 = add_data1[0] ^ add_data2[0];
    assign p1 = add_data1[1] ^ add_data2[1];
    assign p2 = add_data1[2] ^ add_data2[2];
    assign p3 = add_data1[3] ^ add_data2[3];
    assign p4 = add_data1[4] ^ add_data2[4];
    assign p5 = add_data1[5] ^ add_data2[5];
    assign p6 = add_data1[6] ^ add_data2[6];
    assign p7 = add_data1[7] ^ add_data2[7];

    assign g0 = add_data1[0] & add_data2[0];
    assign g1 = add_data1[1] & add_data2[1];
    assign g2 = add_data1[2] & add_data2[2];
    assign g3 = add_data1[3] & add_data2[3];
    assign g4 = add_data1[4] & add_data2[4];
    assign g5 = add_data1[5] & add_data2[5];
    assign g6 = add_data1[6] & add_data2[6];
    assign g7 = add_data1[7] & add_data2[7];

    assign c1 = g0 | p0 & c0;
    assign c2 = g1 | p1 & c1;
    assign c3 = g2 | p2 & c2;
    assign c4 = g3 | p3 & c3;
    assign c5 = g4 | p4 & c4;
    assign c6 = g5 | p5 & c5;
    assign c7 = g6 | p6 & c6;
    assign c8 = g7 | p7 & c7;

    assign result[0] = add_data1[0] ^ add_data2[0] ^ c0 ;
    assign result[1] = add_data1[1] ^ add_data2[1] ^ c1 ;
    assign result[2] = add_data1[2] ^ add_data2[2] ^ c2 ;
    assign result[3] = add_data1[3] ^ add_data2[3] ^ c3 ;
    assign result[4] = add_data1[4] ^ add_data2[4] ^ c4 ;
    assign result[5] = add_data1[5] ^ add_data2[5] ^ c5 ;
    assign result[6] = add_data1[6] ^ add_data2[6] ^ c6 ;
    assign result[7] = add_data1[7] ^ add_data2[7] ^ c7 ;

endmodule

module Complement_generator (
    input [63:0] datain,
    output [63:0] ones_Complement , twos_complement
);
wire [63:0] result ;
wire out;
assign ones_Complement = ~datain;
CLA cla( ones_Complement , 64'b1 , 1'b0 , twos_complement , out );
endmodule

module divider(
    input [63:0] dividend,
    input [63:0] divisor,
    output [63:0] quotient,
    output [63:0] remainder
);

// Temporary variables for calculation
wire [63:0] dividend_;  // 2's complement of dividend
wire [63:0] divisor_;   // 2's complement of divisor
wire [63:0] todo_dividend;
wire [63:0] todo_divisor;
wire [63:0] sub_divisor;
wire [127:0] temp_remainder [0:64];
wire [63:0] sub_result [0:63];
wire out1, out2, out4, out5;
wire out3[0:63];

// CLA modules for handling 2's complement calculations
CLA d1(.add_data1(~dividend), .add_data2(64'b1), .c0(1'b0), .result(dividend_), .c8(out1));
// Determine unsigned equivalents based on signs
assign todo_dividend = dividend[63] ? dividend_ : dividend;
// Initial remainder setup
assign temp_remainder[0] = {63'b0, todo_dividend, 1'b0};


CLA d2(.add_data1(~divisor), .add_data2(64'b1), .c0(1'b0), .result(divisor_), .c8(out2));
assign todo_divisor = divisor[63] ? divisor_ : divisor;
assign sub_divisor = divisor[63] ? divisor : divisor_;

// Iterative division process
genvar i;
generate
    for (i = 0; i < 64; i = i + 1) begin : div_step
        // Subtract divisor from current remainder
        CLA subtractor(
            .add_data1(temp_remainder[i][127:64]),
            .add_data2(sub_divisor),
            .c0(1'b0),
            .result(sub_result[i]),
            .c8(out3[i])
        );

        // Update temp_remainder based on comparison
        assign temp_remainder[i+1] = sub_result[i][63] ? {temp_remainder[i][126:0], 1'b0} : {sub_result[i][62:0], temp_remainder[i][63:0], 1'b1};

    end
endgenerate

// Extract quotient and remainder
wire [63:0] quotient_check = temp_remainder[64][63:0];
wire [63:0] remainder_check = {1'b0, temp_remainder[64][127:65]};
// wire [63:0] quotient_check = {temp_remainder[64][62:0], 1'b0};
// wire [63:0] remainder_check = temp_remainder[64][127:64];

// Adjust signs for signed division
wire [63:0] signed_quotient;
wire [63:0] signed_remainder;

CLA adjust_quotient_sign(
    .add_data1(~quotient_check),
    .add_data2(64'b1),
    .c0(1'b0),
    .result(signed_quotient),
    .c8(out4)
);

CLA adjust_remainder_sign(
    .add_data1(~remainder_check),
    .add_data2(64'b1),
    .c0(1'b0),
    .result(signed_remainder),
    .c8(out5)
);

// assign quotient = (dividend[63] ^ divisor[63]) ? signed_quotient : quotient_check;
// assign remainder = dividend[63] ? signed_remainder : remainder_check;
assign quotient = (divisor == 0) ? 64'b0 :
                    (dividend[63] ^ divisor[63]) ? signed_quotient : quotient_check;
assign remainder = (divisor == 0) ? dividend :
                    (dividend[63] ? signed_remainder : remainder_check);


endmodule

