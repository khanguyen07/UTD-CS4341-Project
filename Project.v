module DFF1(clk,in,out);
  parameter n=1;//width
  input clk;
  input [n-1:0] in;
  output [n-1:0] out;
  reg [n-1:0] out;
  
  always @(posedge clk)
  out = in;
 endmodule

module DFF8(clk,in,out);
  parameter n=8;//width
  input clk;
  input [n-1:0] in;
  output [n-1:0] out;
  reg [n-1:0] out;
  
  always @(posedge clk)
  out = in;
 endmodule
 
 module Mux2(a1, a0, s, b) ;
  parameter k = 8 ;
  input [k-1:0] a1, a0 ;  // inputs
  input [1:0]   s ; // one-hot select
  output[k-1:0] b ;
   assign b = ({k{s[1]}} & a1) |
              ({k{s[0]}} & a0) ;
endmodule // Mux2

module Mux8(a7, a6, a5, a4, a3, a2, a1, a0, s, b) ;
  parameter k = 8 ;
  input [k-1:0] a7, a6, a5, a4, a3, a2, a1, a0 ;  // inputs
  input [k-1:0]   s ; // one-hot select
  output[k-1:0] b ;
   assign b = ({k{s[7]}} & a7) | 
			  ({k{s[6]}} & a6) | 
			  ({k{s[5]}} & a5) | 
			  ({k{s[4]}} & a4) | 
			  ({k{s[3]}} & a3) | 
              ({k{s[2]}} & a2) | 
              ({k{s[1]}} & a1) |
              ({k{s[0]}} & a0) ;
endmodule // Mux4

`define OP_ADD 3'b001
`define OP_SUB 3'b010
`define OP_MUL 3'b011
`define OP_AND 3'b100
`define OP_OR  3'b101
`define OP_NOT 3'b110
`define OP_XOR 3'b111

module ALU(clk, clear, input1, input2, opcode, has_last_res, out);
  parameter w = 8;
  input clk, clear;
  input [w-1:0] input1, input2;
  input [2:0] opcode;
  output [w-1:0] out;
  output has_last_res;
  wire [w-1:0] next, last_res, use_input1, use_input2, use_input3;
  wire did_op;
  
  DFF1 #(1) state1(clk, ~clear, did_op);
  DFF1 #(1) state2(clk, (did_op & ~clear), has_last_res);
  
  DFF8 #(w) last_output(clk, next, last_res);
  
  Mux2 which_input(last_res, input2, {has_last_res, ~has_last_res}, use_input2);
  Mux2 which_input_2(last_res, input1, {has_last_res, ~has_last_res}, use_input1);
  Mux2 which_input_3(input1, input2, {has_last_res, ~has_last_res}, use_input3);
  wire [7:0] add_val = input1 + use_input2;
  wire [7:0] sub_val = use_input1 - use_input3; //(has_last_res ? last_res - input1 : input1 - input2);
  wire signed [15:0] product = input1 * use_input2;
  wire [w-1:0] and_val = input1 & use_input2;
  wire [w-1:0] or_val = input1 | use_input2;
  wire [w-1:0] xor_val = input1 ^ use_input2;
  wire [w-1:0] not_val = ~use_input1;
  
  Mux8 choice(add_val, sub_val, product[7:0], and_val, or_val, xor_val, not_val, 8'b00000000, // Truncates overflow of product
	{(opcode == `OP_ADD) & ~clear,
	 (opcode == `OP_SUB) & ~clear,
	 (opcode == `OP_MUL) & ~clear,
	 (opcode == `OP_AND) & ~clear,
	 (opcode == `OP_OR)  & ~clear,
	 (opcode == `OP_XOR) & ~clear,
	 (opcode == `OP_NOT) & ~clear,
	 clear}, next);

  assign out = next;

endmodule

