
@testitem "Aqua.jl" begin
    using Aqua

    Aqua.test_all(
        MuesliMaterials;
        deps_compat = (check_extras = false),
        ambiguities = false,
        piracies = false
    )
end
