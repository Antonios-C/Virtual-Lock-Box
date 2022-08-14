`default_nettype none

module top (
  // I/O ports
  input  logic hz100, reset,
  input  logic [20:0] pb,
  output logic [7:0] left, right,
         ss7, ss6, ss5, ss4, ss3, ss2, ss1, ss0,
  output logic red, green, blue,

  // Ports from/to UART
  output logic [7:0] txdata,
  input  logic [7:0] rxdata,
  output logic txclk, rxclk,
  input  logic txready, rxready
);

 
  
  logic W_PRESSED, X_PRESSED, Y_PRESSED;
  assign W_PRESSED = pb[16];
  assign X_PRESSED = pb[17];
  assign Y_PRESSED = pb[18];
  
 logic [4:0] keycode;
  logic strobe, is_empty;
  synckey sk (.clk(hz100), .rst(reset), .in(pb[19:0]), .out(keycode), .strobe(strobe));
  logic [31:0] cbo;
  charbuf cb (.clk(strobe), .rst(reset), .enable(charbuf_en), 
              .clr(W_PRESSED), .bksp(X_PRESSED),
              .is_ctrl(|pb[19:16]), .in_char(keycode[3:0]), 
              .is_empty(is_empty), .out(cbo));
  
  
  typedef enum logic [3:0] {INIT = 0, SECURE = 1, OPEN = 2, ALARM = 3} dcl_fsm_t;
  dcl_fsm_t dcl_fsm;
  logic [31:0] passphrase;
  logic charbuf_en;
  
  always_ff @(posedge strobe, posedge reset) begin 
    if(reset)begin 
      dcl_fsm <= INIT;
      passphrase <= 32'b0;
      charbuf_en <= 1'b1;
      end
    else if(W_PRESSED && dcl_fsm == INIT)begin
      passphrase <= cbo;
      dcl_fsm <= SECURE;
      end
    else if(Y_PRESSED && dcl_fsm == OPEN)begin 
      charbuf_en <= 1'b1;
      dcl_fsm <= SECURE;
    end
    else if(W_PRESSED && dcl_fsm == SECURE)begin 
      charbuf_en <= 1'b0;
      if(passphrase == cbo)
        dcl_fsm <= OPEN;
      else 
        dcl_fsm <= ALARM;
    end
    
  
  end

  assign blue = (dcl_fsm == SECURE);
  assign green = (dcl_fsm == OPEN);
  assign red = ((dcl_fsm == ALARM) && hz4);
  
  localparam STR_SECURE   = 64'h6D79393E50790000;
  localparam STR_OPEN     = 64'h5C73795400000000;
  localparam STR_CALL_911 = 64'h3977383800670606;
  
  
  always_comb begin
    if(is_empty)begin
      case(dcl_fsm) 
        INIT : {ss7,ss6,ss5,ss4,ss3,ss2,ss1,ss0} = STR_OPEN;
        OPEN : {ss7,ss6,ss5,ss4,ss3,ss2,ss1,ss0} = STR_OPEN;
        SECURE : {ss7,ss6,ss5,ss4,ss3,ss2,ss1,ss0} = STR_SECURE;
        ALARM : {ss7,ss6,ss5,ss4,ss3,ss2,ss1,ss0} = STR_CALL_911;
        default : {ss7,ss6,ss5,ss4,ss3,ss2,ss1,ss0} = 64'b0;
      endcase
      
      end
    else begin 
      {ss7[6:0],ss6[6:0],ss5[6:0],ss4[6:0],ss3[6:0],ss2[6:0],ss1[6:0],ss0[6:0]} = buf_ss;
      {ss7[7],ss6[7],ss5[7],ss4[7],ss3[7],ss2[7],ss1[7],ss0[7]} = 0;
    end
  end
  
   
  
  logic hz4;
  clock_4hz clk4 (.clk(hz100), .rst(reset), .hz4(hz4));
  

  
  // display charbuf
  logic [55:0] buf_ss;
  ssdec s0 (.in(cbo[3:0]), .enable(charbuf_en), .out(buf_ss[6:0]));
  ssdec s1 (.in(cbo[7:4]), .enable(|cbo[31:4]), .out(buf_ss[13:7]));
  ssdec s2 (.in(cbo[11:8]), .enable(|cbo[31:8]), .out(buf_ss[20:14]));
  ssdec s3 (.in(cbo[15:12]), .enable(|cbo[31:12]), .out(buf_ss[27:21]));
  ssdec s4 (.in(cbo[19:16]), .enable(|cbo[31:16]), .out(buf_ss[34:28]));
  ssdec s5 (.in(cbo[23:20]), .enable(|cbo[31:20]), .out(buf_ss[41:35]));
  ssdec s6 (.in(cbo[27:24]), .enable(|cbo[31:24]), .out(buf_ss[48:42]));
  ssdec s7 (.in(cbo[31:28]), .enable(|cbo[31:28]), .out(buf_ss[55:49])); // 55 49



endmodule

module charbuf(
input logic clk, rst, enable, clr, bksp, is_ctrl,
input logic [3:0]in_char,
output logic is_empty,
output logic [31:0]out
);

logic [31:0]outN;

always_ff @(posedge clk, posedge rst) begin 
  if(rst) //clear - reset
    out <= 32'b0;
  else if(clr) //check passcode for later
    out <= 32'b0;
  else
    out <= outN;
end 

always_comb begin 
  if(enable && bksp)
    outN = out >> 4;
  else if(enable && ~is_ctrl) begin
    outN = out << 4;
    outN[3:0] = in_char;
  end 
  else 
    outN = out;
    
end 
endmodule

module ssdec(  
  input logic [3:0] in,
  input logic enable,
  output logic [6:0]out
);
always_comb
  begin 
    case({enable,in})
    5'b10000 : out = 7'b0111111;
    5'b10001 : out = 7'b0000110;
    5'b10010: out = 7'b1011011;
    5'b10011 : out = 7'b1001111;
    5'b10100 : out = 7'b1100110;
    5'b10101 : out = 7'b1101101;
    5'b10110 : out = 7'b1111101;
    5'b10111 : out = 7'b0000111;
    5'b11000 : out = 7'b1111111;
    5'b11001 : out = 7'b1101111;
    5'b11010 : out = 7'b1110111;
    5'b11011 : out = 7'b1111100;
    5'b11100 : out = 7'b0111001;
    5'b11101 : out = 7'b1011110;
    5'b11110 : out = 7'b1111001;
    5'b11111 : out = 7'b1110001;
    default : out = 7'b0000000;
    endcase
  end
endmodule

module synckey(
input logic clk, rst,
input logic [19:0] in, 
output logic [4:0] out,
output logic strobe
);
  assign out[0] = in[1] | in[3] | in[5] | in[7] | in[9] | in[11] | in[13] | in[15] | in[17] | in[19];
  assign out[1] = in[2] | in[3] | in[6] | in[7] | in[10] | in[11] | in[14] | in[15] | in[18] | in[19];
  assign out[2] = in[4] | in[5] | in[6] | in[7] | in[12] | in[13] | in[14] | in[15];
  assign out[3] = in[8] | in[9] | in[10] | in[11] | in[12] | in[13] | in[14] | in[15];
  assign out[4] = in[16] | in[17] | in[18] | in[19];
  logic keyclk;
  assign keyclk = | in[19:0];
  logic [1:0] delay; 
  always_ff @(posedge clk, posedge rst) begin 
    if(rst)
      delay <= 2'b0;
    else 
      delay <= (delay << 1) | {1'b0, keyclk};
  end
  assign strobe = delay[1];
endmodule

module clock_4hz(
  input logic clk, rst,
  output logic hz4);
  
  logic [4:0]count;
  logic blink;
  assign hz4 = blink;
  always_ff @(posedge clk, posedge rst)
  begin 
    count <= count + 1;
    if(rst)
      begin 
      count <= 0;
      blink <= 1'b1;
      end
    else if(count == 12)
      begin 
      if(blink == 1'b1)
        blink <= 1'b0;
      else
        blink <= 1'b1;
        count <= 0;
      end
  end 
endmodule


