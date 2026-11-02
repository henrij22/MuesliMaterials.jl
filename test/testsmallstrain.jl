@testitem "Small strain: linear isotropic elasticity" begin
    include("testutils.jl")

    E, ν = 210000.0, 0.3
    λ, μ = lame(E, ν)

    mat = ElasticIsotropicMaterial(E, ν)
    @test MuesliMaterials.check(mat)

    mp = ElasticIsotropicMP(mat)
    ε = [0.001 0.0002 0.0; 0.0002 -0.0005 0.0001; 0.0 0.0001 0.0003]
    MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(ε))

    σ = Istensor()
    MuesliMaterials.stress!(mp, σ)
    got = mat3(σ)

    @testset "stress matches the closed-form isotropic law" begin
        @test got ≈ 2μ * ε + λ * tr3(ε) * I3 rtol = 1.0e-12
    end

    @testset "the stress is symmetric" begin
        @test got ≈ got'
    end

    @testset "stored energy is half the stress power" begin
        @test MuesliMaterials.storedEnergy(mp) ≈ 0.5 * sum(got .* ε) rtol = 1.0e-10
    end

    @testset "pressure is minus a third of the trace" begin
        @test MuesliMaterials.pressure(mp) ≈ -tr3(got) / 3 rtol = 1.0e-10
    end
end

@testitem "Small strain: the tangent is the analytic isotropic tensor" begin
    include("testutils.jl")

    E, ν = 210000.0, 0.3
    λ, μ = lame(E, ν)

    mp = ElasticIsotropicMP(ElasticIsotropicMaterial(E, ν))
    MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(zeros(3, 3)))

    C = Itensor4()
    MuesliMaterials.tangentTensor!(mp, C)
    got = ten4(C)

    expected = [
        λ * δ(i, j) * δ(k, l) + μ * (δ(i, k) * δ(j, l) + δ(i, l) * δ(j, k))
            for i in 1:3, j in 1:3, k in 1:3, l in 1:3
    ]
    @test got ≈ expected rtol = 1.0e-10

    @testset "minor and major symmetries" begin
        for i in 1:3, j in 1:3, k in 1:3, l in 1:3
            @test got[i, j, k, l] ≈ got[j, i, k, l]      # minor, first pair
            @test got[i, j, k, l] ≈ got[i, j, l, k]      # minor, second pair
            @test got[i, j, k, l] ≈ got[k, l, i, j]      # major
        end
    end

    @testset "the tangent maps strain onto stress" begin
        ε = [0.001 0.0002 0.0; 0.0002 -0.0005 0.0001; 0.0 0.0001 0.0003]
        mp2 = ElasticIsotropicMP(ElasticIsotropicMaterial(E, ν))
        MuesliMaterials.updateCurrentState(mp2, 1.0, Istensor(ε))
        σ = Istensor()
        MuesliMaterials.stress!(mp2, σ)

        contracted = [sum(got[i, j, k, l] * ε[k, l] for k in 1:3, l in 1:3) for i in 1:3, j in 1:3]
        @test contracted ≈ mat3(σ) rtol = 1.0e-10
    end
end

@testitem "Small strain: elementary properties of the elastic response" begin
    include("testutils.jl")

    E, ν = 210000.0, 0.3
    λ, μ = lame(E, ν)
    mat = ElasticIsotropicMaterial(E, ν)

    stress_at(ε) = begin
        mp = ElasticIsotropicMP(mat)
        MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(ε))
        σ = Istensor()
        MuesliMaterials.stress!(mp, σ)
        mat3(σ)
    end

    @testset "zero strain is stress free" begin
        @test all(abs.(stress_at(zeros(3, 3))) .< 1.0e-12)
    end

    @testset "the response is linear" begin
        ε = [0.001 0.0002 0.0; 0.0002 -0.0005 0.0001; 0.0 0.0001 0.0003]
        @test stress_at(2 .* ε) ≈ 2 .* stress_at(ε) rtol = 1.0e-10
        @test stress_at(-ε) ≈ -stress_at(ε) rtol = 1.0e-10
    end

    @testset "a pure volumetric strain gives a pure pressure" begin
        e = 0.001
        σ = stress_at(e * I3)
        K = E / (3 * (1 - 2ν))                       # bulk modulus
        @test σ ≈ 3K * e * I3 rtol = 1.0e-10
    end

    @testset "a pure shear strain gives a pure shear stress" begin
        γ = 0.001
        ε = [0.0 γ 0.0; γ 0.0 0.0; 0.0 0.0 0.0]
        σ = stress_at(ε)
        @test σ[1, 2] ≈ 2μ * γ rtol = 1.0e-10
        @test abs(tr3(σ)) < 1.0e-8                     # no volumetric part
    end
