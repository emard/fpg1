/* Pixel ring buffer is a linear feedback shift register, 8k of memory with 8 taps. 
   It is used to store pixels visible on the type 30 CRT, as well as their current intensity  */
module pixel_ring_buffer
(
  input clock,
  input [31:0] shiftin,
  output [31:0] shiftout,
  output [255:0] taps
);
  // TODO this is just placeholder, code is missing
intentional_syntax_error;
   
  /*
   altshift_taps  ALTSHIFT_TAPS_component (
            .clock (clock),
            .shiftin (shiftin),
            .shiftout (sub_wire0),
            .taps (sub_wire1)
            // synopsys translate_off
            ,
            .aclr (),
            .clken (),
            .sclr ()
            // synopsys translate_on
            );
   defparam
      ALTSHIFT_TAPS_component.intended_device_family = "Cyclone V",
      ALTSHIFT_TAPS_component.lpm_hint = "RAM_BLOCK_TYPE=M10K",
      ALTSHIFT_TAPS_component.lpm_type = "altshift_taps",
      ALTSHIFT_TAPS_component.number_of_taps = 8,
      ALTSHIFT_TAPS_component.tap_distance = 1024,
      ALTSHIFT_TAPS_component.width = 32;
  */
endmodule
