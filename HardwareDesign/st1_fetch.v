`timescale 1ps / 1ps
`define STARTADDR 32'd0
module st1_fetch (  // ȡָ
    input clk,  // ʱ���ź�
    input resetn,  // ��λ�źţ��͵�ƽ��Ч
    input IF_valid,  // ȡָ����Ч�ź�
    input next_fetch,  // ȡ��һ��ָ���������PCֵ
    input [31:0] inst,  // inst_romȡ����ָ��
    input [32:0] jbr_bus,  // ��ת���� {jbr_taken, jbr_target}
    output [31:0] inst_addr,  // ����inst_rom��ȡֵ��ַ
    output reg IF_over,  // IFģ��ִ�����
    output [63:0] IF_ID_bus,  // IF->ID����

    //չʾpc��ȡ����ָ��
    output [31:0] IF_pc,
    output [31:0] IF_inst
);
  //pc begin
  wire [31:0] next_pc;  // ��һָ���ַ
  wire [31:0] seq_pc;  // ����ת��˳��ִ�У�����һָ���ַ
  reg [31:0] pc;  // ���������pc
  // ��תpc
  wire jbr_taken;  // ��ת�ź�
  wire [31:0] jbr_target;  // ��ת��ַ
  assign {jbr_taken, jbr_target} = jbr_bus;  // ��ת����

  assign seq_pc[31:2] = pc[31:2] + 1'b1;  // ˳��ִ�е���һָ���ַ��b<PC>=b<PC>+b100
  assign seq_pc[1:0] = pc[1:0];

  // ��ָ���ָ����ת��Ϊ��ת��ַ������Ϊ��һ��ָ��
  assign next_pc = jbr_taken ? jbr_target : seq_pc;

  always @(posedge clk) begin  // pc���������
    if (!resetn) begin
      pc <= `STARTADDR;  // ��λ��ȡ������ʼ��ַ
    end else if (next_fetch) begin  // ����pcֵ
      pc <= next_pc;  // ����λ��ȡ��ָ��
    end
  end
  // pc end

  // to instrom begin
  assign inst_addr = pc;
  // to instrom end

  // IFִ����� begin
  // ����inst_romΪͬ������
  // ȡ����ʱ����һ����ʱ
  // ������ַ����һ��ʱ�Ӳ��ܵõ���Ӧ��ָ��
  // ��ȡֵģ����Ҫ����ʱ��
  // ��IF_valid����һ�ļ���IF_over�ź�
  always @(posedge clk) begin  // ͬ����
    // always @(*) begin  // �첽��
    IF_over <= IF_valid;  // ��������ֵ ��ʱIF_valid������һʱ��ֵ0
  end
  // ���inst_romΪ�첽����
  // ��IF_valid����IF_over�ź�
  // ��ȡָһ�����
  // IFִ����� end

  // IF->ID����begin
  assign IF_ID_bus = {pc, inst};
  // IF->ID����end

  // display IF_pc��IF_inst
  assign IF_pc = pc;
  assign IF_inst = inst;
  // display end
endmodule
