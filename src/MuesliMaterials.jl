module MuesliMaterials

using CxxWrap
using MuesliMaterialsWrapper_jll
using Tullio

@wrapmodule(()->libjlmuesli)

function __init__()
    @initcxx
end

export Itensor, Istensor, Itensor4, Ivector
export ElasticIsotropicMaterial, NeoHookeMaterial, SVKMaterial, YeohMaterial
export ElasticIsotropicMP, NeoHookeMP, SVKMP, YeohMP

include("linearalgebra/ivector.jl")
include("linearalgebra/itensor.jl")
include("linearalgebra/itensor4.jl")

end
