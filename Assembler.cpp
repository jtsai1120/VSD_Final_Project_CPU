#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>
#include <cstdlib>
#include <algorithm>
#include <map>
#include <cassert>
#include <iomanip>

using namespace std;

int actual_line_number;
vector<pair<string,int> > labels;

string dec2bin(int num, int len = 5) {
    string bin(len, '0');
    for (int i = len - 1; i >= 0; --i) {
        bin[i] = (num & 1) ? '1' : '0';
        num >>= 1;
    }
    return bin;
}

static const map<string, int> reg_map = {
    {"x0", 0}, {"x1", 1}, {"ra", 1}, {"x2", 2}, {"sp", 2}, {"x3", 3}, {"gp", 3},
    {"x4", 4}, {"tp", 4}, {"x5", 5}, {"t0", 5}, {"x6", 6}, {"t1", 6}, {"x7", 7},
    {"t2", 7}, {"x8", 8}, {"s0", 8}, {"fp", 8}, {"x9", 9}, {"s1", 9}, {"x10", 10},
    {"a0", 10}, {"x11", 11}, {"a1", 11}, {"x12", 12}, {"a2", 12}, {"x13", 13},
    {"a3", 13}, {"x14", 14}, {"a4", 14}, {"x15", 15}, {"a5", 15}, {"x16", 16},
    {"a6", 16}, {"x17", 17}, {"a7", 17}, {"x18", 18}, {"s2", 18}, {"x19", 19},
    {"s3", 19}, {"x20", 20}, {"s4", 20}, {"x21", 21}, {"s5", 21}, {"x22", 22},
    {"s6", 22}, {"x23", 23}, {"s7", 23}, {"x24", 24}, {"s8", 24}, {"x25", 25},
    {"s9", 25}, {"x26", 26}, {"s10", 26}, {"x27", 27}, {"s11", 27}, {"x28", 28},
    {"t3", 28}, {"x29", 29}, {"t4", 29}, {"x30", 30}, {"t5", 30}, {"x31", 31},
    {"t6", 31}
};

string reg2bin(string reg) {
    auto it = reg_map.find(reg);
    if (it != reg_map.end()) {
        return dec2bin(it->second);
    } else {
        cout << "Error: Unknown register : " << reg << endl;
        assert(0);
    }
}

