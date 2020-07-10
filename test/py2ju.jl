@testset "Py2Ju" begin
    pydict_str = """{
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
            }"""
    julia_dict = Dict("format"=> "grib",
                    "month" => "06",
                    "time" => "00:00",
                    "year" => "2020",
                    "pressure_level" => "1",
                    "area" => Any[90, -180, -90, 180],
                    "product_type" => "monthly_averaged_reanalysis",
                    "variable" => "divergence")
    py2ju_result = py2ju(pydict_str)

    @test typeof(py2ju_result) <: Dict
    @test py2ju_result == julia_dict
end
