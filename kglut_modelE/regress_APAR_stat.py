# generates statistics APAR/FAPAR by biome
# contact james.lui@nasa.gov nancy.y.kiang@nasa.gov

import numpy as np
from datetime import datetime
import netCDF4 as nc
import matplotlib.pyplot as plt
from matplotlib.backends.backend_pdf import PdfPages
from math import sqrt, isnan
import warnings
warnings.filterwarnings('ignore', category=UserWarning)

indir = "@@INDIR"
biome_file = "@@BIOME" 

outdir = "@@OUTDIR"
outfilename = "@@OUT_NC"
outAPARpdf = "@@OUT_APAR_PDF"
outFAPARpdf = "@@OUT_FAPAR_PDF"
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

apar_pft = np.empty((13, 18, dimlat, dimlon)) # ra042
fapar_pft = np.empty((13, 18, dimlat, dimlon)) # ra043
lc_pft = np.empty((18, dimlat, dimlon)) # ra001

# Store output statistics
apar_avg = np.empty((17, 40, 13, 3))
fapar_avg = np.empty((17, 40, 13, 3)) # PFT, KG, MONTH, HEMISPHERE
apar_std = np.empty((17, 40, 13, 3))
fapar_std = np.empty((17, 40, 13, 3))
par_num = np.empty((17, 40, 3), dtype=int)
apar_kgn = np.empty((40, 13, dimlat, dimlon))
fapar_kgn = np.empty((40, 13, dimlat, dimlon))

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

month_names = np.array(["January  ", "February ", "March    ", "April    ", "May      ", "June     ", "July     ", "August   ", "September", "October  ", "November ", "December "], dtype='S9')

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
        if (i == 0):
            soilfr = dataset['soilfr'][:]
        for j in range(16):
            apar_pft[i,j] = dataset["ra042{:03d}".format(j+1)][:]
            fapar_pft[i,j] = dataset["ra043{:03d}".format(j+1)][:]
            if (i == 0):
                lc_pft[j] = dataset["ra001{:03d}".format(j+1)][:]

# filter dataset
apar = np.where(apar >= 0., apar, 0)
fapar = np.where(fapar >= 0., fapar, 0)
apar_pft = np.where(apar_pft >= 0., apar_pft, 0)
fapar_pft = np.where(fapar_pft >= 0., fapar_pft, 0)
lc_pft = np.where(lc_pft >= 0., lc_pft, 0)
soilfr = np.where(soilfr >= 0., soilfr, 0)

print("Fetching biomes")
with nc.Dataset(biome_file) as dataset:
    biomes = dataset["KG"][:]

