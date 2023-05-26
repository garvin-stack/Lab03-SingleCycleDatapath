//=========================================================================
// Name & Email must be EXACTLY as in Gradescope roster!
// Name: Garvin Ha
// Email: gha003@ucr.edu
// 
// Assignment name: Lab03-SingleCycleDatapath
// Lab section: 021
// TA: Eren, Omar
// 
// I hereby certify that I have not received assistance on this assignment,
// or used code, from ANY outside source other than the instruction team
// (apart from what was provided in the starter file).
//
//=========================================================================

`timescale 1ns / 1ps

module processor #(parameter WORD_SIZE=32,MEM_FILE="init.coe") (
    input clk,
    input rst,   
	 // Debug signals 
    output wire [WORD_SIZE-1:0] prog_count, 
    output [5:0] instr_opcode,
    output [4:0] reg1_addr,
    output [WORD_SIZE-1:0] reg1_data,
    output [4:0] reg2_addr,
    output [WORD_SIZE-1:0] reg2_data,
    output [4:0] write_reg_addr,
    output [WORD_SIZE-1:0] write_reg_data 
);
wire [31:0] add_mux_output;
wire [31:0] curr_pc;
wire [31:0] next_pc;
wire [31:0] instruction;
wire [31:0] alu_alu_output;
wire [31:0] read_data;
wire [31:0] write_data;
//wire [31:0] write_reg;
wire [31:0] alu_op2;
wire [31:0] add_alu_output;

wire [4:0] write_reg_mux_out;
wire [3:0] alu_out;
wire [1:0] alu_op;
wire [31:0] reg_mux_output_wire;

wire alu_src;
wire mem_read;
wire branch;
wire mem_to_reg;
wire mem_write;
wire reg_write;
wire zero;
wire reg_dst;

wire [31:0] immediate;

assign next_pc = curr_pc + 4;
assign prog_count = curr_pc;
assign instr_opcode = instruction[31:26];
assign reg1_addr = instruction[25:21];
assign reg2_addr = instruction[20:16];
assign write_reg_addr = write_reg_mux_out;
assign immediate = {{16{instruction[15:0]}}, instruction[15:0]};

// ----------------------------------------------
// Insert solution below here
// ----------------------------------------------
gen_register PCRegister (
    .clk(clk),
    .rst(rst),
    .write_en(1'b1),
    .data_in(next_pc),
    .data_out(curr_pc)
);

cpumemory instructionMemory(//#(.MEM_FILE(MEM_FILE)) instructionMemory (
    .clk(clk),
    .rst(rst),
    .instr_read_address(curr_pc[9:2]),
    .instr_instruction(instruction),
    .data_mem_write(mem_write),
    .data_address(alu_alu_output[7:0]),
    .data_read_data(read_data),
    .data_write_data(reg2_data)
);

alu_control alu_contr (
    .alu_out(alu_out),
    .alu_op(alu_op),
    .instruction_5_0(instruction[5:0])
);

cpu_registers cpu_Reg (
    .clk(clk),
    .rst(rst),
    .reg_write(reg_write),
    .read_data_1(reg1_data),
    .read_data_2(reg2_data),
    .write_data(write_reg_data),
    .write_register(write_reg_mux_out),
    .read_register_1(reg1_addr),
    .read_register_2(reg2_addr)    
);

control_unit control_instr_31_26 (
    .instr_op(instr_opcode),
    .reg_dst(reg_dst),
    .branch(branch),
    .mem_read(mem_read),
    .mem_to_reg(mem_to_reg),
    .alu_op(alu_op),
    .mem_write(mem_write),
    .alu_src(alu_src),
    .reg_write(reg_write)
);

mux_2_1 #(.WORD_SIZE(5)) write_reg_mux(
    .select_in(reg_dst),
    .datain1(reg2_addr),
    .datain2(write_reg_addr),
    .data_out(write_reg_mux_out)
);

mux_2_1 registers_to_alu_mux(
    .select_in(alu_src),
    .datain1(reg2_data),
    .datain2({{16{instruction[15]}}, instruction[15:0]}),
    .data_out(reg_mux_output_wire)
);

alu alu_control_unit(
    .alu_control_in(alu_out),
    .channel_a_in(reg1_data),
    .channel_b_in(reg_mux_output_wire),
    .zero_out(zero),
    .alu_result_out(alu_alu_output)
);

mux_2_1 data_mem_mux(
    .select_in(mem_to_reg),
    .datain2(read_data),
    .datain1(alu_alu_output),
    .data_out(write_reg_data)
);


alu add_alu_pc(
    .alu_control_in(`ALU_ADD),
    .channel_a_in(curr_pc),
    .channel_b_in(immediate),//shift 2
    //.zero_out(),
    .alu_result_out(add_alu_output)
);
mux_2_1 add_mux(
    .select_in(branch & zero),
    .datain1(curr_pc),
    .datain2(add_alu_output),
    .data_out(add_mux_output)
);

endmodule
