# CDSAPI
## Example 
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
res = CDSAPI.retrieve(name, params)
<br />
download(res["location"], "get_data.nc")
<br />
