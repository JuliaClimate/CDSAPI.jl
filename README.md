# CDSAPI
Example 

name = "reanalysis-era5-single-levels"
params = Dict(
       "variable"=> "2t",
       "product_type"=> "reanalysis",
       "date"=> "2015-12-01",
       "time"=> "14:00",
       "format"=> "netcdf",
)
download(res["location"], "get_data.nc")