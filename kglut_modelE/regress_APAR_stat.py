# generates statistics APAR/FAPAR by biome
# contact james.lui@nasa.gov nancy.y.kiang@nasa.gov

import numpy as np
from datetime import datetime
import netCDF4 as nc
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
import matplotlib.colors as colors
import matplotlib.ticker as mticker
from mpl_toolkits.basemap import Basemap
from math import sqrt, isnan
import warnings
warnings.filterwarnings('ignore', category=UserWarning)

indir = "@@INDIR"
biome_file = "@@BIOME" 

outdir = "@@OUTDIR"
outfilename = "@@OUT_NC"
outAPARpdf = "@@OUT_APAR_PDF"
outFAPARpdf = "@@OUT_FAPAR_PDF"
outWWpdf = "@@OUT_WW_PDF"



runname = "@@RUNNAME"
canopy_model = "@@CANOPYMODEL"
extra_info = "@@METADATA"

fillvalue = -1e30

aij = [
    "@@JAN",
    "@@FEB",
    "@@MAR",
    "@@APR",
    "@@MAY",
    "@@JUN",
    "@@JUL",
    "@@AUG",
    "@@SEP",
    "@@OCT",
    "@@NOV",
    "@@DEC",
    "@@ANN"
    ]

outNETCDF_format = 'NETCDF4'

time = np.arange(1, 14)
dimlat, dimlon = @@DIMENSIONS
lat = @@LATDIM
lon = @@LONDIM

# Store values from input files
apar = np.empty((13, dimlat, dimlon))
fapar = np.empty((13, dimlat, dimlon))
soilfr = np.empty((dimlat, dimlon))
vsfr = np.empty((dimlat, dimlon))
lai = np.empty((13, dimlat, dimlon))
gpp = np.empty((13, dimlat, dimlon))
tsurf = np.empty((13, dimlat, dimlon))
prec = np.empty((13, dimlat, dimlon))
incsw_grnd = np.empty((13, dimlat, dimlon))

apar_pft = np.empty((13, 18, dimlat, dimlon)) # ra042
fapar_pft = np.empty((13, 18, dimlat, dimlon)) # ra043
lc_pft = np.empty((18, dimlat, dimlon)) # ra001
c_biomass = np.empty((18, dimlat, dimlon)) # ra017 - ra024

oceanmask = np.empty((dimlat, dimlon))

# Store output statistics
apar_avg = np.empty((17, 40, 13, 3))
apar_std = np.empty((17, 40, 13, 3))
apar_intg = np.empty((40, 13, 3)) # integrated
apar_kgn = np.empty((40, 13, dimlat, dimlon))

fapar_avg = np.empty((17, 40, 13, 3)) # PFT, KG, MONTH, HEMISPHERE
fapar_std = np.empty((17, 40, 13, 3))
fapar_kgn = np.empty((40, 13, dimlat, dimlon))

msp_avg = np.empty((40, 13, 3))
msp_std = np.empty((40, 13, 3))
par_num = np.empty((17, 40, 3), dtype=int)

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

lcn_names = np.array(["ever_br_early", "ever_br_late ", "ever_nd_early", "ever_nd_late ", "cold_br_early", "cold_br_late ", "drought_br   ", "decid_nd     ", "cold_shrub   ", "arid_shrub   ", "c3_grass_per ", "c4_grass     ", "c3_grass_ann ", "c3_grass_arct", "crops_herb   ", "crops_woody  ", "bare_bright  ", "bare_dark    "], dtype='S13')

biome_names = np.array(["Af ", "Am ", "As ", "Aw ", "BWk", "BWh", "BSk", "BSh", "Csa", "Csb", "Csc", "Csd", "Cwa", "Cwb", "Cwc", "Cwd", "Cfa", "Cfb", "Cfc", "Cfd", "Dsa", "Dsb", "Dsc", "Dsd", "Dwa", "Dwb", "Dwc", "Dwd", "Dfa", "Dfb", "Dfc", "Dfd", "EF ", "ET ", "UA ", "UAu", "UB ", "UE ", "Ufu", "Uuu"], dtype='S3')

hemisphere_names = np.array(["Northern", "Southern", "Global "], dtype='S8')

month_names = np.array(["January  ", "February ", "March    ", "April    ", "May      ", "June     ", "July     ", "August   ", "September", "October  ", "November ", "December ", "Annual   "], dtype='S9')

month_day = [31, 28, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31, 365]

# colormaps
entcolors = [(0.0, 0.3, 0.0), (0.05, 0.35, 0.05), (0.0, 0.4, 0.4), (0.05, 0.45, 0.45), (0.0, 0.6, 0.0), (0.05, 0.65, 0.05), (0.4, 0.5, 0.3), (0.5, 0.1, 0.1), (0.0, 0.6, 0.6), (0.95, 0.85, 0.65), (0.0, 0.8, 0.1), (0.7, 0.8, 0.0), (1.0, 1.0, 0.0), (0.1, 0.8, 0.8), (0.8, 0.7, 0.1), (0.8, 0.0, 0.0), (0.9, 1.0, 1.0), (0.5, 0.45, 0.5)]
ent_cmap = colors.LinearSegmentedColormap.from_list('ent', entcolors, 18)

