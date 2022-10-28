`timescale 1ps / 1ps
`include "adder.v"
module alu (  // ALUģ�飬�ɽ���12�ֲ���
    input [11:0] alu_control,  // ALU�����ź�
    input [31:0] alu_src1,  // ALU������1��Ϊ����
    input [31:0] alu_src2,  // ALU������2��Ϊ����
    output [31:0] alu_result  // ALU���
);

  // ALU�����źţ�������
  wire alu_add;  // �ӷ�����
  wire alu_sub;  // ��������
  wire alu_slt;  // �з��űȽϣ�С����λ�����üӷ���������
  wire alu_sltu;  // �޷��űȽϣ�С����λ�����üӷ���������
  wire alu_and;  // ��λ��
  wire alu_nor;  // ��λ���
  wire alu_or;  // ��λ��
  wire alu_xor;  // ��λ���
  wire alu_sll;  // �߼�����
  wire alu_srl;  // �߼�����
  wire alu_sra;  // ��������
  wire alu_lui;  // ��λ����

  assign alu_add  = alu_control[11];
  assign alu_sub  = alu_control[10];
  assign alu_slt  = alu_control[9];
  assign alu_sltu = alu_control[8];
  assign alu_and  = alu_control[7];
  assign alu_nor  = alu_control[6];
  assign alu_or   = alu_control[5];
  assign alu_xor  = alu_control[4];
  assign alu_sll  = alu_control[3];
  assign alu_srl  = alu_control[2];
  assign alu_sra  = alu_control[1];
  assign alu_lui  = alu_control[0];

  wire [31:0] add_sub_result;
  wire [31:0] slt_result;
  wire [31:0] sltu_result;
  wire [31:0] and_result;
  wire [31:0] nor_result;
  wire [31:0] or_result;
  wire [31:0] xor_result;
  wire [31:0] sll_result;
  wire [31:0] srl_result;
  wire [31:0] sra_result;
  wire [31:0] lui_result;

  assign and_result = alu_src1 & alu_src2;
  assign or_result  = alu_src1 | alu_src2;
  assign nor_result = ~or_result;
  assign xor_result = alu_src1 ^ alu_src2;
  assign lui_result = {alu_src2[15:0], 16'd0};  // src2��16λװ������16λ

  // �ӷ��� begin
  // add, sub, slt, sltu��ʹ�ø�ģ��
  wire [31:0] adder_operand1;
  wire [31:0] adder_operand2;
  wire adder_cin;
  wire [31:0] adder_result;
  wire adder_cout;
  assign adder_operand1 = alu_src1;
  assign adder_operand2 = alu_add ? alu_src2 : ~alu_src2;  // �ж����ӷ����Ǽ���
  assign adder_cin = ~alu_add;  // ������Ҫcin����Ϊ�����Ĳ�����ȡ����1��ǰ���ѽ�alu_src2��λȡ��

  // ���üӷ���ģ��
  adder adder_module (
      .operand1(adder_operand1),  // input, 32
      .operand2(adder_operand2),  // input, 32
      .cin(adder_cin),  // input, 1
      .result(adder_result),  // output, 32
      .cout(adder_cout)  // output, 1
  );

  // �Ӽ����
  assign add_sub_result = adder_result;

  // slt���
  assign slt_result = adder_result[31] ? 1'b1 : 1'b0;

  // sltu���
  assign sltu_result = adder_cout ? 1'b0 : 1'b1;  //�޷�����С����λ  


  // �߼�����
  assign sll_result = alu_src2 << alu_src1;

  // �߼�����
  assign srl_result = alu_src2 >> alu_src1;

  // ��������
  wire signed [31:0] temp_src2;  //������������ʱ����
  assign temp_src2  = alu_src2;
  assign sra_result = temp_src2 >>> alu_src1;

  // ѡ����Ӧ������
  // assign alu_result = (alu_add | alu_sub) ? add_sub_result[31:0] : alu_slt ? slt_result : alu_sltu ? sltu_result : alu_and ? and_result : alu_nor ? nor_result : alu_or ? or_result : alu_xor ? xor_result : alu_sll ? sll_result : alu_srl ? srl_result : alu_sra ? sra_result : alu_lui ? lui_result : 32'd0;
  reg [31:0] alu_result_r;
  always @(*) begin
    if (alu_add | alu_sub) alu_result_r <= add_sub_result;
    else if (alu_slt) alu_result_r <= slt_result;
    else if (alu_sltu) alu_result_r <= sltu_result;
    else if (alu_and) alu_result_r <= and_result;
    else if (alu_nor) alu_result_r <= nor_result;
    else if (alu_or) alu_result_r <= or_result;
    else if (alu_xor) alu_result_r <= xor_result;
    else if (alu_sll) alu_result_r <= sll_result;
    else if (alu_srl) alu_result_r <= srl_result;
    else if (alu_sra) alu_result_r <= sra_result;
    else if (alu_lui) alu_result_r <= lui_result;
  end
  assign alu_result = alu_result_r;
endmodule
