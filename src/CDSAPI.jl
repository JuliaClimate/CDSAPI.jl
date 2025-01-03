module CDSAPI

using HTTP
using JSON

"""
    retrieve(name, params, filename; max_sleep = 120.)

Retrieves data for `name` from the Climate Data Store
with the specified `params` and stores it in the current
directory as `filename`.

The client periodically requests the status of the retrieve request.
`max_sleep` is the maximum time (in seconds) between the status updates.
"""
function retrieve(name, params, filename; max_sleep=120.0)
    creds = Dict()
    open(joinpath(homedir(), ".cdsapirc")) do f
        for line in readlines(f)
            key, val = strip.(split(line, ':', limit=2))
            creds[key] = val
        end
    end

    response = HTTP.request(
        "POST",
        creds["url"] * "/retrieve/v1/processes/$name/execute/",
        ["PRIVATE-TOKEN" => creds["key"]],
        body=JSON.json(Dict("inputs" => params)),
        verbose=1)

    resp_dict = JSON.parse(String(response.body))
    data = Dict("status" => "queued")
    sleep_seconds = 1.0

    while data["status"] != "successful"
        data = HTTP.request("GET", creds["url"] * "/retrieve/v1/jobs/" * string(resp_dict["jobID"]), ["PRIVATE-TOKEN" => creds["key"]])
        data = JSON.parse(String(data.body))
        println("request queue status ", data["status"])

        if data["status"] == "failed"
            error("Request to dataset $name failed. Check " *
                  "https://cds.climate.copernicus.eu/cdsapp#!/yourrequests " *
                  "for more information (after login).")
        end

        sleep_seconds = min(1.5 * sleep_seconds, max_sleep)
        if data["status"] != "successful"
            sleep(sleep_seconds)
        end
    end

    response = HTTP.request("GET", creds["url"] * "/retrieve/v1/jobs/" * string(resp_dict["jobID"]) * "/results/", ["PRIVATE-TOKEN" => creds["key"]])
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
