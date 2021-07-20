# Regresses Koeppen-Geiger biomes to LC LAI LAImax and HITEent values based on input files
# AUTHOR - James Lui
# email/contact - james.lui@nasa.gov

import numpy as np
import netCDF4 as nc
from datetime import datetime
from math import sqrt

biomeIn_file = "../user/output/V144x90_EntKG_biomes_e7c9c1a.nc" # biomeIn are the biomes corresponding to the source LAI LAImax height files, Koeppen-Geiger classification.
LAI_file = "./data/V144x90_EntMM16_lai_trimmed_scaled_ext1.nc" # 12 month LAI values for the PFT cover types
LAImax_file = "./data/V144x90_EntMM16_lai_max_trimmed_scaled_ext1.nc" # LAI max values for the PFT cover types
HITEent_file = "./data/V144x90_EntMM16_height_trimmed_scaled_ext1.nc" # this specific file has hgt_ added to the front of every pft name, remove the hack below if not present
HITEhack = "hgt_"
LC_file = "./data/V144x90_EntMM16_lc_max_trimmed_scaled.nc" # cover fractions to use as weights for regression - some contamination of data can occur for values of LAI if another pft is dominant

LAI_datasource = "MODIS Average of 2001-2005, v4, March 2014"
LAImax_datasource = "MODIS Average of 2001-2005, v4, March 2014"
HITEent_datasource = "MODIS Average of 2001-2005 + EXT1"
LC_datasource = "MODUS Average of 2001-2005, v4, March 2014"

outNETCDF_format = "NETCDF3_CLASSIC" # see netcdf page for other formats

regressionlai = "EntKG_regressionLAI_monthly_raw_e7c9c1a.csv"
regressionlaimax = "EntKG_regressionLAI_max_raw_e7c9c1a.csv"
regressionheight = "EntKG_regressionheight_raw_e7c9c1a.csv"
regressionlc = "EntKG_regressionLC_raw_e7c9c1a.csv"
regressionsamples = "EntKG_regressionsamples_e7c9c1a.csv" # tracks how many samples taken

indimensions = (90, 144) # input file dimensions, specify for biomeIn_file LAI_file LAImax_file HITEent_file LC_file
lat_in = np.arange(-89.0, 91.0, 2.0)
lon_in = np.arange(-178.75, 181.25, 2.50)

outdir = "../user/output/"
writeNETCDF = False
# define lat long coords/dimensions here, specify for biome_file and output files
# IGNORE IF YOU DO NOT NEED NETCDF OUTPUT

outdimensions = (90, 144)
lat = np.arange(-89.0, 91, 2.0)
lon = np.arange(-178.75, 180.25, 2.50)
time = np.arange(1, 13)

# IGNORE IF YOU DO NOT NEED NETCDF OUTPUT
biome_file = "/discover/nobackup/jlui1/Koeppen/Koeppen-Geiger/eoceneKG.nc" # biome are the biomes corresponding to the desired output
LAI_out = "V144x90_jcl_LAI_monthly_eocene_uncurated.nc"
LAImax_out = "V144x90_jcl_LAImax_eocene_uncurated.nc"
HITEent_out = "V144x90_jcl_HITEent_eocene_uncurated.nc"
LC_out = "V144x90_jcl_LC_eocene_uncurated.nc"

default_biome = 31 
fillvalue = -1e+30

# Table to define behavior for regression. Take samples instead of single grid for areas where possible.
isSouthernHemi = 2 # If the coords given below  are in the southern hemisphere or, if takeSame is true and hasBothHemi is false, where to take the one-hemispheric sample 
takeSample = 3 # Take a sample (weighted average over grid cells) instead of a single grid cell
ignoreHemiVariations = 4 # Use for tropical biomes, regression will not take sample seperately and will not shift for seasonality
hasBothHemi = 5 # If biomes exist on both hemispheres

