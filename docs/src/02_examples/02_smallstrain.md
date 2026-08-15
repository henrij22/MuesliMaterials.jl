# Small strain materials

```@example small
using MuesliMaterials
using MuesliMaterials: check, updateCurrentState, stress!, tangentTensor!, storedEnergy,
    pressure, commitCurrentState, resetCurrentState, setProperty!, getProperty,
    MaterialProperties, PR_YOUNG
nothing # hide
```

Small strain models take the linearised strain tensor ``\varepsilon`` and return the Cauchy
stress ``\sigma``. This page uses linear isotropic elasticity, where every result can be
checked against a closed form.

## Building a material

The isotropic material takes Young's modulus, Poisson's ratio and optionally a density:

```@example small
E, ν = 210000.0, 0.3
material = ElasticIsotropicMaterial(E, ν)
check(material)
```

`check` asks MUESLI whether the parameters are admissible — worth calling once after
construction, since an inadmissible set is otherwise only noticed much later.

Printing a material reports what MUESLI made of it:

```@example small
MuesliMaterials.print(material)
```

### The property map

Most materials can also be built from a [`MuesliMaterials.MaterialProperties`](@ref) map, which
is how MUESLI passes named parameters. This is the only route for models with many parameters:

```@example small
props = MaterialProperties()
setProperty!(props, "young", E)
setProperty!(props, "poisson", ν)

fromProps = ElasticIsotropicMaterial(props)
getProperty(fromProps, PR_YOUNG)
```

Both routes give the same material.

## Driving a material point

A material point carries the state. Push a strain into it with `updateCurrentState`, giving
the time and the strain tensor:

```@example small
mp = ElasticIsotropicMP(material)

ε = [0.001 0.0002 0.0
     0.0002 -0.0005 0.0001
     0.0 0.0001 0.0003]

updateCurrentState(mp, 1.0, Istensor(ε))
nothing # hide
```

Then read what you need. Stresses come back in a tensor you preallocate:

```@example small
σ = Istensor()
stress!(mp, σ)
σ
```

which is exactly ``2\mu\varepsilon + \lambda\,\mathrm{tr}(\varepsilon)\,I``:

```@example small
λ = E * ν / ((1 + ν) * (1 - 2ν))
μ = E / (2 * (1 + ν))
2μ * ε + λ * (ε[1, 1] + ε[2, 2] + ε[3, 3]) * [1.0 0 0; 0 1 0; 0 0 1]
```

The stored energy is half the stress power:

```@example small
storedEnergy(mp), 0.5 * sum(σ[i, j] * ε[i, j] for i in 1:3, j in 1:3)
```

and the pressure is minus a third of the trace:

```@example small
pressure(mp), -sum(σ[i, i] for i in 1:3) / 3
```

## The tangent

`tangentTensor!` fills a fourth-order tensor with ``\partial\sigma/\partial\varepsilon``:

```@example small
ℂ = Itensor4()
tangentTensor!(mp, ℂ)
ℂ[1, 1, 1, 1], ℂ[1, 1, 2, 2], ℂ[1, 2, 1, 2]
```

For an isotropic material those are ``\lambda + 2\mu``, ``\lambda`` and ``\mu``:

```@example small
λ + 2μ, λ, μ
```

Contracting the tangent with the strain reproduces the stress, which is the check worth making
when wiring a new model into an element routine:

```@example small
contracted = [sum(ℂ[i, j, k, l] * ε[k, l] for k in 1:3, l in 1:3) for i in 1:3, j in 1:3]
contracted ≈ convert(Matrix{Float64}, σ)
```

## State bookkeeping

A material point distinguishes the *current* state from the last *converged* one. That is what
lets a solver iterate and then accept a step:

- `updateCurrentState(mp, t, ε)` sets the trial state
- `commitCurrentState(mp)` accepts it as converged
- `resetCurrentState(mp)` throws the trial state away and returns to the converged one

```@example small
commitCurrentState(mp)

# a trial step that the solver then rejects
updateCurrentState(mp, 2.0, Istensor(5 .* ε))
resetCurrentState(mp)

stress!(mp, σ)
σ
```

The stress is back to the committed value.

## Other small strain models

The same pattern covers the rest of the catalogue. The anisotropic families take their
constants as a vector, whose length identifies the model:

```@example small
using MuesliMaterials: ElasticOrthotropicMaterial, ElasticTransverselyisotropicMaterial

orthotropic = ElasticOrthotropicMaterial(
    [210000.0, 210000.0, 210000.0, 80000.0, 80000.0, 80000.0, 0.3, 0.3, 0.3], 1.0)
check(orthotropic)
```

Plasticity, viscoelasticity, viscoplasticity and the damage models
(`SplasticMaterial`, `ViscoelasticMaterial`, `ViscoplasticMaterial`, `GTN_Material`,
`Gurson_Material`, `Lemaitre_Material`, `LemKin_Material`) follow the same material/point
split; see the [API reference](../01_api_reference/02_materials.md) for their constructors.
