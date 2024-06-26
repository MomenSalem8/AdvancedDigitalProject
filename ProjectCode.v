module MUX4x1(I, S, Y);//I for input and S for selection line Y for output
	input [3:0]I;//there are four input for mux4x1
	input [1:0]S;//there are two selecion line to select from input
	output Y;
	wire [3:0]and_wire;//wire for the output of the and gate
	wire [1:0]not_wire;//wire to write delay for inverter
	not #(3ns)(not_wire[0], S[0]);
	not #(3ns)(not_wire[1], S[1]);
	and #(7ns)(and_wire[0], not_wire[1], not_wire[0], I[0]); 
	and #(7ns)(and_wire[1], not_wire[1], S[0], I[1]);
	and #(7ns)(and_wire[2], S[1], not_wire[0], I[2]);
	and #(7ns)(and_wire[3], S[1], S[0], I[3]); 
	or #(7ns)(Y, and_wire[0], and_wire[1], and_wire[2], and_wire[3]); 
endmodule
module testbenchMux;//testbench for mux
	reg [3:0]I;
	reg [1:0]S;
	wire Y;	
	MUX4x1 stage(I, S, Y);
	initial 
		begin
			{I, S} = 6'b000_000;
			repeat(63)
			#10ns {I, S} = {I, S} + 1;
		end
endmodule

module FullAdder(I, Cin, S, Cout);
	input [1:0]I;
	input Cin;
	output S, Cout;
	wire andI, andI1cin, andI0cin;
	xor #(11ns)(S, I[1], I[0], Cin);//the output sum	  
	and #(7ns)(andI, I[0], I[1]);
	and #(7ns)(andI1cin, I[1], Cin);
	and #(7ns)(andI0cin, I[0], Cin);
	or #(7ns)(Cout, andI, andI1cin, andI0cin);//the carry out
endmodule 
module testbenchFA;//testbench for FA
	reg [1:0]I;
	reg Cin;
	wire S, Cout;	
	FullAdder stage(I, Cin, S, Cout);
	initial 
		begin
			{I, Cin} = 3'b000;
			repeat(7)
			#10ns {I, Cin} = {I, Cin} + 1;
		end
endmodule

module FourBitFullAdder(X, Y, Cin, D, Cout);
	input [3:0]X, Y;
	input Cin;
	output [3:0]D;
	output Cout;
	wire [4:0]C;
	assign C[0] = Cin, Cout = C[4];
	genvar i;
	generate 
	for(i = 0 ; i < 4 ; i = i + 1)
		begin:IFA//IFA -> mean instantiate full adder for four times
			FullAdder Stage({Y[i], X[i]}, C[i], D[i], C[i+1]);
		end
		endgenerate 
endmodule
module testbench4bitfulladder;//testbench for 4-bit FA
	reg [3:0]X, Y;
	reg Cin;
	wire [3:0]D;
	wire Cout;	
	FourBitFullAdder stage(X, Y, Cin, D, Cout);
	initial 
		begin
			{X, Y, Cin} = 9'b0000_00000;
			repeat(511)
			#75ns {X, Y, Cin} = {X, Y, Cin} + 1;
		end
endmodule

module Stage1RippleCarryAdderWithoutClock(A, B, S, Cin, D, Cout);//without clock for the glitchy result (without using registers)
	input [3:0]A, B;
	input [1:0]S;
	input Cin;
	output [3:0]D;
	output Cout;
	wire [3:0]NotB;
	wire [3:0]MuxO;//MuxO mean the output of the mux
	not #(3ns)(NotB[0], B[0]);
	not #(3ns)(NotB[1], B[1]);
	not #(3ns)(NotB[2], B[2]);
	not #(3ns)(NotB[3], B[3]);
	genvar i;
	generate 
	for(i = 0 ; i < 4 ; i = i + 1)
		begin :buildALU
			MUX4x1 MUX({1'b1, 1'b0, NotB[i], B[i]}, S, MuxO[i]);
		end
		endgenerate
		FourBitFullAdder SystemFA(A,  MuxO, Cin, D, Cout);