panoplycolors = [(0, 0, 0.8), (0.16, 0.4, 1), (0.36, 0.7, 1), (0.53, 0.86, 1), (0.67, 0.95, 1), (0.95, 0.95, 0.95), (1, 0.91, 0), (1, 0.63, 0), (1, 0.22, 0), (0.86, 0, 0), (0.5, 0, 0)]
panoply_cmap = colors.LinearSegmentedColormap.from_list('panoply', panoplycolors, 200)

maskcolors = [(0, 0, 0, 0), (0.80, 0.80, 0.80, 1)]
oceanmask_cmap = colors.LinearSegmentedColormap.from_list('oceanmask', maskcolors, 2)

# get weights, not exactly axyp but doesn't matter since we only care about relative weights
# weights sum to 2.0 exactly, axyp = surface area of Earth * weights / lenlon / 2
def getweights(lat_arr, lon_arr):
    lenlon = len(lon_arr)
    lenlat = len(lat_arr)
    diffarr = np.diff(lat_arr)
    weights = np.zeros((lenlat, lenlon))

    # convert centers to edges
    lat_arr_edges = np.zeros(lenlat + 1)
    lat_arr_edges[1:-1] = lat_arr[1:] - diffarr / 2.0
    lat_arr_edges[0] = lat_arr[0] - diffarr[0] / 2.0
    lat_arr_edges[-1] = lat_arr[-1] + diffarr[-1] / 2.0

    # equirectangular meshgrid, all latitudes have the same weight
    for i in range(lenlat):
        weights[i] = getweight(lat_arr_edges[i], lat_arr_edges[i+1])

    return weights

# get the weight of a single grid cell based on the bounding lat values
def getweight(start_lat, end_lat):
    if start_lat > 90:
        start_lat = 90
    if end_lat < -90:
        end_lat = -90

    # shift from lat lon to spherical coordinates (doesn't matter if values are negative, cos is even function)
    start_lat -= 90.0
    end_lat -= 90.0

    # to radians
    start_lat = start_lat * np.pi / 180
    end_lat = end_lat * np.pi / 180

    weight = np.cos(end_lat) - np.cos(start_lat)
    return weight

print("Fetching data... Warning could be slow! Please be patient")
for i in range(13):
    with nc.Dataset(indir+aij[i]) as dataset:
        print("Fetching data from {}".format(aij[i]))
        apar[i] = dataset['apar'][:]
        fapar[i] = dataset['fapar'][:]
        lai[i] = dataset['LAI'][:] # m2 m-2
        gpp[i] = dataset['gpp'][:] # gC m-2 day-1
        tsurf[i] = dataset['tsurf'][:] # C
        prec[i] = dataset['prec'][:] # mm day-1
        incsw_grnd[i] = dataset['incsw_grnd'][:]
        if (i == 12):
            soilfr = dataset['soilfr'][:]
            vsfr = dataset['vsfr'][:]
        for j in range(16):
            apar_pft[i,j] = dataset["ra042{:03d}".format(j+1)][:] / 4.05 # 4.05 umol m-2 s-2 -> W m-2 see modelE Ent/ent_const.f
            fapar_pft[i,j] = dataset["ra043{:03d}".format(j+1)][:]
            if (i == 12):
                lc_pft[j] = dataset["ra001{:03d}".format(j+1)][:]
                c_biomass[j] = dataset["ra017{:03d}".format(j+1)][:] - dataset["ra024{:03d}".format(j+1)][:]

# filter dataset
apar = np.where(apar >= 0., apar, 0) # W m-2
fapar = np.where(fapar >= 0., fapar, 0) # frac
apar_pft = np.where(apar_pft >= 0., apar_pft, 0) # W m-2
fapar_pft = np.where(fapar_pft >= 0., fapar_pft, 0) # frac
lc_pft = np.where(lc_pft >= 0., lc_pft, 0) # frac
soilfr = np.where(soilfr >= 0., soilfr * 0.01, 0) # frac
vsfr = np.where(vsfr >= 0., vsfr * 0.01, 0) # frac
c_biomass = np.where(c_biomass >= 0., c_biomass, 0) # kgC m-2 vf

# dominant LC
domlc = np.full((dimlat, dimlon), 999)
domlcval = np.zeros((dimlat, dimlon))
for i in range(16):
    isdominant = np.where(lc_pft[i] > domlcval, True, False)
    domlc = np.where(isdominant, i+1, domlc)
    domlcval = np.where(isdominant, lc_pft[i], domlcval)

# weights
wxyp = getweights(lat, lon)
axyp = wxyp * 5.1e14 / dimlon / 2

# sum biomass
c_biomass_sum = np.zeros((dimlat, dimlon))
for i in range(16):
    c_biomass_sum += axyp * c_biomass[i] * vsfr / 1e12 # PgC

# ocean mask
oceanmask = np.where(soilfr > 0., 0, 1)

print("Fetching biomes")
with nc.Dataset(biome_file) as dataset:
    biomes = dataset["KG"][:]

biomes = np.where(soilfr > 0., biomes, -999)

# plot maps

