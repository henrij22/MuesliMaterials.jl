
Base.IndexStyle(::Ivector) = IndexLinear()
Base.getindex(v::Ivector, i::Int) = cxxgetindex(v, i)[]
function Base.setindex!(v::Ivector, val, i::Int)
    cxxsetindex!(v, convert(Float64, val), i)
end

Base.getindex(v::Ivector, r::UnitRange{Int}) = [v[i] for i in r]
function Base.setindex!(v::Ivector, vals, r::UnitRange{Int})
    @assert length(vals)==length(r) "Mismatch between number of values and indices"
    for (offset, index) in enumerate(r)
        v[index] = vals[offset]
    end
    return v
end

Base.ndims(::Ivector) = 1
Base.length(::Ivector) = 3

Base.axes(::Ivector) = (Base.OneTo(3),)
Base.similar(::Ivector, element_type, dims) = Array{element_type}(undef, 3)

function Base.iterate(v::Ivector, state::Int = 1)
    state > 3 && return nothing
    return (v[state], state + 1)
end

function Base.show(io::IO, ::MIME"text/plain", vec::Ivector)
    Base.print(io, "$(typeof(vec)) with 3 entries\n")
    Base.print(io, "$(vec[1])\n$(vec[2])\n$(vec[3])")
end

Base.convert(::Type{T}, x::Ivector) where {T <: AbstractVector} = @tullio a[i] := x[i]
