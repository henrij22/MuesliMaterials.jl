using MuesliMaterials
using Tensors
using Test

@testset verbose=true "MuesliMaterials.jl" begin
    include("testensors.jl")
    include("testsmallstrain.jl")
    include("Aqua.jl")
end
