`timescale 1ps / 1ps
`include "st1_fetch.v"
`include "st2_decode.v"
`include "st3_exe.v"
`include "st4_mem.v"
`include "st5_wb.v"
`include "inst_rom.v"
`include "data_ram.v"
`include "regfile.v"
module multi_cycle_cpu (  // ������cpu
    // ʱ���븴λ�ź�
    input clk,
    input resetn, // ��׺"n"����͵�ƽ��Ч

    // display data
    input  [ 4:0] rf_addr,
    input  [31:0] mem_addr,
    output [31:0] rf_data,
    output [31:0] mem_data,
    output [31:0] IF_pc,
    output [31:0] IF_inst,
    output [31:0] ID_pc,
    output [31:0] EXE_pc,
    output [31:0] MEM_pc,
    output [31:0] WB_pc,
    output [31:0] display_state
);

  // ���ƶ����ڵ�״̬�� begin
  reg [2:0] state;  // ��ǰ״̬
  reg [2:0] next_state;  // ��һ״̬
  assign display_state = {29'd0, state};  //չʾ��ǰ��������ڴ����ĸ�ģ��
  //״̬��״̬
  parameter IDLE = 3'd0;  //��ʼ
  parameter FETCH = 3'd1;  //ȡָ
  parameter DECODE = 3'd2;  // ����
  parameter EXE = 3'd3;  // ִ��
  parameter MEM = 3'd4;  // �´�
  parameter WB = 3'd5;  // д��

  always @(posedge clk) begin  // ��ǰ״̬
    if (!resetn) begin  // �����λ�ź���Ч
      state <= IDLE;  // ��ǰ״̬Ϊ ��ʼ
    end else begin  // ����
      state <= next_state;  // Ϊ��һ״̬
    end
  end

  wire IF_over;  // IFģ����ִ����
  wire ID_over;  // IDģ����ִ����
  wire EXE_over;  // EXEģ����ִ����
  wire MEM_over;  // MEMģ����ִ����
  wire WB_over;  // WBģ����ִ����
  wire jbr_not_link;  // ��ָ֧���link�ࣩ��ֻ��IF��ID��
  always @(*) begin
    case (state)
      IDLE: begin
        next_state = FETCH;  // IDLE->IF
      end
      FETCH: begin
        if (IF_over) begin
          next_state = DECODE;  // IF->ID
        end else begin
          next_state = FETCH;  // continue IF
        end
      end
      DECODE: begin
        if (ID_over) begin  // ����Ƿ�link��ķ�ָ֧����д�أ�����ִ��
          next_state = jbr_not_link ? FETCH : EXE;  // ID->WB/EXE
        end else begin
          next_state = DECODE;  // continue ID
        end
      end
      EXE: begin
        if (EXE_over) begin
          next_state = MEM;  // EXE->MEM
        end else begin
          next_state = EXE;  // continue EXE
        end
      end
      MEM: begin
        if (MEM_over) begin
          next_state = WB;  // MEM->WB
        end else begin
          next_state = MEM;  // continue MEM
        end
      end
      WB: begin
        if (WB_over) begin
          next_state = FETCH;  // WB->IF
        end else begin
          next_state = WB;  // continue WB
        end
      end
      default: next_state = IDLE;
    endcase
  end
  // 5ģ���valid�ź�
  wire IF_valid;
  wire ID_valid;
  wire EXE_valid;
  wire MEM_valid;
  wire WB_valid;
  assign IF_valid  = (state == FETCH);  // ��ǰ״̬Ϊȡָʱ IF����Ч
  assign ID_valid  = (state == DECODE);  // ��ǰ״̬Ϊ����ʱ ID����Ч
  assign EXE_valid = (state == EXE);  // ��ǰ״̬Ϊִ��ʱ EXE����Ч
  assign MEM_valid = (state == MEM);  // ��ǰ״̬Ϊ�ô�ʱ MEM����Ч
  assign WB_valid  = (state == WB);  // ��ǰ״̬Ϊд��ʱ WB����Ч
  // ���ƶ����ڵ�״̬�� end

  // 5��������� begin
  wire [ 63:0] IF_ID_bus;  // IF->ID������
  wire [149:0] ID_EXE_bus;  // ID->EXE������
  wire [105:0] EXE_MEM_bus;  // EXE->MEM������
  wire [ 69:0] MEM_WB_bus;  // MEM->WB������

  // �������������ź�
  reg  [ 63:0] IF_ID_bus_r;
  reg  [149:0] ID_EXE_bus_r;
  reg  [105:0] EXE_MEM_bus_r;
  reg  [ 69:0] MEM_WB_bus_r;

  //IF->ID�������ź�
  always @(posedge clk) begin
    if (IF_over) begin
      IF_ID_bus_r <= IF_ID_bus;
    end
  end

  //ID->EXE�������ź�
  always @(posedge clk) begin
    if (ID_over) begin
      ID_EXE_bus_r <= ID_EXE_bus;
    end
  end

  //EXE->MEM�������ź�
  always @(posedge clk) begin
    if (EXE_over) begin
      EXE_MEM_bus_r <= EXE_MEM_bus;
    end
  end

  //MEM->WB�������ź�
  always @(posedge clk) begin
    if (MEM_over) begin
      MEM_WB_bus_r <= MEM_WB_bus;
    end
  end
  // 5��������� end

  // ���������ź� begin
  // ��ת����
  wire [32:0] jbr_bus;

  // IF��inst_rom����
  wire [31:0] inst_addr;
  wire [31:0] inst;

  // MEM��data_ram����
  wire [3:0] dm_wen;
  wire [31:0] dm_addr;
  wire [31:0] dm_wdata;
  wire [31:0] dm_rdata;

  // ID��regfile����
  wire [4:0] rs;
  wire [4:0] rt;
  wire [31:0] rs_value;
  wire [31:0] rt_value;

  // WB��regfile����
  wire rf_wen;
  wire [4:0] rf_wdest;
  wire [31:0] rf_wdata;  //͸
  // ���������ź� end

  // ��ģ��ʵ���� begin
  wire next_fetch;  // next_state_is_fetch ��������ȡֵģ�飬��Ҫ������pcֵ
  // ��ǰ״̬ΪID����ָ��Ϊ��ת��ָ֧���link�ࣩ����IDִ�����
  // ���ߣ���ǰ״̬ΪWB����WBִ����ɣ��򼴽�����IF״̬
  assign next_fetch = (state == DECODE & ID_over & jbr_not_link) | (state == WB & WB_over);

  st1_fetch IF_module (  // ȡָ
      .clk(clk),  // input, 1
      .resetn(resetn),  // input, 1
      .IF_valid(IF_valid),  // input, 1
      .next_fetch(next_fetch),  // input, 1
      .inst(inst),  // input, 32
      .jbr_bus(jbr_bus),  // input, 33
      .inst_addr(inst_addr),  // optput, 32
      .IF_over(IF_over),  // output, 1
      .IF_ID_bus(IF_ID_bus),  // output, 64

      // չʾpc��ȡ����ָ��
      .IF_pc  (IF_pc),
      .IF_inst(IF_inst)
  );

  st2_decode ID_module (  // ����
      .ID_valid(ID_valid),  // input, 1
      .IF_ID_bus_r(IF_ID_bus_r),  // input, 64
      .rs_value(rs_value),  // input, 32
      .rt_value(rt_value),  // input, 32
      .rs(rs),  // output, 5
      .rt(rt),  // output, 5
      .jbr_bus(jbr_bus),  // output, 33
      .jbr_not_link(jbr_not_link),  // output, 1
      .ID_over(ID_over),  // output, 1
      .ID_EXE_bus(ID_EXE_bus),  // output, 150

      // չʾpc
      .ID_pc(ID_pc)
  );

  st3_exe EXE_module (  // ִ�м�
      .EXE_valid(EXE_valid),  // input, 1
      .ID_EXE_bus_r(ID_EXE_bus_r),  // input, 150
      .EXE_over(EXE_over),  // output, 1
      .EXE_MEM_bus(EXE_MEM_bus),  // output, 106

      //չʾpc
      .EXE_pc(EXE_pc)
  );

  st4_mem MEM_module (  // �ô漶
      .clk(clk),  // input, 1
      .MEM_valid(MEM_valid),  // input, 1
      .EXE_MEM_bus_r(EXE_MEM_bus_r),  // input, 106
      .dm_rdata(dm_rdata),  // input, 32
      .dm_addr(dm_addr),  // output, 32
      .dm_wen(dm_wen),  // output, 4
      .dm_wdata(dm_wdata),  // output, 32
      .MEM_over(MEM_over),  // output, 1
      .MEM_WB_bus(MEM_WB_bus),  // output, 70

      //չʾpc
      .MEM_pc(MEM_pc)
  );

  st5_wb WB_module (  // д�ؼ�
      .WB_valid(WB_valid),  // input, 1
      .MEM_WB_bus_r(MEM_WB_bus_r),  // input, 70
      .rf_wen(rf_wen),  // output, 1
      .rf_wdest(rf_wdest),  // output, 5
      .rf_wdata(rf_wdata),  // output, 32
      .WB_over(WB_over),  // output, 1

      // չʾpc
      .WB_pc(WB_pc)
  );

  inst_rom inst_rom_module (  // ָ��洢��
      .clk(clk),  // input, 1 ,ʱ��
      .addr(inst_addr[9:2]),  // input, 8, ָ���ַ��pc[9:2]
      .inst(inst)  // output, 32, ָ��
  );

  regfile rf_module (  // �Ĵ�����ģ��
      .clk(clk),  // input, 1
      .wen(rf_wen),  // input, 1
      .raddr1(rs),  // input, 5
      .raddr2(rt),  // input, 5
      .waddr(rf_wdest),  // input, 5
      .wdata(rf_wdata),  // input, 32
      .rdata1(rs_value),  // output, 32
      .rdata2(rt_value),  // output, 32

      //display rf
      .rf_addr(rf_addr),  // input, 4
      .rf_data(rf_data)   // output, 32
  );

  data_ram data_ram_module (  // ���ݴ洢ģ��
      .clk(clk),  // input, 1, ʱ��
      .wen(dm_wen),  // input, 4, дʹ��
      .addr(dm_addr[9:2]),  // input, 8, ����ַ
      .wdata(dm_wdata),  // input, 32, д����
      .rdata(dm_rdata),  // output, 32, ������

      //display mem
      .clka(clk),
      .wea(4'd0),
      .addra(mem_addr[9:2]),  // input, 8
      .rdataa(mem_data),  // output, 32
      .wdataa(32'd0)
  );

  //��ģ��ʵ���� end
endmodule
