# Converts lookup table file and input biomes to LC LAI LAImax HITEent netCDF files for use as inputs in modelE and its branches
# AUTHOR - James Lui
# Contact - james.lui1@nasa.gov

import numpy as np
import netCDF4 as nc
from datetime import datetime

outdimensions = @@DIMENSIONS
lat = @@LATDIM
lon = @@LONDIM
time = np.arange(1, 13)

outNETCDF_format = "@@NETCDF_FORMAT"

biome_file = "@@BIOME"
LUT_file = "@@LUT"

LAI_dataversion = "@@METADATA_DATAVERSION" 
LAImax_dataversion = "@@METADATA_DATAVERSION"
HITEent_dataversion = "@@METADATA_DATAVERSION"
LC_dataversion = "@@METADATA_DATAVERSION"

metadata_description = "@@METADATA_DESCRIPTION"

hgt = "@@HGT"

outdir = "@@OUTDIR"
LAI_out = "@@LAI_OUT"
LAImax_out = "@@LAIMAX_OUT"
HITEent_out = "@@HEIGHT_OUT"
LC_out = "@@LC_OUT"

default_biome = -1
fillvalue = -1e+30

LAI = np.zeros((18, 40, 12)) # PFT Biome Month
LAIs= np.zeros((18, 40, 12)) # SouthernHemi
LAImax = np.zeros((18, 40)) # PFT Biome
HITEent = np.zeros((18, 40))
LC = np.zeros((18, 40))

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

print("Fetching biomes")
with nc.Dataset(biome_file) as dataset:
    biomes = dataset["KG"][:]

print("Fetching from LUT")
with nc.Dataset(LUT_file, mode='r') as dataset:
  LC = dataset['lc'][:]
  HITEent = dataset['height'][:]
  LAImax = dataset['laimax'][:]
  allLAI = dataset['lai'][:]
  LAI = allLAI[0][:]
  LAIs = allLAI[1][:]

dimlat, dimlon = outdimensions

print("Writing LAI file (this may take a while)")
with nc.Dataset(outdir+LAI_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("title", "Estimated LAI")
  dataset.setncattr("data_sources", "LUT: {} Biomes: {}".format(LUT_file, biome_file))
  dataset.setncattr("data_version", LAI_dataversion)
  dataset.setncattr("description", metadata_description)
  dataset.setncattr("contact", "james.lui@nasa.gov, nancy.y.kiang@nasa.gov")
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
            try:
              data[month][i][j] = LAIs[pft-1][KG-1][month]
              if (KG < 1): # don't know why this doesn't raise an IndexError??
                raise IndexError
            except IndexError:
              data[month][i][j] = np.nan
      for i in range(dimlat//2, dimlat):
        for j in range(dimlon):
          KG = default_biome if isinstance(biomes[i][j], np.ma.core.MaskedConstant) else int(biomes[i][j])
          for month in range(12):
            try:
              data[month][i][j] = LAIs[pft-1][KG-1][month]
              if (KG < 1):
                raise IndexError
            except IndexError:
              data[month][i][j] = np.nan

      dataset[pftvalue[0]][:] = data

print("Writing LAImax file")
with nc.Dataset(outdir+LAImax_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("title", "Estimated LAImax")
  dataset.setncattr("data_sources", "LUT: {} Biomes: {}".format(LUT_file, biome_file))
  dataset.setncattr("data_version", LAImax_dataversion)
  dataset.setncattr("description", metadata_description)
  dataset.setncattr("contact", "james.lui@nasa.gov, nancy.y.kiang@nasa.gov")
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
          try:
            data[i][j] = LAImax[pft-1][KG-1]
            if (KG < 1):
              raise IndexError
          except IndexError:
            data[i][j] = np.nan

      dataset[pftvalue[0]][:] = data

print("Writing HITEent file")
with nc.Dataset(outdir+HITEent_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("title", "Estimated Height")
  dataset.setncattr("data_sources", "LUT: {} Biomes: {}".format(LUT_file, biome_file))
  dataset.setncattr("data_version", HITEent_dataversion)
  dataset.setncattr("description", metadata_description)
  dataset.setncattr("contact", "james.lui@nasa.gov, nancy.y.kiang@nasa.gov")
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
    dataset.createVariable(hgt+pftvalue[0], 'f4', dimensions=('lat', 'lon'), fill_value=fillvalue)
    dataset[hgt+pftvalue[0]].setncattr("long_name", pftvalue[1]+" height")
    dataset[hgt+pftvalue[0]].setncattr("units", "m")
    if (pftvalue[2]):
      continue
    else:
      data = np.zeros(outdimensions)
      for i in range(dimlat):
        for j in range(dimlon):
          KG = default_biome if isinstance(biomes[i][j], np.ma.core.MaskedConstant) else int(biomes[i][j])
          try:
            data[i][j] = HITEent[pft-1][KG-1]
            if (KG < 1):
              raise IndexError
          except IndexError:
            data[i][j] = np.nan

      dataset[hgt+pftvalue[0]][:] = data

print("Writing LC file")
with nc.Dataset(outdir+LC_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("title", "Estimated Land Cover")
  dataset.setncattr("data_sources", "LUT: {} Biomes: {}".format(LUT_file, biome_file))
  dataset.setncattr("data_version", LC_dataversion)
  dataset.setncattr("description", metadata_description)
  dataset.setncattr("contact", "james.lui@nasa.gov, nancy.y.kiang@nasa.gov")
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

  checksum = np.zeros((dimlat,dimlon))

  for pft, pftvalue in pfts.items():
    dataset.createVariable(pftvalue[0], 'f4', dimensions=('lat', 'lon'), zlib=True, fill_value=fillvalue)
    dataset[pftvalue[0]].setncattr("long_name", pftvalue[1]+" cover fraction")
    dataset[pftvalue[0]].setncattr("units", "fraction")
    if (pftvalue[2]):
      continue
    else:
      data = np.zeros(outdimensions)
      for i in range(dimlat):
        for j in range(dimlon):
          KG = default_biome if isinstance(biomes[i][j], np.ma.core.MaskedConstant) else int(biomes[i][j])
          try:
            data[i][j] = LC[pft-1][KG-1]
            if (KG < 1):
              raise IndexError
          except IndexError:
            data[i][j] = np.nan

      dataset[pftvalue[0]][:] = data
      checksum += data

checkones = np.isclose(checksum, 1.0)
isnans = np.isnan(checksum)
for i in range(dimlat):
  for j in range(dimlon):
    if (not checkones[i][j] and not isnans[i][j]):
      print("Sum of fractions in cell {}, {} is not 1.0! ({:.5f})".format(i,j,checksum[i][j]))
