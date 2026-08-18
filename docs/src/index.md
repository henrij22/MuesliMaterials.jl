# MuesliMaterials.jl

A Julia interface to [MUESLI](https://materials.imdea.org/muesli/) (Material UnivErSal
LIbrary), the C++ constitutive-model library developed at IMDEA Materials Institute, Madrid.

The developer of this wrapper is not affiliated with IMDEA in any form.

## Overview

MUESLI provides a large catalogue of constitutive models behind a uniform interface. This
package exposes that catalogue to Julia:

- **Small strain models** — isotropic, anisotropic, orthotropic and transversely isotropic
  elasticity, plus plasticity, viscoelasticity, viscoplasticity and damage
- **Finite strain models** — neo-Hookean, Saint Venant–Kirchhoff, Yeoh, Mooney–Rivlin,
  Arruda–Boyce and finite plasticity
- **Tensor types** — `Ivector`, `Itensor`, `Istensor` and `Itensor4`, which behave like
  ordinary Julia arrays

## The material / material point split

MUESLI separates the two halves of a constitutive model, and so does this package:

- A **material** holds the parameters. It is immutable in practice and can be shared.
- A **material point** holds the state at one location — the current strain, the converged
  history, internal variables. Ask it for stresses and tangents.

The workflow is always the same: build a material, create a material point from it, push a
strain into the point, then read what you need out of it.

```@example quickstart
using MuesliMaterials

E, ν = 210000.0, 0.3
material = ElasticIsotropicMaterial(E, ν)
mp = ElasticIsotropicMP(material)

ε = [0.001 0.0002 0.0
     0.0002 -0.0005 0.0001
     0.0 0.0001 0.0003]

MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(ε))

σ = Istensor()
MuesliMaterials.stress!(mp, σ)
σ
```

That is the closed-form isotropic law, ``\sigma = 2\mu\varepsilon + \lambda\,
\mathrm{tr}(\varepsilon)\,I``:

```@example quickstart
λ = E * ν / ((1 + ν) * (1 - 2ν))
μ = E / (2 * (1 + ν))
2μ * ε + λ * (ε[1, 1] + ε[2, 2] + ε[3, 3]) * [1.0 0 0; 0 1 0; 0 0 1]
```

## Conventions

The bindings follow MUESLI's names closely but adapt them to Julia:

- **Function names are kept as they are**, so `storedEnergy` and `updateCurrentState` read the
  same as in the C++ documentation.
- **Routines that fill a preallocated tensor get a bang**: MUESLI's
  `stress(istensor&)` becomes [`stress!`](@ref MuesliMaterials.stress!).
- **Routines that advance the point's own history keep no bang** — `commitCurrentState`,
  `setConvergedState` — because they mutate the receiver rather than an argument.
- **Type names are PascalCase**: `itensor` becomes [`Itensor`](@ref),
  `elasticIsotropicMaterial` becomes [`ElasticIsotropicMaterial`](@ref).
- **Indices are 1-based** throughout, including the `InterfaceState` accessors.

!!! note "Most names are not exported"
    Only the tensor types and a handful of materials are exported. Everything else is reached
    through the module, as `MuesliMaterials.stress!` above, or imported explicitly with
    `using MuesliMaterials: stress!`.

## Documentation structure

- **[Examples](@ref "Examples overview")** — runnable walkthroughs
  - [Tensors and vectors](02_examples/01_tensors.md)
  - [Small strain materials](02_examples/02_smallstrain.md)
  - [Finite strain materials](02_examples/03_finitestrain.md)
- **[API Reference](@ref "Reference overview")**
  - [Tensor types](01_api_reference/01_tensors.md)
  - [Materials](01_api_reference/02_materials.md)
  - [Material points](01_api_reference/03_materialpoints.md)
