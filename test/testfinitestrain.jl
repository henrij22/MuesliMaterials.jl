@testitem "Finite strain: the undeformed state is stress free" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)

    for (name, matT, mpT) in (
            ("NeoHooke", NeoHookeMaterial, NeoHookeMP),
            ("SVK", SVKMaterial, SVKMP),
        )
        @testset "$name" begin
            mat = matT(props)
            @test MuesliMaterials.check(mat)

            mp = mpT(mat)
            MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(I3))

            P = Itensor()
            MuesliMaterials.firstPiolaKirchhoffStress!(mp, P)
            @test all(abs.(mat3(P)) .< 1.0e-8)

            @test MuesliMaterials.storedEnergy(mp) ≈ 0.0 atol = 1.0e-8
        end
    end
end

@testitem "Finite strain: analytic stress agrees with muesli's numerical derivative" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)
    F = [1.05 0.02 0.0; 0.0 0.98 0.01; 0.0 0.0 1.01]

    for (name, matT, mpT) in (
            ("NeoHooke", NeoHookeMaterial, NeoHookeMP),
            ("SVK", SVKMaterial, SVKMP),
        )
        @testset "$name" begin
            mp = mpT(matT(props))
            MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(F))

            P = Itensor()
            MuesliMaterials.firstPiolaKirchhoffStress!(mp, P)
            Pnum = Itensor()
            MuesliMaterials.firstPiolaKirchhoffStressNumerical!(mp, Pnum)
            @test mat3(P) ≈ mat3(Pnum) rtol = 1.0e-5 atol = 1.0e-6

            # secondPiolaKirchhoffStressNumerical is broken upstream: muesli's
            # finiteStrainMP::secondPiolaKirchhoffStressNumerical assigns an itensor into
            # an istensor, which never reaches the symmetric tensor's storage, so the
            # result is whatever was in memory (muesli only zero-initialises tensors when
            # built with INIT2ZERO). Intermittently it looks fine, which is worse.
            S = Istensor()
            MuesliMaterials.secondPiolaKirchhoffStress!(mp, S)
            Snum = Istensor()
            MuesliMaterials.secondPiolaKirchhoffStressNumerical!(mp, Snum)
            @test_skip mat3(S) ≈ mat3(Snum) rtol = 1.0e-5 atol = 1.0e-6
        end
    end
end

@testitem "Finite strain: the stress measures are mutually consistent" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)
    F = [1.05 0.02 0.0; 0.0 0.98 0.01; 0.0 0.0 1.01]
    J = det3(F)

    mp = NeoHookeMP(NeoHookeMaterial(props))
    MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(F))

    P = Itensor()
    MuesliMaterials.firstPiolaKirchhoffStress!(mp, P)
    S = Istensor()
    MuesliMaterials.secondPiolaKirchhoffStress!(mp, S)
    τ = Istensor()
    MuesliMaterials.KirchhoffStress!(mp, τ)
    σ = Istensor()
    MuesliMaterials.CauchyStress!(mp, σ)

    Pm, Sm, τm, σm = mat3(P), mat3(S), mat3(τ), mat3(σ)

    @testset "S is symmetric" begin
        @test Sm ≈ Sm'
    end

    @testset "P = F S" begin
        @test Pm ≈ F * Sm rtol = 1.0e-8
    end

    @testset "τ = J σ" begin
        @test τm ≈ J .* σm rtol = 1.0e-8
    end

    @testset "τ = P Fᵀ" begin
        @test τm ≈ Pm * F' rtol = 1.0e-8
    end
end

@testitem "Finite strain: rigid rotations do not change the material response" begin
    include("testutils.jl")

    # Frame indifference: rotating the deformation must leave S untouched and rotate σ.
    props = properties("young" => 210000.0, "poisson" => 0.3)
    F = [1.05 0.02 0.0; 0.0 0.98 0.01; 0.0 0.0 1.01]

    θ = 0.4
    Q = [cos(θ) -sin(θ) 0.0; sin(θ) cos(θ) 0.0; 0.0 0.0 1.0]
    @test Q * Q' ≈ I3                     # sanity: Q really is a rotation
    @test det3(Q) ≈ 1.0

    stresses(Fᵢ) = begin
        mp = NeoHookeMP(NeoHookeMaterial(props))
        MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(Fᵢ))
        S = Istensor()
        MuesliMaterials.secondPiolaKirchhoffStress!(mp, S)
        σ = Istensor()
        MuesliMaterials.CauchyStress!(mp, σ)
        (mat3(S), mat3(σ), MuesliMaterials.storedEnergy(mp))
    end

    S₁, σ₁, W₁ = stresses(F)
    S₂, σ₂, W₂ = stresses(Q * F)

    @test S₂ ≈ S₁ rtol = 1.0e-8                 # S is unaffected by a rotation
    @test σ₂ ≈ Q * σ₁ * Q' rtol = 1.0e-8        # σ rotates with the body
    @test W₂ ≈ W₁ rtol = 1.0e-10                # the energy is unchanged
