using CDSAPI
using Test

# list of tests
testfiles = [
    "py2ju.jl",
    "retrieve.jl",
]

@testset "CDSAPI.jl" begin
    for testfile in testfiles
        include(testfile)
    end
end
