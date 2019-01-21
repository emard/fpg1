/* Rowbuffer holds next 8 lines of pixels which should be drawn on the screen, 
   storing pixels extracted from ring buffers */
module pdp1_vga_rowbuffer (
  input clock,
  input [7:0] data,
  input [12:0] rdaddress,
  input [12:0] wraddress,
  input wren,
  output reg [7:0] q
);
  reg [7:0] rowbuffer[0:8191];
  always @(posedge clock)
  begin
    q <= rowbuffer[rdaddress];
    if(wren)
      rowbuffer[wraddress] <= data;
  end
endmodule
