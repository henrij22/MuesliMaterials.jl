
Base.IndexStyle(::Itensor) = IndexLinear()
Base.getindex(v::Itensor, i::Int, j::Int) = cxxgetindex(v, i, j)[]

function Base.getindex(v::Itensor, i::UnitRange{Int}, j::Int)
    return [v[ii, j] for ii in i]
end
function Base.getindex(v::Itensor, i::Int, j::UnitRange{Int})
    return [v[i, jj] for jj in j]
end

function Base.getindex(v::Itensor, i::UnitRange{Int}, j::UnitRange{Int})
    return [v[ii, jj] for ii in i, jj in j]
end

function Base.setindex!(v::Itensor, val, i::Int, j::Int)
    cxxsetindex!(v, convert(Float64, val), i, j)
end

function Base.setindex!(v::Itensor, vals, i::UnitRange{Int}, j::Int)
    @assert length(vals)==length(i) "Length mismatch in assignment"
    for (offset, ii) in enumerate(i)
        v[ii, j] = vals[offset]
    end
    return v
end

function Base.setindex!(v::Itensor, vals, i::Int, j::UnitRange{Int})
    @assert length(vals)==length(j) "Length mismatch in assignment"
    for (offset, jj) in enumerate(j)
        v[i, jj] = vals[offset]
    end
    return v
end
function Base.setindex!(v::Itensor, vals, i::UnitRange{Int}, j::UnitRange{Int})
    @assert Base.size(vals)==(length(i), length(j)) "Dimension mismatch in assignment"
    for (ii_offset, ii) in enumerate(i)
        for (jj_offset, jj) in enumerate(j)
            v[ii, jj] = vals[ii_offset, jj_offset]
        end
    end
    return v
end

Base.ndims(::Itensor) = 2
Base.axes(::Itensor) = (Base.OneTo(3), Base.OneTo(3))
Base.axes(::Itensor, ::Int) = Base.OneTo(3)

Base.similar(::Itensor, element_type, dims) = Array{element_type}(undef, 3, 3)

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

function Base.show(io::IO, mime::MIME"text/plain", tensor::Itensor)
    Base.print(io, "$(typeof(tensor)) with 3x3 entries\n")
    for i in 1:3
        Base.print(io, "$(tensor[i, 1]) $(tensor[i, 2]) $(tensor[i, 3])\n")
    end
end

Base.convert(::Type{T}, x::Itensor) where {T <: AbstractMatrix} = @tullio A[i, j] := x[i, j]
