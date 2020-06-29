module CDSAPI

export py2ju, retrieve

using HTTP, JSON, Base64

function retrieve(name, params, filename)
    cred = Dict()
    open(joinpath(homedir(), ".cdsapirc"), "r") do f
        dicttxt = readlines(f)
        for i in dicttxt
            tmp = split(i, ":"; limit=2)
            cred[tmp[1]] = lstrip(tmp[2])
        end
    end

    key = string("Basic ", base64encode(cred["key"]))
    r = HTTP.request("POST", joinpath(cred["url"], "resources/$name"), ["Authorization" => key], body=JSON.json(params), verbose=1)
    str = String(r.body)
    resp_json = JSON.Parser.parse(str)

    data = Dict("state" => "queued")
    while data["state"] != "completed"
        data = HTTP.request("GET", joinpath(cred["url"], "tasks", resp_json["request_id"]),  ["Authorization" => key])
        data = JSON.Parser.parse(String(data.body))
        println("request queue status ", data["state"])
    end

    download(data["location"], filename)

    data
end

py2ju(dictstr::String) = JSON.parse(dictstr)

end # module
