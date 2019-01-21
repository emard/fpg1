//============================================================================
//  PDP1 emulator for MiSTer
//  Copyright (c) 2018 Hrvoje Cavrak
//  Based on Defender by Sorgelig (c) 2017
//
//  This program is free software; you can redistribute it and/or modify it
//  under the terms of the GNU General Public License as published by the Free
//  Software Foundation; either version 2 of the License, or (at your option)
//  any later version.
//
//  This program is distributed in the hope that it will be useful, but WITHOUT
//  ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or
//  FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for
//  more details.
//
//  You should have received a copy of the GNU General Public License along
//  with this program; if not, write to the Free Software Foundation, Inc.,
//  51 Franklin Street, Fifth Floor, Boston, MA 02110-1301 USA.
//============================================================================

`include "../definitions.v"

module emu
(   
   input             CLK_CPU,                /* CPU clock 50 MHz */
   input             CLK_PIXEL,              /* VGA Pixel clock, 75 MHz or 108 MHz */
   input             RESET,                  /* Reset signal from top module */

   output            VGA_CLK,                /* Base video clock = CLK_PIXEL */
   output            VGA_CE,                 /* If pixel clock equals to CLK_VIDEO, this should be fixed to 1 */
   output  reg [7:0] VGA_R,
   output  reg [7:0] VGA_G,
   output  reg [7:0] VGA_B,
   output  reg       VGA_HS,
   output  reg       VGA_VS,
   output  reg       VGA_DE,                 /* = ~(VBlank | HBlank) */

   output            LED_USER,
   output      [1:0] LED_POWER,
   output      [1:0] LED_DISK
);

/*
`include "build_id.v" 
localparam CONF_STR = {
   "PDP1;;",
   "-;",
   "F,PDPRIMBIN;",
   "T5,Enable RIM mode;",
   "T6,Disable RIM mode;", 
   "-;",
   "R7,Reset;",
   "-;",
   "O1,Aspect Ratio,Original,Wide;",
   "O4,Hardware multiply,No,Yes;",
   "-;",
   "O8,Var. brightness,Yes,No;",  
   "O9,CRT wait,No,Yes;",
   "-;", 
   "J,Left,Right,Thrust,Fire,HyperSpace;",
   "V,v1.00.",`BUILD_DATE
};
*(

////////////////////   CLOCKS   ///////////////////

pll pll (
   .refclk(CLK_50M),
   .rst(0),
   .outclk_0(CLK_PIXEL),
   .locked(pll_locked)
);

////////////////////  WIRES  //////////////////////

wire [31:0] status, BUS_out;                                         /* Signal carries menu settings, BUS_out cpu signals to console */
wire  [1:0] current_output_device;                                   /* Currently selected output device */

wire        kbd_read_strobe, console_switch_strobe;                  /* These signal when a key was pressed */

wire        ioctl_download, ioctl_wr, send_next_tape_char;           /* Tape (file download) ioctl interface */
wire [24:0] ioctl_addr;
wire  [7:0] ioctl_dout, ioctl_index;

wire [10:0] ps2_key, console_switches;                               /* Pressed key on keyboard, pressed switches on console */
wire  [5:0] sense_switches;

wire [15:0] joystick_0, joystick_1;                                  /* Pressed keys on joysticks */

wire  [6:0] char_output_w, kbd_char_out;                             /* Pressed keys to typewriter VGA out */
wire        char_strobe_w, halt_w, key_was_processed_w;              /* Strobe / ACK signalling of pressed keys */
                        
wire [17:0] test_word, test_address, AC_out, IO_out, DI_out;         /* Provide signals for console */
wire [11:0] PC_out, AB_out;

wire  [7:0] r_crt, g_crt, b_crt,                                     /* Per-device RGB signals, for CRT, Teletype and Console emulation */
            r_tty, g_tty, b_tty, 
            r_con, g_con, b_con;

wire  [5:0] selected_ptr_x;                                          /* Cursor coordinates for toggling console test switches */
wire  [4:0] selected_ptr_y;

wire        hw_mul_enabled = 1'b0;                                   /* Is hardware multiplication enabled from menu ? */

wire [17:0] data_out;                                                /* Data bus, CPU to RAM */
wire        ram_write_enable;                                        /* When set, writes to main RAM memory */

wire [9:0]  pixel_x_addr_wire, pixel_y_addr_wire;                    /* Lines connecting the CPU and Type 30 CRT */
wire [2:0]  pixel_brightness_wire;
wire        pixel_shift_wire;

wire [7:0]  joystick_emu;                                            /* Output from keyboard module to feed in as spacewar controls */

//////////////////  REGISTERS  ////////////////////

reg        old_state, old_download, old_key_was_processed;           /* Used to detect a rising edge */
reg        ioctl_wait = 0;                                           /* When 1, signal through HPS bus that we are not ready to receive more data */

reg        current_case;                                             /* 0 = lowercase currently active, 1 = uppercase active */
reg  [1:0] current_output;                                           /* What device video output is active? Can be CRT, Typewriter or Console */
reg  [0:0] cpu_running = 1'b1;                                       /* If set to 0, cpu is paused */

reg [11:0] write_address = 12'd0;                                    /* Addresses for writing to memory and start jump location after loading a program in RIM mode or RESET */
reg [11:0] start_address = 12'd4;

reg [17:0] tape_rcv_word;                                            /* tape_rcv_word used to store received binary word from tape */
wire       io_word;                                                  /* io_word used to provide spacewar gamepad controls */
           
reg        write_enable, rim_mode_enabled;                           /* Enables writing to memory or activating the read in mode (i.e. something like a paper tape bootloader) */

reg [35:0] tape_read_buffer = 36'b0;                                 /* Buffer for storing lines received from paper tape */
reg [31:0] timeout = 0;                                              /* Timeout provides a control mechanism to abort a "stuck" paper tape download */
reg [10:0] horizontal_counter, vertical_counter;                     /* Position counters used for generating the video signal, common to all three video output modules */


/////////////////  ASSIGNMENTS  ///////////////////

assign LED_USER = key_was_processed_w;

assign VGA_CLK  = CLK_PIXEL;
assign VGA_CE   = 1'b1;

/* Convert joystick / keyboard commands into PDP1 spacewar IO register 18-bit word */
assign io_word = {joystick_0[1] | joystick_emu[1] | joystick_0[`joystick_left]   | joystick_0[`joystick_hyperspace],       /* Hyperspace is triggered when both left */
                  joystick_0[0] | joystick_emu[3] | joystick_0[`joystick_right]  | joystick_0[`joystick_hyperspace],       /* and right are pressed simultaneously.  */
                  joystick_0[2] | joystick_emu[2] | joystick_0[`joystick_thrust], 
                  joystick_0[3] | joystick_emu[0] | joystick_0[`joystick_fire],
                      
                  {10{1'b0}}, 
                      
                  joystick_1[1] | joystick_emu[5] | joystick_1[`joystick_left]   | joystick_1[`joystick_hyperspace], 
                  joystick_1[0] | joystick_emu[7] | joystick_1[`joystick_right]  | joystick_1[`joystick_hyperspace],
                  joystick_1[2] | joystick_emu[6] | joystick_1[`joystick_thrust],  
                  joystick_1[3] | joystick_emu[4] | joystick_1[`joystick_fire]
               };
               
///////////////////  MODULES  /////////////////////

reg [24:0] typem;
wire [6:0] typed_char;
assign typed_char = typem[24:21];
always @(posedge CLK_PIXEL)
begin
  typem <= typem + 1;
end

assign kbd_char_out = typed_char;
assign kbd_read_strobe = typem[20];

assign char_output_w = typed_char;
assign char_strobe_w = 1'b0;

pdp1_vga_typewriter typewriter (
   .clk(CLK_PIXEL), 
   .horizontal_counter(horizontal_counter),
   .vertical_counter(vertical_counter),

   .red_out(r_tty),
   .green_out(g_tty), 
   .blue_out(b_tty),

   .char_in_kbd(kbd_char_out),
   .have_keyboard_data(kbd_read_strobe),

   .char_in_pdp(char_output_w),
   .have_typewriter_data(char_strobe_w)
);


////////////////  ALWAYS BLOCKS  //////////////////

always @(posedge CLK_CPU) begin
   if (`continue_button || `start_button)
      cpu_running <= 1'b1;
   
   if (`stop_button)
      cpu_running <= 1'b0;      
