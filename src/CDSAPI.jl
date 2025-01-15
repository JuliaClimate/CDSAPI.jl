module CDSAPI

using HTTP
using JSON
using Base.ScopedValues

const auth = ScopedValue(Dict("url" => "", "key" => ""))

"""
    CDScredentials()

Checks the default location for the cds credentials
"""
function credentials()
    url = get(ENV, "CDSAPI_URL", "")
    key = get(ENV, "CDSAPI_KEY", "")

    if isempty(url) || isempty(key)
        dotrc = joinpath(homedir(), ".cdsapirc")
        if !isfile(dotrc)
            error("""
            Missing credentials. Either add the CDSAPI_URL and CDSAPI_KEY env variables
            or create a .cdsapirc file (default location: '$(homedir())').
            """)
        end

        return CDScredentials(dotrc)
    end

    creds = Dict("url" => url, "key" => token)
end

"""
    CDScredentials(file)

Parse the cds credentials from a provided file
"""
function CDScredentials(file)
    creds = Dict()
    open(realpath(file)) do f
        for line in readlines(f)
            key, val = strip.(split(line, ':', limit=2))
            creds[key] = val
        end
    end

    return creds
end

"""
    retrieve(name, params, filename; wait=1.0)

Retrieves dataset with given `name` from the Climate Data Store
with the specified `params` (JSON string) and stores it in the
given `filename`.

The client periodically checks the status of the request and one
can specify the maximum time in seconds to `wait` between updates.
"""
retrieve(name, params::AbstractString, filename; wait=1.0) =
    retrieve(name, JSON.parse(params), filename; wait)

# CDSAPI.parse can be used to convert the request params into a
# Julia dictionary for additional manipulation before retrieval
function retrieve(name, params::AbstractDict, filename; wait=1.0)
    creds = Dict()
    open(joinpath(homedir(), ".cdsapirc")) do f
        for line in readlines(f)
            key, val = strip.(split(line, ':', limit=2))
            creds[key] = val
        end
    end
    creds = auth[]

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
                The requested dataset $name was not found.
                """))
            elseif 400 ≤ e.status < 500
                throw(ArgumentError("""
                The request is in a bad format:
                $params
                """))
            end
        end
        throw(e)
    end

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

"""
    parse(string)

Equivalent to `JSON.parse(string)`.
"""
parse(string) = JSON.parse(string)

@deprecate py2ju(string) parse(string)

end # module