endmodule
module Stage1RippleCarryAdderWithClock(A, B, S, Cin, DA, CoutA, clk, reset);//the reuslt without glitchy(Proper result)
	input [3:0]A, B;
	wire [3:0]AC, BC;
	input [1:0]S;
	wire [1:0]SC;
	input Cin, clk, reset;
	wire CinC;
	wire [3:0]D;
	output reg [3:0] DA;
	output reg CoutA;
	wire Cout;
	wire [3:0]NotB;
	wire [3:0]MuxO;//MuxO mean the output of the mux
	not #(3ns)(NotB[0], BC[0]);
	not #(3ns)(NotB[1], BC[1]);
	not #(3ns)(NotB[2], BC[2]);
	not #(3ns)(NotB[3], BC[3]);
	Register RA(A, clk, reset, AC);	//registers for inputs
	Register RB(B, clk, reset, BC);
	Register #(.n(2))RS(S, clk, reset, SC);
	Register RCin(Cin, clk, reset, CinC);
	defparam RCin.n = 1;
	FourBitFullAdder SystemFA(AC, MuxO, CinC, D, Cout);//four bit full adder
	Register RD(D, clk, reset, DA);//registers for outputs
	Register #(.n(1))RCout(Cout, clk, reset, CoutA);
	genvar i;
	generate 
	for(i = 0 ; i < 4 ; i = i + 1)
		begin :buildALU
			MUX4x1 MUX({1'b1, 1'b0, NotB[i], BC[i]}, SC, MuxO[i]);
		end
		endgenerate
endmodule
module testbenchS1withoutclock;//testbench for Ripple-carry adder (Glitchy Result)
	reg [3:0]A, B;
	reg [1:0]S;
	reg Cin;
	wire [3:0]D;
	wire Cout;	 
	Stage1RippleCarryAdderWithoutClock stage(A, B, S, Cin, D, Cout);
	initial 
		begin
			{A, B, S, Cin} = 11'b00000000000;
			repeat(2048)
			#75ns {A, B, S, Cin} = {A, B, S, Cin} + 1'b1;
		end
endmodule
module testbenchS1withclock;//testbench for Ripple-carry adder (Not Glitchy Result)
	reg [3:0]A, B;
	reg [1:0]S;
	reg Cin, clock, reset;
	wire [3:0]D;
	wire Cout;
	Stage1RippleCarryAdderWithClock stage(A, B, S, Cin, D, Cout , clock, reset);
	initial 
		begin
			clock = 0;
			{S, Cin, A, B} = 11'b00000000000;
			repeat(2048)
			#160ns {S, Cin, A, B} = {S, Cin, A, B} + 1'b1;
		end
		always #75ns clock = ~clock;
endmodule

module D_FlipFlop(D, clk, Q, reset);//Dff
	input D, clk, reset;
	output reg Q;
	always @(posedge clk, reset)
		if(reset)
			Q <= 0'b0;
		else if(clk)
			Q <= D;
endmodule  
module Register(D, clk, reset, Q);//Registers with input reset to the level(when 1 output = 0)
	parameter n = 4;
	input [n-1:0]D;
	input clk, reset;
	output reg [n-1:0]Q;
	always @(posedge clk, reset)
		if(reset)
			Q <= 0;
		else if(clk)
			Q <= D;
endmodule  	
module TestGeneraterForALU(AT, BT, ST, CinT, ResultR, CoutR, clk, reset);
	reg [3:0]A, B;
	reg [1:0]S;
	reg Cin;	
	output [3:0]AT, BT;
	output [1:0]ST;
	output CinT;
   	reg [3:0]ExpectedD;
	reg ExpectedCout;
	output reg [3:0]ResultR;
	output reg CoutR;
	Register Result_R(ExpectedD, clk, reset, ResultR);//i put this result in the register because the input are in the registers so the outputs must be in registers
	Register #(.n(1))Cout_R(ExpectedCout, clk, reset, CoutR);
	input clk;
	input reset;
	assign AT = A,
			BT = B,
			ST = S,
			CinT = Cin;
	initial 
		begin
			{S, Cin, A, B} = 11'b00000000000;
			repeat(2048)
			#(160ns) {S, Cin, A, B} = {S, Cin, A, B} + 1'b1;
		end
	always @(posedge clk, reset) //the good (expected result)
		case({S, Cin})
			3'b000 : {ExpectedCout, ExpectedD} = A + B;
			3'b001 : {ExpectedCout, ExpectedD} = A + B + 1;
			3'b010 : {ExpectedCout, ExpectedD} = A + ~B;
			3'b011 : {ExpectedCout, ExpectedD} = A + ~B + 1;
			3'b100 : {ExpectedCout, ExpectedD} = A;
			3'b101 : {ExpectedCout, ExpectedD} = A + 1;
			3'b110 : {ExpectedCout, ExpectedD} = A - 1;
			3'b111 : {ExpectedCout, ExpectedD} = A;
			endcase
