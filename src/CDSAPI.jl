module CDSAPI

using HTTP
using JSON
using Base64

export
    py2ju

function retrieve(name, params, filename)
    creds = Dict()
    lines = readlines(open(joinpath(homedir(), ".cdsapirc"), "r"))
    for line in lines
        key, val = strip.(split(line, ":"; limit=2))
        creds[key] = val
    end

    apikey = string("Basic ", base64encode(creds["key"]))
    response = HTTP.request(
        "POST",
        "$creds[\"url\"]/resources/$name",
        ["Authorization" => apikey],
        body=JSON.json(params),
        verbose=1)

    resp_json = JSON.Parser.parse(String(response.body))
    data = Dict("state" => "queued")
    while data["state"] != "completed"
        data = HTTP.request("GET", joinpath(creds["url"], "tasks", resp_json["request_id"]),  ["Authorization" => key])
        data = JSON.Parser.parse(String(data.body))
        println("request queue status ", data["state"])
    end

    download(data["location"], filename)

    data
end

py2ju(dictstr::String) = JSON.parse(dictstr)

end # module
