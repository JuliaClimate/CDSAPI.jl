# CDSAPI.jl

This package provides access to the [Climate Data Store](https://cds.climate.copernicus.eu) (a.k.a. CDS) service.

The CDS website provides a [Show API request](https://cds.climate.copernicus.eu/cdsapp#!/dataset/reanalysis-era5-pressure-levels-monthly-means?tab=form) button at the bottom of the download tab of each dataset. This button generates the code to download the dataset with the Python cdsapi module. We've designed this Julia package so that one could copy/paste the generated Python code with minimum modification in Julia.

## Installation

Please install the package with Julia's package manager:

```julia
] add CDSAPI
```

## Usage

Make sure your `~/.cdsapirc` file exists. Instructions on how to create the file for your user account can be found [here](https://cds.climate.copernicus.eu/api-how-to).

Suppose that the `Show API request` button generated the following Python code:

```python
#!/usr/bin/env python
import cdsapi
c = cdsapi.Client()
c.retrieve("insitu-glaciers-elevation-mass",
{
"variable": "all",
"product_type": "elevation_change",
"file_version": "20170405",
"format": "tgz"
},
"download.tar.gz")
```

You can obtain the same results in Julia with the following code:

```julia
using CDSAPI

CDSAPI.retrieve("insitu-glaciers-elevation-mass",
py2ju("""
{
"variable": "all",
"product_type": "elevation_change",
"file_version": "20170405",
"format": "tgz"
}
"""),
"download.tar.gz")
```

We've copied/pasted the code and called the `py2ju` function (exported by CDSAPI.jl) on the second argument of the `retrieve` function. The `py2ju` function simply converts the string containing a Python dictionary to an actual Julia dictionary.

## Authors

@michiboo @juliohm
