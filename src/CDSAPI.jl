module CDSAPI

import HTTP
import JSON
# Write your package code here.
    name = "reanalysis-era5-single-levels"
    cred = Dict()
    open("./src/c.json", "r") do f
       dicttxt = read(f,String)
       global cred
       cred = JSON.parse(dicttxt)
       end
    params = Dict(
        "variable"=> "temperature",
        "pressure_level"=> "1000",
        "product_type"=> "reanalysis",
        "year"=> "2008",
        "month"=> "01",
        "day"=> "01",
        "time"=> "12:00",
        "format"=> "grib"
    )
    println(string(cred["url"], "/resources/$name"))
    a = split(cred["key"],":")
    a = (a[1], a[2])
    println(string("Basic ", cred["key"]))
    r = HTTP.request("GET", string(cred["url"], "/resources/$name"), ["Content-Type" => "application/json",  "Authorization" =>string("Basic ", cred["key"])], JSON.json(params))
    println(r.body)
    str = string(r.body)
    resp_json = JSON.Parser.parse(str)
    # write the file with the stringdata variable information
    open("write_read.json", "w") do f
        write(f, str)
     end
end