end

@testitem "Small strain: building a material from MaterialProperties" begin
    include("testutils.jl")

    E, ν = 210000.0, 0.3
    props = MuesliMaterials.MaterialProperties()
    MuesliMaterials.setProperty!(props, "young", E)
    MuesliMaterials.setProperty!(props, "poisson", ν)

    fromProps = ElasticIsotropicMaterial(props)
    direct = ElasticIsotropicMaterial(E, ν)

    @test MuesliMaterials.check(fromProps)
    @test MuesliMaterials.getProperty(fromProps, MuesliMaterials.PR_YOUNG) ≈ E
    @test MuesliMaterials.getProperty(fromProps, MuesliMaterials.PR_POISSON) ≈ ν

    @testset "both routes give the same response" begin
        ε = [0.001 0.0 0.0; 0.0 0.0 0.0; 0.0 0.0 0.0]
        stress_of(m) = begin
            mp = ElasticIsotropicMP(m)
            MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(ε))
            σ = Istensor()
            MuesliMaterials.stress!(mp, σ)
            mat3(σ)
        end
        @test stress_of(direct) ≈ stress_of(fromProps) rtol = 1.0e-12
    end
end

@testitem "Small strain: state bookkeeping" begin
    include("testutils.jl")

    E, ν = 210000.0, 0.3
    λ, μ = lame(E, ν)
    mp = ElasticIsotropicMP(ElasticIsotropicMaterial(E, ν))
    ε = [0.001 0.0 0.0; 0.0 0.0 0.0; 0.0 0.0 0.0]

    MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(ε))
    MuesliMaterials.commitCurrentState(mp)

    @testset "resetCurrentState returns to the committed state" begin
        MuesliMaterials.updateCurrentState(mp, 2.0, Istensor(5 .* ε))
        MuesliMaterials.resetCurrentState(mp)

        σ = Istensor()
        MuesliMaterials.stress!(mp, σ)
        @test mat3(σ) ≈ 2μ * ε + λ * tr3(ε) * I3 rtol = 1.0e-10
    end

    @testset "InterfaceState accessors are 1-based" begin
        st = MuesliMaterials.getCurrentState(mp)
        n = Int(MuesliMaterials.getStensorSize(st))
        @test n ≥ 1
        @test MuesliMaterials.getStensor(st, 1) !== nothing
        if !Sys.isapple()
            @test_throws Exception MuesliMaterials.getStensor(st, 0)
            @test_throws Exception MuesliMaterials.getStensor(st, n + 1)
        end
        @test MuesliMaterials.getTime(st) isa Float64
    end
end

