# Finite strain materials

```@example finite
using MuesliMaterials
using MuesliMaterials: check, updateCurrentState, storedEnergy, deformationGradient,
    firstPiolaKirchhoffStress!, firstPiolaKirchhoffStressNumerical!,
    secondPiolaKirchhoffStress!, KirchhoffStress!, CauchyStress!,
    convectedTangent!, materialTangent!, spatialTangent!,
    setProperty!, MaterialProperties
nothing # hide
```

Finite strain models take the deformation gradient ``F`` rather than a strain tensor, and
offer several stress measures. This page uses a neo-Hookean material.

## Building the material

Hyperelastic materials are constructed from a property map:

```@example finite
props = MaterialProperties()
setProperty!(props, "young", 210000.0)
setProperty!(props, "poisson", 0.3)

material = NeoHookeMaterial(props)
check(material)
```

```@example finite
mp = NeoHookeMP(material)
nothing # hide
```

## The undeformed state

At ``F = I`` a hyperelastic material must be stress free and store no energy:

```@example finite
I3 = [1.0 0 0; 0 1 0; 0 0 1]
updateCurrentState(mp, 1.0, Itensor(I3))

P = Itensor()
firstPiolaKirchhoffStress!(mp, P)
P
```

```@example finite
storedEnergy(mp)
```

## A deformed state

`updateCurrentState` takes the deformation gradient as an [`Itensor`](@ref) — note that this
is a general tensor, not a symmetric one:

```@example finite
F = [1.05 0.02 0.0
     0.0 0.98 0.01
     0.0 0.0 1.01]

updateCurrentState(mp, 1.0, Itensor(F))
deformationGradient(mp)
```

```@example finite
storedEnergy(mp)
```

## The stress measures

MUESLI exposes the usual family, each filled into a preallocated tensor. Note which are
symmetric: ``S``, ``\tau`` and ``\sigma`` are, ``P`` is not.

```@example finite
P = Itensor();   firstPiolaKirchhoffStress!(mp, P)
S = Istensor();  secondPiolaKirchhoffStress!(mp, S)
τ = Istensor();  KirchhoffStress!(mp, τ)
σ = Istensor();  CauchyStress!(mp, σ)
nothing # hide
```

They are related by ``P = FS``, ``\tau = PF^{T}`` and ``\tau = J\sigma``. Those identities are
the quickest way to confirm you are reading the right quantity:

```@example finite
Pm = convert(Matrix{Float64}, P)
Sm = convert(Matrix{Float64}, S)
τm = convert(Matrix{Float64}, τ)
σm = convert(Matrix{Float64}, σ)

J = F[1, 1] * (F[2, 2] * F[3, 3] - F[2, 3] * F[3, 2]) -
    F[1, 2] * (F[2, 1] * F[3, 3] - F[2, 3] * F[3, 1]) +
    F[1, 3] * (F[2, 1] * F[3, 2] - F[2, 2] * F[3, 1])

(PeqFS = Pm ≈ F * Sm, τeqPFt = τm ≈ Pm * F', τeqJσ = τm ≈ J .* σm)
```

### Checking an implementation

MUESLI can differentiate the stored energy numerically, which is the check to run when you are
unsure whether a model is wired up correctly:

```@example finite
Pnum = Itensor()
firstPiolaKirchhoffStressNumerical!(mp, Pnum)
isapprox(convert(Matrix{Float64}, P), convert(Matrix{Float64}, Pnum); rtol = 1e-5, atol = 1e-6)
```

## Frame indifference

Rotating the deformation must leave the material response unchanged: ``S`` is untouched,
``\sigma`` rotates with the body, and the stored energy is the same.

```@example finite
θ = 0.4
Q = [cos(θ) -sin(θ) 0.0; sin(θ) cos(θ) 0.0; 0.0 0.0 1.0]

rotated = NeoHookeMP(material)
updateCurrentState(rotated, 1.0, Itensor(Q * F))

S2 = Istensor(); secondPiolaKirchhoffStress!(rotated, S2)
σ2 = Istensor(); CauchyStress!(rotated, σ2)

(
    S_unchanged = convert(Matrix{Float64}, S2) ≈ Sm,
    σ_rotates = convert(Matrix{Float64}, σ2) ≈ Q * σm * Q',
    W_unchanged = storedEnergy(rotated) ≈ storedEnergy(mp),
)
```

## Tangents

Three tangents are available, in the configuration their names suggest:

```@example finite
c = Itensor4()
convectedTangent!(mp, c)
c[1, 1, 1, 1]
```

```@example finite
cm = Itensor4(); materialTangent!(mp, cm)
cs = Itensor4(); spatialTangent!(mp, cs)
(material = cm[1, 1, 1, 1], spatial = cs[1, 1, 1, 1])
```

## Other finite strain models

`SVKMaterial`, `YeohMaterial`, `MooneyMaterial` and `ArrudaBoyceMaterial` follow the same
pattern, as does `FplasticMaterial` for finite plasticity. Saint Venant–Kirchhoff, for
instance:

```@example finite
svk = SVKMaterial(props)
svkmp = SVKMP(svk)
updateCurrentState(svkmp, 1.0, Itensor(F))

Psvk = Itensor()
firstPiolaKirchhoffStress!(svkmp, Psvk)
Psvk
```
