using CDSAPI
using Test

@testset "Py2Ju" begin
    pydict_str = """{
               'format': 'tgz',
               'variable': 'surface_air_relative_humidity',
               'product_type': 'climatology',
               'month': "09",
               'origin': 'era_interim',
           }"""
    julia_dict = Dict("format" => "tgz",
            "variable" => "surface_air_relative_humidity",
            "product_type" => "climatology",
            "month" => "09",
            "origin" => "era_interim")
    py2ju_result = py2ju(pydict_str)

    @test typeof(py2ju_result) <: Dict
    @test py2ju_result == julia_dict
end