with PdfPages(outdir+outWWpdf) as WWpdf:
    #Ent PFT cover (dominant type)
    #Tsurf (C)
    #Precip (mm/yr)
    #PAR incident (W/m^2)
    fig = plt.figure(figsize=(20, 10))
    fig.suptitle("{} ({}) Maps Page 1".format(runname, canopy_model), fontsize = 30)
    m = Basemap(projection='cyl', resolution='c')

    plt.subplot(2,2,1)
    plt.title("Dominant Plant Functional Type")
    axi = m.imshow(domlc, interpolation='none', norm=colors.Normalize(vmin=0.5, vmax=18.5), cmap=ent_cmap)
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(1,19), format=mticker.FixedFormatter(["ever_br_early", "ever_br_late", "ever_nd_early", "ever_nd_late", "cold_br_early", "cold_br_late", "drought_br", "decid_nd", "cold_shrub", "arid_shrub", "c3_grass_per", "c4_grass", "c3_grass_ann", "c3_grass_arct", "crops_herb", "crops_woody", "bare_bright", "bare_dark"]))

    plt.subplot(2,2,2)
    plt.title("Mean Annual Surface Air Temperature")
    axi = m.imshow(tsurf[12], interpolation='none', norm=colors.Normalize(vmin=-40, vmax=40), cmap=panoply_cmap)
    #m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(-40,50,10), label="°C")

    plt.subplot(2,2,3)
    plt.title("Annual Precipitation")
    axi = m.imshow(prec[12]*365, interpolation='none', norm=colors.LogNorm(vmin=10, vmax=5000), cmap='Blues')
    #m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=[10, 100, 1000], label="mm/year")

    plt.subplot(2,2,4)
    plt.title("Incident Shortwave Radiation")
    axi = m.imshow(incsw_grnd[12], interpolation='none', norm=colors.Normalize(vmin=0, vmax=300), cmap='magma')
    #m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(0,350,50), label="W/m²")

    plt.tight_layout(rect=[0, 0.03, 1, 0.96])
    WWpdf.savefig()
    plt.close()

    ########################################################################

    #LAI: DJF, MAM, JJA, SON
    fig = plt.figure(figsize=(20, 10))
    fig.suptitle("{} ({}) Maps Page 2".format(runname, canopy_model), fontsize = 30)

    plt.subplot(2,2,1)
    plt.title("LAI (Winter = Dec, Jan, Feb)")
    axi = m.imshow((lai[11] + lai[0] + lai[1])/3, interpolation='none', norm=colors.Normalize(vmin=0, vmax=5), cmap='YlGn')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(0,6), label="m²/m²")

    plt.subplot(2,2,2)
    plt.title("LAI (Spring = Mar, Apr, May)")
    axi = m.imshow((lai[2] + lai[3] + lai[4])/3, interpolation='none', norm=colors.Normalize(vmin=0, vmax=5), cmap='YlGn')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(0,6), label="m²/m²")

    plt.subplot(2,2,3)
    plt.title("LAI (Summer = Jun, Jul, Aug)")
    axi = m.imshow((lai[5] + lai[6] + lai[7])/3, interpolation='none', norm=colors.Normalize(vmin=0, vmax=5), cmap='YlGn')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(0,6), label="m²/m²")

    plt.subplot(2,2,4)
    plt.title("LAI (Autumn = Sep, Oct, Nov)")
    axi = m.imshow((lai[8] + lai[9] + lai[10])/3, interpolation='none', norm=colors.Normalize(vmin=0, vmax=5), cmap='YlGn')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(0,6), label="m²/m²")

    plt.tight_layout(rect=[0, 0.03, 1, 0.96])
    WWpdf.savefig()
    plt.close()

    ########################################################################

    #APAR (per grid area= vsfr x wtd sum ra001)
    #APAR (per veg area = wtd sum ra001)
    #FAPAR (APAR over veg / IPAR over grid area)
    #FAPAR (per veg area = wtd sum ra001)
    fig = plt.figure(figsize=(20, 10))
    fig.suptitle("{} ({}) Maps Page 3".format(runname, canopy_model), fontsize = 30)

    plt.subplot(2,2,1)
    plt.title("APAR per grid area")
    axi = m.imshow(apar[12] * vsfr, interpolation='none', norm=colors.Normalize(vmin=0, vmax=300), cmap='cividis')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(0,350,50), label="W/m²")

    plt.subplot(2,2,2)
    plt.title("APAR per vegetated area")
    axi = m.imshow(apar[12], interpolation='none', norm=colors.Normalize(vmin=0, vmax=300), cmap='cividis')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=range(0,350,50), label="W/m²")

    plt.subplot(2,2,3)
    plt.title("FAPAR per grid area")
    axi = m.imshow(fapar[12] * vsfr, interpolation='none', norm=colors.Normalize(vmin=0, vmax=1), cmap=panoply_cmap)
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=np.arange(0,1.1,0.1), label="fraction")

    plt.subplot(2,2,4)
    plt.title("FAPAR per vegetated area")
    axi = m.imshow(fapar[12], interpolation='none', norm=colors.Normalize(vmin=0, vmax=1), cmap=panoply_cmap)
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=np.arange(0,1.1,0.1), label="fraction")

    plt.tight_layout(rect=[0, 0.03, 1, 0.96])
    WWpdf.savefig()
    plt.close()

    #Mean simulated biomass (PgC)
    #Mass Specific Power (APAR * axyp / biomass) (W gC-1)
    #GPP I guess
    #light use efficiency = GPP/APAR
    fig = plt.figure(figsize=(20, 10))
    fig.suptitle("{} ({}) Maps Page 4".format(runname, canopy_model), fontsize = 30)

    plt.subplot(2,2,1)
    plt.title("Mean Simulated Biomass")
    axi = m.imshow(c_biomass_sum, interpolation='none', norm=colors.Normalize(vmin=0, vmax=3), cmap='Greens')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, label="PgC")

    plt.subplot(2,2,2)
    plt.title("Mass-Specific Power")
    axi = m.imshow(apar[12] * axyp * vsfr / c_biomass_sum / 1e15, interpolation='none', norm=colors.LogNorm(vmin=1e-3, vmax=1e-1), cmap='plasma')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=[1e-3, 1e-2, 1e-1], label="W/gC")

    plt.subplot(2,2,3)
    plt.title("Annual Gross Primary Productivity")
    axi = m.imshow(gpp[12] * axyp * vsfr * 365 / 1e15, interpolation='none', norm=colors.Normalize(vmin=0, vmax=0.25), cmap='Greens')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, label="PgC")

    plt.subplot(2,2,4) # [ (gC / m2 / day) * (365 day / year) ] / [ (W / m2) * (86400 second / day) * (365 day / year) ]
    plt.title("Light Use Efficiency") # gC / MJ
    axi = m.imshow(gpp[12] / (apar[12] * 86400 / 1e6), interpolation='none', norm=colors.Normalize(vmin=0, vmax=1), cmap='inferno')
    m.imshow(oceanmask, interpolation='none', cmap=oceanmask_cmap)
    m.drawcoastlines()
    cbar = plt.colorbar(axi, ticks=np.arange(0, 1.2, 0.2), label="gC/MJ")

    plt.tight_layout(rect=[0, 0.03, 1, 0.96])
    WWpdf.savefig()
    plt.close()

