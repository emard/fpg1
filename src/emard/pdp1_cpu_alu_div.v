/* Divider used for hardware division instruction (cheating!!) */

module pdp1_cpu_alu_div (
   in_clock,
	denom,
	numer,
	quotient,
	remain);

	input in_clock;
	input	[16:0]  denom;
	input	[33:0]  numer;
	output	[33:0]  quotient;
	output	[16:0]  remain;

// TODO: this is just placeholder, code is missing
intentional_syntax_error;

	wire [33:0] sub_wire0;
	wire [16:0] sub_wire1;
	wire [33:0] quotient = sub_wire0[33:0];
	wire [16:0] remain = sub_wire1[16:0];
/*
	lpm_divide	LPM_DIVIDE_component (
				.denom (denom),
				.numer (numer),
				.quotient (sub_wire0),
				.remain (sub_wire1),
				.aclr (1'b0),
				.clken (1'b1),
				.clock (in_clock));
	defparam
		LPM_DIVIDE_component.lpm_drepresentation = "UNSIGNED",
		LPM_DIVIDE_component.lpm_hint = "MAXIMIZE_SPEED=6,LPM_REMAINDERPOSITIVE=TRUE,LPM_PIPELINE=34",
		LPM_DIVIDE_component.lpm_nrepresentation = "UNSIGNED",
		LPM_DIVIDE_component.lpm_type = "LPM_DIVIDE",
		LPM_DIVIDE_component.lpm_widthd = 17,
		LPM_DIVIDE_component.lpm_widthn = 34;		
*/
endmodule
