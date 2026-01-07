# Regresses Koeppen-Geiger biomes to LC LAI LAImax and HITEent values based on input files
# AUTHOR - James Lui
# email/contact - james.lui@nasa.gov

import numpy as np
import netCDF4 as nc
from datetime import datetime
from math import sqrt
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.colors as colors
import warnings
from scipy import stats, signal
warnings.filterwarnings('ignore', category=UserWarning)
warnings.filterwarnings('ignore', category=RuntimeWarning)




biomeIn_file = "@@BIOME" # biomeIn are the biomes corresponding to the source LAI LAImax height files, Koeppen-Geiger classification.
LAI_file = "@@LAI" # 12 month LAI values for the PFT cover types
LAImax_file = "@@LAIMAX" # LAI max values for the PFT cover types
HITEent_file = "@@HEIGHT" # this specific file has hgt_ added to the front of every pft name, remove the prefix below if not present
HITEprefix = "@@HGT"
LC_file = "@@LC" # cover fractions to use as weights for regression - some contamination of data can occur for values of LAI if another pft is dominant





regression_method = "@@REGRESSION" # regression method, weighted_average or kde
outNETCDF_format = "NETCDF3_CLASSIC" # see netcdf page for other formats

regressionlai = "@@LAI_CSV_FILE_RAW"
regressionlaimax = "@@LAIMAX_CSV_FILE_RAW"
regressionheight = "@@HEIGHT_CSV_FILE_RAW"
regressionlc = "@@LC_CSV_FILE_RAW"
regressionsamples = "@@SAMPLES_CSV_FILE" # tracks how many samples taken

indimensions = @@DIMENSIONS # input file dimensions, specify for biomeIn_file LAI_file LAImax_file HITEent_file LC_file
lat_in = @@LATDIM
lon_in = @@LONDIM

outdir = "@@OUTDIR"

default_biome = 31 
fillvalue = -1e+30

# Table to define decision tree for regression by KG biome type. Take samples instead of single grid for areas where possible. Indices to columns are:
# I grid cell = column 0, value of -1 means not specified
# J grid cell = column 1, value of -1 means not specified
isSouthernHemi = 2 # If the (I,J) coords are in the southern hemisphere or, if takeSample is true and hasBothHemi is false, if isSouthernHemi TRUE, take sample grids in southern hemisphere (SH) else in northern hemisphere (NH).
takeSample = 3 # Take a sample (weighted average over grid cells) instead of a single grid cell
ignoreHemiVariations = 4 # Use for tropical biomes, regression will not take sample seperately and will not shift for seasonality
hasBothHemi = 5 # If biome existis in both hemispheres

biome_coords = { # I J isSouthernHemi takeSample ignoreHemiVariations hasBothHemi (generic decision table)
    1 : [-1, -1, False, True, True, True],        #Af
    2 : [-1, -1, False, True, False, True],       #As
    3 : [-1, -1, False, True, False, True],       #Am
    4 : [-1, -1, False, True, False, True],       #Aw
    5 : [-1, -1, False, True, False, True],       #BWk
    6 : [-1, -1, False, True, False, True],       #BWh
    7 : [-1, -1, False, True, False, True],       #BSk
    8 : [-1, -1, False, True, False, True],       #BSh
    9 : [-1, -1, False, True, False, True],       #Csa
    10: [-1, -1, False, True, False, True],       #Csb
    11: [-1, -1, False, True, False, True],       #Csc
    12: None,                                     #Csd # This biome does not exist
    13: [-1, -1, False, True, False, True],       #Cwa
    14: [-1, -1, False, True, False, True],       #Cwb
    15: [-1, -1, False, True, False, True],       #Cwc
    16: None,                                     #Cwd # This biome does not exist
    17: [-1, -1, False, True, False, True],       #Cfa
    18: [-1, -1, False, True, False, True],       #Cfb
    19: [-1, -1, False, True, False, True],       #Cfc
    20: None,                                     #Cfd # This biome does not exist
    21: [-1, -1, False, True, False, True],       #Dsa
    22: [-1, -1, False, True, False, True],       #Dsb
    23: [-1, -1, False, True, False, True],       #Dsc
    24: [-1, -1, False, True, False, True],       #Dsd
    25: [-1, -1, False, True, False, True],       #Dwa
    26: [-1, -1, False, True, False, True],       #Dwb
    27: [-1, -1, False, True, False, True],       #Dwc
    28: [-1, -1, False, True, False, True],       #Dwd
    29: [-1, -1, False, True, False, True],       #Dfa
    30: [-1, -1, False, True, False, True],       #Dfb
    31: [-1, -1, False, True, False, True],       #Dfc
    32: [-1, -1, False, True, False, True],       #Dfd
    33: [-1, -1, False, True, False, True],       #EF
    34: [-1, -1, False, True, False, True],       #ET
    35: None,                                     #UA
    36: None,                                     #UAu
    37: None,                                     #UB
    38: None,                                     #UE
    39: None,                                     #Ufu
    40: None,                                     #Uuu
    }
