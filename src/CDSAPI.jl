module CDSAPI

using HTTP
using JSON
using Base64

export
    py2ju

"""
    retrieve(name, params, filename; max_sleep = 120.)

Retrieves data for `name` from the Climate Data Store
with the specified `params` and stores it in the current
directory as `filename`.

The client periodically requests the status of the retrieve request.
`max_sleep` is the maximum time (in seconds) between the status updates.
"""
function retrieve(name, params, filename; max_sleep = 120.)
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

    resp_dict = JSON.parse(String(response.body))
    data = Dict("state" => "queued")
    sleep_seconds = 1.

    while data["state"] != "completed"
        data = HTTP.request("GET", creds["url"] * "/tasks/" * string(resp_dict["request_id"]),  ["Authorization" => apikey])
        data = JSON.parse(String(data.body))
        println("request queue status ", data["state"])

        sleep_seconds = min(1.5 * sleep_seconds,max_sleep)
        if data["state"] != "completed"
            sleep(sleep_seconds)
        end
    end

    HTTP.download(data["location"], filename)
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

julia> py2ju(str)
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
        dictstr_cpy = dictstr_cpy[firstindex(dictstr_cpy):(lastcomma_pos - 1)] * dictstr_cpy[(lastcomma_pos + 1):lastindex(dictstr_cpy)]
    end

    # removes trailing comma from a list
    rx = r",[ \n\r\t]*\]"
    dictstr_cpy = replace(dictstr_cpy, rx => "]")

    return JSON.parse(dictstr_cpy)
end

end # module
