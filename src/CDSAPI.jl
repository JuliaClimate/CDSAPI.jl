module CDSAPI

using HTTP
using JSON

"""
    retrieve(name, params, filename; wait=1.0)

Retrieves data for `name` from the Climate Data Store
with the specified `params` and stores it in the current
directory as `filename`.

The client periodically requests the status of the retrieve request.
`wait` is the maximum time (in seconds) between status updates.
"""
function retrieve(name, params, filename; wait=1.0) end

function retrieve(name, params::AbstractDict, filename; wait=1.0)
    creds = Dict()
    open(joinpath(homedir(), ".cdsapirc")) do f
        for line in readlines(f)
            key, val = strip.(split(line, ':', limit=2))
            creds[key] = val
        end
    end

    response = HTTP.request("POST",
        creds["url"] * "/retrieve/v1/processes/$name/execute",
        ["PRIVATE-TOKEN" => creds["key"]],
        body=JSON.json(Dict("inputs" => params))
    )
    
    data = JSON.parse(String(response.body))
    endpoint = Dict(response.headers)["location"]

    while data["status"] != "successful"
        data = HTTP.request("GET", endpoint,
            ["PRIVATE-TOKEN" => creds["key"]]
        )
        data = JSON.parse(String(data.body))
        @info "CDS request" dataset=name status=data["status"]

        if data["status"] == "failed"
            throw(ErrorException("""
            Request to dataset $name failed.
            Check https://cds.climate.copernicus.eu/requests
            for more information (after login).
            """
            ))
        end

        if data["status"] != "successful"
            sleep(wait)
        end
    end

    response = HTTP.request("GET",
        endpoint * "/results",
        ["PRIVATE-TOKEN" => creds["key"]]
    )
    body = JSON.parse(String(response.body))
    HTTP.download(body["asset"]["value"]["href"], filename)

    return data
end

retrieve(name, params::AbstractString, filename; wait=1.0) =
    retrieve(name, JSON.parse(params), filename; wait)

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

julia> CDSAPI.py2ju(str)
Dict{String,Any} with 5 entries:
  "format"       => "zip"
  "month"        => "08"
  "product_type" => "climatology"
  "variable"     => "surface_air_temperature"
  "origin"       => "era_interim"

```
"""
function py2ju(dictstr)
    Base.depwarn("""
    The function `py2ju` is deprecated in favor of `JSON.parse` directly.
    To update, simply replace the `py2ju` with `JSON.parse`. Making sure
    that the request string does not contain single quotes (`'`) but only double quotes
    (`"`).
    Another option is to pass the request string directly. See the README.md for more examples.
    """)
    dictstr_cpy = replace(dictstr, "'" => "\"")
    lastcomma_pos = findlast(",", dictstr_cpy).start

    # if there's no pair after the last comma
    if findnext(":", dictstr_cpy, lastcomma_pos) == nothing
        # remove the comma
        dictstr_cpy = dictstr_cpy[firstindex(dictstr_cpy):(lastcomma_pos-1)] * dictstr_cpy[(lastcomma_pos+1):lastindex(dictstr_cpy)]
    end

    # removes trailing comma from a list
    rx = r",[ \n\r\t]*\]"
    dictstr_cpy = replace(dictstr_cpy, rx => "]")

    return JSON.parse(dictstr_cpy)
end

end # module