string Mnemonic2MachineCode(vector<string> substrings) {
    string machine_code_line = "";
    string opcode, rs1, rs2, rd, shamt, funct3, funct7;
    string imm_11_0, imm_11_5, imm_4_0, imm_12, imm_10_5, imm_4_1, imm_11, imm_31_12, imm_20, imm_10_1, imm_19_12;
    auto operation = substrings[0];

    if (operation == "add" || operation == "sub" || operation == "mul" || operation == "and" || operation == "remu" || operation == "or" || operation == "rem" || operation == "xor" || operation == "div" || operation == "sll" || operation == "mulh" || operation == "srl" || operation == "sra" || operation == "divu" || operation == "slt" || operation == "mulhsu" || operation == "sltu" || operation == "mulhu") {
        // R-type
        opcode = "0110011";
        // opcode = (operation == "slt" || operation == "sltu") ? "0110011" : "0000011";
        funct3 = (operation == "add" || operation == "sub" || operation == "mul") ? "000" :
                (operation == "sll" || operation == "mulh") ? "001" :
                (operation == "slt" || operation == "mulhsu") ? "010" :
                (operation == "sltu" || operation == "mulhu") ? "011" :
                (operation == "sra" || operation == "srl" || operation == "divu") ? "101" :
                (operation == "xor" || operation == "div") ? "100" :
                (operation == "or" || operation == "rem") ? "110" :
                (operation == "and" || operation == "remu") ? "111" : "000";
        funct7 = (operation == "sub" || operation == "sra")? "0100000" : 
                (operation == "mul" || operation == "mulh" || operation == "mulhsu" || operation == "mulhu" || operation == "div" || operation == "divu" || operation == "rem" || operation == "remu") ? "0000001" : "0000000";
        rd = reg2bin(substrings[1]);
        rs1 = reg2bin(substrings[2]);
        rs2 = reg2bin(substrings[3]);
        machine_code_line = funct7 + rs2 + rs1 + funct3 + rd + opcode;
    } else if (operation == "addw" || operation == "subw" || operation == "mulw" || operation == "andw" || operation == "remuw" || operation == "orw" || operation == "remw" || operation == "xorw" || operation == "divw" || operation == "sllw" || operation == "srlw" || operation == "sraw" || operation == "divuw" || operation == "sltw" || operation == "sltuw") {
        // R-type
        opcode = "0111011";
        // opcode = (operation == "slt" || operation == "sltu") ? "0110011" : "0000011";
        funct3 = (operation == "addw" || operation == "subw" || operation == "mulw") ? "000" :
                (operation == "sllw") ? "001" :
                (operation == "sltw") ? "010" :
                (operation == "sltuw") ? "011" :
                (operation == "sraw" || operation == "srlw" || operation == "divuw") ? "101" :
                (operation == "xorw" || operation == "divw") ? "100" :
                (operation == "orw" || operation == "remw") ? "110" :
                (operation == "andw" || operation == "remuw") ? "111" : "000";
        funct7 = (operation == "subw" || operation == "sraw")? "0100000" : 
                (operation == "mulw" || operation == "divw" || operation == "divuw" || operation == "remw" || operation == "remuw") ? "0000001" : "0000000";
        rd = reg2bin(substrings[1]);
        rs1 = reg2bin(substrings[2]);
        rs2 = reg2bin(substrings[3]);
        machine_code_line = funct7 + rs2 + rs1 + funct3 + rd + opcode;
    } else if (operation == "slli" || operation == "srli" || operation == "srai" || operation == "addi" || operation == "xori" || operation == "ori" || operation == "andi" || operation == "slti" || operation == "sltiu") {
        // I-type
        opcode = "0010011";
        funct3 = (operation == "addi") ? "000" :
                (operation == "xori") ? "100" :
                (operation == "ori") ? "110" :
                (operation == "andi") ? "111" :
                (operation == "slti") ? "010" :
                (operation == "sltiu") ? "011" :
                (operation == "slli") ? "001" :
                (operation == "srli" || operation == "srai") ? "101" : "000";
        rd = reg2bin(substrings[1]);
        rs1 = reg2bin(substrings[2]);
        imm_11_0 = dec2bin(stoi(substrings[3]), 12);
        machine_code_line = imm_11_0 + rs1 + funct3 + rd + opcode;
    } else if (operation == "slliw" || operation == "srliw" || operation == "sraiw" || operation == "addiw" || operation == "xoriw" || operation == "oriw" || operation == "andiw" || operation == "sltiw" || operation == "sltiuw") {
        // I-type
        opcode = "0010011";
        funct3 = (operation == "addiw") ? "000" :
                (operation == "xoriw") ? "100" :
                (operation == "oriw") ? "110" :
                (operation == "andiw") ? "111" :
                (operation == "sltiw") ? "010" :
                (operation == "sltiuw") ? "011" :
                (operation == "slliw") ? "001" :
                (operation == "srliw" || operation == "sraiw") ? "101" : "000";
        rd = reg2bin(substrings[1]);
        rs1 = reg2bin(substrings[2]);
        imm_11_0 = dec2bin(stoi(substrings[3]), 12);
        machine_code_line = imm_11_0 + rs1 + funct3 + rd + opcode;
    } else if (operation == "lb" || operation == "lh" || operation == "lw" || operation == "ld" || operation == "lbu" || operation == "lhu" || operation == "lwu") {
        // I-type
        opcode = "0000011";
        funct3 = (operation == "lb") ? "000" :
                (operation == "lh") ? "001" :
                (operation == "lw") ? "010" :
                (operation == "ld") ? "011" :
                (operation == "lbu") ? "100" :
                (operation == "lhu") ? "101" : 
                (operation == "lwu") ? "110" : "000";
        rd = reg2bin(substrings[1]);
        auto open_bracket = substrings[2].find('('); // 找到 '(' 的位置
        auto close_bracket = substrings[2].find(')'); // 找到 ')' 的位置
        auto offset_str = substrings[2].substr(0, open_bracket); // 提取 "offset"
        auto reg_str = substrings[2].substr(open_bracket + 1, close_bracket - open_bracket - 1); // 提取 "reg"

        rs1 = reg2bin(reg_str);
        imm_11_0 = dec2bin(stoi(offset_str), 12);
        machine_code_line = imm_11_0 + rs1 + funct3 + rd + opcode;
     } else if (operation == "sb" || operation == "sh" || operation == "sw" || operation == "sd") {
        // S-type
        opcode = "0100011";
        funct3 = (operation == "sb") ? "000" :
                (operation == "sh") ? "001" :
                (operation == "sw") ? "010" :
                (operation == "sd") ? "011" : "000";
        rs2 = reg2bin(substrings[1]);
        auto open_bracket = substrings[2].find('('); // 找到 '(' 的位置
        auto close_bracket = substrings[2].find(')'); // 找到 ')' 的位置
        auto offset_str = substrings[2].substr(0, open_bracket); // 提取 "offset"
        auto reg_str = substrings[2].substr(open_bracket + 1, close_bracket - open_bracket - 1); // 提取 "reg"

        rs1 = reg2bin(reg_str);
        auto imm_tmp = dec2bin(stoi(offset_str), 12);
        imm_11_5 = imm_tmp.substr(0, 7);
        imm_4_0 = imm_tmp.substr(7, 5);
        machine_code_line = imm_11_5 + rs2 + rs1 + funct3 + imm_4_0 + opcode;
    } else if (operation == "beq" || operation == "bne" || operation == "blt" || operation == "bge" || operation == "bltu" || operation == "bgeu") {
        // B-type
        opcode = "1100011";
        funct3 = (operation == "beq") ? "000" :
                (operation == "bne") ? "001" :
                (operation == "blt") ? "100" :
                (operation == "bge") ? "101" :
                (operation == "bltu") ? "110" :
                (operation == "bgeu") ? "111" : "000";
        rs1 = reg2bin(substrings[1]);
        rs2 = reg2bin(substrings[2]);
        for (auto l : labels) {
            if (l.first == substrings[3]) {
                auto imm_tmp = dec2bin(4*(l.second - actual_line_number), 13);
                imm_12 = imm_tmp.substr(0, 1);
                imm_10_5 = imm_tmp.substr(2, 6);
                imm_4_1 = imm_tmp.substr(8, 4);
                imm_11 = imm_tmp.substr(1, 1);
                machine_code_line = imm_12 + imm_10_5 + rs2 + rs1 + funct3 + imm_4_1 + imm_11 + opcode;
                return machine_code_line;
            }
        }
        cout << "Error: Unknown label : " << substrings[3] << endl;
        assert(0);
    } 
    // else if (operation == "mul" || operation == "div") {
    //     // R-type
    //     opcode = "0110011";
    //     funct3 = (operation == "mul") ? "000" :
    //             (operation == "div") ? "100" : "000";
    //     funct7 = "0000001";
    //     rd = reg2bin(substrings[1]);  
    //     rs1 = reg2bin(substrings[2]);
    //     rs2 = reg2bin(substrings[3]);
    //     machine_code_line = funct7 + rs2 + rs1 + funct3 + rd + opcode;      
    // } 
    else if (operation == "jalr") {
        // I-type
        opcode = "1100111";
        funct3 = "000";
        rd = reg2bin(substrings[1]);
        rs1 = reg2bin(substrings[2]);
        imm_11_0 = dec2bin(4*(actual_line_number + stoi(substrings[3])), 12);
        machine_code_line = imm_11_0 + rs1 + funct3 + rd + opcode;
    } else if (operation == "jal") {
        // J-type
        opcode = "1101111";
        rd = reg2bin(substrings[1]);
        for (auto l : labels) {
            if (l.first == substrings[2]) {
                auto imm_tmp = dec2bin(4*(l.second - actual_line_number), 21);
                imm_20 = imm_tmp.substr(0, 1);
                imm_10_1 = imm_tmp.substr(10, 10);
                imm_11 = imm_tmp.substr(9, 1);
                imm_19_12 = imm_tmp.substr(1, 8);
                machine_code_line = imm_20 + imm_10_1 + imm_11 + imm_19_12 + rd + opcode;
                return machine_code_line;
            }
        }
        cout << "Error: Unknown label : " << substrings[2] << endl;
        assert(0);
    } else if (operation == "lui" || operation == "auipc") {
        // U-type
        opcode = (operation == "lui") ? "0110111" : "0010111";
        rd = reg2bin(substrings[1]);
        imm_31_12 = dec2bin(stoi(substrings[2]), 20);
        machine_code_line = imm_31_12 + rd + opcode;
    } else if (operation == "halt") {
        machine_code_line = "00000000000000000000000000000000";
    } else if (operation == "nop") {
        // nop = addi x0, x0, 0
        opcode = "0010011";
        funct3 = "000";
        rd = reg2bin("x0");
        rs1 = reg2bin("x0");
        imm_11_0 = dec2bin(0, 12);
        machine_code_line = imm_11_0 + rs1 + funct3 + rd + opcode;
    } else {
        cout << "Error: Unknown operation : " << operation << endl;
        assert(0);
    }
    return machine_code_line;
}