end

@testitem "Finite strain: stored energy grows away from the undeformed state" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)

    energy(F) = begin
        mp = NeoHookeMP(NeoHookeMaterial(props))
        MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(F))
        MuesliMaterials.storedEnergy(mp)
    end

    @test energy(I3) ≈ 0.0 atol = 1.0e-8
    for s in (1.01, 1.05, 1.1)
        @test energy(s * I3) > 0
        @test energy(Diagonal3(s, 1.0, 1.0)) > 0
    end

    @testset "energy increases monotonically with stretch" begin
        e = [energy(Diagonal3(s, 1.0, 1.0)) for s in (1.01, 1.02, 1.05, 1.1)]
        @test issorted(e)
    end
end

@testitem "Finite strain: the deformation gradient is stored as given" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)
    F = [1.05 0.02 0.0; 0.0 0.98 0.01; 0.0 0.0 1.01]

    mp = NeoHookeMP(NeoHookeMaterial(props))
    MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(F))

    # Column-major Julia input must survive the trip into muesli's row-major constructor.
    @test mat3(MuesliMaterials.deformationGradient(mp)) ≈ F

    MuesliMaterials.commitCurrentState(mp)
    @test mat3(MuesliMaterials.convergedDeformationGradient(mp)) ≈ F
end

@testitem "Finite strain: tangents are finite and symmetric where they should be" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)
    F = [1.05 0.02 0.0; 0.0 0.98 0.01; 0.0 0.0 1.01]

    mp = NeoHookeMP(NeoHookeMaterial(props))
    MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(F))

    for (name, f) in (
            ("convectedTangent!", MuesliMaterials.convectedTangent!),
            ("materialTangent!", MuesliMaterials.materialTangent!),
            ("spatialTangent!", MuesliMaterials.spatialTangent!),
        )
        @testset "$name" begin
            C = Itensor4()
            f(mp, C)
            got = ten4(C)
            @test all(isfinite, got)
            @test any(!=(0.0), got)
        end
    end

    @testset "the convected tangent has the major symmetry" begin
        C = Itensor4()
        MuesliMaterials.convectedTangent!(mp, C)
        got = ten4(C)
        for i in 1:3, j in 1:3, k in 1:3, l in 1:3
            @test got[i, j, k, l] ≈ got[k, l, i, j] atol = 1.0e-6
        end
    end
end

@testitem "Finite strain: all tangent contractions at once" begin
    include("testutils.jl")

    mp = NeoHookeMP(NeoHookeMaterial(210000.0, 0.3))
    MuesliMaterials.updateCurrentState(mp, 1.0, Itensor([1.05 0.02 0.0; 0.0 0.98 0.01; 0.0 0.0 1.01]))
    v1, v2 = Ivector([1.0, 0.5, -0.3]), Ivector([0.2, -1.0, 0.7])

    Tdev, Tmixed = Itensor(), Istensor()
    Tvol = MuesliMaterials.contractWithAllTangents!(mp, v1, v2, Tdev, Tmixed)

    Tdev_ref, Tmixed_ref = Itensor(), Istensor()
    MuesliMaterials.contractWithDeviatoricTangent!(mp, v1, v2, Tdev_ref)
    MuesliMaterials.contractWithMixedTangent!(mp, Tmixed_ref)
    @test mat3(Tdev) ≈ mat3(Tdev_ref)
    @test mat3(Tmixed) ≈ mat3(Tmixed_ref)
    @test Tvol ≈ MuesliMaterials.volumetricStiffness(mp)
end

@testitem "Finite strain points keep their material alive" begin
    include("testutils.jl")

    F = [1.05 0.02 0.0; 0.0 0.98 0.01; 0.0 0.0 1.01]
    make() = NeoHookeMP(NeoHookeMaterial(210000.0, 0.3))

    points = [make() for _ in 1:2000]
    for _ in 1:3
        GC.gc(true)
    end
    junk = [NeoHookeMaterial(1.0 + i, 0.4) for i in 1:5000]

    P = Itensor()
    stresses = map(points) do mp
        MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(F))
        MuesliMaterials.firstPiolaKirchhoffStress!(mp, P)
        mat3(P)
    end
    @test allequal(stresses)
    @test all(isfinite, first(stresses))
    @test length(junk) == 5000
