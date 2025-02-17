
Base.IndexStyle(::Itensor4) = IndexLinear()
function Base.getindex(v::Itensor4, i::Int, j::Int, k::Int, l::Int)
    cxxgetindex(v, i, j, k, l)[]
end
function Base.setindex!(v::Itensor4, val, i::Int, j::Int, k::Int, l::Int)
    cxxsetindex!(v, convert(Float64, val), i, j, k, l)
end

Base.ndims(::Itensor4) = 4

Base.length(::Itensor) = 3 * 3
Base.length(::Itensor4) = 3 * 3 * 3 * 3

Base.axes(::Itensor4) = (Base.OneTo(3), Base.OneTo(3), Base.OneTo(3), Base.OneTo(3))
Base.axes(::Itensor4, ::Int) = Base.OneTo(3)

Base.similar(::Itensor4, element_type, dims) = Array{element_type}(undef, 3, 3, 3, 3)

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

function Base.show(io::IO, mime::MIME"text/plain", tensor::Itensor4)
    Base.print(io, "$(typeof(tensor)) with 3x3x3x3 entries\n")
    Base.show(io, mime, convert(Array{Float64}, tensor))
end

Base.convert(::Type{T}, x::Itensor4) where {T <: AbstractArray} = @tullio A[i, j, k, l] := x[i, j, k, l]

function Base.getindex(v::Itensor4, i::Union{Int, UnitRange{Int}},
        j::Union{Int, UnitRange{Int}},
        k::Union{Int, UnitRange{Int}},
        l::Union{Int, UnitRange{Int}})
    # If all indices are integers, use the scalar method:
    if isa(i, Int) && isa(j, Int) && isa(k, Int) && isa(l, Int)
        return cxxgetindex(v, i, j, k, l)[]
    else
        # Replace any integer index by a singleton range:
        Ir = isa(i, Int) ? (i:i) : i
        Jr = isa(j, Int) ? (j:j) : j
        Kr = isa(k, Int) ? (k:k) : k
        Lr = isa(l, Int) ? (l:l) : l

        # Build a 4D array via comprehension
        A = [v[ii, jj, kk, ll] for ii in Ir, jj in Jr, kk in Kr, ll in Lr]

        # For any index given as an Int, drop that singleton dimension.
        dims_to_drop = Int[]
        if i isa Int
            push!(dims_to_drop, 1)
        end
        if j isa Int
            push!(dims_to_drop, 2)
        end
        if k isa Int
            push!(dims_to_drop, 3)
        end
        if l isa Int
            push!(dims_to_drop, 4)
        end

        return isempty(dims_to_drop) ? A : dropdims(A, dims_to_drop)
    end
end

function assign_slice!(v::Itensor4, new_vals, slices::NTuple{4, Union{Int, UnitRange{Int}}})
    # Compute the expected shape from indices that are ranges:
    range_dims = [length(s) for s in slices if s isa UnitRange{Int}]
    @assert size(new_vals)==Tuple(range_dims) "Dimension mismatch in assignment"

    # For each index, if it’s an Int, turn it into a singleton range.
    Ir = slices[1] isa Int ? (slices[1]:slices[1]) : slices[1]
    Jr = slices[2] isa Int ? (slices[2]:slices[2]) : slices[2]
    Kr = slices[3] isa Int ? (slices[3]:slices[3]) : slices[3]
    Lr = slices[4] isa Int ? (slices[4]:slices[4]) : slices[4]

    # Loop over all positions in the full 4D block and assign.
    for (ii_offset, ii) in enumerate(Ir)
        for (jj_offset, jj) in enumerate(Jr)
            for (kk_offset, kk) in enumerate(Kr)
                for (ll_offset, ll) in enumerate(Lr)
                    # Build the index for new_vals from only those dimensions corresponding to a UnitRange.
                    offsets = Int[]
                    if slices[1] isa UnitRange{Int}
                        push!(offsets, ii_offset)
                    end
                    if slices[2] isa UnitRange{Int}
                        push!(offsets, jj_offset)
                    end
                    if slices[3] isa UnitRange{Int}
                        push!(offsets, kk_offset)
                    end
                    if slices[4] isa UnitRange{Int}
                        push!(offsets, ll_offset)
                    end
                    new_idx = Tuple(offsets)
                    v[ii, jj, kk, ll] = new_vals[new_idx...]
                end
            end
        end
    end
    return v
end

function Base.setindex!(v::Itensor4, new_vals,
        i::Union{Int, UnitRange{Int}},
        j::Union{Int, UnitRange{Int}},
        k::Union{Int, UnitRange{Int}},
        l::Union{Int, UnitRange{Int}})
    # If all indices are integers, use the scalar method:
    if isa(i, Int) && isa(j, Int) && isa(k, Int) && isa(l, Int)
        cxxsetindex!(v, convert(Float64, new_vals), i, j, k, l)
        return v
    else
        assign_slice!(v, new_vals, (i, j, k, l))
        return v
    end
end
