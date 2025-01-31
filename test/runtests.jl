using Muesli
using Test

@testset "Muesli.jl" begin
    mat = Muesli.ElasticIsotropicMaterial(1000, 100)
    mp = Muesli.ElasticIsotropicMP(mat)

    C = [0.600872 -0.179083 0
        -0.179083 0.859121 0
        0 0 1]


    σ = zeros(3, 3)
    ℂ = zeros(3, 3, 3, 3)

    Muesli.stress!(mp, σ)
    Muesli.tangentTensor!(mp, ℂ)

    @test all(σ != 0.0)
    @test all(ℂ != 0.0)
end
