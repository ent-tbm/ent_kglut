# Takes the dominant hemisphere for lai values for each pft and each biome, else leaving values alone
# 2024/02 - update to take weighted average as well
# AUTHOR - James Lui
# Contact - james.lui@nasa.gov

import numpy as np

LAI_in = "@@LAI_CSV_FILE_RAW"
samples_in = "@@SAMPLES_CSV_FILE"

outdir = "@@OUTDIR"
LAI_out = "@@LAI_CSV_FILE"

threshold = @@LAI_THRESHOLD_REPLACE

with open(LAI_in, 'r') as flin, open(outdir+LAI_out, 'w') as flout, open(samples_in, 'r') as fsamples:
  while(True):
    try:
      # read 4 lines at a time
      nline = flin.readline()
      flin.readline() # ignore std
      sline = flin.readline()
      flin.readline() # ignore std

      nweightline = fsamples.readline()
      sweightline = fsamples.readline()
      
      if not ',' in nline:
        raise IOError
      if not ',' in nweightline:
        raise IOError
    except IOError:
      break
    narray = np.array(nline.split(',')[1:]).astype(np.float64)
    sarray = np.array(sline.split(',')[1:]).astype(np.float64)

    if (threshold < 0): # take weighted average of N and S hemispheres
      nweight = float(nweightline.split(',')[-2])
      sweight = float(sweightline.split(',')[-2])

      if (nweight + sweight) == 0:
        flout.write(nline)
        flout.write(sline)
        continue

      rarray = np.zeros(12)

      sarray = np.roll(sarray, 6)

      for i in range(12):
        rarray[i] = (narray[i] * nweight + sarray[i] * sweight) / (nweight + sweight)
        
      narray = rarray
      sarray = np.roll(rarray, 6)
      flout.write("{},{}\n".format(nline.split(',')[0],' '.join(np.array2string(narray).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
      flout.write("{},{}\n".format(sline.split(',')[0],' '.join(np.array2string(sarray).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))

    else:
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

print("Thresholded lai values")
