module CDSAPI

using HTTP
using JSON
using Base64

export
        retrieve, cdskeys

"""
    retrieve(name, params, filename)

Retrieves data for `name` from the Climate Data Store
with the specified `params` and stores it in the current
directory as `filename`.
"""
function retrieve(
    fname::AbstractString,
    cdsdataset::AbstractString,
    cdsparams::AbstractDict,
    cdskeys::AbstractDict = cdskeys()
)

    @info "$(now()) - Welcome to the Climate Data Store"
    apikey = string("Basic ", base64encode(cdskeys["key"]))

    @info "$(now()) - Sending request to https://cds.climate.copernicus.eu/api/v2/resources/$(cdsdataset) ..."
    response = HTTP.request(
        "POST", cdskeys["url"] * "/resources/$(cdsdataset)",
        ["Authorization" => apikey],
        body=JSON.json(cdsparams),
        verbose=0
    )
    resp_dict = JSON.parse(String(response.body))
    data = Dict("state" => "queued")

    @info "$(now()) - Request is queued"
    while data["state"] == "queued"
        data = HTTP.request(
            "GET", cdskeys["url"] * "/tasks/" * string(resp_dict["request_id"]),
            ["Authorization" => apikey]
        )
        data = JSON.parse(String(data.body))
    end

    @info "$(now()) - Request is running"
    while data["state"] == "running"
        data = HTTP.request(
            "GET", cdskeys["url"] * "/tasks/" * string(resp_dict["request_id"]),
            ["Authorization" => apikey]
        )
        data = JSON.parse(String(data.body))
    end

    @info "$(now()) - Request is completed"

    @info """$(now()) - Downloading $(uppercase(cdsdataset)) data
      $(BOLD("URL:"))         $(data["location"])
      $(BOLD("Destination:")) $(fnc)
    """

    dt1 = now()
    HTTP.download(data["location"],fname,update_period=Inf)
    dt2 = now()

    @info "$(now()) - Downloaded $(@sprintf("%.1f",data["content_length"]/1e6)) MB in $(@sprintf("%.1f",Dates.value(dt2-dt1)/1000)) seconds (Rate: $(@sprintf("%.1f",data["content_length"]/1e3/Dates.value(dt2-dt1))) MB/s)"

    return

end

"""
    py2ju(dictstr)

Takes a Python dictionary as string and converts it into Julia's `Dict`

# Examples
```julia-repl
julia> str = \"""{
               'format': 'zip',
               'variable': 'surface_air_temperature',
               'product_type': 'climatology',
               'month': '08',
               'origin': 'era_interim',
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
function cdskeys()

    cdskeys = Dict(); cdsapirc = joinpath(homedir(),".cdsapirc")

    @info "$(now()) - Loading CDSAPI credentials from $(cdsapirc) ..."
    open(cdsapirc) do f
        for line in readlines(f)
            key,val = strip.(split(line,':',limit=2))
            cdskeys[key] = val
        end
    end

    return cdskeys

end

end # module
