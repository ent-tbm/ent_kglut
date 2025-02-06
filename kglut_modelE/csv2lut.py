# Converts CSV files outputted from regress_biome2laihite.py into a lookup table file
# AUTHOR - James Lui
# Contact - james.lui@nasa.gov

import numpy as np
import netCDF4 as nc
import re
from datetime import datetime
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.colors as colors









outdimensions = @@DIMENSIONS
lat = @@LATDIM
lon = @@LONDIM
time = np.arange(1, 13)

outNETCDF_format = "@@NETCDF_FORMAT"

lai_file = "@@LAI_CSV_FILE"
laimax_file = "@@LAIMAX_CSV_FILE"
height_file = "@@HEIGHT_CSV_FILE"
lc_file = "@@LC_CSV_FILE"

outdir = "@@OUTDIR" 
LUT_out = "@@LUT_OUT"

LAI = np.zeros((2, 18, 40, 12)) # hemi PFT Biome Month
LAImax = np.zeros((18, 40)) # PFT Biome
HITEent = np.zeros((18, 40))
LC = np.zeros((18, 40))

def translateCode(code):
  regexmatch = re.match("PFT(\d+)/KG(\d+)/(\w{4})", code)
  if regexmatch:
    PFT, KG, hemi = regexmatch.groups()
  else:
    raise ValueError
  return int(PFT), int(KG), hemi

print("Reading from csv files")
with open(lai_file) as flai:
  while(True):
    lailine = flai.readline().split(',')

    try:
      lcnname, biomename, heminame = translateCode(lailine[0])
      #print(lcnname, biomename, heminame)
    except ValueError:
      break

    if not 'val' in heminame:
      continue
    if 'N' in heminame:
      LAI[0][lcnname-1][biomename-1][:] = np.asarray(lailine[1:], dtype=np.float64)
    elif 'S' in heminame:
      LAI[1][lcnname-1][biomename-1][:] = np.asarray(lailine[1:], dtype=np.float64)
    else:
      pass

with open(laimax_file) as flaimax, open(height_file) as fheight, open(lc_file) as flc:
  flaimax.readline()
  fheight.readline()
  flc.readline()

  while(True):
    laimaxline = flaimax.readline().split(',')
    heightline = fheight.readline().split(',')
    lcline = flc.readline().split(',')
    try:
      pftno = int(laimaxline[0][3:-4])
      if not 'VAL' in laimaxline[0]:
        int(laimaxline[0][3:-4])
        continue # this is extremely asinine, for some god forsaken reason running this script from bash makes string slicing WRONG
      LAImax[pftno-1][:] = np.array(laimaxline[1:]).astype(np.float64) # so e.g. laimaxline[0] = 'PFT5/VAL'
      HITEent[pftno-1][:] = np.array(heightline[1:]).astype(np.float64) # therefore laimaxline[0][3:-4] -> '5' right? (orig script)
      LC[pftno-1][:] = np.array(lcline[1:]).astype(np.float64) # NOPE! It gives T5/ ???? WHY IS IT COUNTING '' AS PART OF THE STRING????
    except ValueError as e: # OH AND EVEN WORSE, [4:-5] and [3:-4][1:-1] DOESN'T FIX IT! IT JUST MAKES AN EMPTY STRING
      #print(e)
      break
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