end

@testitem "Finite strain: Johnson-Cook and Zerilli-Armstrong plasticity" begin
    include("testutils.jl")

    stretch(λ) = Diagonal3(λ, 1.0, 1.0)

    function response(mat, MP, λ, t)
        mp = MP(mat)
        MuesliMaterials.updateCurrentState(mp, t, Itensor(stretch(λ)))
        P = Itensor()
        MuesliMaterials.firstPiolaKirchhoffStress!(mp, P)
        return mat3(P)[1, 1], MuesliMaterials.plasticSlip(mp)
    end

    jc(T = 293.0) = JohnsonCookMaterial(;
        E = 124.0e3, nu = 0.34, rho = 8.9e-9, A = 90.0, B = 292.0, C = 0.025, n = 0.31, m = 1.09,
        edot0 = 1.0, T, Tref = 293.0, Tmelt = 1356.0
    )
    za(T = 293.0) = ZerilliArmstrongMaterial(;
        E = 124.0e3, nu = 0.34, rho = 8.9e-9, C0 = 20.0, C1 = 0.0, C2 = 600.0, C3 = 0.005,
        C4 = 0.0003, C5 = 0.0, n = 0.5, T
    )

    for (name, make, MP, temperatures) in (
            ("Johnson-Cook", jc, JohnsonCookMP, (293.0, 600.0, 1000.0)),
            ("Zerilli-Armstrong", za, ZerilliArmstrongMP, (200.0, 293.0, 500.0)),
        )
        @testset "$name" begin
            mat = make()
            @test MuesliMaterials.check(mat)
            @test MuesliMaterials.density(mat) ≈ 8.9e-9
            @test MP(mat) isa MP

            @test response(mat, MP, 1.0001, 1.0)[2] == 0
            @test response(mat, MP, 1.01, 1.0)[2] > 0

            slow, medium, fast = (response(mat, MP, 1.05, t)[1] for t in (1.0e3, 1.0, 1.0e-3))
            @test fast > medium > slow

            cold, warm, hot = (response(make(T), MP, 1.05, 1.0)[1] for T in temperatures)
            @test cold > warm > hot
        end
    end

    @testset "the keyword constructor needs every model parameter" begin
        @test_throws UndefKeywordError JohnsonCookMaterial(; E = 1.0, nu = 0.3)
    end
end

@testitem "Reduced models: finite strain" begin
    include("testutils.jl")

    E, ν = 210.0e3, 0.3
    props = properties("young" => E, "poisson" => ν)

    @testset "bar with a Saint Venant-Kirchhoff material" begin
        rmp = FbarMP(SVKMP(SVKMaterial(props)))
        F = Itensor(Diagonal3(1.1, 1.0, 1.0))
        MuesliMaterials.updateCurrentState!(rmp, 1.0, F)

        S = Istensor()
        MuesliMaterials.secondPiolaKirchhoffStress!(rmp, S)
        @test S[1, 1] ≈ E * (1.1^2 - 1) / 2
        @test all(abs(S[i, j]) < 1.0e-6 for (i, j) in ((2, 2), (3, 3), (2, 3), (1, 3), (1, 2)))
        @test F[2, 2] ≈ F[3, 3] && F[2, 2] < 1

        C = zeros(6, 6)
        MuesliMaterials.convectedTangentMatrix!(rmp, C)
        @test C[1, 1] ≈ E
    end

    @testset "shell, plane and beam" begin
        Fr = [1.05 0.02 0.01; 0.01 0.97 0.02; 0.0 0.01 0.98]
        for (R, zeroed) in (
                (FshellMP, ((3, 3),)),
                (FplaneMP, ((3, 3), (2, 3), (1, 3))),
                (FbeamMP, ((1, 1), (2, 2), (1, 2))),
            )
            rmp = R(NeoHookeMP(NeoHookeMaterial(props)))
            MuesliMaterials.updateCurrentState!(rmp, 1.0, Itensor(Fr))
            S = Istensor()
            MuesliMaterials.secondPiolaKirchhoffStress!(rmp, S)
            @test all(abs(S[i, j]) < 1.0e-6 * E for (i, j) in zeroed)
            @test rmp isa MuesliMaterials.ReducedFiniteStrainMP
        end
    end
end