biome_coords = { # I90 J144 isSouthernHemi takeSample ignoreHemiVariations hasBothHemi (depends on your source files)
    1 : [47, 45, False, True, False, True],
    2 : [50, 68, False, True, False, True],
    3 : [46, 25, False, True, False, True],
    4 : [50, 71, False, True, False, True],
    5 : [66, 114, False, True, False, True],
    6 : [57, 73, False, True, False, True],
    7 : [65, 27, False, True, False, True],
    8 : [52, 80, False, True, False, True],
    9 : [64, 70, False, True, False, False],
    10: [67, 70, False, True, False, True],
    11: [22, 44, True, False, False, False],
    12: None,
    13: [57, 112, True, True, False, True],
    14: [59, 113, False, True, False, True],
    15: [34, 46, True, True, False, False],
    16: None,
    17: [61, 39, False, True, False, True],
    18: [71, 72, False, True, False, True],
    19: [72, 21, False, True, False, True],
    20: None,
    21: [65, 89, False, False, False, False],
    22: [65, 90, False, True, False, False],
    23: [65, 101, False, True, False, False],
    24: None,
    25: [67, 122, False, True, False, False],
    26: [69, 125, False, True, False, False],
    27: [73, 123, False, True, False, False],
    28: [78, 127, False, True, False, False],
    29: [67, 36, False, True, False, False],
    30: [72, 93, False, True, False, False],
    31: [77, 113, False, True, False, False],
    32: [81, 117, False, True, False, False],
    33: [83, 55, False, True, False, False],
    34: [81, 34, False, True, False, True],
    35: None,
    36: None,
    37: None,
    38: None,
    39: None,
    40: None,
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
biomes = np.empty(outdimensions)

stdLAI = np.zeros((18, 40, 12))
stdLAIs = np.zeros((18, 40, 12))
stdLAImax = np.zeros((18, 40))
stdHITEent = np.zeros((18, 40))
stdLC = np.zeros((40, 18))

print("Fetching biome files")
with nc.Dataset(biome_file) as dataset:
  biomes = dataset["KG"][:]
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
                samplesN = "0,X"
                samplesS = "0,X"
                continue
              LAI[pft-1][KG-1][i], stdLAI[pft-1][KG-1][i] = weighted_average_std(data[i][:][:], weights)
              LAIs[pft-1][KG-1][i] = LAI[pft-1][KG-1][i] # duplicate the data
              stdLAIs[pft-1][KG-1][i] = stdLAI[pft-1][KG-1][i]

              samplesN = "{},B".format(np.count_nonzero(weights))
              samplesS = samplesN
            else: # take samples seperately from N and S hemispheres
              northernSlice = data[i][dimlat//2:][:]
              weights = np.multiply(np.where(biomesIn[dimlat//2:][:] == KG, wxyp[dimlat//2:][:], 0), LCdata[dimlat//2:][:])
              if np.sum(weights) == 0:
                samplesN = "0,X"
              else:
                LAI[pft-1][KG-1][i], stdLAI[pft-1][KG-1][i] = weighted_average_std(northernSlice, weights)
                samplesN = "{},N".format(np.count_nonzero(weights))

              southernSlice = data[i][:dimlat//2][:]
              weights = np.multiply(np.where(biomesIn[:dimlat//2][:] == KG, wxyp[:dimlat//2][:], 0), LCdata[:dimlat//2][:])
              if np.sum(weights) == 0:
                samplesS = "0,X"
              else:
                LAIs[pft-1][KG-1][i], stdLAIs[pft-1][KG-1][i] = weighted_average_std(southernSlice, weights)
                samplesS = "{},S".format(np.count_nonzero(weights))

          else:
            if biomecoords[isSouthernHemi]: # take sample single hemispheric only, roll 6 months for other hemi
              southernSlice = data[i][:dimlat//2][:]
              weights = np.multiply(np.where(biomesIn[:dimlat//2][:] == KG, wxyp[:dimlat//2][:], 0), LCdata[:dimlat//2][:])
              if np.sum(weights) == 0:
                samplesN = "0,X"
                samplesS = "0,X"
                continue
              LAIs[pft-1][KG-1][i], stdLAIs[pft-1][KG-1][i] = weighted_average_std(southernSlice, weights)
              LAI[pft-1][KG-1][(i+6)%12] = LAIs[pft-1][KG-1][i]
              stdLAI[pft-1][KG-1][(i+6)%12] = stdLAIs[pft-1][KG-1][i]
              samplesS = "{},S".format(np.count_nonzero(weights))
              samplesN = "{},R".format(samplesS[:-2])
            else:
              northernSlice = data[i][dimlat//2:][:]
              weights = np.multiply(np.where(biomesIn[dimlat//2:][:] == KG, wxyp[dimlat//2:][:], 0), LCdata[dimlat//2:][:])
              if np.sum(weights) == 0:
                samplesN = "0,X"
                samplesS = "0,X"
                continue
              LAI[pft-1][KG-1][i], stdLAI[pft-1][KG-1][i] = weighted_average_std(northernSlice, weights)
              LAIs[pft-1][KG-1][(i+6)%12] = LAI[pft-1][KG-1][i]
              stdLAIs[pft-1][KG-1][(i+6)%12] = stdLAI[pft-1][KG-1][i]
              samplesN = "{},N".format(np.count_nonzero(weights))
              samplesS = "{},R".format(samplesN[:-2])
        fsamples.write("PFT{}/KG{}/Nsample,{}\n".format(pft, KG, samplesN))
        fsamples.write("PFT{}/KG{}/Ssample,{}\n".format(pft, KG, samplesS))

      else: # take sample from 1 gridcell (when there's only 1 or 2 cells that are of a certain biome)
        if biomecoords[isSouthernHemi]:
          LAIs[pft-1][KG-1][:] = data[np.arange(0, 12), np.full(12, biomecoords[0]-1), np.full(12, biomecoords[1]-1)]
          LAI[pft-1][KG-1][:] = np.roll(LAIs[pft-1][KG-1][:], 6)
          fsamples.write("PFT{}/KG{}/Nsamples,{}\n".format(pft, KG, "1,S"))
          fsamples.write("PFT{}/KG{}/Ssamples,{}\n".format(pft, KG, "1,R"))
        else:
          LAI[pft-1][KG-1][:] = data[np.arange(0, 12), np.full(12, biomecoords[0]-1), np.full(12, biomecoords[1]-1)]
          LAIs[pft-1][KG-1][:] = np.roll(LAI[pft-1][KG-1][:], 6)
          fsamples.write("PFT{}/KG{}/Nsamples,{}\n".format(pft, KG, "1,N"))
          fsamples.write("PFT{}/KG{}/Ssamples,{}\n".format(pft, KG, "1,R"))
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
      HITEentdata = dHITEent[HITEhack + pftvalue[0]][:]
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
          LAImax[pft-1][KG-1], stdLAImax[pft-1][KG-1] = weighted_average_std(LAImaxdata, weights)
          HITEent[pft-1][KG-1], stdHITEent[pft-1][KG-1] = weighted_average_std(HITEentdata, weights)
          LC[KG-1][pft-1], stdLC[KG-1][pft-1] = weighted_average_std(LCdata, weightsLC)
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
      data = dataset[HITEhack + pftvalue[0]][:]
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
          HITEent[pft-1][KG-1], stdHITEent[pft-1][KG-1] = weighted_average_std(data, weights)
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

dimlat, dimlon = outdimensions

if not writeNETCDF:
  exit(0)

print("Writing LAI file (this may take a while)")
with nc.Dataset(outdir+LAI_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("title", "Estimated LAI")
  dataset.setncattr("source", LAI_file)
  dataset.setncattr("data_source", LAI_datasource)
  dataset.setncattr("info", "Estimated monthly LAI generated from input biomes: {} and weighed by grid-surface area and cover fraction: {}".format(biome_file, LC_file))
  dataset.setncattr("contact", "james.lui@nasa.gov, nancy.y.kiang@nasa.gov, allegra.n.legrand@nasa.gov")
  dataset.setncattr("institution", "NASA Goddard Institute for Space Studies")
  dataset.setncattr("date_created", datetime.today().strftime('%Y-%m-%d %H:%M:%S'))
  dataset.createDimension('lat', size=dimlat)
  dataset.createDimension('lon', size=dimlon)
  dataset.createDimension('time', size=0)

  dataset.createVariable('lat', 'f4', ('lat'))
  dataset.createVariable('lon', 'f4', ('lon'))
  dataset.createVariable('time', 'i4', ('time'))
  dataset['lat'][:] = lat
  dataset['lon'][:] = lon
  dataset['time'][:] = time
  dataset['lat'].setncattr("long_name", "latitude")
  dataset['lat'].setncattr("units", "degrees_north")
  dataset['lon'].setncattr("long_name", "longitude")
  dataset['lon'].setncattr("units", "degrees_east")
  dataset['time'].setncattr("long_name", "time")
  dataset['time'].setncattr("units", "months")

  for pft, pftvalue in pfts.items():
    dataset.createVariable(pftvalue[0], 'f4', dimensions=('time', 'lat', 'lon'), fill_value=fillvalue)
    dataset[pftvalue[0]].setncattr("long_name", pftvalue[1]+" LAI")
    dataset[pftvalue[0]].setncattr("units", "m2/m2")
    if (pftvalue[2]):
      continue
    else:
      data = np.zeros((12, dimlat, dimlon)) # Generate LAI values from table, split grid into north and south
      for i in range(dimlat//2): # southern hemisphere
        for j in range(dimlon):
          KG = default_biome if isinstance(biomes[i][j], np.ma.core.MaskedConstant) else int(biomes[i][j]) 
          for month in range(12):  
            data[month][i][j] = LAIs[pft-1][KG-1][month]
      for i in range(dimlat//2, dimlat):
        for j in range(dimlon):
          KG = default_biome if isinstance(biomes[i][j], np.ma.core.MaskedConstant) else int(biomes[i][j])
          for month in range(12):  
            data[month][i][j] = LAI[pft-1][KG-1][month]

      dataset[pftvalue[0]][:] = data

print("Writing LAImax file")
with nc.Dataset(outdir+LAImax_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("title", "Estimated LAImax")
  dataset.setncattr("source", LAImax_file)
  dataset.setncattr("data_source", LAImax_datasource)
  dataset.setncattr("info", "Estimated LAI max generated from input biomes: {} picking the highest value in each biome".format(biome_file))
  dataset.setncattr("contact", "james.lui@nasa.gov, nancy.y.kiang@nasa.gov, allegra.n.legrand@nasa.gov")
  dataset.setncattr("institution", "NASA Goddard Institute for Space Studies")
  dataset.setncattr("date_created", datetime.today().strftime('%Y-%m-%d %H:%M:%S'))
  dataset.createDimension('lat', size=dimlat)
  dataset.createDimension('lon', size=dimlon)

  dataset.createVariable('lat', 'f4', ('lat'))
  dataset.createVariable('lon', 'f4', ('lon'))
  dataset['lat'][:] = lat
  dataset['lon'][:] = lon
  dataset['lat'].setncattr("long_name", "latitude")
  dataset['lat'].setncattr("units", "degrees_north")
  dataset['lon'].setncattr("long_name", "longitude")
  dataset['lon'].setncattr("units", "degrees_east")
  for pft, pftvalue in pfts.items():
    dataset.createVariable(pftvalue[0], 'f4', dimensions=('lat', 'lon'), fill_value=fillvalue)
    dataset[pftvalue[0]].setncattr("long_name", pftvalue[1]+" LAImax")
    dataset[pftvalue[0]].setncattr("units", "m2/m2")
    if (pftvalue[2]):
      continue
    else:
      data = np.zeros(outdimensions)
      for i in range(dimlat):
        for j in range(dimlon):
          KG = default_biome if isinstance(biomes[i][j], np.ma.core.MaskedConstant) else int(biomes[i][j]) 
          data[i][j] = LAImax[pft-1][KG-1]

      dataset[pftvalue[0]][:] = data

print("Writing HITEent file")
with nc.Dataset(outdir+HITEent_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("title", "Estimated Height")
  dataset.setncattr("source", HITEent_file)
  dataset.setncattr("data_source", HITEent_datasource)
  dataset.setncattr("info", "Estimated height generated from input biomes: {} and weighed by grid-surface area and cover fraction: {}".format(biome_file, LC_file))
  dataset.setncattr("contact", "james.lui@nasa.gov, nancy.y.kiang@nasa.gov, allegra.n.legrand@nasa.gov")
  dataset.setncattr("institution", "NASA Goddard Institute for Space Studies")
  dataset.setncattr("date_created", datetime.today().strftime('%Y-%m-%d %H:%M:%S'))
  dataset.createDimension('lat', size=dimlat)
  dataset.createDimension('lon', size=dimlon)

  dataset.createVariable('lat', 'f4', ('lat'))
  dataset.createVariable('lon', 'f4', ('lon'))
  dataset['lat'][:] = lat
  dataset['lon'][:] = lon
  dataset['lat'].setncattr("long_name", "latitude")
  dataset['lat'].setncattr("units", "degrees_north")
  dataset['lon'].setncattr("long_name", "longitude")
  dataset['lon'].setncattr("units", "degrees_east")

  for pft, pftvalue in pfts.items():
    dataset.createVariable(pftvalue[0], 'f4', dimensions=('lat', 'lon'), fill_value=fillvalue)
    dataset[pftvalue[0]].setncattr("long_name", pftvalue[1]+" height")
    dataset[pftvalue[0]].setncattr("units", "m")
    if (pftvalue[2]):
      continue
    else:
      data = np.zeros(outdimensions)
      for i in range(dimlat):
        for j in range(dimlon):
          KG = default_biome if isinstance(biomes[i][j], np.ma.core.MaskedConstant) else int(biomes[i][j]) 
          data[i][j] = HITEent[pft-1][KG-1]

      dataset[pftvalue[0]][:] = data

print("Writing LC file")
with nc.Dataset(outdir+LC_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("title", "Estimated Height")
  dataset.setncattr("source", LC_file)
  dataset.setncattr("data_source", LC_datasource)
  dataset.setncattr("info", "Estimated cover fraction generated from input biomes: {} and weighed by grid-surface area.".format(biome_file))
  dataset.setncattr("contact", "james.lui@nasa.gov, nancy.y.kiang@nasa.gov, allegra.n.legrand@nasa.gov")
  dataset.setncattr("institution", "NASA Goddard Institute for Space Studies")
  dataset.setncattr("date_created", datetime.today().strftime('%Y-%m-%d %H:%M:%S'))
  dataset.createDimension('lat', size=dimlat)
  dataset.createDimension('lon', size=dimlon)

  dataset.createVariable('lat', 'f4', ('lat'))
  dataset.createVariable('lon', 'f4', ('lon'))
  dataset['lat'][:] = lat
  dataset['lon'][:] = lon
  dataset['lat'].setncattr("long_name", "latitude")
  dataset['lat'].setncattr("units", "degrees_north")
  dataset['lon'].setncattr("long_name", "longitude")
  dataset['lon'].setncattr("units", "degrees_east")

  for pft, pftvalue in pfts.items():
    dataset.createVariable(pftvalue[0], 'f4', dimensions=('lat', 'lon'), fill_value=fillvalue)
    dataset[pftvalue[0]].setncattr("long_name", pftvalue[1]+" cover fraction")
    dataset[pftvalue[0]].setncattr("units", "fraction")
    if (pftvalue[2]):
      continue
    else:
      data = np.zeros(outdimensions)
      for i in range(dimlat):
        for j in range(dimlon):
          KG = default_biome if isinstance(biomes[i][j], np.ma.core.MaskedConstant) else int(biomes[i][j]) 
          data[i][j] = LC[pft-1][KG-1]

      dataset[pftvalue[0]][:] = data