print("Writing to netCDF file")
with nc.Dataset(outdir+LUT_out, mode='w', format=outNETCDF_format) as dataset:
  dataset.setncattr("description", "Ent Global Vegetation Structure Dataset (Ent GVSD) v1.0.KG2004.  Koeppen-Geiger biome class lookup table of Ent Terrestrial Biosphere Model vegetation boundary conditions.")
  dataset.setncattr("date_created", datetime.today().strftime('%Y-%m-%d %H:%M:%S'))
  dataset.setncattr("version", "@@METADATA_DATAVERSION")
  dataset.setncattr("contact", "James.Lui@nasa.gov, Nancy.Y.Kiang@nasa.gov, Allegra.N.LeGrande@nasa.gov")
  dataset.setncattr("institution", "NASA Goddard Institute for Space Studies")
  dataset.setncattr("data_sources", "@@METADATA_DATASOURCELUT")
  #dataset.setncattr("lcn_names", "ever_br_early ever_br_late ever_nd_early ever_nd_late cold_br_early cold_br_late drought_br decid_nd cold_shrub arid_shrub c3_grass_per c4_grass c3_grass_ann c3_grass_arct crops_herb crops_woody bare_bright bare_dark")
  #dataset.setncattr("kgn_names", "Af Am As Aw BWk BWh BSk BSh Csa Csb Csc Csd Cwa Cwb Cwc Cwd Cfa Cfb Cfc Cfd Dsa Dsb Dsc Dsd Dwa Dwb Dwc Dwd Dfa Dfb Dfc Dfd EF ET UA UAu UB UE Ufu Uuu")

  dataset.createDimension('hemisphere', size=2)
  dataset.createDimension('lcn', size=18)
  dataset.createDimension('kgn', size=40)
  dataset.createDimension('month', size=12)
  dataset.createDimension('nbiomechars', size=3)
  dataset.createDimension('nbiomedescchars', size=59)
  dataset.createDimension('npftchars', size=13)

  dataset.createVariable('hemisphere', 'i4', ('hemisphere'))
  dataset.createVariable('lcn', 'i4', ('lcn'))
  dataset.createVariable('kgn', 'i4', ('kgn'))
  dataset.createVariable('month', 'i4', ('month'))
  dataset.createVariable('KGcode', 'S1', ('kgn', 'nbiomechars'))
  dataset.createVariable('KGbiome', 'S1', ('kgn', 'nbiomedescchars'))
  dataset.createVariable('ent_cover_names', 'S1', ('lcn', 'npftchars'))

  dataset['hemisphere'].setncattr("long_name", "Hemisphere - 1 = North, 2 = South")
  dataset['lcn'].setncattr("long_name", "Plant Functional Type")
  dataset['kgn'].setncattr("long_name", "Koeppen-Geiger Climate Classification")
  dataset['month'].setncattr("long_name", "Month")
  dataset['KGcode'].setncattr("long_name", "Koeppen-Geiger biome codes")
  dataset['KGbiome'].setncattr("long_name", "Koeppen-Geiger biome description")
  dataset['ent_cover_names'].setncattr("long_name", "Ent GISS cover type netcdf names")

  dataset['hemisphere'][:] = [1, 2]
  dataset['lcn'][:] = np.arange(1, 19)
  dataset['kgn'][:] = np.arange(1, 41)
  dataset['month'][:] = np.arange(1, 13)

  biome_names = np.array(["Af ", "Am ", "As ", "Aw ", "BWk", "BWh", "BSk", "BSh", "Csa", "Csb", "Csc", "Csd", "Cwa", "Cwb", "Cwc", "Cwd", "Cfa", "Cfb", "Cfc", "Cfd", "Dsa", "Dsb", "Dsc", "Dsd", "Dwa", "Dwb", "Dwc", "Dwd", "Dfa", "Dfb", "Dfc", "Dfd", "EF ", "ET ", "UA ", "UAu", "UB ", "UE ", "Ufu", "Uuu"], dtype='S3')
  dataset['KGcode'][:] = nc.stringtochar(biome_names)
  dataset['KGcode']._Encoding = 'ascii'

  dataset['KGbiome'][:] = nc.stringtochar(biome_desc)
  dataset['KGbiome']._Encoding = 'ascii'

  lcn_names = np.array(["ever_br_early", "ever_br_late ", "ever_nd_early", "ever_nd_late ", "cold_br_early", "cold_br_late ", "drought_br   ", "decid_nd     ", "cold_shrub   ", "arid_shrub   ", "c3_grass_per ", "c4_grass     ", "c3_grass_ann ", "c3_grass_arct", "crops_herb   ", "crops_woody  ", "bare_bright  ", "bare_dark    "], dtype='S13')
  dataset['ent_cover_names'][:] = nc.stringtochar(lcn_names)
  dataset['ent_cover_names']._Encoding = 'ascii'

  dataset.createVariable("lc", 'f4', dimensions=('lcn', 'kgn'))
  dataset.createVariable("height", 'f4', dimensions=('lcn', 'kgn'))
  dataset.createVariable("laimax", 'f4', dimensions=('lcn', 'kgn'))
  dataset.createVariable("lai", 'f4', dimensions=('hemisphere', 'lcn', 'kgn', 'month'))

  dataset['lc'].setncattr("long_name", "Cover Fraction")
  dataset['height'].setncattr("long_name", "Canopy Height")
  dataset['laimax'].setncattr("long_name", "Maximum Annual Leaf Area Index")
  dataset['lai'].setncattr("long_name", "Monthly Annual Leaf Area Index")

  dataset['lc'].setncattr("units", "fraction")
  dataset['height'].setncattr("units", "m")
  dataset['laimax'].setncattr("units", "m^2/m^2")
  dataset['lai'].setncattr("units", "m^2/m^2")

  dataset['lc'][:] = LC
  dataset['height'][:] = HITEent
  dataset['laimax'][:] = LAImax
  dataset['lai'][:] = LAI