end

/* Video generation */
         
always @(posedge CLK_PIXEL) begin
/*
   case (current_output_device)
      `output_crt:      {VGA_R, VGA_G, VGA_B} <= {r_crt, g_crt, b_crt};
      `output_console:  {VGA_R, VGA_G, VGA_B} <= {r_con, g_con, b_con};    
      `output_teletype: {VGA_R, VGA_G, VGA_B} <= {r_tty, g_tty, b_tty};          
   endcase
*/
   {VGA_R, VGA_G, VGA_B} <= {r_tty, g_tty, b_tty};

   /* Common video routines for generating blanking and sync signals */

   VGA_HS <= ((horizontal_counter >= `h_front_porch )  && (horizontal_counter < `h_front_porch + `h_sync_pulse)) ? 1'b0 : 1'b1;
   VGA_VS <= ((vertical_counter   >= `v_front_porch )  && (vertical_counter   < `v_front_porch + `v_sync_pulse)) ? 1'b0 : 1'b1;
   
   VGA_DE <= ~((horizontal_counter < `h_visible_offset) | (vertical_counter < `v_visible_offset)); 
   
   horizontal_counter <= horizontal_counter + 1'b1;      

   if (horizontal_counter == `h_line_timing) 
   begin
       vertical_counter <= vertical_counter + 1'b1;                
       horizontal_counter <= 11'b0;
   end
   
   if (vertical_counter == `v_line_timing) 
       vertical_counter <= 11'b0;                  
end

endmodule
	