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

Base.IndexStyle(::Ivector) = IndexLinear()
Base.getindex(v::Ivector, i::Int) = cxxgetindex(v, i)[]
function Base.setindex!(v::Ivector, val, i::Int)
    cxxsetindex!(v, convert(Float64, val), i)
end

Base.IndexStyle(::Itensor) = IndexLinear()
Base.getindex(v::Itensor, i::Int, j::Int) = cxxgetindex(v, i, j)[]
function Base.setindex!(v::Itensor, val, i::Int, j::Int)
    cxxsetindex!(v, convert(Float64, val), i, j)
end

Base.IndexStyle(::Itensor4) = IndexLinear()
function Base.getindex(v::Itensor4, i::Int, j::Int, k::Int, l::Int)
    cxxgetindex(v, i, j, k, l)[]
end
function Base.setindex!(v::Itensor4, val, i::Int, j::Int, k::Int, l::Int)
    cxxsetindex!(v, convert(Float64, val), i, j, k, l)
end

Base.ndims(::Ivector) = 1
Base.ndims(::Itensor) = 2
Base.ndims(::Itensor4) = 4

Base.length(::Ivector) = 3
Base.length(::Itensor) = 3 * 3
Base.length(::Itensor4) = 3 * 3 * 3 * 3

Base.axes(::Ivector) = (Base.OneTo(3),)
Base.axes(::Itensor) = (Base.OneTo(3), Base.OneTo(3))
Base.axes(::Itensor, ::Int) = Base.OneTo(3)
Base.axes(::Itensor4) = (Base.OneTo(3), Base.OneTo(3), Base.OneTo(3), Base.OneTo(3))
Base.axes(::Itensor4, ::Int) = Base.OneTo(3)

Base.similar(::Ivector, element_type, dims) = Array{element_type}(undef, 3)
Base.similar(::Itensor, element_type, dims) = Array{element_type}(undef, 3, 3)
Base.similar(::Itensor4, element_type, dims) = Array{element_type}(undef, 3, 3, 3, 3)

function Base.iterate(v::Ivector, state::Int = 1)
    state > 3 && return nothing
    return (v[state], state + 1)
end

function Base.iterate(T::Itensor, state::Tuple{Int, Int} = (1, 1))
    i, j = state
    if j > 3  # if the column index exceeds 3, we're done
        return nothing
    end
    # Retrieve the value at the current multi-index.
    val = T[i, j]
    # Compute the next state: increment i until it exceeds 3, then reset i and increment j.
    next_state = i < 3 ? (i + 1, j) : (1, j + 1)
    return (val, next_state)
end

function Base.iterate(T::Itensor4, state::NTuple{4, Int} = (1, 1, 1, 1))
    i, j, k, l = state
    if l > 3  # once the outermost index exceeds 3, we are done
        return nothing
    end
    val = T[i, j, k, l]
    # Compute the next state:
    if i < 3
        next_state = (i + 1, j, k, l)
    elseif j < 3
        next_state = (1, j + 1, k, l)
    elseif k < 3
        next_state = (1, 1, k + 1, l)
    elseif l < 3
        next_state = (1, 1, 1, l + 1)
    else
        next_state = nothing
    end
    return (val, next_state)
end

function Base.show(io::IO, ::MIME"text/plain", vec::Ivector)
    Base.print(io, "$(typeof(vec)) with 3 entries\n")
    Base.print(io, "$(vec[1])\n$(vec[2])\n$(vec[3])")
end

function Base.show(io::IO, mime::MIME"text/plain", tensor::Itensor)
    Base.print(io, "$(typeof(tensor)) with 3x3 entries\n")
    for i in 1:3
        Base.print(io, "$(tensor[i, 1]) $(tensor[i, 2]) $(tensor[i, 3])\n")
    end
end

function Base.show(io::IO, mime::MIME"text/plain", tensor::Itensor4)
    Base.print(io, "$(typeof(tensor)) with 3x3x3x3 entries\n")
    Base.show(io, mime, convert(Array{Float64}, tensor))
end

Base.convert(::Type{T}, x::Ivector) where {T <: AbstractVector} = @tullio a[i] := x[i]
Base.convert(::Type{T}, x::Itensor) where {T <: AbstractMatrix} = @tullio A[i, j] := x[i, j]
Base.convert(::Type{T}, x::Itensor4) where {T <: AbstractArray} = @tullio A[i, j, k, l] := x[i, j, k, l]

end
