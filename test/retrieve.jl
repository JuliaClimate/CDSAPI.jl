@testset "ERA5 data" begin
    name = "reanalysis-era5-pressure-levels-monthly-means"
    params = """{
            'format': 'grib',
            'product_type': 'monthly_averaged_ensemble_members_by_hour_of_day',
            'variable': 'divergence',
            'pressure_level': '775',
            'year': '2020',
            'month': '03',
            'time': '12:00',
        }"""

    if !isdir("data")
        mkdir("data")
    end
    filepath = "data/era5.grib"

    @testset "Retrieve" begin
        data = CDSAPI.retrieve(name, py2ju(params), filepath)
        @test typeof(data) <: Dict
        @test data["result_provided_by"] == "dd02ed70-03e3-4989-b5a3-9b551adbd4e3"
        @test data["content_type"] == "application/x-grib"
    end

    @testset "ERA5 data" begin
        @test isfile("data/era5.grib")
        rm("data/era5.grib")
    end
end