biomes = np.where(soilfr > 0., biomes, -999)

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
    #dataset.createDimension('nmonthchars', size=9)
    dataset.createDimension('nhemichars', size=8)
    dataset.createDimension('lat', size=dimlat)
    dataset.createDimension('lon', size=dimlon)

    dataset.createVariable('hemisphere', 'i4', ('hemisphere'))
    dataset.createVariable('lcn', 'i4', ('lcn'))
    dataset.createVariable('kgn', 'i4', ('kgn'))
    dataset.createVariable('month', 'i4', ('month'))
    dataset.createVariable('KGcode', 'S1', ('kgn', 'nbiomechars'))
    dataset.createVariable('KGbiome', 'S1', ('kgn', 'nbiomedescchars'))
    dataset.createVariable('ent_cover_names', 'S1', ('lcn', 'npftchars'))
    dataset.createVariable('lat', 'f4', ('lat'))
    dataset.createVariable('lon', 'f4', ('lon'))

    dataset['hemisphere'].setncattr("long_name", "Hemisphere - 1 = North, 2 = South, 3 = Global")
    dataset['lcn'].setncattr("long_name", "Plant Functional Type")
    dataset['kgn'].setncattr("long_name", "Koeppen-Geiger Climate Classification")
    dataset['month'].setncattr("long_name", "Month (13=Annual mean)")
    dataset['KGcode'].setncattr("long_name", "Koeppen-Geiger biome codes")
    dataset['KGbiome'].setncattr("long_name", "Koeppen-Geiger biome description")
    dataset['ent_cover_names'].setncattr("long_name", "Ent GISS cover type netcdf names")
    dataset['lat'].setncattr("long_name", "latitude")
    dataset['lat'].setncattr("units", "degrees_north")
    dataset['lon'].setncattr("long_name", "longitude")
    dataset['lon'].setncattr("units", "degrees_east")


    dataset['hemisphere'][:] = [1, 2, 3]
    dataset['lcn'][:] = np.arange(1, 19)
    dataset['kgn'][:] = np.arange(1, 41)
    dataset['month'][:] = time
    dataset['lat'][:] = lat
    dataset['lon'][:] = lon

    dataset['KGcode'][:] = nc.stringtochar(biome_names)
    dataset['KGcode']._Encoding = 'ascii'

    dataset['KGbiome'][:] = nc.stringtochar(biome_desc)
    dataset['KGbiome']._Encoding = 'ascii'

    dataset['ent_cover_names'][:] = nc.stringtochar(lcn_names)
    dataset['ent_cover_names']._Encoding = 'ascii'

    dataset.createVariable("apar_global", 'f4', dimensions=('kgn', 'month', 'lat', 'lon'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_global", 'f4', dimensions=('kgn', 'month', 'lat', 'lon'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("apar_pft", 'f4', dimensions=('lcn', 'kgn', 'month', 'lat', 'lon'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_pft", 'f4', dimensions=('lcn', 'kgn', 'month', 'lat', 'lon'), fill_value=fillvalue, zlib=True)

    dataset.createVariable("apar_global_avg", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_global_avg", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("apar_global_std", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_global_std", 'f4', dimensions=('kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("apar_pft_avg", 'f4', dimensions=('lcn', 'kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_pft_avg", 'f4', dimensions=('lcn', 'kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("apar_pft_std", 'f4', dimensions=('lcn', 'kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("fapar_pft_std", 'f4', dimensions=('lcn', 'kgn', 'month', 'hemisphere'), fill_value=fillvalue, zlib=True)

    dataset.createVariable("par_global_samples", 'f4', dimensions=('kgn', 'hemisphere'), fill_value=fillvalue, zlib=True)
    dataset.createVariable("par_pft_samples", 'f4', dimensions=('lcn', 'kgn', 'hemisphere'), fill_value=fillvalue, zlib=True)

    dataset['apar_global'].setncattr("long_name", "APAR Global Contribution Map by Koeppen-Geiger Biome and Month")
    dataset['apar_global_avg'].setncattr("long_name", "APAR Global Mean by Koeppen-Geiger Biome and Month")
    dataset['apar_global_std'].setncattr("long_name", "APAR Global Standard Deviation by Koeppen-Geiger Biome and Month")
    dataset['apar_pft'].setncattr("long_name", "APAR Map by Plant Functional Type, Koeppen-Geiger Biome, and Month")
    dataset['apar_pft_avg'].setncattr("long_name", "APAR Mean by Plant Functional Type, Koeppen-Geiger Biome, and Month")
    dataset['apar_pft_std'].setncattr("long_name", "APAR Standard Deviation by Plant Functional Type, Koeppen-Geiger Biome, and Month")

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

    dataset['fapar_global'].setncattr("units", "1")
    dataset['fapar_global_avg'].setncattr("units", "1")
    dataset['fapar_global_std'].setncattr("units", "1")
    dataset['fapar_pft'].setncattr("units", "1")
    dataset['fapar_pft_avg'].setncattr("units", "1")
    dataset['fapar_pft_std'].setncattr("units", "1")

    dataset['par_global_samples'].setncattr("units", "count")
    dataset['par_pft_samples'].setncattr("units", "count")

    # weights
    wxyp = getweights(lat, lon)

    for PFT in range(17): # lcn
        if (PFT == 16):
            wxyp_lc = np.ma.MaskedArray(wxyp, mask=np.ma.where(soilfr > 0., False, True))
            print("PFT: global")
        else:
            wxyp_lc = wxyp * lc_pft[PFT,:,:]
            print("PFT: {}".format(lcn_names[PFT].decode('utf-8').strip()))
        for KG in range(40): # kgn
            for MON in range(13): # month
                if (PFT == 16):
                    apar_mnth = apar[MON,:,:]
                    fapar_mnth = fapar[MON,:,:]
                    par_mask = np.full((dimlat, dimlon), False)
                else:
                    apar_mnth = apar_pft[MON,PFT,:,:]
                    fapar_mnth = fapar_pft[MON,PFT,:,:]
                    par_mask = np.where(lc_pft[PFT,:,:] == 0, True, False)
                KG_mask = np.where(biomes != KG+1, True, False)
                apar_masked = np.ma.MaskedArray(apar_mnth, mask=np.logical_or(KG_mask,par_mask))
                fapar_masked = np.ma.MaskedArray(fapar_mnth, mask=np.logical_or(KG_mask,par_mask))

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

        ran = range(1,13)
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
        else:
            dataset['apar_pft'][PFT,:,:,:,:] = apar_kgn
            dataset['fapar_pft'][PFT,:,:,:,:] = fapar_kgn
            dataset['apar_pft_avg'][PFT,:,:,:] = apar_avg[PFT,:,:,:]
            dataset['fapar_pft_avg'][PFT,:,:,:] = fapar_avg[PFT,:,:,:]
            dataset['apar_pft_std'][PFT,:,:,:] = apar_std[PFT,:,:,:]
            dataset['fapar_pft_std'][PFT,:,:,:] = fapar_std[PFT,:,:,:]
            dataset['par_pft_samples'][PFT,:,:] = par_num[PFT,:,:]
