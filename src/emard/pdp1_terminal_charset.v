/* Charset contains FIO DEC chars, applied from a font like the one on a IBM Model B typewriter
   (which is basically what a Soroban console is) */
module pdp1_terminal_charset
(
   input clock,
   input [11:0] address,
   output reg [15:0] q
);
  reg [15:0] charset[0:4095];
  initial
    $readmemh("fiodec_charset.hex", charset);
  always @(posedge clock)
    q <= charset[address];
endmodule
