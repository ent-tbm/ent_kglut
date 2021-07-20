# This file converts monthly aij files into two yearly files with precipitation and temperature

import netCDF4 as nc
import numpy as np

indir = "@@INDIR"
outdir = "@@OUTDIR"
outfilename_prec = "@@PREC"
outfilename_temp = "@@TEMP"

fillvalue = -1e30

inprecname = "prec"
outprecname = "prec"
intempname = "tsurf"
outtempname = "tmp"

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
    "@@DEC"
    ]

daymonth = [31, 28.25, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31]

temp = np.empty((12, 90, 144))
prec = np.empty((12, 90, 144))

time = np.arange(1, 13)
latdim = 90
londim = 144
lat = np.arange(-89.0, 91, 2.0)
lon = np.arange(-178.75, 180.25, 2.50) 

print("Fetching data... Warning could be slow! Please be patient")
for i in range(12):
  with nc.Dataset(indir+aij[i]) as dataset:
    print("Fetching data from {}".format(aij[i]))
    prec[i] = dataset[inprecname][:] * daymonth[i]
    temp[i] = dataset[intempname][:]

precdataset = nc.Dataset(outdir+outfilename_prec, mode='w')
precdataset.setncattr("title", "Mean monthly precipitation")
precdataset.setncattr("comment", "Generated with script by James Lui")
precdataset.setncattr("source", indir)
precdataset.createDimension('lat', size=latdim)
precdataset.createDimension('lon', size=londim)
precdataset.createDimension('time', size=0)

precdataset.createVariable("lat", "f4", ("lat"))
precdataset.createVariable("lon", "f4", ("lon"))
precdataset.createVariable("time", "i4", ("time"))
precdataset['lat'][:] = lat
precdataset['lon'][:] = lon
precdataset['time'][:] = time
precdataset['lat'].setncattr("long_name", "latitude")
precdataset['lat'].setncattr("units", "degrees_north")
precdataset['lon'].setncattr("long_name", "longitude")
precdataset['lon'].setncattr("units", "degrees_east")
precdataset['time'].setncattr("long_name", "time")
precdataset['time'].setncattr("units", "months")

precdataset.createVariable(outprecname, "f4", dimensions=("time", "lat", "lon"), fill_value=fillvalue)
precdataset[outprecname].setncattr("long_name", "monthly precipitation")
precdataset[outprecname].setncattr("units", "mm/month")
precdataset[outprecname][:] = prec
precdataset.close()
#--------------------------------------
tempdataset = nc.Dataset(outdir+outfilename_temp, mode='w')
tempdataset.setncattr("title", "Mean monthly temperature")
tempdataset.setncattr("comment", "Generated with script by James Lui")
tempdataset.setncattr("source", indir)
tempdataset.createDimension('lat', size=latdim)
tempdataset.createDimension('lon', size=londim)
tempdataset.createDimension('time', size=0)

tempdataset.createVariable("lat", "f4", ("lat"))
tempdataset.createVariable("lon", "f4", ("lon"))
tempdataset.createVariable("time", "i4", ("time"))
tempdataset['lat'][:] = lat
tempdataset['lon'][:] = lon
tempdataset['time'][:] = time
tempdataset['lat'].setncattr("long_name", "latitude")
tempdataset['lat'].setncattr("units", "degrees_north")
tempdataset['lon'].setncattr("long_name", "longitude")
tempdataset['lon'].setncattr("units", "degrees_east")
tempdataset['time'].setncattr("long_name", "time")
tempdataset['time'].setncattr("units", "months")

tempdataset.createVariable(outtempname, "f4", dimensions=("time", "lat", "lon"), fill_value=fillvalue)
tempdataset[outtempname].setncattr("long_name", "monthly temperature")
tempdataset[outtempname].setncattr("units", "C")
tempdataset[outtempname][:] = temp
tempdataset.close()

