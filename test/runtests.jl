using CDSAPI
using NCDatasets
using Test

# list of tests

@testset "CDSAPI.jl" begin

    ddir = joinpath(@__DIR__,"data")

    @testset "ERA5 Single Level" begin

        fnc = joinpath(ddir,"era5test.nc")
        lsm = Dict(
            "product_type" => "reanalysis",
            "variable"     => "land_sea_mask",
            "year"         => 2019,
            "month"        => 1,
            "day"          => 1,
            "time"         => "00:00",
            "format"       => "netcdf"
        )
        retrieve("reanalysis-era5-single-levels",lsm,fnc)

        ds = NCDataset(fnc)
        @test ds["longitude"] == collect(0:0.25:359.75)
        @test ds["latitude"]  == collect(90:-0.25:-90)
        @test ds["time"]      == DateTime(2019,1,1)
        close(ds)

        rm(fnc)

    end

    @testset "ERA5 Arrays in Dict" begin

        fnc = joinpath(ddir,"era5test.nc")
        lsm = Dict(
            "product_type" => "reanalysis",
            "variable"     => "land_sea_mask",
            "year"         => [2019,2020],
            "month"        => 1,
            "day"          => 1,
            "grid"         => [20,90,-15,165]
            "time"         => "00:00",
            "format"       => "netcdf"
        )
        retrieve("reanalysis-era5-single-levels",lsm,fnc)

        ds = NCDataset(fnc)
        @test ds["longitude"] == collect(90:0.25:165)
        @test ds["latitude"]  == collect(20:-0.25:-15)
        @test ds["time"]      == DateTime.([2019,2020],1,1)
        close(ds)

        rm(fnc)

    end

end
