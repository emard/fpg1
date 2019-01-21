#!/usr/bin/env python3

import sys
import os.path
# import parse

fin = open(sys.argv[1], 'r')
fout = open(sys.argv[2], 'w')

begin = 0
for line in fin:
  # strip whitespace
  line = line.strip();
  if line == "BEGIN":
    begin = 1
  if begin:
    # print(line)
    spl = line.strip(";")
    spl = spl.split(":")
    if len(spl) > 1:
      binstr = spl[1].strip()
      binint = int(binstr, 2)
      fout.write("%04x\n" % binint)
  if line == "END;":
    break

fin.close()
fout.close()
