using Aqua

@testset "Aqua.jl" begin
    Aqua.test_all(
        MuesliMaterials;
        deps_compat = (check_extras = false),
        ambiguities = false,
        piracies = false
    )
end
