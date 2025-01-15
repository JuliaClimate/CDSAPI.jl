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
function retrieve(name, params, filename; wait=1.0)
    creds = Dict()
    open(joinpath(homedir(), ".cdsapirc")) do f
        for line in readlines(f)
            key, val = strip.(split(line, ':', limit=2))
            creds[key] = val
        end
    end

    try
        response = HTTP.request("POST",
            creds["url"] * "/retrieve/v1/processes/$name/execute",
            ["PRIVATE-TOKEN" => creds["key"]],
            body=JSON.json(Dict("inputs" => params))
        )
    catch e
        if e isa HTTP.StatusError
            if e.status == 404
                throw(ArgumentError("""
                The requested dataset '$name' was not found
                """))
            elseif 500 > e.status >= 400
                throw(ArgumentError("""
                The request is in a bad format:
                $params
                """))
            end
        end
        throw(e)
    end

    body = JSON.parse(String(response.body))
    data = Dict("status" => "queued")

    while data["status"] != "successful"
        data = HTTP.request("GET",
            creds["url"] * "/retrieve/v1/jobs/" * string(body["jobID"]),
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
        creds["url"] * "/retrieve/v1/jobs/" * string(body["jobID"]) * "/results",
        ["PRIVATE-TOKEN" => creds["key"]]
    )
    body = JSON.parse(String(response.body))
    HTTP.download(body["asset"]["value"]["href"], filename)

    return data
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
