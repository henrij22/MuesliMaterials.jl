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
export JohnsonCookMaterial, ZerilliArmstrongMaterial, ViscoplasticNLMaterial
export JohnsonCookMP, ZerilliArmstrongMP, ViscoplasticNLMP
export SbarMP, SbeamMP, SshellMP, SplaneMP, FbarMP, FbeamMP, FshellMP, FplaneMP

include("linearalgebra/ivector.jl")
include("linearalgebra/itensor.jl")
include("linearalgebra/itensor4.jl")
include("materialpoints.jl")
include("ratedependent.jl")
include("reduced.jl")

# Documentation
include("stubs.jl")

end
