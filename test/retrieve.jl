@testset "Retrieve" begin
    datadir = joinpath(@__DIR__, "data")

    @testset "ERA5 monthly preasure data" begin
        filepath = joinpath(datadir, "era5.grib")
        response = CDSAPI.retrieve("reanalysis-era5-pressure-levels-monthly-means",
            CDSAPI.py2ju("""{
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
            }"""),
            filepath)

        @test typeof(response) <: Dict
        @test isfile(filepath)

        GribFile(filepath) do datafile
            data = Message(datafile)
            @test data["name"] == "Divergence"
            @test data["level"] == 1
            @test data["year"] == 2020
            @test data["month"] == 6
        end
        rm(filepath)
    end
end
