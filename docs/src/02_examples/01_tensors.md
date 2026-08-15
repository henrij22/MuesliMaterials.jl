# Tensors and vectors

```@example tensors
using MuesliMaterials
nothing # hide
```

MUESLI carries its own small fixed-size types rather than using a general array library. This
package wraps four of them, all in three dimensions:

| Type | Shape | Notes |
| :-- | :-- | :-- |
| [`Ivector`](@ref) | 3 | a vector |
| [`Itensor`](@ref) | 3 × 3 | a general second-order tensor |
| [`Istensor`](@ref) | 3 × 3 | symmetric; stores only six components |
| [`Itensor4`](@ref) | 3 × 3 × 3 × 3 | a fourth-order tensor |

## Construction

Each type builds from the corresponding Julia array:

```@example tensors
v = Ivector([1.0, 2.0, 3.0])
```

```@example tensors
m = [1.0 2.0 3.0
     4.0 5.0 6.0
     7.0 8.0 9.0]
t = Itensor(m)
```

Julia stores matrices column-major and MUESLI's constructors are row-major, so the conversion
reorders the components. The round trip is faithful — in particular nothing is transposed:

```@example tensors
t[1, 2], t[2, 1]
```

[`Istensor`](@ref) is symmetric and keeps only six components, so it reads the symmetric part
of what you give it:

```@example tensors
s = Istensor([1.0 0.2 0.3
              0.2 2.0 0.4
              0.3 0.4 3.0])
```

A fourth-order tensor takes a `3×3×3×3` array:

```@example tensors
c = Itensor4(reshape(collect(1.0:81.0), 3, 3, 3, 3))
c[1, 2, 3, 1]
```

Sizes are checked, so a wrong shape is an error rather than a silent misread:

```@example tensors
try
    Itensor(zeros(2, 2))
catch err
    err
end
```

## They behave like Julia arrays

Indexing is 1-based, and slicing, `axes`, `length` and iteration all work:

```@example tensors
t[1, :], t[:, 2]
```

```@example tensors
axes(t), length(t), ndims(t)
```

```@example tensors
sum(t)          # iteration
```

Assignment works too, including into slices:

```@example tensors
t[1, 1] = 100.0
t[2, 1:3] = [7.0, 8.0, 9.0]
t
```

## Converting back

`convert` produces an ordinary Julia array:

```@example tensors
convert(Matrix{Float64}, s)
```

```@example tensors
convert(Array{Float64}, c)[1, 2, 3, 1]
```

## Interop with Tensors.jl

Loading [Tensors.jl](https://github.com/Ferrite-FEM/Tensors.jl) activates an extension that
converts to its static tensor types, which is what you want inside an element routine:

```@example tensors
using Tensors
convert(Tensor{2, 3}, Itensor([1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0]))
```

```@example tensors
convert(SymmetricTensor{2, 3}, s)
```
