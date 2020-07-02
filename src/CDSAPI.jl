module CDSAPI

using HTTP
using JSON
using Base64

export
    py2ju

function retrieve(name, params, filename)
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
    while data["state"] != "completed"
        data = HTTP.request("GET", creds["url"] * "/tasks/" * string(resp_dict["request_id"]),  ["Authorization" => apikey])
        data = JSON.parse(String(data.body))
        println("request queue status ", data["state"])
    end

    download(data["location"], filename)

    data
end

function py2ju(dictstr)
    dictstr_cpy = replace(dictstr, "'" => "\"")
    lastcomma_pos = findlast(",", dictstr_cpy).start

    # if there's no pair after the last comma
    if findnext(":", dictstr_cpy, lastcomma_pos) == nothing
        # remove the comma
        dictstr_cpy = dictstr_cpy[begin:lastcomma_pos - 1] * dictstr_cpy[lastcomma_pos + 1:end]
    end
    return JSON.parse(dictstr_cpy)
end

end # module