module TestBench;
  reg clk, clear;
  parameter n=8;
  reg [n-1:0] input1, input2;
  reg [2:0] opcode;
  wire [n-1:0] out;
  wire has_last_res;
  
  
 ALU alu(clk, clear, input1, input2, opcode, has_last_res, out);


  initial begin
    clk = 1 ; #5 clk = 0 ;
	    $display("Clock|Clear|Input1        |Input2        |OpCode   |OUT           |State");
	    $display("-----+-----+--------------+--------------+---------+--------------+-------------");
    forever
      begin
	    $display("%b    |%b    |%b (%d)|%b (%d)|%b (%s)|%b (%d)|%s", clk, clear, input1, input1, input2, input2, opcode, (opcode==3'b001 ?"Add":(opcode==3'b010 ?"Sub":(opcode==3'b011 ?"Mul":(opcode==3'b100 ?"And":(opcode==3'b101 ?"Or ":(opcode==3'b110 ?"Not":(opcode==3'b111 ?"Xor":"Nil"))))))), out, out, (has_last_res&~clear?"Use Last Result":"First Operation"));
        #5 clk = 1;

		#5 clk = 0;
      end
    end

  // input stimuli
  initial begin
         clear=0;input1=8'b00000000;input2=8'b00000000;opcode=`OP_ADD;
	#0
    #10  clear=1;input1=8'b00000000;input2=8'b00000000;opcode=`OP_ADD;
    #10  clear=0;input1=8'b00000001;input2=8'b00000001;opcode=`OP_ADD;
	#10  clear=0;input1=8'b00000001;input2=8'b00000000;opcode=`OP_ADD;
	#50  
	#10  clear=1;input1=8'b00000000;input2=8'b00000000;opcode=`OP_SUB;
    #10  clear=0;input1=8'b00001111;input2=8'b00000001;opcode=`OP_SUB;
	#10  clear=0;input1=8'b00000001;input2=8'b00000000;opcode=`OP_SUB;
	#50  
	#10  clear=1;input1=8'b00000000;input2=8'b00000000;opcode=`OP_MUL;
    #10  clear=0;input1=8'b00000010;input2=8'b00000010;opcode=`OP_MUL;
	#10  clear=0;input1=8'b00000010;input2=8'b00000000;opcode=`OP_MUL;
	#50  
	#10  clear=1;input1=8'b00000000;input2=8'b00000000;opcode=`OP_AND;
    #10  clear=0;input1=8'b11111111;input2=8'b01111110;opcode=`OP_AND;
	#10  clear=0;input1=8'b00111100;input2=8'b00000000;opcode=`OP_AND;
	#10  clear=0;input1=8'b00011000;input2=8'b00000000;opcode=`OP_AND;
	#10  clear=0;input1=8'b00000000;input2=8'b00000000;opcode=`OP_AND;
	
	#10  clear=1;input1=8'b00000000;input2=8'b00000000;opcode=`OP_OR;
    #10  clear=0;input1=8'b10000000;input2=8'b00000001;opcode=`OP_OR;
	#10  clear=0;input1=8'b01000000;input2=8'b00000000;opcode=`OP_OR;
	#10  clear=0;input1=8'b00000010;input2=8'b00000000;opcode=`OP_OR;
	#10  clear=0;input1=8'b00100000;input2=8'b00000000;opcode=`OP_OR;
	#10  clear=0;input1=8'b00000100;input2=8'b00000000;opcode=`OP_OR;
	#10  clear=0;input1=8'b00010000;input2=8'b00000000;opcode=`OP_OR;
	#10  clear=0;input1=8'b00001000;input2=8'b00000000;opcode=`OP_OR;
	
	#10  clear=1;input1=8'b00000000;input2=8'b00000000;opcode=`OP_XOR;
    #10  clear=0;input1=8'b11000000;input2=8'b11110000;opcode=`OP_XOR;
	#10  clear=0;input1=8'b00111100;input2=8'b00000000;opcode=`OP_XOR;
	#10  clear=0;input1=8'b00001111;input2=8'b00000000;opcode=`OP_XOR;
	#10  clear=0;input1=8'b00000011;input2=8'b00000000;opcode=`OP_XOR;
	
	#10  clear=1;input1=8'b00000000;input2=8'b00000000;opcode=`OP_NOT;
	#10  clear=0;input1=8'b00001111;input2=8'b00000000;opcode=`OP_NOT;
	#10  clear=0;input1=8'b00000000;input2=8'b00000000;opcode=`OP_NOT;
	#30
	
    $stop ;
  end
endmodule
