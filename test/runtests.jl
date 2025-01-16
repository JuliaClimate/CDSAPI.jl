using CDSAPI
using ZipFile
using GRIB, NetCDF

using Test

datadir = joinpath(@__DIR__, "data")

@testset "CDSAPI.jl" begin
    @testset "ERA5 monthly preasure data" begin
        filename = joinpath(datadir, "era5.grib")
        response = CDSAPI.retrieve(
            "reanalysis-era5-pressure-levels-monthly-means",
            """{
                'data_format': 'grib',
                'product_type': 'monthly_averaged_reanalysis',
                'variable': 'divergence',
                'pressure_level': '1',
                'year': '2020',
                'month': '06',
                'area': [
                    90, -180, -90,
                    180,
                ],
                'time': '00:00',
            }""",
            filename
        )

        @test typeof(response) <: Dict
        @test isfile(filename)

        GribFile(filename) do datafile
            data = Message(datafile)
            @test data["name"] == "Divergence"
            @test data["level"] == 1
            @test data["year"] == 2020
            @test data["month"] == 6
        end
        rm(filename)
    end

    @testset "Sea ice type data" begin
        filename = joinpath(datadir, "sea_ice_type.zip")
        response = CDSAPI.retrieve(
            "satellite-sea-ice-edge-type",
            """{
                'variable': 'sea_ice_type',
                'region': 'northern_hemisphere',
                'cdr_type': 'cdr',
                'year': '1979',
                'month': '01',
                'day': '02',
                'version': '3_0',
                'data_format': 'zip',
            }""",
            filename
        )

        @test typeof(response) <: Dict
        @test isfile(filename)

        # extract contents
        zip_reader = ZipFile.Reader(filename)
        ewq_fileio = zip_reader.files[1]
        ewq_file = joinpath(datadir, ewq_fileio.name)
        write(ewq_file, read(ewq_fileio))
        close(zip_reader)

        # test file contents
        @test ncgetatt(ewq_file, "Global", "time_coverage_start") == "19790102T000000Z"
        @test ncgetatt(ewq_file, "Global", "time_coverage_end") == "19790103T000000Z"

        # cleanup
        rm(filename)
        rm(ewq_file)
    end

    @testset "Bad requests errors are catched" begin
        goodname = "reanalysis-era5-single-levels"
        badname = "bad-dataset"
        badrequest = """{
            "this": "is",
            "a": "bad",
            "re": ["quest"]
        }"""

        @test_throws ArgumentError CDSAPI.retrieve(goodname, badrequest, "unreachable")
        @test_throws ArgumentError CDSAPI.retrieve(badname, badrequest, "unreachable")
    end
end
