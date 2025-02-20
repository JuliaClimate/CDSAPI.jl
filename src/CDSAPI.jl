module CDSAPI

using HTTP
using JSON
using Dates

using ScopedValues

const KEY = ScopedValue("")
const URL = ScopedValue("https://cds.climate.copernicus.eu/api")

"""
    credentials()

Attempt to find CDS credentials using different methods:

    1. direct credentials provided via a specific file
    2. environmental variables `CDSAPI_URL` and `CDSAPI_KEY`
    3. credential file in home directory `~/.cdsapirc`

A credential file is a text file with two lines:

url: https://yourendpoint
key: your-personal-api-token
"""
function credentials()

    dotrc = joinpath(homedir(), ".cdsapirc")
    if isfile(dotrc)
        url, key = credentialsfromfile(dotrc)
    else
        url = key = ""
    end

    # overwrite with environmental variables
    url = get(ENV, "CDSAPI_URL", url)
    key = get(ENV, "CDSAPI_KEY", key)

    # overwrite with ScopedValues provided by user

    url = isempty(URL[]) ? url : URL[]
    key = isempty(KEY[]) ? key : KEY[]


    if isempty(url) || isempty(key)
        error("""
        Missing credentials. Either add the CDSAPI_URL and CDSAPI_KEY env variables
        or create a .cdsapirc file (default location: '$(homedir())').
        """)
    end

    return url, key
end

"""
    credentials(file)

Parse the cds credentials from a provided file
"""
function credentialsfromfile(file)
    creds = Dict()
    open(realpath(file)) do f
        for line in readlines(f)
            key, val = strip.(split(line, ':', limit=2))
            creds[key] = val
        end
    end

    if !(haskey(creds, "url") || haskey(creds, "key")) # we can allow files with only one of the keys.
        error("""
        The credentials' file must have at least a `key` value or a `url` value in the following format:

        url: https://yourendpoint
        key: your-personal-api-token
        """)
    end

    return get(creds, "url", ""), get(creds, "key", "")
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
    
    url, key = credentials()

    try
        response = HTTP.request("POST",
            url * "/retrieve/v1/processes/$name/execute",
            ["PRIVATE-TOKEN" => key],
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

    laststatus = nothing
    while data["status"] != "successful"
        data = HTTP.request("GET", endpoint,
            ["PRIVATE-TOKEN" => key]
        )
        data = JSON.parse(String(data.body))

        if data["status"] != laststatus
            @info "CDS request update on $(now())" dataset = name status = data["status"]
            laststatus = data["status"]
        end

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
        ["PRIVATE-TOKEN" => key]
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
