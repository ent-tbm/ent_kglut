# Changes the ent covers to account for evolutionary history of plants
# @auth James Lui james.lui@nasa.gov Februrary 2025
# @contact Nancy Kiang nancy.y.kiang@nancy.gov

import netCDF4 as nc
import numpy as np
from datetime import datetime
import os, sys, argparse

parser = argparse.ArgumentParser()
parser.add_argument('-i', '--input', nargs='+', required=True, help='List of modelE standard input files for land cover types.')
parser.add_argument('-o', '--output', nargs='*', help='List of output file names (must match number of input files). Otherwise t is appended to file name')
parser.add_argument('-t', '--time', nargs=1, required=True, help='Time in Ma for vegetation changes.')
parser.add_argument('-fmt', '-f', '--format', nargs='?', help='NetCDF format of output dataset(s).')

args = parser.parse_args()

valid_netcdf_fmt = ['NETCDF3_CLASSIC', 'NETCDF3_64BIT_OFFSET', 'NETCDF3_64BIT_DATA', 'NETCDF4_CLASSIC', 'NETCDF4']

for k, v in vars(args).items():
    if (k == 'input'):
        infiles = v
    elif (k == 'output'):
        outfiles = v
    elif (k == 'format'):
        nc_format = v.upper() if v is not None else 'NETCDF3_CLASSIC'
        if nc_format not in valid_netcdf_fmt:
            print("Invalid NetCDF format {}".format(nc_format))
            exit(1)
    elif (k == 'time'):
        time = v[0]
        try:
            time = float(time)
            if (time < 0. or time > 540.):
                raise ValueError
        except ValueError:
            print("Invalid time {} Ma.".format(time))
            exit(1)

for infile in infiles:
    if (not os.path.isfile(infile)):
        print("Specified file {} does not exist, exiting...".format(infile))
        exit(3)

if (outfiles is None):
    outfiles = ["{}_{}Ma.nc".format(infile[:-3], time) for infile in infiles]

if (len(outfiles) != len(infiles)):
    print("Number of output files does not match number of input files")
    exit(4)

fillvalue_giss = -1e30
replacements = ""

varname = 0
longname = 1
evolved = 2 # time pft first evolved
rampup = 3 # ramp up time, i.e. from 100% replacement to 0% replacement

pfts = { # varname longname 
    1 : ["ever_br_early", "1 - Evergeen Broadleaf Early Succ", 145, 40], 
    2 : ["ever_br_late", "2 - Evergreen Broadleaf Late Succ", 145, 40],
    3 : ["ever_nd_early", "3 - Evergreen Needleleaf Early Succ", 4540, 0], # not set in code yet 380, 40
    4 : ["ever_nd_late", "4 - Evergreen Needleleaf Late Succ", 4540, 0], # not set in code yet 380, 40
    5 : ["cold_br_early", "5 - Cold Deciduous Broadleaf Early Succ", 66, 46], 
    6 : ["cold_br_late", "6 - Cold Deciduous Broadleaf Late Succ", 66, 46],
    7 : ["drought_br", "7 - Drought Deciduous Broadleaf", 66, 46],
    8 : ["decid_nd", "8 - Deciduous Needleleaf", 120, 40], 
    9 : ["cold_shrub", "9 - Cold Adapted Shrub", 4540, 0], # not set in code yet 360, 60
    10: ["arid_shrub", "10 - Arid Adapted Shrub", 4540, 0], # not set in code yet 420, 60
    11: ["c3_grass_per", "11 - C3 Grass Perennial", 80, 30], 
    12: ["c4_grass", "12 - C4 Grass", 32, 24], 
    13: ["c3_grass_ann", "13 - C3 Grass Annual", 80, 30], 
    14: ["c3_grass_arct", "14 - Arctic C3 Grass", 47.5, 21.5], 
    15: ["crops_herb", "15 - Crops Herb", 0, 0], 
    16: ["crops_woody", "16 - Crops Woody", 0, 0], 
    17: ["bare_bright", "17 - Bright Bare Soil", 4540, 0],
    18: ["bare_dark", "18 - Dark Bare Soil", 4540, 0]
    }

