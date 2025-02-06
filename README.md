# Muesli

[![Build Status](https://github.com/henrij22/Muesli.jl/actions/workflows/CI.yml/badge.svg?branch=main)](https://github.com/henrij22/Muesli.jl/actions/workflows/CI.yml?query=branch%3Amain)


This is a warepper for the Julia Programming Language of the MUESLI library (Material UnivErSal LIbrary), a C++ library for modeling material response, developed at IMDEA Materials Institute, Madrid (Spain).See [Homepage](https://materials.imdea.org/muesli/) and [Repo](https://bitbucket.org/ignromero/muesli/src/master/).
The developer of this wrapper library is is not affiliated with IMDEA.

## Bindings
Currently the following modules have bindings:

- FiniteStrain models (without plasticity etc.)
- SmallStrain models (including plasticity, viscoelasticiy and damage models)
- Tensor and Vector classes

### Naming convention

All bindings where made to be as faithful as possible but at the same time keeping existing julia naming conventions in tact.

- Function names were kept as is. Functions that pass a preallocated tensor or vector quanities (e.g. `convectedTangent(itensor4& T)`) get a bang (!) (e.g `convectedTangent!(mp::MP, T::itensor4)`). Function names that alter the state of the materrial point (e.g. `setConvergedState`) don't get a bang.
- Class names were changed from camelCase to PascalCase (e.g. `itensor` -> `Itensor`)