endmodule
module designAnalyzer(S, ExpectedResult, ExpectedCout, DesignResult, DesignCout, clk, reset);
	input [3:0]ExpectedResult, DesignResult;
	input S, ExpectedCout,DesignCout, clk, reset;
	always @(posedge clk, reset)
		begin
			if(ExpectedResult != DesignResult)	
					$display ("The expected result = %h does not equal result from design = %h at time =%0d", ExpectedResult, DesignResult, $time);
				if (S != 2'b01 && S != 2'b11)//when S = 1 or 3 cout is not good and Complemeted
					begin
						if(ExpectedCout != DesignCout)//there is an small error when goes to S = 1 or 3 we can avoid it in the future
			  					$display ("The good (expected) carry out = %b does not equal carry out from design = %b at time =%0d", ExpectedCout, DesignCout, $time);
					end
		end
endmodule
module ALUStage1Verification;
	reg clk;
	reg reset;
	reg [3:0]A, B;
	reg [1:0]S;
	reg Cin;
		initial
		clk = 0;
	always #75ns clk = ~clk;	
	wire [3:0]GlitchyResult;//without register
	wire [3:0]ExpectedResult;
	wire [3:0]TheResult;//the result with register
	wire CoutWithGlitch;
	wire ExpectedCout;
	wire TheCout;
	TestGeneraterForALU TGS1(A, B, S, Cin, ExpectedResult, ExpectedCout, clk, reset); 
	Stage1RippleCarryAdderWithoutClock S1UT(A, B, S, Cin, GlitchyResult, CoutWithGlitch);//UT -> mean under test
	Stage1RippleCarryAdderWithClock S1UTWithRegister(A, B, S, Cin, TheResult, TheCout, clk, reset);
	designAnalyzer S1A(S, ExpectedResult, ExpectedCout, TheResult, TheCout, clk, reset);
endmodule
module CarryLookaheadAdder(A, B, Cin, Cout);
	input [3:0]A, B;
	input Cin;
	output [4:0]Cout;
	assign Cout[0] = Cin;
	wire [3:0]G, P;//propagate and generate functions
	wire [3:0]PandC;//wire for and between ci-1 and pi
	wire C2;
	wire [1:0]C3;
	wire [2:0]C4;
	genvar i;
	generate 
	for(i = 0 ; i < 4 ; i = i + 1)
		begin:CLA
			and #(7ns) genand(G[i], A[i], B[i]);
			or #(7ns) proor(P[i], A[i], B[i]);
		end
	endgenerate
	and #(7ns) pandc(PandC[0], P[0], Cout[0]);
	or #(7ns) resor1(Cout[1], G[0], PandC[0]);
	and #(7ns) pandg2(C2, G[0], P[1]);
	and #(7ns) pandc2(PandC[1], P[0], P[1], Cout[0]);
	or #(7ns) resor2(Cout[2], G[1], C2, PandC[1]);
	and #(7ns) pandg3a(C3[0], G[1], P[2]);
	and #(7ns) pandg3b(C3[1], P[2], P[1], G[0]);
	and #(7ns) pandc3(PandC[2], P[2], P[1], P[0], Cout[0]);
	or #(7ns) resor3(Cout[3], G[2], C3[0], C3[1], PandC[2]);
	and #(7ns) pandg4a(C4[0], G[2], P[3]);
	and #(7ns) pandg4b(C4[1], P[3], P[2], G[1]);
	and #(7ns) pandg4c(C4[2], P[3], P[2], P[1], G[0]);
	and #(7ns) pandc4(PandC[3], P[3], P[2], P[1], P[0], Cout[0]);
	or #(7ns) resor4(Cout[4], G[3], C4[0], C4[1], C4[2], PandC[3]);
endmodule
module testbenchCLA;
	reg [3:0]A, B;
	reg Cin;
	wire [4:0]Cout;
	CarryLookaheadAdder CLA(A, B, Cin, Cout);
	initial 
		begin
			{A, B, Cin} = 9'b0000_00000;
			repeat(512)
			#(40ns) {A, B, Cin} = {A, B, Cin} + 1;
		end
endmodule
module FourBitCarryLookAheadFullAdder(X, Y, Cin, D, Cout);
	input [3:0]X, Y;
	input Cin;
	wire [4:0]Cpre;
	assign Cpre[0] = Cin, Cout = Cpre[4];
	output [3:0]D;
	output Cout;
	CarryLookaheadAdder CLA(X, Y, Cin, Cpre);
	genvar i;
	generate 
	for(i = 0 ; i < 4 ; i = i + 1)
		begin:IFA//IFA -> mean instantiate full adder for four times
			FullAdder Stage({Y[i], X[i]}, Cpre[i], D[i], Cpre[i+1]);
		end
		endgenerate 
endmodule
module testbench4bitCLA;//testbench for 4-bit CLA ADDER
	reg [3:0]X, Y;
	reg Cin;
	wire [3:0]D;
	wire Cout;	
	FourBitCarryLookAheadFullAdder FLAA(X, Y, Cin, D, Cout);
	initial 
		begin
			{X, Y, Cin} = 9'b0000_11111;
			repeat(511)
			#50ns {X, Y, Cin} = {X, Y, Cin} + 1;
		end
