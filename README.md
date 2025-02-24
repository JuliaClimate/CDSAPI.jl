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

The package will attempt to use CDS credentials using three different methods with the following priority:

    1. direct credentials provided through the scoped values `CDSAPI.KEY` and `CDSAPI.URL`
    2. environmental variables `CDSAPI_URL` and `CDSAPI_KEY`
    3. default credential file in home directory `~/.cdsapirc`

A valid credential file is a text file with two lines:
```
url: https://yourendpoint
key: your-personal-api-token
```

Instructions on how to create the file for your user account can be found
[here](https://cds.climate.copernicus.eu/how-to-api).

For the following example to work, make sure your `~/.cdsapirc` file exists or the env vars `CDSAPI_URL` and `CDSAPI_KEY` are set.

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

In case you want to use multiple credentials for different requests, pass the desired values to the corresponding scoped values `CDSAPI.URL` and `CDSAPI.KEY`:
```julia
using CDSAPI

dataset = "reanalysis-era5-single-levels"
request = """ #= some request =# """

customkey = "an-example-of-key"
customurl = "http://my-custom-endpoint"

# overwrite KEY and use URL from other methods
CDSAPI.with(CDSAPI.KEY => customkey) do
    CDSAPI.retrieve(dataset, request, "download.nc")
end

# overwrite URL and use KEY from other methods
CDSAPI.with(CDSAPI.URL => customurl) do
    CDSAPI.retrieve(dataset, request, "download.nc")
end
```

[build-img]: https://img.shields.io/github/actions/workflow/status/JuliaClimate/CDSAPI.jl/CI.yml?branch=master&style=flat-square
[build-url]: https://github.com/JuliaClimate/CDSAPI.jl/actions

[codecov-img]: https://img.shields.io/codecov/c/github/JuliaClimate/CDSAPI.jl?style=flat-square
[codecov-url]: https://codecov.io/gh/JuliaClimate/CDSAPI.jl
