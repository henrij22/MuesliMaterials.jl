module TensorsExt

# using MuesliMaterials
import MuesliMaterials: Ivector, Itensor, Istensor, Itensor4

using Tensors

Base.convert(::Type{T}, x::Ivector) where {T <: Tensor{1, 3}} = Tensor{1, 3, Float64}(i -> x[i])
Base.convert(::Type{T}, x::Itensor) where {T <: Tensor{2, 3}} = Tensor{2, 3, Float64}((i, j) -> x[i, j])
function Base.convert(::Type{T}, x::Istensor) where {T <: SymmetricTensor{2, 3}}
    SymmetricTensor{2, 3, Float64}((i, j) -> x[i, j])
end
function Base.convert(::Type{T}, x::Itensor4) where {T <: Tensor{4, 3}}
    Tensor{4, 3, Float64}((i, j, k, l) -> x[i, j, k, l])
end

function Ivector(x::T) where {T <: Tensor{1, 3}}
    Ivector(x[1], x[2], x[3])
end

function Itensor(x::T) where {T <: Tensor{2, 3}}
    Itensor(x[1, 1], x[1, 2], x[1, 3], x[2, 1], x[2, 2], x[2, 3], x[3, 1], x[3, 2], x[3, 3])
end

function Istensor(x::T) where {T <: SymmetricTensor{2, 3}}
    Istensor(x[1, 1], x[2, 2], x[3, 3], x[2, 3], x[3, 1], x[1, 2])
end

function Itensor4(x::T) where {T <: Tensor{4, 3}}
    Itensor4(Array(x))
end

end