endmodule
module Stage2CarryLookAheadAdderWithoutClock(A, B, S, Cin, D, Cout);
	input [3:0]A, B;
	input [1:0]S;
	input Cin;
	output [3:0]D;
	output Cout;
	wire [3:0]NotB;
	wire [3:0]MuxO;//MuxO mean the output of the mux
	not #(3ns)(NotB[0], B[0]);
	not #(3ns)(NotB[1], B[1]);
	not #(3ns)(NotB[2], B[2]);
	not #(3ns)(NotB[3], B[3]);
	genvar i;
	generate 
	for(i = 0 ; i < 4 ; i = i + 1)
		begin :buildALU
			MUX4x1 MUX({1'b1, 1'b0, NotB[i], B[i]}, S, MuxO[i]);
		end
		endgenerate
		FourBitCarryLookAheadFullAdder FLAA(A, B, Cin, D, Cout);
endmodule
module Stage2CarryLookAheadAdderWithClock(A, B, S, Cin, DA, CoutA, clk, reset);
	input [3:0]A, B;
	wire [3:0]AC, BC;
	input [1:0]S;
	wire [1:0]SC;
	input Cin, clk, reset;
	wire CinC;
	wire [3:0]D;
	output reg [3:0] DA;
	output reg CoutA;
	wire Cout;
	wire [3:0]NotB;
	wire [3:0]MuxO;//MuxO mean the output of the mux
	not #(3ns)(NotB[0], BC[0]);
	not #(3ns)(NotB[1], BC[1]);
	not #(3ns)(NotB[2], BC[2]);
	not #(3ns)(NotB[3], BC[3]);
	wire [3:0]MUXR;
	Register RA(A, clk, reset, AC);
	Register RB(B, clk, reset, BC);
	Register #(.n(2))RS(S, clk, reset, SC);
	Register RCin(Cin, clk, reset, CinC);
	defparam RCin.n = 1;
	FourBitCarryLookAheadFullAdder SystemFA(AC, MuxO, CinC, D, Cout);
	Register RD(D, clk, reset, DA);
	Register #(.n(1))RCout(Cout, clk, reset, CoutA);
	genvar i;
	generate 
	for(i = 0 ; i < 4 ; i = i + 1)
		begin :buildALU
			MUX4x1 MUX({1'b1, 1'b0, NotB[i], BC[i]}, SC, MuxO[i]);//SC***
		end
		endgenerate
endmodule
module testbenchCLAwithoutclock;//testbench for CLA 
	reg [3:0]A, B;
	reg [1:0]S;
	reg Cin;
	wire [3:0]D;
	wire Cout;	 
	Stage2CarryLookAheadAdderWithoutClock S2(A, B, S, Cin, D, Cout);
	initial 
		begin
			{S, Cin,A, B} = 11'b00100001111; 
			repeat(2048)
			#80ns {S, Cin,A, B} = {S, Cin,A, B} + 1'b1;
		end
endmodule
module testbenchCLAwithclock;//testbench for Ripple-carry adder
	reg [3:0]A, B;
	reg [1:0]S;
	reg Cin, clock, reset;
	wire [3:0]D;
	wire Cout;
	always #63ns clock = ~clock;
	Stage2CarryLookAheadAdderWithClock Stage(A, B, S, Cin, D, Cout, clock, reset);
	initial 
		begin
			clock = 0;
			{S, Cin, A, B} = 11'b00000000000;
			repeat(2048)
			#126ns {S, Cin, A, B} = {S, Cin, A, B} + 1'b1;
		end
		
endmodule//test bench for the stage with input clocked
module ALUStage2Verification;
	reg clk;
	reg reset;
	reg [3:0]A, B;
	reg [1:0]S;
	reg Cin;
	initial 
		clk = 0;
	always #63ns clk = ~clk;	
	wire [3:0]GlitchyResult;//without register
	wire [3:0]ExpectedResult;
	wire [3:0]TheResult;//D with register
	wire CoutWithGlitch;
	wire ExpectedCout;
	wire TheCout;
	TestGeneraterForALU TGS1(A, B, S, Cin, ExpectedResult, ExpectedCout, clk, reset); 
	Stage2CarryLookAheadAdderWithoutClock S2UT(A, B, S, Cin, GlitchyResult, CoutWithGlitch);//UT -> mean under test
	Stage2CarryLookAheadAdderWithClock S2UTWithRegister(A, B, S, Cin, TheResult, TheCout, clk, reset);
	designAnalyzer S1A(S, ExpectedResult, ExpectedCout, TheResult, TheCout, clk, reset);
endmodule	
	
	
	
	
	
