@testitem "Aqua.jl" begin
    using Aqua

    # The CxxWrap-generated methods (`__delete`) are reported as piracy, and the ambiguity
    # check does not terminate on the wrapped API.
    Aqua.test_all(
        MuesliMaterials;
        deps_compat = (check_extras = false),
        ambiguities = false,
        piracies = false,
        persistent_tasks = false
    )
end
