using CDSAPI
using Test

@testset "CDSAPI.jl" begin
    # Write your tests here.
end

datadir = joinpath(@__DIR__,"data")

# list of tests
testfiles = [
  "py2ju.jl",
]

@testset "CDSAPI.jl" begin
  for testfile in testfiles
    include(testfile)
  end
end