# shadeTolerance = [None, None, 60, 10]

# PFT replacement scheme. Rule is only invoked if replacement is necessary for specified time period.

# a value = proportional replacement values scaled by land cover, if the listed PFT exists
# b value = proportional replacement values, if no listed PFT exist

# example: PFT1 : [[PFT2, 1, 0], [PFT3, 1, 1]] at 100% replacement

# suppose initial fractions: PFT1 = 30%, PFT2 = 15%, PFT3 = 15%
# final fractions:           PFT1 =  0%, PFT2 = 30%, PFT3 = 30%

# suppose initial fractions: PFT1 = 30%, PFT2 = 10%, PFT3 = 20%
# final fractions:           PFT1 =  0%, PFT2 = 20%, PFT3 = 40%

# suppose initial fractions: PFT1 = 30%, PFT2 = 10%, PFT3 =  0%
# final fractions:           PFT1 =  0%, PFT2 = 40%, PFT3 =  0%

# suppose initial fractions: PFT1 = 30%, PFT2 =  0%, PFT3 =  0%
# final fractions:           PFT1 =  0%, PFT2 =  0%, PFT3 = 30%

# this allows for biased replacements, should it be needed
# example: PFT1 : [[PFT2, 2, 1], [PFT3, 1, 2]] at 100% replacement

# suppose initial fractions: PFT1 = 30%, PFT2 = 15%, PFT3 = 15%
# final fractions:           PFT1 =  0%, PFT2 = 35%, PFT3 = 25%

# suppose initial fractions: PFT1 = 30%, PFT2 = 10%, PFT3 = 20%
# final fractions:           PFT1 =  0%, PFT2 = 25%, PFT3 = 35%

# suppose initial fractions: PFT1 = 30%, PFT2 = 10%, PFT3 =  0%
# final fractions:           PFT1 =  0%, PFT2 = 40%, PFT3 =  0%

# suppose initial fractions: PFT1 = 30%, PFT2 =  0%, PFT3 =  0%
# final fractions:           PFT1 =  0%, PFT2 = 10%, PFT3 = 20%

pftreplace = { # [pft, a value, b value]
    1 : [[3, 1, 1]], # ever_br_early
    2 : [[4, 1, 1]], # ever_br_late
    3 : [[9, 1, 0], [10, 2, 1], [17, 0, 0.3], [18, 0, 0.7]], # ever_nd_early
    4 : [[9, 1, 0], [10, 2, 1], [17, 0, 0.3], [18, 0, 0.7]], # ever_nd_late
    5 : [[3, 1, 0]], # cold_br_early
    6 : [[4, 1, 0]], # cold_br_late
    7 : [[4, 1, 0]], # drought_br
    8 : [[4, 1, 0]], # decid_nd
    9 : [[10, 1, 1]], # cold_shrub
    10: [[17, 0, 0.6], [18, 0, 0.4]], # arid_shrub
    11: [[17, 0, 0.3], [18, 0, 0.7]], # c3_grass_per
    12: [[11, 1, 1], [13, 1, 0], [14, 1, 0]], # c4_grass
    13: [[17, 0, 0.3], [18, 0, 0.7]], # c3_grass_ann
    14: [[11, 1, 1]], # c3_grass_arct
    15: [[11, 0.5, 0.2], [13, 0.5, 0.8], [17, 0, 0.1], [18, 0, 0.2]], # crops_herb
    16: [[2, 1, 0], [4, 1, 0], [6, 1, 0], [7, 1, 0], [17, 0, 0.1], [18, 0, 0.2]], # crops_woody
    17: [], # bare_bright
    18: [], # bare_dark
}

