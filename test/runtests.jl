using MuesliMaterials
using Tensors
using Test

@testset verbose=true "MuesliMaterials.jl" begin
    include("testtensors.jl")
    include("testsmallstrain.jl")
end
