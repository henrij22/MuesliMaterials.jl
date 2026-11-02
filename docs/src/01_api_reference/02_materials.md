# Materials

A material carries the parameters of a constitutive model. It is built once and can be shared
by any number of material points.

## Material properties

Most models can be constructed from a property map, which is how MUESLI passes named
parameters.

```@docs
MuesliMaterials.MaterialProperties
MuesliMaterials.setProperty!
MuesliMaterials.getProperty
MuesliMaterials.setString!
MuesliMaterials.getString
MuesliMaterials.hasKeyword
```

## Common queries

```@docs
MuesliMaterials.check
MuesliMaterials.print
MuesliMaterials.createMaterialPoint
MuesliMaterials.name
```

## Bulk properties

Every material has a density and a reference temperature, and can be flagged for the variational
formulation.

```@docs
MuesliMaterials.density
MuesliMaterials.setDensity
MuesliMaterials.referenceTemperature
MuesliMaterials.setReferenceTemperature
MuesliMaterials.isVariational
MuesliMaterials.setVariational
```

## Small strain materials

```@docs
ElasticIsotropicMaterial
MuesliMaterials.ElasticAnisotropicMaterial
MuesliMaterials.ElasticOrthotropicMaterial
MuesliMaterials.ElasticTransverselyisotropicMaterial
MuesliMaterials.SplasticMaterial
MuesliMaterials.ViscoelasticMaterial
MuesliMaterials.ViscoplasticMaterial
ViscoplasticNLMaterial
```

### Damage models

```@docs
MuesliMaterials.GTN_Material
MuesliMaterials.Gurson_Material
MuesliMaterials.Lemaitre_Material
MuesliMaterials.LemKin_Material
```

## Finite strain materials

```@docs
NeoHookeMaterial
SVKMaterial
YeohMaterial
MuesliMaterials.MooneyMaterial
MuesliMaterials.ArrudaBoyceMaterial
MuesliMaterials.FplasticMaterial
JohnsonCookMaterial
ZerilliArmstrongMaterial
```

## Property names

The `PR_*` constants name the properties a material can be queried for with
[`MuesliMaterials.getProperty`](@ref) — `PR_YOUNG`, `PR_POISSON`, `PR_LAMBDA`, `PR_MU`,
`PR_BULK`, `PR_YIELD` and so on.