@testitem "Small strain: anisotropic and orthotropic materials" begin
    include("testutils.jl")
    # These material types are registered but not exported, unlike ElasticIsotropic.
    using MuesliMaterials: ElasticAnisotropicMaterial, ElasticOrthotropicMaterial,
        ElasticTransverselyisotropicMaterial, ElasticTransverselyisotropicMP

    # The constant-vector constructors only validate the length here; whether the resulting
    # material is admissible is not asserted, because muesli's 9- and 6-constant constructors
    # fill only part of the elasticity matrix and leave the rest uninitialised. The property
    # map route below zeroes it first and is the one to use.
    @testset "orthotropic takes nine constants" begin
        c = [210000.0, 210000.0, 210000.0, 80000.0, 80000.0, 80000.0, 0.3, 0.3, 0.3]
        @test ElasticOrthotropicMaterial(c, 1.0) !== nothing
        !Sys.isapple() && @test_throws Exception ElasticOrthotropicMaterial([1.0, 2.0], 1.0)
    end

    @testset "transversely isotropic takes six" begin
        c = [210000.0, 80000.0, 0.3, 210000.0, 80000.0, 0.3]
        @test ElasticTransverselyisotropicMaterial(c, 1.0) !== nothing
        !Sys.isapple() && @test_throws Exception ElasticTransverselyisotropicMaterial([1.0], 1.0)
    end

    @testset "transversely isotropic from engineering constants" begin
        # Unlike the c-vector constructor above, this one zeroes the whole elasticity matrix
        # before filling it in, so check() and the stresses below are fully deterministic.
        E1, E2, ν12, G23, G12 = 210000.0, 70000.0, 0.3, 25000.0, 30000.0
        mat = ElasticTransverselyisotropicMaterial(E1, E2, ν12, G23, G12, 1.0)
        @test MuesliMaterials.check(mat) isa Bool

        # Replicates muesli's own derivation of the stiffness matrix from the engineering
        # constants, to check the constructor end to end against the resulting stresses.
        ν21 = E2 / E1 * ν12
        ν23 = E2 / (2.0 * G23) - 1.0
        lam = (ν12 * ν21 + ν23) / ((1.0 - ν23 - 2.0 * ν12 * ν21) * (1.0 + ν23)) * E2
        C11 = (1.0 - ν23) / (1.0 - ν23 - 2.0 * ν12 * ν21) * E1
        C12 = 2.0 * ν12 * (lam + G23)   # == C13, by transverse symmetry about the x axis
        C22 = lam + 2.0 * G23           # == C33
        C23 = lam

        stress_at(ε) = begin
            mp = ElasticTransverselyisotropicMP(mat)
            MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(ε))
            σ = Istensor()
            MuesliMaterials.stress!(mp, σ)
            mat3(σ)
        end

        σ1 = stress_at(Diagonal3(0.001, 0.0, 0.0))
        @test σ1[1, 1] ≈ C11 * 0.001 rtol = 1.0e-10
        @test σ1[2, 2] ≈ C12 * 0.001 rtol = 1.0e-10
        @test σ1[3, 3] ≈ C12 * 0.001 rtol = 1.0e-10

        σ2 = stress_at(Diagonal3(0.0, 0.001, 0.0))
        @test σ2[2, 2] ≈ C22 * 0.001 rtol = 1.0e-10
        @test σ2[3, 3] ≈ C23 * 0.001 rtol = 1.0e-10
    end

    @testset "orthotropic is constructible from a property map" begin
        mat = ElasticOrthotropicMaterial(
            properties(
                "young1" => 210000.0, "young2" => 190000.0, "young3" => 180000.0,
                "poisson12" => 0.3, "poisson13" => 0.28, "poisson23" => 0.27,
                "g12" => 80000.0, "g13" => 78000.0, "g23" => 76000.0, "density" => 1.0
            )
        )
        @test MuesliMaterials.check(mat) isa Bool
    end

    @testset "fully anisotropic takes twenty-one" begin
        !Sys.isapple() && @test_throws Exception ElasticAnisotropicMaterial(zeros(20), 1.0)
    end
end

@testitem "Small strain: Voigt tangent matrix" begin
    include("testutils.jl")

    E, ν = 210000.0, 0.3
    λ, μ = lame(E, ν)

    mp = ElasticIsotropicMP(ElasticIsotropicMaterial(E, ν))
    MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(zeros(3, 3)))

    Cm = zeros(6, 6)
    MuesliMaterials.tangentMatrix!(mp, Cm)

    # order 11, 22, 33, 23, 13, 12; the matrix acts on engineering shear strains
    expected = zeros(6, 6)
    for i in 1:3, j in 1:3
        expected[i, j] = i == j ? λ + 2μ : λ
    end
    for i in 4:6
        expected[i, i] = μ
    end
    @test Cm ≈ expected rtol = 1.0e-10

    !Sys.isapple() && @test_throws Exception MuesliMaterials.tangentMatrix!(mp, zeros(3, 3))
end

