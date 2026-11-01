module MuesliMaterials

using CxxWrap
using MuesliMaterialsWrapper_jll

@wrapmodule(() -> libjlmuesli)

function __init__()
    return @initcxx
end

export Itensor, Istensor, Itensor4, Ivector
export ElasticIsotropicMaterial, NeoHookeMaterial, SVKMaterial, YeohMaterial
export ElasticIsotropicMP, NeoHookeMP, SVKMP, YeohMP

include("linearalgebra/ivector.jl")
include("linearalgebra/itensor.jl")
include("linearalgebra/itensor4.jl")
include("materialpoints.jl")

# Documentation
include("stubs.jl")

end
