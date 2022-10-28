`timescale 1ns / 1ps
module regfile (
    input clk,  // ʱ��
    input wen,  // ʹ���ź� 1: д; 0: ��
    input [4:0] raddr1,  // ���˿�1��ַ
    input [4:0] raddr2,  // ���˿�2��ַ
    input [4:0] waddr,  // д�˿ڵ�ַ
    input [31:0] wdata,  // д����
    output reg [31:0] rdata1,  // ���˿�1����
    output reg [31:0] rdata2,  // ���˿�2����

    // display rf
    input  [ 4:0] rf_addr,
    output [31:0] rf_data
);


  reg [31:0] regfile[31:0];
  initial begin
      regfile[0] <= 0;
  end


  always @(posedge clk) begin  // д���� ͬ��
    if (wen) begin
      regfile[waddr] <= wdata;
    end
  end

  always @(*) begin  // ������ �첽
  // always @(posedge clk) begin  // ������ ͬ��
    if (raddr1 > 0 && raddr1 < 32) begin
      rdata1 <= regfile[raddr1];
    end else begin
      rdata1 <= 32'd0;
    end

    if (raddr2 > 0 && raddr2 < 32) begin
      rdata2 <= regfile[raddr2];
    end else begin
      rdata2 <= 32'd0;
    end
  end

  // display rf begin
  assign rf_data = regfile[rf_addr];
  // display rf end

endmodule
