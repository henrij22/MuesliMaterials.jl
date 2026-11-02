# A MUESLI material point keeps only a C++ reference to its material, which Julia knows nothing
# about. Without this, the garbage collector may free a material while points built from it are
# still alive, and they then read freed memory.
#
# A finalizer closure would not do: the GC does not keep what a finalizer captures alive. A
# WeakKeyDict holds its values strongly for exactly as long as the key (the point) is reachable.
const MATERIAL_OF_POINT = WeakKeyDict{Any, Any}()

function keepalive(point, material)
    MATERIAL_OF_POINT[point] = material
    return point
end

function createMaterialPoint(material::Material)
    return keepalive(cxxCreateMaterialPoint(material), material)
end

# `FooMP(material)` goes through createMaterialPoint. The argument type is deliberately narrower
# than the constructor CxxWrap generates, which accepts `Union{FooMaterial, CxxRef{<:FooMaterial}, ...}`,
# so this adds a more specific method instead of overwriting one.
for name in names(@__MODULE__; all = true)
    string_name = String(name)
    endswith(string_name, "Material") || continue
    MaterialType = getfield(@__MODULE__, name)
    MaterialType isa DataType && nameof(MaterialType) === name || continue   # skips the __cxxwrap_dt_ aliases
    point_name = Symbol(chopsuffix(string_name, "Material") * "MP")
    isdefined(@__MODULE__, point_name) || continue
    hasmethod(cxxCreateMaterialPoint, Tuple{MaterialType}) || continue
    PointType = getfield(@__MODULE__, point_name)
    @eval (::Type{$PointType})(material::$MaterialType) = createMaterialPoint(material)
end
