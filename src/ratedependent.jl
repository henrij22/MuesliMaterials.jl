function propertymap(pairs...)
    props = MaterialProperties()
    for (key, value) in pairs
        setProperty!(props, key, Float64(value))
    end
    return props
end

function JohnsonCookMaterial(;
        E, nu, A, B, C, n, m, edot0, T, Tref, Tmelt, rho = 1.0
    )
    return JohnsonCookMaterial(
        propertymap(
            "young" => E, "poisson" => nu, "density" => rho, "a" => A, "b" => B, "c" => C,
            "n" => n, "m" => m, "edot0" => edot0, "temp" => T, "modelreftemp" => Tref,
            "melttemp" => Tmelt,
        )
    )
end

function ZerilliArmstrongMaterial(;
        E, nu, C0, C1, C2, C3, C4, C5, n, T, a1 = 1.0, b1 = 1.0, rho = 1.0
    )
    return ZerilliArmstrongMaterial(
        propertymap(
            "young" => E, "poisson" => nu, "density" => rho, "c0" => C0, "c1" => C1, "c2" => C2,
            "c3" => C3, "c4" => C4, "c5" => C5, "n" => n, "temp" => T, "a1" => a1, "b1" => b1,
        )
    )
end

function ViscoplasticNLMaterial(;
        E, nu, yield, Hiso, Hinf, H0, Hdelta, eta, exponent, alpha, Hkine = 0.0, rho = 1.0,
        plasticity = "mises"
    )
    props = propertymap(
        "young" => E, "poisson" => nu, "density" => rho, "yieldstress" => yield,
        "isotropich" => Hiso, "isohardinf" => Hinf, "isohardzero" => H0, "isoharddelta" => Hdelta,
        "kinematich" => Hkine, "eta" => eta, "viscousexponent" => exponent, "alpha" => alpha,
    )
    setString!(props, "plasticity", plasticity)
    return ViscoplasticNLMaterial(props)
end

function ViscoplasticMaterial(;
        E, nu, yield, Hiso, Hkine, eta, alpha, exponent = 1.0, rateref = 1.0, rho = 1.0,
        plasticity = "von_mises"
    )
    props = propertymap(
        "young" => E, "poisson" => nu, "density" => rho, "yieldstress" => yield,
        "isotropich" => Hiso, "kinematich" => Hkine, "eta" => eta, "alpha" => alpha,
        "viscousexponent" => exponent, "srateref" => rateref,
    )
    setString!(props, "model", plasticity)
    return ViscoplasticMaterial(props)
end
