<h1 align="center">MuesliMaterials.jl</h1>

<p align="center">
  <strong>Julia bindings for the <a href="https://materials.imdea.org/muesli/">MUESLI</a> material library</strong>
</p>

<p align="center">
  <a href="https://henrij22.github.io/MuesliMaterials.jl/dev"><img src="https://img.shields.io/badge/docs-dev-blue.svg" alt="Docs dev"></a>
  <a href="https://github.com/henrij22/MuesliMaterials.jl/actions/workflows/CI.yml"><img src="https://github.com/henrij22/MuesliMaterials.jl/actions/workflows/CI.yml/badge.svg" alt="Build status"></a>
  <a href="https://codecov.io/gh/henrij22/MuesliMaterials.jl"><img src="https://codecov.io/gh/henrij22/MuesliMaterials.jl/graph/badge.svg?token=O5JKOFDWX1" alt="codecov"></a>
  <a href="https://github.com/JuliaTesting/Aqua.jl"><img src="https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg" alt="Aqua QA"></a>
  <a href="https://github.com/fredrikekre/Runic.jl"><img src="https://img.shields.io/badge/code_style-%E1%9A%B1%E1%9A%A2%E1%9A%BE%E1%9B%81%E1%9A%B2-black" alt="Code style: Runic"></a>
</p>

<p align="center">
  <a href="#installation">Installation</a> ·
  <a href="#bindings">Bindings</a> ·
  <a href="#documentation">Documentation</a>
</p>

---

This is a wrapper for the Julia Programming Language of the MUESLI library (Material UnivErSal LIbrary), a C++ library for modeling material response, developed at IMDEA Materials Institute, Madrid (Spain). See [Homepage](https://materials.imdea.org/muesli/) and [Repo](https://bitbucket.org/ignromero/muesli/src/master/).
The developer of this wrapper library is not affiliated with IMDEA in any form.

## Installation

MuesliMaterials.jl is **not registered** in the Julia General registry. The package and its binary
dependency `MuesliMaterialsWrapper_jll` are available through my Julia registry, which is the
recommended way to install it:

1. Add my registry:

```julia
using Pkg
pkg"registry add https://github.com/henrij22/JuliaRegistry"
```

2. Install MuesliMaterials:

```julia
pkg"add MuesliMaterials"
```

## Bindings

Currently the following modules have bindings:

- FiniteStrain models (hyperelastic and fininte plasticity available)
- SmallStrain models (including plasticity, viscoelasticity and damage models)
- Tensor and Vector classes

## Documentation

The [documentation](https://henrij22.github.io/MuesliMaterials.jl/dev/) has runnable examples
for the tensor types, small strain materials and finite strain materials, plus a full API
reference. Build it locally with:

```bash
julia --project=docs -e 'using Pkg; Pkg.develop(path="."); Pkg.instantiate()'
julia --project=docs docs/make.jl liveserver
```

### Naming convention

All bindings where made to be as faithful as possible but at the same time keeping existing Julia naming conventions in tact.

- Function names were kept as is. Functions that pass a pre-allocated tensor or vector quantities (e.g. `convectedTangent(itensor4& T)`) get a bang (!) (e.g `convectedTangent!(mp::MP, T::itensor4)`). Function names that alter the state of the material point (e.g. `setConvergedState`) don't get a bang.
- Class names were changed from camelCase to PascalCase (e.g. `itensor` -> `Itensor`)