print("Creating plots")

entcolors = [(0.0, 0.3, 0.0), (0.05, 0.35, 0.05), (0.0, 0.4, 0.4), (0.05, 0.45, 0.45), (0.0, 0.6, 0.0), (0.05, 0.65, 0.05), (0.4, 0.5, 0.3), (0.5, 0.1, 0.1), (0.0, 0.6, 0.6), (0.95, 0.85, 0.65), (0.0, 0.8, 0.1), (0.7, 0.8, 0.0), (1.0, 1.0, 0.0), (0.1, 0.8, 0.8), (0.8, 0.7, 0.1), (0.8, 0.0, 0.0), (0.9, 1.0, 1.0), (0.5, 0.45, 0.5)]
ent_cmap = colors.LinearSegmentedColormap.from_list('ent', entcolors, 18)

mStyles = ["o","v","^","<",">","1","2","3","4","s","p","P","*","H","X","D"]

# LAI month by PFT
ran = range(1,13)
with PdfPages("{}{}{}".format(outdir, LUT_out, "_LAIplot.pdf")) as LAIpdf:
  for PFT in range(16):
    fig = plt.figure(figsize=(30, 20))
    fig.suptitle("{} LAI monthly regression".format(lcn_names[PFT].decode('utf-8').strip()), fontsize = 30)
    for KG in range(40):
      plt.subplot(8, 5, KG+1)
      plt.title("{}: {}".format(biome_names[KG].decode('utf-8').strip(), biome_desc[KG].decode('utf-8').strip()))
      plt.ylabel("LAI (m²/m²)")
      plt.xlabel("Month")
      plt.xlim(1, 12)
      plt.ylim(0, 6)
      plt.plot(ran, np.full((12), LAImax[PFT,KG]), color='black', label="LAImax", linestyle='dashed', alpha=0.5)
      plt.plot(ran, LAI[0,PFT,KG,:], color='green', label="Northern")
      plt.plot(ran, LAI[1,PFT,KG,:], color='blue', label="Southern")
      #plt.ylim(bottom=0) # have to set it after plotting if letting top limit free
      plt.legend(framealpha=0.1)
    plt.tight_layout(rect=[0, 0.03, 1, 0.96])
    LAIpdf.savefig()
    plt.close()

# LAI month by biome
  fig = plt.figure(figsize=(30, 150))
  fig.suptitle("LAImax by Biome", fontsize = 30, y=0.997)
  for KG in range(40):
    legend=False
    plt.subplot(40,2,KG*2+1) # Northern
    plt.title("{}: {} Northern".format(biome_names[KG].decode('utf-8').strip(), biome_desc[KG].decode('utf-8').strip()))
    plt.ylabel("LAI (m²/m²)")
    plt.xlim(0.8, 12.2)
    plt.xlabel("Month")
    plt.ylim(0, 6)
    for PFT in range(16):
      if (LAImax[PFT,KG] == 0):
        continue
      else:
        plt.plot(ran, LAI[0,PFT,KG,:], color=entcolors[PFT], label=lcn_names[PFT].decode('utf-8').strip(), marker=mStyles[PFT])
        legend=True
    if (legend):
      plt.legend(framealpha=0.1, loc='best', fontsize = 7)

    legend=False
    plt.subplot(40,2,KG*2+2) # Southern
    plt.title("{}: {} Southern".format(biome_names[KG].decode('utf-8').strip(), biome_desc[KG].decode('utf-8').strip()))
    plt.ylabel("LAI (m²/m²)")
    plt.xlim(0.8, 12.2)
    plt.xlabel("Month")
    plt.ylim(0, 6)
    for PFT in range(16):
      if (LAImax[PFT,KG] == 0):
        continue
      else:
        plt.plot(ran, LAI[1,PFT,KG,:], color=entcolors[PFT], label=lcn_names[PFT].decode('utf-8').strip(), marker=mStyles[PFT])
        legend=True
    if (legend):
      plt.legend(framealpha=0.1, loc='best', fontsize = 7)

  plt.tight_layout(rect=[0, 0.005, 1, 0.995])
  LAIpdf.savefig()
  plt.close()
