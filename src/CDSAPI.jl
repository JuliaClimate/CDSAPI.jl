
module CDSAPI
using HTTP, JSON, Base64
# Write your package code here.
    function retrieve(name, params)
        cred = Dict()
        open("c.json", "r") do f
            dicttxt = read(f,String)
            cred = JSON.parse(dicttxt)
        end
        key = string("Basic ", base64encode(cred["key"]))
        r = HTTP.request("POST", string(cred["url"], "/resources/$name"), ["Authorization" => key], body=JSON.json(params), verbose=1) 
        str = String(r.body)
        resp_json = JSON.Parser.parse(str)
        data = Dict("state" => "queued")
        while data["state"] != "completed"
            data = HTTP.request("GET", string(cred["url"], "/tasks/", resp_json["request_id"]),  ["Authorization" => key])
            data = JSON.Parser.parse(String(data.body)) 
        end
        return data
    end # function
end # module