biome_coords_144x90 = { # I90 J144 isSouthernHemi takeSample ignoreHemiVariations hasBothHemi (decision table based on 144x90 dataset)
    1 : [47, 45, False, True, False, True],     #Af
    2 : [50, 68, False, True, False, True],     #As
    3 : [46, 25, False, True, False, True],     #Am
    4 : [50, 71, False, True, False, True],     #Aw
    5 : [66, 114, False, True, False, True],    #BWk
    6 : [57, 73, False, True, False, True],     #BWh
    7 : [65, 27, False, True, False, True],     #BSk
    8 : [52, 80, False, True, False, True],     #BSh
    9 : [64, 70, False, True, False, False],    #Csa
    10: [67, 70, False, True, False, True],     #Csb
    11: [22, 44, True, False, False, False],    #Csc # few grid cells exist in 144x90 dataset
    12: None,                                   #Csd
    13: [57, 112, True, True, False, True],     #Cwa
    14: [59, 113, False, True, False, True],    #Cwb
    15: [34, 46, True, True, False, False],     #Cwc
    16: None,                                   #Cwd
    17: [61, 39, False, True, False, True],     #Cfa
    18: [71, 72, False, True, False, True],     #Cfb
    19: [72, 21, False, True, False, True],     #Cfc
    20: None,                                   #Cfd
    21: [65, 89, False, False, False, False],   #Dsa # few grid cells exist in 144x90 dataset
    22: [65, 90, False, True, False, False],    #Dsb
    23: [65, 101, False, True, False, False],   #Dsc
    24: None,                                   #Dsd # not present in 144x90 dataset
    25: [67, 122, False, True, False, False],   #Dwa
    26: [69, 125, False, True, False, False],   #Dwb
    27: [73, 123, False, True, False, False],   #Dwc
    28: [78, 127, False, True, False, False],   #Dwd
    29: [67, 36, False, True, False, False],    #Dfa
    30: [72, 93, False, True, False, False],    #Dfb
    31: [77, 113, False, True, False, False],   #Dfc
    32: [81, 117, False, True, False, False],   #Dfd
    33: [83, 55, False, True, False, False],    #EF
    34: [81, 34, False, True, False, True],     #ET
    35: None,                                   #UA
    36: None,                                   #UAu
    37: None,                                   #UB
    38: None,                                   #UE
    39: None,                                   #Ufu
    40: None,                                   #Uuu
    }

pftIgnore = 2
pfts = { # name longname ignore
    1 : ["ever_br_early", "1 - Evergeen Broadleaf Early Succ", False], #T
    2 : ["ever_br_late", "2 - Evergreen Broadleaf Late Succ", False],
    3 : ["ever_nd_early", "3 - Evergreen Needleleaf Early Succ", False], #T
    4 : ["ever_nd_late", "4 - Evergreen Needleleaf Late Succ", False],
    5 : ["cold_br_early", "5 - Cold Deciduous Broadleaf Early Succ", False], #T
    6 : ["cold_br_late", "6 - Cold Deciduous Broadleaf Late Succ", False],
    7 : ["drought_br", "7 - Drought Deciduous Broadleaf", False],
    8 : ["decid_nd", "8 - Deciduous Needleleaf", False],
    9 : ["cold_shrub", "9 - Cold Adapted Shrub", False],
    10: ["arid_shrub", "10 - Arid Adapted Shrub", False],
    11: ["c3_grass_per", "11 - C3 Grass Perennial", False],
    12: ["c4_grass", "12 - C4 Grass", False],
    13: ["c3_grass_ann", "13 - C3 Grass Annual", False],
    14: ["c3_grass_arct", "14 - Arctic C3 Grass", False],
    15: ["crops_herb", "15 - Crops Herb", False], #T
    16: ["crops_woody", "16 - Crops Woody", False], #T
    17: ["bare_bright", "17 - Bright Bare Soil", False], #T
    18: ["bare_dark", "18 - Dark Bare Soil", False] #T
    }

#-----------------------------------------------------------------------------------------------------------------
# don't edit the code below here unless you know what you're doing
#-----------------------------------------------------------------------------------------------------------------

dimlat, dimlon = indimensions

def weighted_average_std(values, weights):
  # returns weighted average and standard deviation (biased, should not matter here)
  average = np.average(values, weights=weights)
  variance = np.average((values-average)**2, weights=weights)
  return average, sqrt(variance)

