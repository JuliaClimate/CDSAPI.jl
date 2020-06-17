# CDSAPI
Example 
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
download(res["location"], "get_data.nc")
