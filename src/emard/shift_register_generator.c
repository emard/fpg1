// written by David Shah

string Platform_GetShiftTapSignals(string inst_name, int port_width,
                                   int line_width, int n_taps) {
  stringstream vhdl;
  if (xilinx_mode) {
    int ram_width = port_width * n_taps;

    int nloc = 2;
    int adsize = 1;
    for (adsize = 1; adsize < 32; adsize++) {
      if (nloc >= line_width) {
        break;
      }
      nloc *= 2;
    }

    vhdl << "\ttype " << inst_name << "_ram_t is array(" << (1 << adsize) - 1
         << " downto 0) of std_logic_vector(" << ram_width - 1 << " downto 0);"
         << endl;
    vhdl << "\tsignal " << inst_name << "_ram : " << inst_name << "_ram_t;"
         << endl;

    vhdl << "\tsignal " << inst_name << "_rdptr : unsigned(" << adsize - 1
         << " downto 0);" << endl;
    vhdl << "\tsignal " << inst_name << "_wrptr : unsigned(" << adsize - 1
         << " downto 0);" << endl;
    vhdl << "\tsignal " << inst_name << "_q : std_logic_vector("
         << ram_width - 1 << " downto 0);" << endl;
    for (int i = 0; i < n_taps; i++) {
      vhdl << "\tsignal " << inst_name << "_tap" << i << " : std_logic_vector("
           << port_width - 1 << " downto 0);" << endl;
    }
  }
  return vhdl.str();
}


string Platform_InstantiateShiftTapComponent(string inst_name, int port_width,
                                             int line_width, int n_taps,
                                             string clock_sig,
                                             string enable_sig, string din_sig,
                                             string base_type,
                                             vector<string> tap_sig) {
  stringstream vhdl;
  int nloc = 2;
  int adsize = 1;
  for (adsize = 1; adsize < 32; adsize++) {
    if (nloc >= line_width) {
      break;
    }
    nloc *= 2;
  }
  if (xilinx_mode) {
    vhdl << "\tprocess(" << clock_sig << ")" << endl;
    vhdl << "\tbegin" << endl;
    vhdl << "\t\tif rising_edge(" << clock_sig << ") then" << endl;
    vhdl << "\t\t\tif " << enable_sig << " = '1' then" << endl;
    vhdl << "\t\t\t\t" << inst_name << "_wrptr <= " << inst_name
         << "_wrptr + 1;" << endl;
    vhdl << "\t\t\t\t" << inst_name << "_ram(to_integer(" << inst_name
         << "_wrptr)) <= std_logic_vector(" << din_sig << ")";
    for (int t = 0; t < n_taps - 1; t++) {
      vhdl << " & " << inst_name << "_tap" << t;
    }
    vhdl << ";" << endl;
    vhdl << "\t\t\t\t" << inst_name << "_q <= " << inst_name
         << "_ram(to_integer(" << inst_name << "_rdptr));" << endl;
    vhdl << "\t\t\tend if;" << endl;
    vhdl << "\t\tend if;" << endl;
    vhdl << "\tend process;" << endl;
    vhdl << "\t" << inst_name << "_rdptr <= " << inst_name << "_wrptr - "
         << (line_width - 1) << ";" << endl;
    for (int t = 0; t < n_taps; t++) {
      vhdl << "\t" << inst_name << "_tap" << ((n_taps - 1) - t)
           << " <= " << inst_name << "_q(" << ((t + 1) * port_width - 1)
           << " downto " << (t * port_width) << ");" << endl;
      vhdl << "\t" << tap_sig[t] << " <= " << base_type << "(" << inst_name
           << "_tap" << t << ");" << endl;
    }

  } else {
    vhdl << "\t" << inst_name << " : altshift_taps" << endl;
    vhdl << "\t\tgeneric map(" << endl;
    vhdl << "\t\t\tnumber_of_taps => " << n_taps << ", " << endl;
    vhdl << "\t\t\ttap_distance => " << line_width << ", " << endl;
    vhdl << "\t\t\twidth => " << port_width << endl << "\t\t\t)" << endl;

    vhdl << "\t\tport map(" << endl;
    vhdl << "\t\t\tclock => " << clock_sig << ", " << endl;
    vhdl << "\t\t\tclken => " << enable_sig << ", " << endl;
    vhdl << "\t\t\tshiftin => std_logic_vector(" << din_sig << "), " << endl;

    for (int i = tap_sig.size() - 1; i >= 0; i--) {
      vhdl << "\t\t\t" << base_type << "(taps(" << (port_width * (i + 1) - 1)
           << " downto " << (port_width * i) << ")) => ";
      vhdl << tap_sig[i];
      if (i >= 1) {
        vhdl << ", ";
      }
      vhdl << endl;
    }
    vhdl << "\t\t\t);" << endl;
  }
  return vhdl.str();
}


