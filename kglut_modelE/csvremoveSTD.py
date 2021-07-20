# Simple script to remove std values from csv files - James Lui

laimax_in = "@@LAIMAX_CSV_FILE_RAW"
height_in = "@@HEIGHT_CSV_FILE_RAW"

outdir = "@@OUTDIR"
laimax_out = "@@LAIMAX_CSV_FILE"
height_out = "@@HEIGHT_CSV_FILE"

with open(laimax_in, 'r') as flmin, open(height_in, 'r') as fhin, open(outdir+laimax_out, 'w') as flmout, open(outdir+height_out, 'w') as fhout:
  flmout.write(flmin.readline())
  fhout.write(fhin.readline())

  while(True):
    lmline = flmin.readline()
    hline = fhin.readline()
    if 'VAL' in lmline:
      flmout.write(lmline)
      fhout.write(hline)
    elif 'STD' in lmline:
      continue
    else:
      break
print("Removed standard deviations from height and laimax")