# generates a gaussian probability density function to find the tallest peak and full-width at half maximum
def kde_mode_fwhm(values, weights, method='scott'):
  values = np.ma.masked_array(values, mask=weights == 0).compressed()
  weights = np.ma.masked_array(weights, mask=weights == 0).compressed()
  if (values.size <= 10): # KDE is probably not good for few sample points
    return weighted_average_std(values, weights)
  if (np.all(np.isclose(values, values[0]))): # will cause error if values are very close
    return weighted_average_std(values, weights)
  sample_distribution = np.linspace(min(values), max(values), min(max(values.size, 30), 300))
  density_values = stats.gaussian_kde(values, bw_method=method, weights=weights).evaluate(sample_distribution)
  peak_idxs, properties = signal.find_peaks(density_values)
  if (peak_idxs.size == 0): # no peaks found, default to weighted average
    return weighted_average_std(values, weights)
  fwhms = signal.peak_widths(density_values, peak_idxs, rel_height=0.5)
  fwhm_peak_idx = np.argmax(density_values[peak_idxs])
  max_peak_idx = peak_idxs[fwhm_peak_idx]
  mode = sample_distribution[max_peak_idx]
  fwhm = fwhms[0][fwhm_peak_idx] * (sample_distribution[1] - sample_distribution[0])
  #print(mode, fwhm)
  return mode, fwhm

#def kde_bandwidth(obj, fac=1.0):
#  return np.power(obj.n, -1./(obj.d+4)) * fac

def regress(values, weights, method='weighted_average'):
  if (method == 'weighted_average'):
    return weighted_average_std(values, weights)
  elif (method == 'kde' or method == 'kde_scott'):
    return kde_mode_fwhm(values, weights)
#  elif (method == 'kde_scott0.5'):
#    return kde_mode_fwhm(values, weights, method=partial(kde_bandwidth, fac=0.5))
  elif (method == 'kde_silverman'):
    return kde_mode_fwhm(values, weights, method='silverman')
  else:
    raise ValueError("Invalid method for regression {} selected".format(method))
    
def getCosWeight(start_lat, end_lat):
  if start_lat > 90:
    start_lat = 90
  if end_lat < -90:
    end_lat = -90
  
  start_lat -= 90.0
  end_lat -= 90.0
  
  start_lat = start_lat * np.pi/180
  end_lat = end_lat * np.pi/180

  return(np.cos(end_lat) - np.cos(start_lat))

def calculateWeights(lat_arr, lon_arr): # calculate weights for each gridcell, similar to axyp but units are arbitrary
  lenlon = len(lon_arr)
  lenlat = len(lat_arr)
  diffarr = np.diff(lat_arr)
  weights = np.zeros((lenlat, lenlon))

  lat_arr_edges = np.zeros(lenlat + 1)
  lat_arr_edges[1:-1] = lat_arr[1:] - diffarr / 2.0
  lat_arr_edges[0] = lat_arr[0] - diffarr[0] / 2.0
  lat_arr_edges[-1] = lat_arr[-1] + diffarr[-1] / 2.0

  for i in range(lenlat):
    weights[i] = getCosWeight(lat_arr_edges[i], lat_arr_edges[i+1])
  return weights

wxyp = calculateWeights(lat_in, lon_in)

LAI = np.zeros((18, 40, 12)) # PFT Biome Month
LAIs= np.zeros((18, 40, 12)) # SouthernHemi
LAImax = np.zeros((18, 40)) # PFT Biome
HITEent = np.zeros((18, 40))
LC = np.zeros((40, 18))

stdLAI = np.zeros((18, 40, 12))
stdLAIs = np.zeros((18, 40, 12))
stdLAImax = np.zeros((18, 40))
stdHITEent = np.zeros((18, 40))
stdLC = np.zeros((40, 18))

samples = np.zeros((2, 18, 40), dtype=int)
samplesWeight = np.zeros((2, 18, 40))
sampleCode = np.full((2, 18, 40), 'X')

print("Fetching biome files")
with nc.Dataset(biomeIn_file) as dataset:
  biomesIn = dataset["KG"][:]

#f = open(outdir+"regression-info.txt", "w")
flai = open(outdir+regressionlai, "w")
fsamples = open(outdir+regressionsamples, "w")
dLC = nc.Dataset(LC_file)

