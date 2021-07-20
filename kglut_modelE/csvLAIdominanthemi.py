# Takes the dominant hemisphere for lai values for each pft and each biome, else leaving values alone
# AUTHOR - James Lui
# Contact - james.lui@nasa.gov

import numpy as np

LAI_in = "@@LAI_CSV_FILE_RAW"

outdir = "@@OUTDIR"
LAI_out = "@@LAI_CSV_FILE"

threshold = @@LAI_THRESHOLD_REPLACE

with open(LAI_in, 'r') as flin, open(outdir+LAI_out, 'w') as flout:
  # read 4 lines at a time
  while(True):
    try:
      nline = flin.readline()
      flin.readline() # ignore std
      sline = flin.readline()
      flin.readline() # ignore std
      
      if not ',' in nline:
        raise IOError
      narray = np.array(nline.split(',')[1:]).astype(np.float64)
      sarray = np.array(sline.split(',')[1:]).astype(np.float64)

      nsum = np.sum(narray)
      ssum = np.sum(sarray)

      if nsum > ssum:
        if nsum - ssum > threshold * nsum:
          sarray = np.roll(narray, 6)
          flout.write(nline)
          flout.write("{},{}\n".format(sline.split(',')[0],' '.join(np.array2string(sarray).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
          #print(nline, sline)
        else:
          flout.write(nline)
          flout.write(sline)
      elif ssum > nsum:
        if ssum - nsum > threshold * ssum:
          narray = np.roll(sarray, 6)
          flout.write("{},{}\n".format(nline.split(',')[0],' '.join(np.array2string(narray).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
          flout.write(sline)
          #print(nline, sline)
        else:
          flout.write(nline)
          flout.write(sline)
      else: # they are the same, or all zeros
        flout.write(nline)
        flout.write(sline)
    except IOError:
      break

print("Thresholded lai values")
