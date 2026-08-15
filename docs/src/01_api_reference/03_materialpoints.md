# Material points

A material point carries the state at one location: the current deformation, the last
converged state, and any internal variables. It is created from a material and then driven
through a load history.

## Types

```@docs
ElasticIsotropicMP
NeoHookeMP
SVKMP
YeohMP
```

Every material has a matching point type, named the same way
(`SplasticMP`, `ViscoelasticMP`, `GTN_MP`, `FplasticMP`, …).

## Driving the state

```@docs
MuesliMaterials.updateCurrentState
MuesliMaterials.commitCurrentState
MuesliMaterials.resetCurrentState
MuesliMaterials.setConvergedState
```

## Small strain response

```@docs
MuesliMaterials.stress!
MuesliMaterials.deviatoricStress!
MuesliMaterials.pressure
MuesliMaterials.tangentTensor!
```

## Finite strain response

```@docs
MuesliMaterials.firstPiolaKirchhoffStress!
MuesliMaterials.secondPiolaKirchhoffStress!
MuesliMaterials.KirchhoffStress!
MuesliMaterials.CauchyStress!
MuesliMaterials.firstPiolaKirchhoffStressNumerical!
MuesliMaterials.secondPiolaKirchhoffStressNumerical!
MuesliMaterials.deformationGradient
MuesliMaterials.convergedDeformationGradient
```

### Tangents

```@docs
MuesliMaterials.convectedTangent!
MuesliMaterials.materialTangent!
MuesliMaterials.spatialTangent!
```

## Energies

```@docs
MuesliMaterials.storedEnergy
MuesliMaterials.effectiveStoredEnergy
MuesliMaterials.deviatoricEnergy
MuesliMaterials.volumetricEnergy
MuesliMaterials.kineticPotential
MuesliMaterials.energyDissipationInStep
```

## Inspecting the state

```@docs
MuesliMaterials.getCurrentState
MuesliMaterials.getConvergedState
MuesliMaterials.InterfaceState
MuesliMaterials.getTime
MuesliMaterials.getStensorSize
MuesliMaterials.getStensor
MuesliMaterials.getTensorSize
MuesliMaterials.getTensor
MuesliMaterials.getVectorSize
MuesliMaterials.getVector
```

## Plasticity and damage

```@docs
MuesliMaterials.plasticSlip
MuesliMaterials.getCurrentPlasticStrain
MuesliMaterials.getConvergedPlasticStrain
MuesliMaterials.getDamage
MuesliMaterials.isFullyDamaged
```
