module CDSAPI

using HTTP
using JSON
using Base64

export
    py2ju

"""
    retrieve(name::AbstractString,
        params::Dict{T, V},
        filename::AbstractString)

Retrieves data for `name` from the Climate Data Store
with the specified `params` and stores it in the current
directory as `filename`.
"""
function retrieve(name::AbstractString, params::Dict, filename::AbstractString)
    creds = Dict()
    open(joinpath(homedir(),".cdsapirc")) do f
        for line in readlines(f)
            key, val = strip.(split(line,':', limit=2))
            creds[key] = val
        end
    end

    apikey = string("Basic ", base64encode(creds["key"]))
    response = HTTP.request(
        "POST",
        creds["url"] * "/resources/$name",
        ["Authorization" => apikey],
        body=JSON.json(params),
        verbose=1)

    resp_json = JSON.Parser.parse(string(response.body))
    data = Dict("state" => "queued")
    while data["state"] != "completed"
        data = HTTP.request("GET", creds["url"] * "/tasks/" * string(resp_json["request_id"]),  ["Authorization" => key])
        data = JSON.Parser.parse(string(data.body))
        println("request queue status ", data["state"])
    end

    download(data["location"], filename)
    return data
end

"""
    py2ju(dictstr::AbstractString)

Takes a Python dictionary as string and converts it into Julia's `Dict`

# Examples
```julia-repl
julia> str = \"""{
               "format": "zip",
               "variable": "surface_air_temperature",
               "product_type": "climatology",
               "month": "08",
               "origin": "era_interim"
           }\""";

julia> py2ju(str)
Dict{String,Any} with 5 entries:
  "format"       => "zip"
  "month"        => "08"
  "product_type" => "climatology"
  "variable"     => "surface_air_temperature"
  "origin"       => "era_interim"

```
"""
py2ju(dictstr::AbstractString) = JSON.parse(dictstr)

end # module
