# Examples overview

These pages are runnable: every code block is executed when the documentation is built, so the
printed results are what MuesliMaterials.jl actually returns.

- [Tensors and vectors](01_tensors.md) — the `Ivector`, `Itensor`, `Istensor` and `Itensor4`
  types, how they map onto Julia arrays, and how to convert between them.
- [Small strain materials](02_smallstrain.md) — building a material, driving a material point,
  and reading stresses, tangents and energies.
- [Finite strain materials](03_finitestrain.md) — hyperelasticity, the different stress
  measures, and how they relate to one another.

## Conventions used throughout

**Most names need qualifying.** Only the tensor types and a few materials are exported, so the
examples either write `MuesliMaterials.stress!` or import what they need:

```@example conventions
using MuesliMaterials
using MuesliMaterials: stress!, tangentTensor!, updateCurrentState, storedEnergy
nothing # hide
```

**Materials and material points are separate.** A material carries the parameters; a material
point carries the state. Build one material and as many points from it as you have quadrature
points.

```@example conventions
material = ElasticIsotropicMaterial(210000.0, 0.3)
mp = ElasticIsotropicMP(material)
nothing # hide
```

**Output tensors are preallocated.** Bang methods write into a tensor you supply, which is what
MUESLI's out-parameter interface expects:

```@example conventions
updateCurrentState(mp, 1.0, Istensor([0.001 0.0 0.0; 0.0 0.0 0.0; 0.0 0.0 0.0]))

σ = Istensor()
stress!(mp, σ)
σ
```

**Tensors behave like arrays.** Indexing, iteration and `convert` all work, so a result can be
handed straight to ordinary Julia code:

```@example conventions
σ[1, 1], sum(σ[i, i] for i in 1:3)
```
