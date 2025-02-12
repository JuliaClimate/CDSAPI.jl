# CDSAPI.jl

[![][build-img]][build-url] [![][codecov-img]][codecov-url]

This package provides access to the [Climate Data Store](https://cds.climate.copernicus.eu) (a.k.a. CDS) service.

The CDS website provides a `Show API request` button at the bottom of the download tab of each dataset.
This button generates the code to download the dataset with the Python cdsapi module. We've designed this
Julia package so that one could copy/paste the generated Python code with minimum modification in Julia.

## Installation

Please install the package with Julia's package manager:

```julia
] add CDSAPI
```

## Basic usage

Make sure your `~/.cdsapirc` file exists or the env vars `CDSAPI_URL` and `CDSAPI_KEY` are set.
Instructions on how to create the file for your user account can be found
[here](https://cds.climate.copernicus.eu/how-to-api).

Suppose that the `Show API request` button generated the following Python code:
```python
#!/usr/bin/env python
import cdsapi

dataset = "reanalysis-era5-single-levels"
request = {
    "product_type": ["reanalysis"],
    "variable": [
        "10m_u_component_of_wind",
        "10m_v_component_of_wind"
    ],
    "year": ["2024"],
    "month": ["12"],
    "day": ["06"],
    "time": ["16:00"],
    "data_format": "netcdf",
    "download_format": "unarchived",
    "area": [58, 6, 55, 9]
}

client = cdsapi.Client()
client.retrieve(dataset, request).download()
```

You can obtain the same results in Julia:
```julia
using CDSAPI

dataset = "reanalysis-era5-single-levels"
request = """{
    "product_type": ["reanalysis"],
    "variable": [
        "10m_u_component_of_wind",
        "10m_v_component_of_wind"
    ],
    "year": ["2024"],
    "month": ["12"],
    "day": ["06"],
    "time": ["16:00"],
    "data_format": "netcdf",
    "download_format": "unarchived",
    "area": [58, 6, 55, 9]
}""" # <- notice the multiline string.

CDSAPI.retrieve(dataset, request, "download.nc")
```

Besides the downloaded file, the `retrieve` function also returns a dictionary with metadata:

```
Dict{String,Any} with 6 entries:
  "result_provided_by" => "8a3eb001-c8e3-4a9c-8170-28191ebea14b"
  "location"           => "http://136.156.133.36/cache-compute-0010/cache/data0/dataset-insitu-glaciers-elevation-mass-8a3eb001a14b.tar.gz"
  "content_type"       => "application/gzip"
  "request_id"         => "04534ef1-874d-4c81-bb59-9b5effe63e9e"
  "content_length"     => 193660
  "state"              => "completed"
```
# Multiple credentials
In case you want to use multiple api-tokens for different requests, you can specify the token to use with each different request.
To do so you can have multiple versions of a `.cdsapirc` file stored somewhere. These files must be in the same format as the classic `.cdsapirc` file.

To use them, parse them and pass the result to the scoped value `CDSAPI.auth`:
```julia
using CDSAPI

dataset = "reanalysis-era5-single-levels"
request = """ #= some request =# """

cred1 = CDSAPI.credentials("path/to/credential/file1")
cred2 = CDSAPI.credentials("path/to/credential/file2")

with( CDSAPI.auth => cred1 ) do
    CDSAPI.retrieve(dataset, request, "download.nc")
end

with( CDSAPI.auth => cred2 ) do
    CDSAPI.retrieve(dataset, request, "download.nc")
end
```

[build-img]: https://img.shields.io/github/actions/workflow/status/JuliaClimate/CDSAPI.jl/CI.yml?branch=master&style=flat-square
[build-url]: https://github.com/JuliaClimate/CDSAPI.jl/actions

[codecov-img]: https://img.shields.io/codecov/c/github/JuliaClimate/CDSAPI.jl?style=flat-square
[codecov-url]: https://codecov.io/gh/JuliaClimate/CDSAPI.jl