# lc - LC array
# dimlat - length of latitude
# dimlon - length of longitude
# pftin - PFT to be replaced (note this is PFT number not array number)
# pftinreplacefrac - fraction of PFT that is to be replaced
# pftout - list of PFTs to gain replaced fraction
# pftoutweights - weights of gain for listed PFTs
# pftfallback - fallback replacement if pftout does not exist in gridcell
# pftfallbackweights - fallback weights
def replacePFTlc(lc, dimlat, dimlon, pftin, pftinreplacefrac, pftout, pftoutweights, pftfallback=None, pftfallbackweights=None):
    assert len(pftout) == len(pftoutweights), "Listed PFTs must be equal in number to listed weights"
    assert len(pftout) != 0

    if (pftinreplacefrac <= 0):
        return

    if (pftfallback is not None):
        if (pftfallbackweights is not None):
            assert len(pftfallback) == len(pftfallbackweights), "Listed PFTs must be equal in number to listed weights"
        else:
            raise Exception("Fallback weights not specified")
    
    defaultpftfallback = [17, 18]
    defaultpftoutweights = [0.3, 0.7]

    if (sum(pftoutweights) == 0): # no weights provided, assume same
        pftoutweights[:] = 1

    if (pftfallbackweights is not None and sum(pftfallbackweights) == 0):
        pftfallbackweights = 1

    for i in range(dimlat):
        for j in range(dimlon):
            replace_lc = lc[pftin-1,i,j] * pftinreplacefrac
            if (replace_lc <= 0): # do nothing if there is nothing to replace
                continue
            lc[pftin-1,i,j] *= 1 - pftinreplacefrac
            validpftreplace = []
            validpftreplaceweights = []
            for k in range(len(pftout)):
                if (lc[pftout[k]-1,i,j] > 0): # check for PFTs from list that exist
                    validpftreplace.append(pftout[k])
                    validpftreplaceweights.append(pftoutweights[k] * lc[pftout[k]-1,i,j])
            if (len(validpftreplace) > 0):
                validpftreplaceweights /= sum(validpftreplaceweights)
                for k in range(len(validpftreplace)):
                    lc[validpftreplace[k]-1,i,j] += validpftreplaceweights[k] * replace_lc
            elif (pftfallback is not None):
                pftfallbackweights /= sum(pftfallbackweights)
                for k in range(len(pftfallback)):
                    lc[pftfallback[k]-1,i,j] += pftfallbackweights[k] * replace_lc
            else:
                for k in range(len(defaultpftfallback)):
                    lc[defaultpftfallback[k]-1,i,j] += defaultpftoutweights[k] * replace_lc

# returns fraction of PFT that should be replaced
def getreplacefrac(time, timeevolved, rampuptime):
    if (time > timeevolved):
        return 1
    elif (time > timeevolved - rampuptime):
        return (time - timeevolved + rampuptime) / rampuptime
    else:
        return 0

# returns input parameters for replacePFTlc from table parameters
def translateTable(table):
    pftout = []
    pftoutweights = []
    pftfallback = []
    pftfallbackweights = []

    n_entries = 0

    table = np.array(table)
    for i in range(len(table)):
        if (table[i,1] > 0):
            pftout.append(int(table[i,0]))
            pftoutweights.append(table[i,1])
            n_entries += 1
        if (table[i,2] > 0):
            pftfallback.append(int(table[i,0]))
            pftfallbackweights.append(table[i,2])
            n_entries += 1

    if (n_entries == 0):
        return [17, 18], [0.3, 0.7], None, None
    if (len(pftfallback) == 0):
        return pftout, pftoutweights, None, None
    elif (len(pftout) == 0):
        return pftfallback, pftfallbackweights, None, None
    else:
        return pftout, pftoutweights, pftfallback, pftfallbackweights

# wrapper for replacement
def replace(pft):
    f_replace = getreplacefrac(time, pfts[pft][evolved], pfts[pft][rampup])
    replace_str = ""
    if (f_replace > 0):
        i,j,k,l = translateTable(pftreplace[pft])
        #print(pfts[pft][varname], f_replace, i, j, k, l)

        replace_str = "Replace {:.2f}% of {} with:".format(f_replace*100, pfts[pft][varname])
        for a in range(len(i)):
            replace_str += " {}, wt={:.2f};".format(pfts[i[a]][varname], j[a])

        if (k is not None):
            replace_str = "{}. Default replacement:".format(replace_str[:-1])
            for a in range(len(k)):
                replace_str += " {}, wt={:.2f};".format(pfts[k[a]][varname], l[a])

        replace_str = "{}.\n".format(replace_str[:-1])
        print(replace_str, end="")

        replacePFTlc(lc_pft, dimlat, dimlon, pft, f_replace, i, j, k, l)
    return replace_str