print("Fetching from LAI file")
with nc.Dataset(LAI_file) as dataset:
  # loop over PFTs
  for pft, pftvalue in pfts.items():
    if (pftvalue[pftIgnore]):
      continue
    else:
      data = dataset[pftvalue[0]][:]
      LCdata = dLC[pftvalue[0]][:]
    #f.write("-----------------------------------------------------------\n")
    #f.write("{} {} LAI monthly:\n".format(pftvalue[0], pftvalue[1]))
    #f.write("-----------------------------------------------------------\n")
    # loop over biomes
    for KG, biomecoords in biome_coords.items():
      if biomecoords is None:
        continue
      elif biomecoords[takeSample]:
        # loop over months
        for i in range(12):
          if biomecoords[hasBothHemi]:
            if biomecoords[ignoreHemiVariations]: # take global sample (use for tropical regions)
              weights = np.multiply(np.where(biomesIn == KG, wxyp, 0), LCdata)
              if np.sum(weights) == 0:
                samplesN = "0,0,X"
                samplesS = "0,0,X"
                continue
              LAI[pft-1][KG-1][i], stdLAI[pft-1][KG-1][i] = regress(data[i][:][:], weights, method=regression_method)
              LAIs[pft-1][KG-1][i] = LAI[pft-1][KG-1][i] # duplicate the data
              stdLAIs[pft-1][KG-1][i] = stdLAI[pft-1][KG-1][i]

              samples[:,pft-1,KG-1] = np.count_nonzero(weights)
              samplesWeight[:,pft-1,KG-1] = np.sum(weights)
              sampleCode[:,pft-1,KG-1] = 'B'
              samplesN = "{},{},B".format(samples[0,pft-1,KG-1], samplesWeight[0,pft-1,KG-1])
              samplesS = samplesN
            else: # take samples seperately from N and S hemispheres
              northernSlice = data[i][dimlat//2:][:]
              weights = np.multiply(np.where(biomesIn[dimlat//2:][:] == KG, wxyp[dimlat//2:][:], 0), LCdata[dimlat//2:][:])
              if np.sum(weights) == 0:
                samplesN = "0,0,X"
              else:
                LAI[pft-1][KG-1][i], stdLAI[pft-1][KG-1][i] = regress(northernSlice, weights, method=regression_method)
                samples[0,pft-1,KG-1] = np.count_nonzero(weights)
                samplesWeight[0,pft-1,KG-1] = np.sum(weights)
                sampleCode[0,pft-1,KG-1] = 'N'
                samplesN = "{},{},N".format(samples[0,pft-1,KG-1], samplesWeight[0,pft-1,KG-1])

              southernSlice = data[i][:dimlat//2][:]
              weights = np.multiply(np.where(biomesIn[:dimlat//2][:] == KG, wxyp[:dimlat//2][:], 0), LCdata[:dimlat//2][:])
              if np.sum(weights) == 0:
                samplesS = "0,0,X"
              else:
                LAIs[pft-1][KG-1][i], stdLAIs[pft-1][KG-1][i] = regress(southernSlice, weights, method=regression_method)
                samples[1,pft-1,KG-1] = np.count_nonzero(weights)
                sampleCode[1,pft-1,KG-1] = 'S'
                samplesWeight[1,pft-1,KG-1] = np.sum(weights)
                samplesS = "{},{},S".format(samples[1,pft-1,KG-1], samplesWeight[1,pft-1,KG-1])

          else:
            if biomecoords[isSouthernHemi]: # take sample single hemispheric only, roll 6 months for other hemi
              southernSlice = data[i][:dimlat//2][:]
              weights = np.multiply(np.where(biomesIn[:dimlat//2][:] == KG, wxyp[:dimlat//2][:], 0), LCdata[:dimlat//2][:])
              if np.sum(weights) == 0:
                samplesN = "0,0,X"
                samplesS = "0,0,X"
                continue
              LAIs[pft-1][KG-1][i], stdLAIs[pft-1][KG-1][i] = regress(southernSlice, weights, method=regression_method)
              LAI[pft-1][KG-1][(i+6)%12] = LAIs[pft-1][KG-1][i]
              stdLAI[pft-1][KG-1][(i+6)%12] = stdLAIs[pft-1][KG-1][i]
              samples[:,pft-1,KG-1] = np.count_nonzero(weights)
              samplesWeight[:,pft-1,KG-1] = np.sum(weights)
              sampleCode[1,pft-1,KG-1] = 'S'
              samplesS = "{},{},S".format(samples[1,pft-1,KG-1], samplesWeight[1,pft-1,KG-1])
              sampleCode[0,pft-1,KG-1] = 'R'
              samplesN = "{},R".format(samplesS[:-2])
            else:
              northernSlice = data[i][dimlat//2:][:]
              weights = np.multiply(np.where(biomesIn[dimlat//2:][:] == KG, wxyp[dimlat//2:][:], 0), LCdata[dimlat//2:][:])
              if np.sum(weights) == 0:
                samplesN = "0,0,X"
                samplesS = "0,0,X"
                continue
              LAI[pft-1][KG-1][i], stdLAI[pft-1][KG-1][i] = regress(northernSlice, weights, method=regression_method)
              LAIs[pft-1][KG-1][(i+6)%12] = LAI[pft-1][KG-1][i]
              stdLAIs[pft-1][KG-1][(i+6)%12] = stdLAI[pft-1][KG-1][i]
              samples[:,pft-1,KG-1] = np.count_nonzero(weights)
              samplesWeight[:,pft-1,KG-1] = np.sum(weights)
              sampleCode[0,pft-1,KG-1] = 'N'
              samplesN = "{},{},N".format(samples[0,pft-1,KG-1], samplesWeight[0,pft-1,KG-1])
              sampleCode[1,pft-1,KG-1] = 'R'
              samplesS = "{},R".format(samplesN[:-2])
        fsamples.write("PFT{}/KG{}/Nsamples,{}\n".format(pft, KG, samplesN))
        fsamples.write("PFT{}/KG{}/Ssamples,{}\n".format(pft, KG, samplesS))

      else: # take sample from 1 gridcell (when there's only 1 or 2 cells that are of a certain biome)
        if biomecoords[isSouthernHemi]:
          LAIs[pft-1][KG-1][:] = data[np.arange(0, 12), np.full(12, biomecoords[0]-1), np.full(12, biomecoords[1]-1)]
          LAI[pft-1][KG-1][:] = np.roll(LAIs[pft-1][KG-1][:], 6)
          samples[:,pft-1,KG-1] = 1
          sampleCode[1,pft-1,KG-1] = 'S'
          sampleCode[0,pft-1,KG-1] = 'R'
          fsamples.write("PFT{}/KG{}/Nsamples,1,{},R\n".format(pft, KG, LCdata[biomecoords[0]-1, biomecoords[1]-1]))
          fsamples.write("PFT{}/KG{}/Ssamples,1,{},S\n".format(pft, KG, LCdata[biomecoords[0]-1, biomecoords[1]-1]))
        else:
          LAI[pft-1][KG-1][:] = data[np.arange(0, 12), np.full(12, biomecoords[0]-1), np.full(12, biomecoords[1]-1)]
          LAIs[pft-1][KG-1][:] = np.roll(LAI[pft-1][KG-1][:], 6)
          samples[:,pft-1,KG-1] = 1
          sampleCode[0,pft-1,KG-1] = 'N'
          sampleCode[1,pft-1,KG-1] = 'R'
          fsamples.write("PFT{}/KG{}/Nsamples,1,{},N\n".format(pft, KG, LCdata[biomecoords[0]-1, biomecoords[1]-1]))
          fsamples.write("PFT{}/KG{}/Ssamples,1,{},R\n".format(pft, KG, LCdata[biomecoords[0]-1, biomecoords[1]-1]))
        #print(pft, KG, LAI[pft-1][KG-1])
      
      #f.write("KG {} north: {}\n".format(KG, np.array2string(LAI[pft-1][KG-1][:]).replace('\n', '')))
      #f.write("   {}   std: {}\n".format("  " if KG >= 10 else " ", np.array2string(stdLAI[pft-1][KG-1][:]).replace('\n', '')))
      #f.write("KG {} south: {}\n".format(KG, np.array2string(LAIs[pft-1][KG-1][:]).replace('\n', '')))
      #f.write("   {}   std: {}\n\n".format("  " if KG >= 10 else " ", np.array2string(stdLAIs[pft-1][KG-1][:]).replace('\n', '')))
      flai.write("PFT{}/KG{}/Nval,{}\n".format(pft, KG, ' '.join(np.array2string(LAI[pft-1][KG-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
      flai.write("PFT{}/KG{}/Nstd,{}\n".format(pft, KG, ' '.join(np.array2string(stdLAI[pft-1][KG-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
      flai.write("PFT{}/KG{}/Sval,{}\n".format(pft, KG, ' '.join(np.array2string(LAIs[pft-1][KG-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
      flai.write("PFT{}/KG{}/Sstd,{}\n".format(pft, KG, ' '.join(np.array2string(stdLAIs[pft-1][KG-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))

  #print(type(test))
flai.close()
fsamples.close()

flaimax = open(outdir+regressionlaimax, "w")
fheight = open(outdir+regressionheight, "w")
flc = open(outdir+regressionlc, 'w')
flaimax.write("biome")
fheight.write("biome")
flc.write("biome")
for KG, biomecoords in biome_coords.items():
  #if biomecoords is not None:
  flaimax.write(",KG{}".format(KG))
  fheight.write(",KG{}".format(KG))
  flc.write(",KG{}".format(KG))
flaimax.write("\n")
fheight.write("\n")
flc.write("\n")

print("Fetching from LAImax file")
print("Fetching from HITEent file")
print("Fetching from LC file")

with nc.Dataset(LAImax_file) as dLAImax, nc.Dataset(HITEent_file) as dHITEent:
  for pft, pftvalue in pfts.items():
    if (pftvalue[pftIgnore]):
      continue
    else:
      LAImaxdata = dLAImax[pftvalue[0]][:]
      LCdata = dLC[pftvalue[0]][:]
      HITEentdata = dHITEent[HITEprefix + pftvalue[0]][:]
      #f.write("-----------------------------------------------------------\n")
      #f.write("\n{} {} LAI max:\n".format(pftvalue[0], pftvalue[1]))
      #f.write("-----------------------------------------------------------\n")
    for KG, biomecoords in biome_coords.items():
      if biomecoords is None:
        continue
      elif biomecoords[takeSample]:
        weights = np.multiply(np.where(biomesIn == KG, wxyp, 0), LCdata)
        weightsLC = np.where(biomesIn == KG, wxyp, 0)
        if np.sum(weights) == 0:
          pass
        else:
          LAImax[pft-1][KG-1], stdLAImax[pft-1][KG-1] = regress(LAImaxdata, weights, method=regression_method)
          HITEent[pft-1][KG-1], stdHITEent[pft-1][KG-1] = regress(HITEentdata, weights, method=regression_method)
          LC[KG-1][pft-1], stdLC[KG-1][pft-1] = regress(LCdata, weightsLC) # weighted average for LC
          #print("{}, {}, {}, {}".format(KG, pft, LC[KG-1][pft-1], stdLC[KG-1][pft-1]))
        #fulldata = np.where(biomesIn == KG, data, 0)
        #LAImax[pft-1][KG-1] = np.amax(fulldata) # get the highest LAImax value per biome per PFT
      else:
        LAImax[pft-1][KG-1] = LAImaxdata[biomecoords[0]-1][biomecoords[1]-1]
        HITEent[pft-1][KG-1] = HITEentdata[biomecoords[0]-1][biomecoords[1]-1]
        LC[KG-1][pft-1] = LCdata[biomecoords[0]-1][biomecoords[1]-1]
        #print(pft, KG, LAImax[pft-1][KG-1])
      #f.write("KG {}: {}, std: {}\n".format(KG, LAImax[pft-1][KG-1], stdLAImax[pft-1][KG-1]))
    flaimax.write("PFT{}/VAL,{}\n".format(pft, ' '.join(np.array2string(LAImax[pft-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
    flaimax.write("PFT{}/STD,{}\n".format(pft, ' '.join(np.array2string(stdLAImax[pft-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
    fheight.write("PFT{}/VAL,{}\n".format(pft, ' '.join(np.array2string(HITEent[pft-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
    fheight.write("PFT{}/STD,{}\n".format(pft, ' '.join(np.array2string(stdHITEent[pft-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
flaimax.close()

"""
with nc.Dataset(HITEent_file) as dataset:
  for pft, pftvalue in pfts.items():
    if (pftvalue[pftIgnore]):
      continue
    else:
      data = dataset[HITEprefix + pftvalue[0]][:]
      LCdata = dLC[pftvalue[0]][:]
      #f.write("-----------------------------------------------------------\n")
      #f.write("\n{} {} height:\n".format(pftvalue[0], pftvalue[1]))
      #f.write("-----------------------------------------------------------\n")
    for KG, biomecoords in biome_coords.items():
      if biomecoords is None:
        continue
      elif biomecoords[takeSample]:
        weights = np.multiply(np.where(biomesIn == KG, wxyp, 0), LCdata)
        if np.sum(weights) == 0:
          pass
        else:
          HITEent[pft-1][KG-1], stdHITEent[pft-1][KG-1] = regress(data, weights, method=regression_method)
      else:
        HITEent[pft-1][KG-1] = data[biomecoords[0]-1][biomecoords[1]-1]
        #print(pft, KG, HITEent[pft-1][KG-1])
      #f.write("KG {}: {}, std: {}\n".format(KG, HITEent[pft-1][KG-1], stdHITEent[pft-1][KG-1]))
    fheight.write("PFT{}/VAL,{}\n".format(pft, ' '.join(np.array2string(HITEent[pft-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
    fheight.write("PFT{}/STD,{}\n".format(pft, ' '.join(np.array2string(stdHITEent[pft-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
"""

fheight.close()
#f.close()
dLC.close()

"""
# normalize lc to sum to 1
for KG in biome_coords.keys():
  LCfracsum = np.sum(LC[KG-1][:])
  if LCfracsum == 0:
    continue
  else:
    LC[KG-1][:] /= LCfracsum
    stdLC[KG-1][:] /= LCfracsum
"""

LC = LC.T
stdLC = stdLC.T

for pft, pftvalue in pfts.items():
  if (pftvalue[pftIgnore]):
    continue
  else:
    flc.write("PFT{}/VAL,{}\n".format(pft, ' '.join(np.array2string(LC[pft-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))
    flc.write("PFT{}/STD,{}\n".format(pft, ' '.join(np.array2string(stdLC[pft-1][:]).replace('\n', '').split()).replace(' ', ',')[1:-1].strip(',')))

flc.close()

print("Creating plots")

entcolors = [(0.0, 0.3, 0.0), (0.05, 0.35, 0.05), (0.0, 0.4, 0.4), (0.05, 0.45, 0.45), (0.0, 0.6, 0.0), (0.05, 0.65, 0.05), (0.4, 0.5, 0.3), (0.5, 0.1, 0.1), (0.0, 0.6, 0.6), (0.95, 0.85, 0.65), (0.0, 0.8, 0.1), (0.7, 0.8, 0.0), (1.0, 1.0, 0.0), (0.1, 0.8, 0.8), (0.8, 0.7, 0.1), (0.8, 0.0, 0.0), (0.9, 1.0, 1.0), (0.5, 0.45, 0.5)]
ent_cmap = colors.LinearSegmentedColormap.from_list('ent', entcolors, 18)

mStyles = ["o","v","^","<",">","1","2","3","4","s","p","P","*","H","X","D"]

lcn_names = ["ever_br_early", "ever_br_late", "ever_nd_early", "ever_nd_late", "cold_br_early", "cold_br_late", "drought_br", "decid_nd", "cold_shrub", "arid_shrub", "c3_grass_per", "c4_grass", "c3_grass_ann", "c3_grass_arct", "crops_herb", "crops_woody", "bare_bright", "bare_dark"]

biome_names = ["Af ", "Am ", "As ", "Aw ", "BWk", "BWh", "BSk", "BSh", "Csa", "Csb", "Csc", "Csd", "Cwa", "Cwb", "Cwc", "Cwd", "Cfa", "Cfb", "Cfc", "Cfd", "Dsa", "Dsb", "Dsc", "Dsd", "Dwa", "Dwb", "Dwc", "Dwd", "Dfa", "Dfb", "Dfc", "Dfd", "EF ", "ET ", "UA ", "UAu", "UB ", "UE ", "Ufu", "Uuu"]

biome_desc = np.array([
    "Equatorial rainforest, fully humid                         ",
    "Equatorial monsoon                                         ",
    "Equatorial savannah with dry summer                        ",
    "Equatorial savannah with dry winter                        ",
    "Arid desert cold                                           ",
    "Arid desert hot                                            ",
    "Arid steppe cold steppe                                    ",
    "Arid steppe hot                                            ",
    "Warm temperate with dry hot summer                         ",
    "Warm temperate with dry warm summer                        ",
    "Warm temperate with dry cool summer and cold winter        ",
    "Warm temperate with dry summer extremely continental       ",
    "Warm temperate with dry winter and hot summer              ",
    "Warm temperate with dry winter and warm summer             ",
    "Warm temperate with dry cold winter and cool summer        ",
    "Warm temperate with dry winter extremely continental       ",
    "Warm temperate fully humid with hot summer                 ",
    "Warm temperate fully humid with warm summer                ",
    "Warm temperate fully humid with cool summer and cold winter",
    "Warm temperate fully humid extremely continental           ",
    "Snow with dry hot summer                                   ",
    "Snow with dry warm summer                                  ",
    "Snow with dry cool summer and cold winter                  ",
    "Snow with dry summer extremely continental                 ",
    "Snow with dry winter and hot summer                        ",
    "Snow with dry winter and warm summer                       ",
    "Snow with dry cold winter and cool summer                  ",
    "Snow with dry winter extremely continental                 ",
    "Snow fully humid with hot summer                           ",
    "Snow fully humid with warm summer                          ",
    "Snow fully humid with cool summer and cold winter          ",
    "Snow fully humid extremely continental                     ",
    "Polar frost                                                ",
    "Polar tundra                                               ",
    "Unknown equatorial                                         ",
    "Unknown equatorial 3                                       ",
    "Unknown arid                                               ",
    "Unknown polar                                              ",
    "Unknown warmtemp.snow                                      ",
    "No data                                                    "
    ], dtype='S59')

# LAI month by PFT
ran = range(1,13)
with PdfPages("{}{}{}".format(outdir, regressionlai, "_LAIplot.pdf")) as LAIpdf:
  for PFT in range(16):
    fig = plt.figure(figsize=(30, 30))
    fig.suptitle("{} LAI monthly regression - raw data".format(lcn_names[PFT]), fontsize = 30)
    for KG in range(40):
      legend=False
      plt.subplot(8, 5, KG+1)
      plt.title("{}: {}".format(biome_names[KG], biome_desc[KG].decode('utf-8').strip()), fontsize=15)
      plt.ylabel("LAI (m²/m²)", fontsize=15)
      plt.xlabel("Month", fontsize=15)
      plt.xlim(1, 12)
      plt.ylim(0, 7)
      plt.xticks(fontsize=15)
      plt.yticks(fontsize=15)
      if (sampleCode[0,PFT,KG] != 'X') or (sampleCode[1,PFT,KG] != 'X'):
        plt.plot(ran, np.full((12), LAImax[PFT,KG]), color='black', label="LAImax", linestyle='dashed', alpha=0.5)
        plt.fill_between(ran, np.full((12), LAImax[PFT,KG]+stdLAImax[PFT,KG]), np.full((12), LAImax[PFT,KG]-stdLAImax[PFT,KG]), color='black', alpha=0.05)
        legend=True
      if (sampleCode[0,PFT,KG] == 'N'):
        plt.plot(ran, LAI[PFT,KG,:], color='green', label="Northern, n={}".format(samples[0,PFT,KG]))
        plt.fill_between(ran, LAI[PFT,KG,:]+stdLAI[PFT,KG,:], LAI[PFT,KG,:]-stdLAI[PFT,KG,:], color='green', alpha=0.1)
        legend=True
      elif (sampleCode[0,PFT,KG] == 'B'):
        plt.plot(ran, LAI[PFT,KG,:], color='red', label="Global, n={}".format(samples[0,PFT,KG]))
        plt.fill_between(ran, LAI[PFT,KG,:]+stdLAI[PFT,KG,:], LAI[PFT,KG,:]-stdLAI[PFT,KG,:], color='red', alpha=0.1)
        legend=True
      if (sampleCode[1,PFT,KG] == 'S'):
        plt.plot(ran, LAIs[PFT,KG,:], color='blue', label="Southern, n={}".format(samples[1,PFT,KG]))
        plt.fill_between(ran, LAIs[PFT,KG,:]+stdLAIs[PFT,KG,:], LAIs[PFT,KG,:]-stdLAIs[PFT,KG,:], color='blue', alpha=0.1)
        legend=True
      #plt.ylim(bottom=0) # have to set it after plotting if letting top limit free
      if (legend):
        plt.legend(framealpha=0.1)
    plt.tight_layout(rect=[0, 0.03, 1, 0.96])
    LAIpdf.savefig()
    plt.close()

# LAI month by biome
  fig = plt.figure(figsize=(30, 150))
  fig.suptitle("Monthly LAI by Biome - raw data", fontsize = 30, y=0.997)
  for KG in range(40):
    legend=False
    plt.subplot(40,2,KG*2+1) # Northern
    plt.title("{}: {} Northern".format(biome_names[KG], biome_desc[KG].decode('utf-8').strip()), fontsize=15)
    plt.ylabel("LAI (m²/m²)", fontsize=15)
    plt.xlim(0.8, 12.2)
    plt.xlabel("Month", fontsize=15)
    plt.ylim(0, 7)
    plt.xticks(fontsize=15)
    plt.yticks(fontsize=15)
    for PFT in range(16):
      if (sampleCode[0,PFT,KG] == 'X') or (sampleCode[0,PFT,KG] == 'R'):
        continue
      else:
        plt.plot(ran, LAI[PFT,KG,:], color=entcolors[PFT], label="{}, n={}".format(lcn_names[PFT], samples[0,PFT,KG]), marker=mStyles[PFT])
        plt.plot(ran, LAI[PFT,KG,:]+stdLAI[PFT,KG,:], color=entcolors[PFT], linestyle='dashed', linewidth=0.5, marker=mStyles[PFT], markersize=3, alpha=0.5)
        plt.plot(ran, LAI[PFT,KG,:]-stdLAI[PFT,KG,:], color=entcolors[PFT], linestyle='dashed', linewidth=0.5, marker=mStyles[PFT], markersize=3, alpha=0.5)
        legend=True
    if (legend):
      plt.legend(framealpha=0.1, loc='best', fontsize = 7)

    legend=False
    plt.subplot(40,2,KG*2+2) # Southern
    plt.title("{}: {} Southern".format(biome_names[KG], biome_desc[KG].decode('utf-8').strip()), fontsize=15)
    plt.ylabel("LAI (m²/m²)", fontsize=15)
    plt.xlim(0.8, 12.2)
    plt.xlabel("Month", fontsize=15)
    plt.ylim(0, 7)
    plt.xticks(fontsize=15)
    plt.yticks(fontsize=15)
    for PFT in range(16):
      if (sampleCode[1,PFT,KG] == 'X') or (sampleCode[1,PFT,KG] == 'R'):
        continue
      else:
        plt.plot(ran, LAIs[PFT,KG,:], color=entcolors[PFT], label="{}, n={}".format(lcn_names[PFT], samples[1,PFT,KG]), marker=mStyles[PFT])
        plt.plot(ran, LAIs[PFT,KG,:]+stdLAIs[PFT,KG,:], color=entcolors[PFT], linestyle='dashed', linewidth=0.5, marker=mStyles[PFT], markersize=3, alpha=0.5)
        plt.plot(ran, LAIs[PFT,KG,:]-stdLAIs[PFT,KG,:], color=entcolors[PFT], linestyle='dashed', linewidth=0.5, marker=mStyles[PFT], markersize=3, alpha=0.5)
        legend=True
    if (legend):
      plt.legend(framealpha=0.1, loc='best', fontsize = 7)

  plt.tight_layout(rect=[0, 0.005, 1, 0.995])
  LAIpdf.savefig()
  plt.close()
