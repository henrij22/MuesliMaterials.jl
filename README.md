# Muesli

[![Build Status](https://github.com/henrij22/Muesli.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/henrij22/Muesli.jl/actions/workflows/CI.yml?query=branch%3Amain)
[![codecov](https://codecov.io/gh/henrij22/MuesliMaterials.jl/graph/badge.svg?token=O5JKOFDWX1)](https://codecov.io/gh/henrij22/MuesliMaterials.jl)
[![SciML Code Style](https://img.shields.io/static/v1?label=code%20style&message=SciML&color=9558b2&labelColor=389826)](https://github.com/SciML/SciMLStyle)
[![Aqua QA](https://raw.githubusercontent.com/JuliaTesting/Aqua.jl/master/badge.svg)](https://github.com/JuliaTesting/Aqua.jl)

This is a wrapper for the Julia Programming Language of the MUESLI library (Material UnivErSal LIbrary), a C++ library for modeling material response, developed at IMDEA Materials Institute, Madrid (Spain). See [Homepage](https://materials.imdea.org/muesli/) and [Repo](https://bitbucket.org/ignromero/muesli/src/master/).
The developer of this wrapper library is not affiliated with IMDEA in any form.

## Bindings

Currently the following modules have bindings:

- FiniteStrain models (without plasticity etc.)
- SmallStrain models (including plasticity, viscoelasticity and damage models)
- Tensor and Vector classes

### Naming convention

All bindings where made to be as faithful as possible but at the same time keeping existing Julia naming conventions in tact.

- Function names were kept as is. Functions that pass a pre-allocated tensor or vector quantities (e.g. `convectedTangent(itensor4& T)`) get a bang (!) (e.g `convectedTangent!(mp::MP, T::itensor4)`). Function names that alter the state of the material point (e.g. `setConvergedState`) don't get a bang.
- Class names were changed from camelCase to PascalCase (e.g. `itensor` -> `Itensor`)