for infile, outfile in zip(infiles, outfiles):
    with nc.Dataset(infile) as src, nc.Dataset(outfile, "w", format=nc_format) as dst:

        # copy global attributes all at once via dictionary
        dst.setncatts(src.__dict__)
        dst.setncattr("simulated_lc_time", "{}Ma".format(time))
        dst.setncattr("date_created", datetime.today().strftime('%Y-%m-%d %H:%M:%S'))

        # copy dimensions
        for name, dimension in src.dimensions.items():
            dst.createDimension(name, (len(dimension) if not dimension.isunlimited() else None))
            if (name == 'latitude' or name == 'lat' or name == 'y'):
                dimlat = len(dimension)
            elif (name == 'longitude' or name == 'lon' or name == 'x'):
                dimlon = len(dimension)

        # copy all file data
        for name, variable in src.variables.items():
            dst.createVariable(name, variable.datatype, variable.dimensions, zlib=True)
            dst[name].setncatts(src[name].__dict__)
            dst[name][:] = src[name][:]

        try:
            # checksum
            dst.createVariable('checksum', src['decid_nd'].datatype, src['decid_nd'].dimensions, zlib=True, fill_value=fillvalue_giss)
            dst['checksum'].setncattr("name", "checksum")
            dst['checksum'].setncattr("long_name", "checksum")
            dst['checksum'].setncattr("units", "frac")
        except:
            pass

        # dominant PFT
        dst.createVariable('domlc', src['decid_nd'].datatype, src['decid_nd'].dimensions, zlib=True, fill_value=fillvalue_giss)
        dst['domlc'].setncattr("name", "Dominant Ent land cover")
        dst['domlc'].setncattr("long_name", "Dominant Ent land cover category")
        dst['domlc'].setncattr("units", "category")

        print((dimlat, dimlon))
        lc_pft = np.zeros((18, dimlat, dimlon))

        # get PFT all data
        for k, v in pfts.items():
            lc_pft[k-1] = src[v[varname]][:]

        # start with shade tolerance # IGNORE FOR NOW
        #shadereplace = getreplacefrac(time, shadeTolerance[evolved], shadeTolerance[rampup])
        #if (shadereplace > 0):
        #    for i in range(9,15):
        #        replacePFTlc(lc_pft, dimlat, dimlon, i-1, shadereplace, np.arange(0, 8), np.full((8), 1))

        # replace all crops
        replacements += replace(15)
        replacements += replace(16)
        # replacement order for grass: C4 grass -> C3 arctic grass -> C3 annual grass -> C3 perennial grass
        replacements += replace(12)
        replacements += replace(14)
        replacements += replace(13)
        replacements += replace(11)
        # replacement order for trees: Drought Deciduous -> Cold Deciduous -> Deciduous Needleleaf -> Evergreen Broadleaf -> Evergreen Needleleaf
        replacements += replace(7)
        replacements += replace(5)
        replacements += replace(6)
        replacements += replace(8)
        replacements += replace(1)
        replacements += replace(2)
        replacements += replace(3)
        replacements += replace(4)
        # replacement order for shrubs: Cold shrubs -> Arid shrubs
        replacements += replace(9)
        replacements += replace(10)

        # write to file
        for k, v in pfts.items():
            dst[v[varname]][:] = lc_pft[k-1]

        checksum = np.sum(lc_pft, axis=0) 
        dst['checksum'][:] = checksum
        dst['domlc'][:] = np.where(checksum > 0.999, np.add(np.argmax(lc_pft, axis=0), 1), fillvalue_giss)
        dst.setncattr("replacements", replacements)