@testitem "Small strain: thermodynamic potentials" begin
    include("testutils.jl")

    mp = ElasticIsotropicMP(ElasticIsotropicMaterial(210000.0, 0.3))
    ε = [0.001 0.0002 0.0; 0.0002 -0.0005 0.0001; 0.0 0.0001 0.0003]
    MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(ε))

    tp = MuesliMaterials.thermodynamicPotentials(mp)
    @test MuesliMaterials.volumetric(tp) ≈ MuesliMaterials.volumetricEnergy(mp) rtol = 1.0e-10
    @test MuesliMaterials.deviatoric(tp) ≈ MuesliMaterials.deviatoricEnergy(mp) rtol = 1.0e-10
    @test MuesliMaterials.internalEnergy(tp) ≈ MuesliMaterials.storedEnergy(mp) rtol = 1.0e-10
end

@testitem "Properties shared by every material" begin
    for mat in (ElasticIsotropicMaterial(210000.0, 0.3), NeoHookeMaterial(210000.0, 0.3))
        MuesliMaterials.setDensity(mat, 7.85)
        @test MuesliMaterials.density(mat) == 7.85
        MuesliMaterials.setReferenceTemperature(mat, 293.0)
        @test MuesliMaterials.referenceTemperature(mat) == 293.0
        @test !MuesliMaterials.isVariational(mat)
        MuesliMaterials.setVariational(mat)
        @test MuesliMaterials.isVariational(mat)
    end
end

@testitem "Material points keep their material alive" begin
    include("testutils.jl")

    E, ν = 210000.0, 0.3
    λ, μ = lame(E, ν)
    ε = [0.001 0.0 0.0; 0.0 0.0 0.0; 0.0 0.0 0.0]
    expected = 2μ * ε + λ * ε[1, 1] * I3

    # the material goes out of scope as soon as the point is built
    from_constructor() = ElasticIsotropicMP(ElasticIsotropicMaterial(E, ν))
    from_create() = MuesliMaterials.createMaterialPoint(ElasticIsotropicMaterial(E, ν))

    @testset "$name" for (name, make) in (("constructor", from_constructor), ("createMaterialPoint", from_create))
        points = [make() for _ in 1:2000]
        for _ in 1:3
            GC.gc(true)
        end
        junk = [ElasticIsotropicMaterial(1.0 + i, 0.4) for i in 1:5000]   # reuse the freed memory

        σ = Istensor()
        stresses = map(points) do mp
            MuesliMaterials.updateCurrentState(mp, 1.0, Istensor(ε))
            MuesliMaterials.stress!(mp, σ)
            mat3(σ)
        end
        @test all(s -> s ≈ expected, stresses)
        @test length(junk) == 5000
    end
end

@testitem "Small strain: viscoplasticity with nonlinear hardening" begin
    include("testutils.jl")

    mat = ViscoplasticNLMaterial(;
        E = 210.0e3, nu = 0.3, rho = 7.8e-9, yield = 300.0, Hiso = 1000.0, Hinf = 100.0, H0 = 0.0,
        Hdelta = 1.0, eta = 1.0, exponent = 1.0, alpha = 0.5
    )
    @test MuesliMaterials.check(mat)
    @test MuesliMaterials.density(mat) ≈ 7.8e-9

    function response(ε11, t)
        mp = ViscoplasticNLMP(mat)
        MuesliMaterials.updateCurrentState(mp, t, Istensor(Diagonal3(ε11, 0.0, 0.0)))
        σ = Istensor()
        MuesliMaterials.stress!(mp, σ)
        return σ[1, 1], MuesliMaterials.plasticSlip(mp)
    end

    @test response(1.0e-4, 1.0)[2] == 0
    @test response(2.0e-2, 1.0)[2] > 0
    slow, medium, fast = (response(2.0e-2, t)[1] for t in (1.0e3, 1.0, 1.0e-3))
    @test fast > medium ≥ slow
end

