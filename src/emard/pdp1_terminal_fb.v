/* Terminal frame buffer, contains 64 x 32 characters which correspond to letters on teletype emulator screen */
module pdp1_terminal_fb
(
  input clock,
  input [7:0] data,
  input [10:0] rdaddress,
  input [10:0] wraddress,
  output reg [7:0] q
);
  reg [7:0] framebuffer[0:2047];
  always @(posedge clock)
  begin
    q <= framebuffer[rdaddress];
    // q <= rdaddress[3:1];
    framebuffer[wraddress] <= data;
  end
endmodule
