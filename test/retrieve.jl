@testset "Retrieve" begin
    datadir = joinpath(@__DIR__,"data")

    @testset "ERA5 monthly preasure data" begin
        filepath = joinpath(datadir, "era5.grib")
        response = CDSAPI.retrieve("reanalysis-era5-pressure-levels-monthly-means",
            py2ju("""{
                'format': 'grib',
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
        @test response["content_type"] == "application/x-grib"
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

    @testset "Europe water quantity data" begin
        filepath = joinpath(datadir, "ewq.zip")
        response = CDSAPI.retrieve("sis-water-quantity-swicca",
            py2ju("""{
                'variable': 'river_flow',
                'time_aggregation': 'annual_maximum',
                'horizontal_aggregation': 'catchments',
                'emissions_scenario': 'rcp_2_6',
                'period': '2071_2100',
                'return_period': '100',
                'format': 'zip',
            }"""),
            filepath)

        @test typeof(response) <: Dict
        @test response["content_type"] == "application/zip"
        @test isfile(filepath)

        # extract contents
        zip_reader = ZipFile.Reader(filepath)
        ewq_fileio = zip_reader.files[1]
        ewq_file = joinpath(datadir, ewq_fileio.name)
        write(ewq_file, read(ewq_fileio))
        close(zip_reader)

        # test file contents
        @test ncgetatt(ewq_file, "Global", "time_coverage_start") == "20710101"
        @test ncgetatt(ewq_file, "Global", "time_coverage_end") == "21001231"
        @test ncgetatt(ewq_file, "Global", "invar_experiment_name") == "rcp26"

        # cleanup
        rm(filepath)
        rm(ewq_file)
    end

    @testset "European energy sector cimate" begin
        filepath = joinpath(datadir, "ees.tar.gz")
        response = CDSAPI.retrieve("sis-european-energy-sector",
            py2ju("""{
                'variable': 'precipitation',
                'time_aggregation': '1_year_average',
                'vertical_level': '0_m',
                'bias_correction': 'bias_adjustment_based_on_gamma_distribution',
                'format': 'tgz',
            }"""),
            filepath)

        @test typeof(response) <: Dict
        @test response["content_type"] == "application/gzip"
        @test isfile(filepath)

        # extract contents
        gzip_io = GZip.open(filepath)
        eesfile_dir = Tar.extract(gzip_io, joinpath(datadir, "ees"))
        ees_file = joinpath(eesfile_dir, readdir(eesfile_dir)[1])
        close(gzip_io)

        # test file contents
        @test ncgetatt(ees_file, "Global", "frequency") == "year"
        @test ncgetatt(ees_file, "tp", "long_name") == "precip total"

        # cleanup
        rm(filepath)
        rm(ees_file)
        rm(eesfile_dir)
    end
end
