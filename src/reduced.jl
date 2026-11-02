# A reduced point only holds a pointer to the 3D point it wraps, so that point (and through it
# the material) has to be kept alive by the reduced one. See materialpoints.jl.
for (reduced, threed) in (
        (:SbarMP, :SmallStrainMP), (:SbeamMP, :SmallStrainMP), (:SshellMP, :SmallStrainMP),
        (:SplaneMP, :SmallStrainMP), (:FbarMP, :FiniteStrainMP), (:FbeamMP, :FiniteStrainMP),
        (:FshellMP, :FiniteStrainMP), (:FplaneMP, :FiniteStrainMP),
    )
    # CxxRef reaches the constructor CxxWrap generated; the narrower method below is not
    # applicable to it
    @eval begin
        $reduced(point::$threed) = keepalive($reduced(CxxRef(point)), point)
        $reduced(point::$threed, method::AbstractString) =
            keepalive($reduced(CxxRef(point), String(method)), point)
    end
end