with nc.Dataset(outdir+outfilename, mode='w', format=outNETCDF_format) as dataset, PdfPages(outdir+outAPARpdf) as APARpdf, PdfPages(outdir+outFAPARpdf) as FAPARpdf:
    dataset.setncattr("description", "Statistical regression of APAR (absorbed photosynthetically activate radiation) and FAPAR (fraction APAR / PAR) based on yearly diagnostics generated with ModelE Earth GCM, based on Koeppen-Geiger biome classification.")
    dataset.setncattr("date_created", datetime.today().strftime('%Y-%m-%d %H:%M:%S'))
    dataset.setncattr("runname", "Model run used to generate statistics: {}".format(runname))
    dataset.setncattr("canopy_model", canopy_model)
    dataset.setncattr("other_info", extra_info)
    dataset.setncattr("contact", "James.Lui@nasa.gov, Nancy.Y.Kiang@nasa.gov")
    dataset.setncattr("institution", "NASA Goddard Institute for Space Studies")

    dataset.createDimension('hemisphere', size=3)
    dataset.createDimension('lcn', size=18)
    dataset.createDimension('kgn', size=40)
    dataset.createDimension('month', size=13)
    dataset.createDimension('nbiomechars', size=3)
    dataset.createDimension('nbiomedescchars', size=59)
    dataset.createDimension('npftchars', size=13)
    dataset.createDimension('nmonthchars', size=9)
    dataset.createDimension('nhemichars', size=8)
    dataset.createDimension('lat', size=dimlat)
    dataset.createDimension('lon', size=dimlon)

    dataset.createVariable('hemisphere', 'S1', ('hemisphere', 'nhemichars'))
    #dataset.createVariable('lcn', 'i4', ('lcn'))
    dataset.createVariable('lcn', 'S1', ('lcn', 'npftchars'))
    #dataset.createVariable('kgn', 'i4', ('kgn'))
    dataset.createVariable('kgn', 'S1', ('kgn', 'nbiomechars'))
    dataset.createVariable('month', 'S1', ('month', 'nmonthchars'))
    #dataset.createVariable('KGcode', 'S1', ('kgn', 'nbiomechars'))
    dataset.createVariable('KGbiome', 'S1', ('kgn', 'nbiomedescchars'))
    #dataset.createVariable('ent_cover_names', 'S1', ('lcn', 'npftchars'))
    dataset.createVariable('lat', 'f4', ('lat'))
    dataset.createVariable('lon', 'f4', ('lon'))

    dataset['hemisphere'].setncattr("long_name", "Hemisphere - 1 = North, 2 = South, 3 = Global")
    #dataset['lcn'].setncattr("long_name", "Plant Functional Type")
    dataset['lcn'].setncattr("long_name", "Ent GISS cover type netcdf names")
    #dataset['kgn'].setncattr("long_name", "Koeppen-Geiger Climate Classification")
    dataset['kgn'].setncattr("long_name", "Koeppen-Geiger biome codes")
    dataset['month'].setncattr("long_name", "Month (13=Annual mean)")
    #dataset['KGcode'].setncattr("long_name", "Koeppen-Geiger biome codes")
    dataset['KGbiome'].setncattr("long_name", "Koeppen-Geiger biome description")
    #dataset['ent_cover_names'].setncattr("long_name", "Ent GISS cover type netcdf names")
    dataset['lat'].setncattr("long_name", "latitude")
    dataset['lat'].setncattr("units", "degrees_north")
    dataset['lon'].setncattr("long_name", "longitude")
    dataset['lon'].setncattr("units", "degrees_east")

    dataset['hemisphere'][:] = nc.stringtochar(hemisphere_names)
    dataset['hemisphere']._Encoding = 'ascii'
    #dataset['lcn'][:] = np.arange(1, 19)
    dataset['lcn'][:] = nc.stringtochar(lcn_names)
    dataset['lcn']._Encoding = 'ascii'
    #dataset['kgn'][:] = np.arange(1, 41)
    dataset['kgn'][:] = nc.stringtochar(biome_names)
    dataset['kgn']._Encoding = 'ascii'
    dataset['month'][:] = nc.stringtochar(month_names)
    dataset['month']._Encoding = 'ascii'
    dataset['lat'][:] = lat
    dataset['lon'][:] = lon

    #dataset['KGcode'][:] = nc.stringtochar(biome_names)
    #dataset['KGcode']._Encoding = 'ascii'

    dataset['KGbiome'][:] = nc.stringtochar(biome_desc)
    dataset['KGbiome']._Encoding = 'ascii'

    #dataset['ent_cover_names'][:] = nc.stringtochar(lcn_names)
    #dataset['ent_cover_names']._Encoding = 'ascii'

    dataset.createVariable("apar_global", 'f4', dimensions=('kgn', 'month', 'lat', 'lon'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("apar_pft", 'f4', dimensions=('lcn', 'kgn', 'month', 'lat', 'lon'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_global", 'f4', dimensions=('kgn', 'month', 'lat', 'lon'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_pft", 'f4', dimensions=('lcn', 'kgn', 'month', 'lat', 'lon'), fill_value=fillvalue, zlib=True)

    dataset.createVariable("apar_global_integrated", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("msp_avg", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("msp_std", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)

    dataset.createVariable("apar_global_avg", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("apar_global_std", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("apar_pft_avg", 'f4', dimensions=('lcn', 'kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("apar_pft_std", 'f4', dimensions=('lcn', 'kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_global_avg", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_global_std", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_pft_avg", 'f4', dimensions=('lcn', 'kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_pft_std", 'f4', dimensions=('lcn', 'kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)

    dataset.createVariable("par_global_samples", 'f4', dimensions=('kgn', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("par_pft_samples", 'f4', dimensions=('lcn', 'kgn', 'hemisphere'), fill_value=fillvalue, zlib=True)

    dataset['apar_global'].setncattr("long_name", "APAR Global Contribution Map by Koeppen-Geiger Biome and Month")
    dataset['apar_global_avg'].setncattr("long_name", "APAR Global Mean by Koeppen-Geiger Biome and Month")
    dataset['apar_global_std'].setncattr("long_name", "APAR Global Standard Deviation by Koeppen-Geiger Biome and Month")
    dataset['apar_pft'].setncattr("long_name", "APAR Map by Plant Functional Type, Koeppen-Geiger Biome, and Month")
    dataset['apar_pft_avg'].setncattr("long_name", "APAR Mean by Plant Functional Type, Koeppen-Geiger Biome, and Month")
    dataset['apar_pft_std'].setncattr("long_name", "APAR Standard Deviation by Plant Functional Type, Koeppen-Geiger Biome, and Month")

    dataset['apar_global_integrated'].setncattr("long_name", "APAR integrated over vegetated surface area by Koeppen-Geiger Biome and Month")
    dataset['msp_avg'].setncattr("long_name", "Mean Mass-Specific Power by Koeppen-Geiger Biome and Month")
    dataset['msp_std'].setncattr("long_name", "Standard Deviation Mass-Specific Power by Koeppen-Geiger Biome and Month")

    dataset['fapar_global'].setncattr("long_name", "FAPAR Global Contribution Map by Koeppen-Geiger Biome and Month")
    dataset['fapar_global_avg'].setncattr("long_name", "FAPAR Global Mean by Koeppen-Geiger Biome and Month")
    dataset['fapar_global_std'].setncattr("long_name", "FAPAR Global Standard Deviation by Koeppen-Geiger Biome and Month")
    dataset['fapar_pft'].setncattr("long_name", "FAPAR Map by Plant Functional Type, Koeppen-Geiger Biome, and Month")
    dataset['fapar_pft_avg'].setncattr("long_name", "FAPAR Mean by Plant Functional Type, Koeppen-Geiger Biome, and Month")
    dataset['fapar_pft_std'].setncattr("long_name", "FAPAR Standard Deviation by Plant Functional Type, Koeppen-Geiger Biome, and Month")

    dataset['par_global_samples'].setncattr("long_name", "Number of Samples by Koeppen-Geiger Biome")
    dataset['par_pft_samples'].setncattr("long_name", "Number of Samples by Plant Functional Type and Koeppen-Geiger Biome")

    dataset['apar_global'].setncattr("units", "W m-2")
    dataset['apar_global_avg'].setncattr("units", "W m-2")
    dataset['apar_global_std'].setncattr("units", "W m-2")
    dataset['apar_pft'].setncattr("units", "W m-2")
    dataset['apar_pft_avg'].setncattr("units", "W m-2")
    dataset['apar_pft_std'].setncattr("units", "W m-2")

    dataset['apar_global_integrated'].setncattr("units", "GJ")
    dataset['msp_avg'].setncattr("units", "W g-1")
    dataset['msp_std'].setncattr("units", "W g-1")

    dataset['fapar_global'].setncattr("units", "1")
    dataset['fapar_global_avg'].setncattr("units", "1")
    dataset['fapar_global_std'].setncattr("units", "1")
    dataset['fapar_pft'].setncattr("units", "1")
    dataset['fapar_pft_avg'].setncattr("units", "1")
    dataset['fapar_pft_std'].setncattr("units", "1")

    dataset['par_global_samples'].setncattr("units", "count")
    dataset['par_pft_samples'].setncattr("units", "count")

    ran = range(1,13)
    for PFT in range(17): # lcn
        if (PFT == 16):
            wxyp_lc = np.ma.MaskedArray(wxyp * soilfr, mask=np.ma.where(soilfr > 0., False, True))
            print("PFT: global")
        else:
            wxyp_lc = wxyp * lc_pft[PFT,:,:] * soilfr
            print("PFT: {}".format(lcn_names[PFT].decode('utf-8').strip()))
        for KG in range(40): # kgn
            for MON in range(13): # month

                KG_mask = np.where(biomes != KG+1, True, False)

                if (PFT == 16):
                    apar_mnth = apar[MON,:,:]
                    fapar_mnth = fapar[MON,:,:]
                    par_mask = np.full((dimlat, dimlon), False)

                    apar_mnth_intg = np.ma.MaskedArray(apar_mnth * vsfr * axyp * month_day[MON] / 1e9, mask=KG_mask)
                    msp_mnth_intg = apar_mnth * vsfr * axyp / c_biomass_sum / 1e15
                    msp_mnth_intg = np.ma.MaskedArray(np.ma.masked_invalid(msp_mnth_intg), mask=KG_mask)

                    # north
                    apar_intg[KG,MON,0] = apar_mnth_intg[dimlat//2:].sum()
                    msp_avg[KG,MON,0] = np.ma.average(msp_mnth_intg[dimlat//2:], weights=wxyp_lc[dimlat//2:])
                    try:
                        msp_std[KG,MON,0] = sqrt(np.ma.average((msp_mnth_intg[dimlat//2:]-msp_avg[KG,MON,0])**2, weights=wxyp_lc[dimlat//2:]))
                    except ValueError:
                        pass
                    # south
                    apar_intg[KG,MON,1] = apar_mnth_intg[:dimlat//2].sum()
                    msp_avg[KG,MON,1] = np.ma.average(msp_mnth_intg[:dimlat//2], weights=wxyp_lc[:dimlat//2])
                    try:
                        msp_std[KG,MON,1] = sqrt(np.ma.average((msp_mnth_intg[:dimlat//2]-msp_avg[KG,MON,1])**2, weights=wxyp_lc[:dimlat//2]))
                    except ValueError:
                        pass
                    # global
                    apar_intg[KG,MON,2] = apar_mnth_intg.sum()
                    msp_avg[KG,MON,2] = np.ma.average(msp_mnth_intg, weights=wxyp_lc)
                    try:
                        msp_std[KG,MON,2] = sqrt(np.ma.average((msp_mnth_intg-msp_avg[KG,MON,2])**2, weights=wxyp_lc))
                    except ValueError:
                        pass
                else:
                    apar_mnth = apar_pft[MON,PFT,:,:]
                    fapar_mnth = fapar_pft[MON,PFT,:,:]
                    par_mask = np.where(lc_pft[PFT,:,:] == 0, True, False)

                KGpar_mask = np.logical_or(KG_mask,par_mask)
                apar_masked = np.ma.MaskedArray(apar_mnth, mask=KGpar_mask)
                fapar_masked = np.ma.MaskedArray(fapar_mnth, mask=KGpar_mask)

                # north
                apar_avg[PFT,KG,MON,0] = np.ma.average(apar_masked[dimlat//2:], weights=wxyp_lc[dimlat//2:])
                fapar_avg[PFT,KG,MON,0] = np.ma.average(fapar_masked[dimlat//2:,:], weights=wxyp_lc[dimlat//2:])
                try:
                    apar_std[PFT,KG,MON,0] = sqrt(np.ma.average((apar_masked[dimlat//2:]-apar_avg[PFT,KG,MON,0])**2, weights=wxyp_lc[dimlat//2:]))
                    fapar_std[PFT,KG,MON,0] = sqrt(np.ma.average((fapar_masked[dimlat//2:]-fapar_avg[PFT,KG,MON,0])**2, weights=wxyp_lc[dimlat//2:]))
                except ValueError:
                    pass
                # south
                apar_avg[PFT,KG,MON,1] = np.ma.average(apar_masked[:dimlat//2], weights=wxyp_lc[:dimlat//2])
                fapar_avg[PFT,KG,MON,1] = np.ma.average(fapar_masked[:dimlat//2], weights=wxyp_lc[:dimlat//2])
                try:
                    apar_std[PFT,KG,MON,1] = sqrt(np.ma.average((apar_masked[:dimlat//2]-apar_avg[PFT,KG,MON,1])**2, weights=wxyp_lc[:dimlat//2]))
                    fapar_std[PFT,KG,MON,1] = sqrt(np.ma.average((fapar_masked[:dimlat//2]-fapar_avg[PFT,KG,MON,1])**2, weights=wxyp_lc[:dimlat//2]))
                except ValueError:
                    pass
                # global
                apar_avg[PFT,KG,MON,2] = np.ma.average(apar_masked, weights=wxyp_lc)
                fapar_avg[PFT,KG,MON,2] = np.ma.average(fapar_masked, weights=wxyp_lc)
                try:
                    apar_std[PFT,KG,MON,2] = sqrt(np.ma.average((apar_masked-apar_avg[PFT,KG,MON,2])**2, weights=wxyp_lc))
                    fapar_std[PFT,KG,MON,2] = sqrt(np.ma.average((fapar_masked-fapar_avg[PFT,KG,MON,2])**2, weights=wxyp_lc))
                except ValueError:
                    pass

                #print(PFT,KG,MON,apar_avg[PFT,KG,MON,2],apar_std[PFT,KG,MON,2])
                apar_kgn[KG,MON,:,:] = apar_masked.filled(np.nan)
                fapar_kgn[KG,MON,:,:] = fapar_masked.filled(np.nan)

            par_num[PFT,KG,0] = apar_masked[dimlat//2:].count()
            par_num[PFT,KG,1] = apar_masked[:dimlat//2].count()
            par_num[PFT,KG,2] = apar_masked.count()

        # APAR
        fig = plt.figure(figsize=(30, 20))
        if (PFT == 16):
            fig.suptitle("Global APAR {} ({})".format(runname, canopy_model), fontsize = 30)
        else:
            fig.suptitle("{} APAR {} ({})".format(lcn_names[PFT].decode('utf-8').strip(), runname, canopy_model), fontsize = 30)
        for KG in range(40):
            plt.subplot(8, 5, KG+1)
            plt.title(biome_desc[KG].decode('utf-8').strip())
            plt.ylabel("APAR (W m-2)")
            plt.xlabel("Month")
            plt.plot(ran, apar_avg[PFT,KG,:-1,2], color='red', label="Global n={}".format(par_num[PFT,KG,2]))
            plt.fill_between(ran, apar_avg[PFT,KG,:-1,2]+apar_std[PFT,KG,:-1,2], apar_avg[PFT,KG,:-1,2]-apar_std[PFT,KG,:-1,2], color='red', alpha=0.1)
            plt.plot(ran, apar_avg[PFT,KG,:-1,0], color='green', label="Northern n={}".format(par_num[PFT,KG,0]))
            plt.fill_between(ran, apar_avg[PFT,KG,:-1,0]+apar_std[PFT,KG,:-1,0], apar_avg[PFT,KG,:-1,0]-apar_std[PFT,KG,:-1,0], color='green', alpha=0.1)
            plt.plot(ran, apar_avg[PFT,KG,:-1,1], color='blue', label="Southern n={}".format(par_num[PFT,KG,1]))
            plt.fill_between(ran, apar_avg[PFT,KG,:-1,1]+apar_std[PFT,KG,:-1,1], apar_avg[PFT,KG,:-1,1]-apar_std[PFT,KG,:-1,1], color='blue', alpha=0.1)
            plt.ylim(bottom=0) # have to set it after plotting
            plt.legend(framealpha=0.1)
        plt.tight_layout(rect=[0, 0.03, 1, 0.96])
        APARpdf.savefig()
        plt.close()

        # FAPAR
        fig = plt.figure(figsize=(30, 20))
        if (PFT == 16):
            fig.suptitle("Global FAPAR {} ({})".format(runname, canopy_model), fontsize = 30)
        else:
            fig.suptitle("{} FAPAR {} ({})".format(lcn_names[PFT].decode('utf-8').strip(), runname, canopy_model), fontsize = 30)
        for KG in range(40):
            plt.subplot(8, 5, KG+1)
            plt.title(biome_desc[KG].decode('utf-8').strip())
            plt.ylabel("FAPAR (frac)")
            plt.xlabel("Month")
            plt.ylim(0, 1)
            plt.plot(ran, fapar_avg[PFT,KG,:-1,2], color='red', label="Global n={}".format(par_num[PFT,KG,2]))
            plt.fill_between(ran, fapar_avg[PFT,KG,:-1,2]+fapar_std[PFT,KG,:-1,2], fapar_avg[PFT,KG,:-1,2]-fapar_std[PFT,KG,:-1,2], color='red', alpha=0.1)
            plt.plot(ran, fapar_avg[PFT,KG,:-1,0], color='green', label="Northern n={}".format(par_num[PFT,KG,0]))
            plt.fill_between(ran, fapar_avg[PFT,KG,:-1,0]+fapar_std[PFT,KG,:-1,0], fapar_avg[PFT,KG,:-1,0]-fapar_std[PFT,KG,:-1,0], color='green', alpha=0.1)
            plt.plot(ran, fapar_avg[PFT,KG,:-1,1], color='blue', label="Southern n={}".format(par_num[PFT,KG,1]))
            plt.fill_between(ran, fapar_avg[PFT,KG,:-1,1]+fapar_std[PFT,KG,:-1,1], fapar_avg[PFT,KG,:-1,1]-fapar_std[PFT,KG,:-1,1], color='blue', alpha=0.1)
            plt.legend(framealpha=0.1)
        plt.tight_layout(rect=[0, 0.03, 1, 0.96])
        FAPARpdf.savefig()
        plt.close()

        if (PFT == 16):
            dataset['apar_global'][:,:,:,:] = apar_kgn
            dataset['fapar_global'][:,:,:,:] = fapar_kgn
            dataset['apar_global_avg'][:,:,:] = apar_avg[PFT,:,:,:]
            dataset['fapar_global_avg'][:,:,:] = fapar_avg[PFT,:,:,:]
            dataset['apar_global_std'][:,:,:] = apar_std[PFT,:,:,:]
            dataset['fapar_global_std'][:,:,:] = fapar_std[PFT,:,:,:]
            dataset['par_global_samples'][:,:] = par_num[PFT,:,:]
            dataset['apar_global_integrated'][:,:,:] = apar_intg
            dataset['msp_avg'][:,:,:] = msp_avg
            dataset['msp_std'][:,:,:] = msp_std
        else:
            dataset['apar_pft'][PFT,:,:,:,:] = apar_kgn
            dataset['fapar_pft'][PFT,:,:,:,:] = fapar_kgn
            dataset['apar_pft_avg'][PFT,:,:,:] = apar_avg[PFT,:,:,:]
            dataset['fapar_pft_avg'][PFT,:,:,:] = fapar_avg[PFT,:,:,:]
            dataset['apar_pft_std'][PFT,:,:,:] = apar_std[PFT,:,:,:]
            dataset['fapar_pft_std'][PFT,:,:,:] = fapar_std[PFT,:,:,:]
            dataset['par_pft_samples'][PFT,:,:] = par_num[PFT,:,:]

    fig = plt.figure(figsize=(30, 20))
    fig.suptitle("Monthly Integrated APAR {} ({})".format(runname, canopy_model), fontsize = 30)
    for KG in range(40):
        plt.subplot(8, 5, KG+1)
        plt.title(biome_desc[KG].decode('utf-8').strip())
        plt.ylabel("Integrated APAR (GJ/month)")
        plt.xlabel("Month")
        plt.plot(ran, apar_intg[KG,:-1,2], color='red', label="Global n={}".format(par_num[PFT,KG,2]))
        plt.plot(ran, apar_intg[KG,:-1,0], color='green', label="Northern n={}".format(par_num[PFT,KG,0]))
        plt.plot(ran, apar_intg[KG,:-1,1], color='blue', label="Southern n={}".format(par_num[PFT,KG,1]))
        plt.ylim(bottom=0)
        plt.legend(framealpha=0.1)
    plt.tight_layout(rect=[0, 0.03, 1, 0.96])
    APARpdf.savefig()
    plt.close()

    fig = plt.figure(figsize=(30, 20))
    fig.suptitle("Mass Specific Power {} ({})".format(runname, canopy_model), fontsize = 30)
    for KG in range(40):
        plt.subplot(8, 5, KG+1)
        plt.title(biome_desc[KG].decode('utf-8').strip())
        plt.ylabel("MSP (W/gC)")
        plt.xlabel("Month")
        plt.plot(ran, msp_avg[KG,:-1,2], color='red', label="Global n={}".format(par_num[PFT,KG,2]))
        plt.fill_between(ran, msp_avg[KG,:-1,2]+msp_std[KG,:-1,2], msp_avg[KG,:-1,2]-msp_std[KG,:-1,2], color='red', alpha=0.1)
        plt.plot(ran, msp_avg[KG,:-1,0], color='green', label="Northern n={}".format(par_num[PFT,KG,0]))
        plt.fill_between(ran, msp_avg[KG,:-1,0]+msp_std[KG,:-1,0], msp_avg[KG,:-1,0]-msp_std[KG,:-1,0], color='green', alpha=0.1)
        plt.plot(ran, msp_avg[KG,:-1,1], color='blue', label="Southern n={}".format(par_num[PFT,KG,1]))
        plt.fill_between(ran, msp_avg[KG,:-1,1]+msp_std[KG,:-1,1], msp_avg[KG,:-1,1]-msp_std[KG,:-1,1], color='blue', alpha=0.1)
        plt.ylim(bottom=0)
        plt.legend(framealpha=0.1)
    plt.tight_layout(rect=[0, 0.03, 1, 0.96])
    APARpdf.savefig()
    plt.close()
