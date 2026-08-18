# Shared helpers for the test items.
#
# Each @testitem runs in its own module, so this file is `include`d from the items that need
# it rather than defining anything globally.

using MuesliMaterials

"""Read a 3x3 muesli tensor into a plain Julia matrix."""
mat3(t) = [t[i, j] for i in 1:3, j in 1:3]

"""Read a 3x3x3x3 muesli tensor into a plain Julia array."""
ten4(t) = [t[i, j, k, l] for i in 1:3, j in 1:3, k in 1:3, l in 1:3]

"""Kronecker delta."""
δ(i, j) = i == j ? 1.0 : 0.0

"""Trace of a 3x3 matrix."""
tr3(a) = a[1, 1] + a[2, 2] + a[3, 3]

const I3 = [1.0 0.0 0.0; 0.0 1.0 0.0; 0.0 0.0 1.0]

"""Lamé parameters `(λ, μ)` from Young's modulus and Poisson's ratio."""
lame(E, ν) = (E * ν / ((1 + ν) * (1 - 2ν)), E / (2 * (1 + ν)))

"""A `MaterialProperties` map built from `"key" => value` pairs."""
function properties(pairs...)
    p = MuesliMaterials.MaterialProperties()
    for (k, v) in pairs
        MuesliMaterials.setProperty!(p, k, v)
    end
    return p
end

"""Determinant of a 3x3 matrix, without pulling in LinearAlgebra."""
function det3(a)
    return a[1, 1] * (a[2, 2] * a[3, 3] - a[2, 3] * a[3, 2]) -
        a[1, 2] * (a[2, 1] * a[3, 3] - a[2, 3] * a[3, 1]) +
        a[1, 3] * (a[2, 1] * a[3, 2] - a[2, 2] * a[3, 1])
end

"""A 3x3 diagonal matrix."""
Diagonal3(a, b, c) = [a 0.0 0.0; 0.0 b 0.0; 0.0 0.0 c]
