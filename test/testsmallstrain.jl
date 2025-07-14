@testitem "Test Small Strain" begin
    mat = ElasticIsotropicMaterial(1000, 100)
    mp = ElasticIsotropicMP(mat)

    σ = Istensor()
    ℂ = Itensor4()

    MuesliMaterials.stress!(mp, σ)
    MuesliMaterials.tangentTensor!(mp, ℂ)

    @test all(σ != 0.0)
    @test all(ℂ != 0.0)
end
