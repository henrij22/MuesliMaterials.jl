@testitem "Finite strain: the undeformed state is stress free" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)

    for (name, matT, mpT) in (("NeoHooke", NeoHookeMaterial, NeoHookeMP),
        ("SVK", SVKMaterial, SVKMP))
        @testset "$name" begin
            mat = matT(props)
            @test MuesliMaterials.check(mat)

            mp = mpT(mat)
            MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(I3))

            P = Itensor()
            MuesliMaterials.firstPiolaKirchhoffStress!(mp, P)
            @test all(abs.(mat3(P)) .< 1e-8)

            @test MuesliMaterials.storedEnergy(mp) ≈ 0.0 atol = 1e-8
        end
    end
end

@testitem "Finite strain: analytic stress agrees with muesli's numerical derivative" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)
    F = [1.05 0.02 0.0; 0.0 0.98 0.01; 0.0 0.0 1.01]

    for (name, matT, mpT) in (("NeoHooke", NeoHookeMaterial, NeoHookeMP),
        ("SVK", SVKMaterial, SVKMP))
        @testset "$name" begin
            mp = mpT(matT(props))
            MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(F))

            P = Itensor()
            MuesliMaterials.firstPiolaKirchhoffStress!(mp, P)
            Pnum = Itensor()
            MuesliMaterials.firstPiolaKirchhoffStressNumerical!(mp, Pnum)
            @test mat3(P)≈mat3(Pnum) rtol=1e-5 atol=1e-6

            # secondPiolaKirchhoffStressNumerical is broken upstream: muesli's
            # finiteStrainMP::secondPiolaKirchhoffStressNumerical assigns an itensor into
            # an istensor, which never reaches the symmetric tensor's storage, so the
            # result is whatever was in memory (muesli only zero-initialises tensors when
            # built with INIT2ZERO). Intermittently it looks fine, which is worse.
            S = Istensor()
            MuesliMaterials.secondPiolaKirchhoffStress!(mp, S)
            Snum = Istensor()
            MuesliMaterials.secondPiolaKirchhoffStressNumerical!(mp, Snum)
            @test_skip mat3(S)≈mat3(Snum) rtol=1e-5 atol=1e-6
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
        @test Pm ≈ F * Sm rtol = 1e-8
    end

    @testset "τ = J σ" begin
        @test τm ≈ J .* σm rtol = 1e-8
    end

    @testset "τ = P Fᵀ" begin
        @test τm ≈ Pm * F' rtol = 1e-8
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

    @test S₂ ≈ S₁ rtol = 1e-8                 # S is unaffected by a rotation
    @test σ₂ ≈ Q * σ₁ * Q' rtol = 1e-8        # σ rotates with the body
    @test W₂ ≈ W₁ rtol = 1e-10                # the energy is unchanged
end

@testitem "Finite strain: stored energy grows away from the undeformed state" begin
    include("testutils.jl")

    props = properties("young" => 210000.0, "poisson" => 0.3)

    energy(F) = begin
        mp = NeoHookeMP(NeoHookeMaterial(props))
        MuesliMaterials.updateCurrentState(mp, 1.0, Itensor(F))
        MuesliMaterials.storedEnergy(mp)
    end

    @test energy(I3) ≈ 0.0 atol = 1e-8
    for s in (1.01, 1.05, 1.10)
        @test energy(s * I3) > 0
        @test energy(Diagonal3(s, 1.0, 1.0)) > 0
    end

    @testset "energy increases monotonically with stretch" begin
        e = [energy(Diagonal3(s, 1.0, 1.0)) for s in (1.01, 1.02, 1.05, 1.10)]
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

    for (name, f) in (("convectedTangent!", MuesliMaterials.convectedTangent!),
        ("materialTangent!", MuesliMaterials.materialTangent!),
        ("spatialTangent!", MuesliMaterials.spatialTangent!))
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
            @test got[i, j, k, l] ≈ got[k, l, i, j] atol = 1e-6
        end
    end
end