@testitem "Reduced models: small strain" begin
    include("testutils.jl")

    E, ν = 210.0e3, 0.3
    G = E / (2 * (1 + ν))
    ε = [1.0e-3 4.0e-4 2.0e-4; 4.0e-4 -5.0e-4 3.0e-4; 2.0e-4 3.0e-4 7.0e-4]

    function response(R, ε, args...)
        mat = ElasticIsotropicMaterial(E, ν)
        rmp = R(ElasticIsotropicMP(mat), args...)
        strain = Istensor(ε)
        MuesliMaterials.updateCurrentState!(rmp, 1.0, strain)
        σ = Istensor()
        MuesliMaterials.stress!(rmp, σ)
        C = zeros(6, 6)
        MuesliMaterials.tangentMatrix!(rmp, C)
        return mat3(strain), mat3(σ), C
    end

    @testset "bar" begin
        εf, σ, C = response(SbarMP, Diagonal3(1.0e-3, 0.0, 0.0))
        @test εf[2, 2] ≈ -ν * 1.0e-3 && εf[3, 3] ≈ -ν * 1.0e-3
        @test σ[1, 1] ≈ E * 1.0e-3
        @test C[1, 1] ≈ E
    end

    @testset "plane stress and shell" begin
        for R in (SplaneMP, SshellMP)
            εf, σ, C = response(R, ε)
            @test εf[3, 3] ≈ -ν / (1 - ν) * (ε[1, 1] + ε[2, 2])
            @test σ[3, 3] ≈ 0 atol = 1.0e-6
            @test C[1, 1] ≈ E / (1 - ν^2)
        end
    end

    @testset "beam" begin
        _, σ, C = response(SbeamMP, ε)
        @test all(abs(σ[i, j]) < 1.0e-6 for (i, j) in ((1, 1), (2, 2), (1, 2)))
        @test C[3, 3] ≈ E && C[4, 4] ≈ G
    end

    @testset "conjugate gradient solver" begin
        @test response(SbeamMP, ε, "nlcg")[2] ≈ response(SbeamMP, ε)[2] atol = 1.0e-6
    end

    @testset "the 3D point and its material outlive their last reference" begin
        rmp = SplaneMP(ElasticIsotropicMP(ElasticIsotropicMaterial(E, ν)))
        GC.gc(); GC.gc()
        strain = Istensor(ε)
        MuesliMaterials.updateCurrentState!(rmp, 1.0, strain)
        σ = Istensor()
        MuesliMaterials.stress!(rmp, σ)
        @test σ[3, 3] ≈ 0 atol = 1.0e-6
        @test rmp isa MuesliMaterials.ReducedSmallStrainMP
        @test MuesliMaterials.MATERIAL_OF_POINT[rmp] isa ElasticIsotropicMP
    end
end

@testitem "Small strain: viscoplasticity from keywords" begin
    include("testutils.jl")

    E, ν = 210.0e3, 0.3
    mat = MuesliMaterials.ViscoplasticMaterial(;
        E, nu = ν, rho = 7.8e-9, yield = 300.0, Hiso = 1000.0, Hkine = 0.0, eta = 1.0, alpha = 0.0
    )
    @test MuesliMaterials.check(mat)
    @test MuesliMaterials.getProperty(mat, MuesliMaterials.PR_YOUNG) ≈ E
    @test MuesliMaterials.getProperty(mat, MuesliMaterials.PR_POISSON) ≈ ν
    @test MuesliMaterials.density(mat) ≈ 7.8e-9

    function response(ε11, t)
        mp = MuesliMaterials.ViscoplasticMP(mat)
        MuesliMaterials.updateCurrentState(mp, t, Istensor(Diagonal3(ε11, -ν * ε11, -ν * ε11)))
        σ = Istensor()
        MuesliMaterials.stress!(mp, σ)
        return σ[1, 1], MuesliMaterials.plasticSlip(mp)
    end

    σ, slip = response(1.0e-4, 1.0)
    @test σ ≈ E * 1.0e-4 rtol = 1.0e-6
    @test slip == 0
    @test response(2.0e-2, 1.0)[2] > 0
end

@testitem "Small strain: positional viscoplasticity takes Young's modulus and Poisson's ratio" begin
    include("testutils.jl")

    E, ν = 210.0e3, 0.3
    mat = MuesliMaterials.ViscoplasticMaterial(E, ν, 7.8e-9, 1000.0, 0.0, 300.0, "mises", 1.0, 0.0)
    @test MuesliMaterials.check(mat)
    @test MuesliMaterials.density(mat) ≈ 7.8e-9
    @test MuesliMaterials.getProperty(mat, MuesliMaterials.PR_YOUNG) ≈ E
    @test MuesliMaterials.getProperty(mat, MuesliMaterials.PR_POISSON) ≈ ν
end