int main() {
    string Mnemonic_file;

    cout << "Enter the name of the file containing the Mnemonics: ";
    cin >> Mnemonic_file;

    ifstream Mnemonic_file_stream(Mnemonic_file);
    if (!Mnemonic_file_stream) {
        cout << "Error: File not found" << endl;
        return 1;
    }

    string Machine_code_file = Mnemonic_file.substr(0, Mnemonic_file.find('.')) + ".prog";

    ofstream Machine_code_file_stream(Machine_code_file);
    if (!Machine_code_file_stream) {
        cout << "Error: File not found" << endl;
        return 1;
    }

    vector<string> Mnemonics_lines;
    string tmpstr;
    while (getline(Mnemonic_file_stream, tmpstr)) {
        if (tmpstr.empty()) continue; 
        auto startPos = tmpstr.find_first_not_of(" \t");
        // 如果全是空格或 tab，則跳過
        if (startPos == std::string::npos) continue;
        // 檢查剩餘部分是否以 "//" 開頭
        if (tmpstr.substr(startPos, 2) == "//") continue;

        Mnemonics_lines.push_back(tmpstr);
        cout << tmpstr << endl;
    }

    labels.clear();
    actual_line_number = 0;

    // 先把所有 label 都讀出來
    for (int line_number = 0; line_number < static_cast<int>(Mnemonics_lines.size()); line_number++) {
        auto line = Mnemonics_lines[line_number];
        if (line[0] != ' ') { // labels
            auto label = line.substr(0, line.find(':'));
            labels.push_back(make_pair(label, actual_line_number));
            cout << endl << "Label: " << label << "        line: " << actual_line_number << endl;
        } else {
            actual_line_number++;
        }
    }
    cout << endl;

    actual_line_number = 0;

    for (int line_number = 0; line_number < static_cast<int>(Mnemonics_lines.size()); line_number++) {
        auto line = Mnemonics_lines[line_number];
        if (line[0] != ' ') { // labels
            continue;
        } else { // instructions
            auto comment_pos = line.find("//");
            if (comment_pos != std::string::npos) {
                line = line.substr(0, comment_pos); // 保留 "//" 之前的部分
            }
            // Replace commas with spaces for easier splitting
            for (char &ch : line) {
                if (ch == ',') {
                    ch = ' ';
                }
            }
            // Use stringstream to split by spaces
            vector<string> substrings;
            istringstream iss(line);
            while (iss >> tmpstr) {
                substrings.push_back(tmpstr);
            }

            // Print the results
            /*for (const std::string &substr : substrings) {
                cout << substr << " ";
            }
            cout << endl;
            */
            // Generate machine code
            cout << "Line " << actual_line_number << ": " << line << endl;
            auto machine_code_line = Mnemonic2MachineCode(substrings);
            // Seperate machine_code_line into 8-bit chunks
            for (int i = 0; i < 32; i += 8) {
                Machine_code_file_stream << machine_code_line.substr(i, 8) << " ";
            }
            Machine_code_file_stream << "    // ";
            string str_tmp = " ";
            for(auto l : labels) {
                if (l.second == actual_line_number) {
                    str_tmp = l.first + ": ";
                    break;
                }
            }
            Machine_code_file_stream << std::left << setw(25) << setfill(' ') << str_tmp;
            Machine_code_file_stream << Mnemonics_lines[line_number].substr(4, Mnemonics_lines[line_number].length() - 4);
            Machine_code_file_stream << endl;

            actual_line_number++;
        }
    }

    Mnemonic_file_stream.close();
    Machine_code_file_stream.close();

    cout << "Machine code generated successfully" << endl;

    return 0;
}
