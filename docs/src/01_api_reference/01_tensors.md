# Tensor types

The fixed-size, three-dimensional vector and tensor classes MUESLI uses throughout. All of
them support 1-based indexing, slicing, iteration and `convert` to ordinary Julia arrays; see
[Tensors and vectors](../02_examples/01_tensors.md) for worked examples.

## Types

```@docs
Ivector
Itensor
Istensor
Itensor4
```

## Array interface

Each type implements enough of the `AbstractArray` interface to be used like one:

- `getindex` / `setindex!`, including `UnitRange` slices
- `axes`, `ndims`, `length`, `similar`
- `iterate`, so `sum`, `collect` and comprehensions work
- `convert` to `Matrix{Float64}` / `Array{Float64}`, and — with
  [Tensors.jl](https://github.com/Ferrite-FEM/Tensors.jl) loaded — to `Tensor{2,3}` and
  `SymmetricTensor{2,3}`

## Collections of tensors

Some MUESLI routines take a list of tensors, for instance the relaxation strains of a
viscoelastic material.

```@docs
MuesliMaterials.ArrayOfITensors
MuesliMaterials.ArrayOfIsTensors
```
