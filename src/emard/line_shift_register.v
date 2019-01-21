] intentional # syntax # error [

/* 1,6k of memory which holds a single line of pixels. Three of these are instantiated
   and chained together with 3 additional registers per line, so a 3x3 matrix is formed and
   various kernels can be applied (blur) */

module line_shift_register
(
  input clock,
  input [7:0] shiftin,
  output [7:0] shiftout,
  output [7:0] taps
);
  // TODO this is just placeholder, code is missing

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
      ALTSHIFT_TAPS_component.number_of_taps = 1,
      
      ALTSHIFT_TAPS_component.tap_distance = 1685, 
      ALTSHIFT_TAPS_component.width = 8;
  */

      /* component.tap_distance = 1685
         Not 1688 (the number of clock cycles in 1280 x 1024 @ 60 Hz row) 
         because 3 explicitly defined registers are used in the chain as well, 
         adding up to 1685 + 3 = 1688 */

endmodule
