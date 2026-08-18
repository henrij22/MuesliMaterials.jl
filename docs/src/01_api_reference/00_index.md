# Reference overview

Detailed documentation of the types and functions exposed by MuesliMaterials.jl.

```@contents
Pages = [
    "01_tensors.md",
    "02_materials.md",
    "03_materialpoints.md",
]
Depth = 2
```

## How the pieces fit together

- **[Tensor types](01_tensors.md)** — the fixed-size vector and tensor classes that every
  other call takes and returns.
- **[Materials](02_materials.md)** — the parameter carriers. One per material model, plus the
  [`MuesliMaterials.MaterialProperties`](@ref) map used to construct them.
- **[Material points](03_materialpoints.md)** — the state carriers, and the stress, tangent
  and energy queries that make up the bulk of the interface.

## A note on exports

Only the tensor types and a handful of material types are exported:

```@example exports
using MuesliMaterials
sort(string.(names(MuesliMaterials)))
```

Everything else is reached through the module (`MuesliMaterials.stress!`) or imported
explicitly (`using MuesliMaterials: stress!`). The full list of registered names is
considerably longer:

```@example exports
length(filter(n -> !startswith(string(n), "#"), names(MuesliMaterials; all = true)))
```
