#include <iostream>
#include <fstream>
#include <string>
#include <vector>
#include <sstream>

using namespace std;

#define MAX_LINE 1000

int actual_line_number;

int reg2num(string reg) {
    if (reg == "x0") return 0;
    if (reg == "x1" || reg == "ra") return 1;
    if (reg == "x2" || reg == "sp") return 2;
    if (reg == "x3" || reg == "gp") return 3;
    if (reg == "x4" || reg == "tp") return 4;
    if (reg == "x5" || reg == "t0") return 5;
    if (reg == "x6" || reg == "t1") return 6;
    if (reg == "x7" || reg == "t2") return 7;
    if (reg == "x8" || reg == "s0" || reg == "fp") return 8;
    if (reg == "x9" || reg == "s1") return 9;
    if (reg == "x10" || reg == "a0") return 10;
    if (reg == "x11" || reg == "a1") return 11;
    if (reg == "x12" || reg == "a2") return 12;
    if (reg == "x13" || reg == "a3") return 13;
    if (reg == "x14" || reg == "a4") return 14;
    if (reg == "x15" || reg == "a5") return 15;
    if (reg == "x16" || reg == "a6") return 16;
    if (reg == "x17" || reg == "a7") return 17;
    if (reg == "x18" || reg == "s2") return 18;
    if (reg == "x19" || reg == "s3") return 19;
    if (reg == "x20" || reg == "s4") return 20;
    if (reg == "x21" || reg == "s5") return 21;
    if (reg == "x22" || reg == "s6") return 22;
    if (reg == "x23" || reg == "s7") return 23;
    if (reg == "x24" || reg == "s8") return 24;
    if (reg == "x25" || reg == "s9") return 25;
    if (reg == "x26" || reg == "s10") return 26;
    if (reg == "x27" || reg == "s11") return 27;
    if (reg == "x28" || reg == "t3") return 28;
    if (reg == "x29" || reg == "t4") return 29;
    if (reg == "x30" || reg == "t5") return 30;
    if (reg == "x31" || reg == "t6") return 31;
    return -1;
}

string Mnemonic2MachineCode(vector<string> substrings) {
    string machine_code_line = "";
    string opcode, rs1, rs2, rd, imm, shamt, funct3, funct7;
    auto operation = substrings[0];
    if (operation == "add" || operation == "sub" || operation == "and" || operation == "or" || operation == "xor" || operation == "sll" || operation == "srl" || operation == "sra" || operation == "slt" || operation == "sltu") {
        // R-type
        opcode = (operation == "slt" || operation == "sltu") ? "0110011" : "0000011";
        funct3 = (operation == "add" || operation == "sub") ? "000" :
                (operation == "sll") ? "001" :
                (operation == "slt" || operation == "srl") ? "010" :
                (operation == "sra") ? "011" :
                (operation == "xor") ? "100" :
                (operation == "or") ? "110" :
                (operation == "and") ? "111" : "000";
        funct7 = (operation == "sub" || operation == "sra")? "0100000" : "0000000";
        rd = reg2num(substrings[1]);
        rs1 = reg2num(substrings[2]);
        rs2 = reg2num(substrings[3]);
    } else if (operation == "addi" || operation == "slti" || operation == "sltiu" || operation == "xori" || operation == "ori" || operation == "andi" || operation == "slli" || operation == "srli" || operation == "srai") {
        // I-type
        opcode = "0010011";
        funct3 = (operation == "slli" || operation == "srli") ? "001" :
                (operation == "slti") ? "010" :
                (operation == "xori") ? "100" :
                (operation == "ori") ? "110" :
                (operation == "andi") ? "111" : "000";
        rd = reg2num(substrings[1]);
        rs1 = reg2num(substrings[2]);
        imm = substrings[3];
    } else if (operation == "lb" || operation == "lh" || operation == "lw" || operation == "lbu" || operation == "lhu") {

    }
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
        Mnemonics_lines.push_back(tmpstr);
    }

    vector<pair<string,int> > labels;

    int line_number = 0;
    actual_line_number = 0;
    for (; line_number < Mnemonics_lines.size(); line_number++) {
        auto line = Mnemonics_lines[line_number];
        if (line[0] != ' ') { // labels
            auto label = line.substr(0, line.find(':'));
            labels.push_back(make_pair(label, actual_line_number));
            cout << endl << "Label: " << label << "        line: " << actual_line_number << endl;
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
            for (const std::string &substr : substrings) {
                cout << substr << " ";
            }
            cout << endl;

            // Generate machine code
            auto machine_code_line = Mnemonic2MachineCode(substrings);
            Machine_code_file_stream << machine_code_line << endl;

            actual_line_number++;
        }
    }

    Mnemonic_file_stream.close();
    Machine_code_file_stream.close();

    cout << "Machine code generated successfully" << endl;

    return 0;
}