# CDSAPI
## Example 
First copy your key and url found on copernicus into the file $HOME/.cdsapirc


<br />
include("CDSAPI.jl")
<br />
name = "reanalysis-era5-single-levels" 
<br />
params = Dict(
       "variable"=> "2t",
       "product_type"=> "reanalysis",
       "date"=> "2015-12-01",
       "time"=> "14:00",
       "format"=> "netcdf",
)
<br />
res = CDSAPI.retrieve(name, params, "get_data.nc")
<br />

alternativly you can convert python dict to julia dict using
for example the following Python call:
<br />
c = cdsapi.Client()
c.retrieve("insitu-glaciers-elevation-mass",
{
"variable": "all",
"product_type": "elevation_change",
"file_version": "20170405",
"format": "tgz"
},
"download.tar.gz")
<br />
could be easily converted into a Julia call as:

using CDSAPI

CDSAPI.retrieve("insitu-glaciers-elevation-mass",
py2ju("""
{
"variable": "all",
"product_type": "elevation_change",
"file_version": "20170405",
"format": "tgz"
}
"""),
"download.tar.gz"