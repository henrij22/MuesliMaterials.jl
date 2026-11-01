@testitem "Test Tensors" begin
    using Tensors

    v = rand(3)
    t = rand(3, 3)
    ts = 0.5 * (t' + t)
    T = rand(3, 3, 3, 3)

    iv = Ivector(v)
    it = Itensor(t)
    ist = Istensor(ts)
    it4 = Itensor4(T)

    @test all(v ≈ convert(Vector{Float64}, iv))
    @test all(t ≈ convert(Matrix{Float64}, it))
    @test all(ts ≈ convert(Matrix{Float64}, ist))
    @test all(T ≈ convert(Array{Float64}, it4))

    @test axes(iv) == axes(v)
    @test axes(it) == axes(t)
    @test axes(ist) == axes(ts)
    @test axes(it4) == axes(T)

    @test length(iv) == 3
    @test length(it) == 9
    @test length(ist) == 9
    @test length(it4) == 81

    for i in 1:3
        @test v[i] ≈ iv[i]
    end
    for i in 1:3, j in 1:3

        @test t[i, j] ≈ it[i, j]
        @test ts[i, j] ≈ ist[i, j]
    end
    for i in 1:3, j in 1:3, k in 1:3, l in 1:3
        @test T[i, j, k, l] ≈ it4[i, j, k, l]
    end

    # Testing iterator
    for (a, b) in zip(t, it)
        @test a ≈ b
    end
    for (a, b) in zip(v, iv)
        @test a ≈ b
    end
    for (a, b) in zip(T, it4)
        @test a ≈ b
    end

    # Testing conversions
    @test v == convert(Vector{Float64}, iv)
    @test t == convert(Matrix{Float64}, it)
    @test ts == convert(Matrix{Float64}, ist)
    @test T == convert(Array{Float64}, it4)

    @test Tensor{1, 3}(v) == convert(Tensor{1, 3}, iv)
    @test Tensor{2, 3}(t) == convert(Tensor{2, 3}, it)
    @test SymmetricTensor{2, 3}(ts) == convert(SymmetricTensor{2, 3}, ist)
    @test Tensor{4, 3}(T) == convert(Tensor{4, 3}, it4)

    if !Sys.isapple()
        @test_throws "size 3," Ivector(rand(4))
        @test_throws "size 3x3" Itensor(rand(4, 4))
    end
    # Testing slicing
    @test iv[1:2] ≈ v[1:2]
    @test it[1:2, 1:2] ≈ t[1:2, 1:2]
    @test ist[1:2, 1:2] ≈ ts[1:2, 1:2]
    @test it4[1:2, 1:2, 1:2, 1:2] ≈ T[1:2, 1:2, 1:2, 1:2]

    @test it[1:2, 1] ≈ t[1:2, 1]
    @test it[1, 1:2] ≈ t[1, 1:2]
    @test ist[1, 1:2] ≈ ts[1, 1:2]

    # Now we are testing setIndex Operations
    it[1:2, 1:2] = t[1:2, 1:2]
    it[1:2, 1] = t[1:2, 1]
    it[1, 1:2] = t[1, 1:2]
end

@testitem "Bulk transfer between tensors and arrays" begin
    t = [1.0 2.0 3.0; 4.0 5.0 6.0; 7.0 8.0 9.0]
    T = reshape(collect(1.0:81.0), 3, 3, 3, 3)

    @testset "copyto! out of a tensor" begin
        A = zeros(3, 3)
        @test copyto!(A, Itensor(t)) === A
        @test A == t

        a = zeros(3, 3, 3, 3)
        copyto!(a, Itensor4(T))
        @test a == T

        v = zeros(3)
        copyto!(v, Ivector([1.0, 2.0, 3.0]))
        @test v == [1.0, 2.0, 3.0]
    end

    @testset "copyto! into an existing tensor" begin
        it = Itensor(zeros(3, 3))
        @test copyto!(it, t) === it
        @test convert(Matrix{Float64}, it) == t

        it4 = Itensor4()
        copyto!(it4, T)
        @test convert(Array{Float64}, it4) == T

        iv = Ivector([0.0, 0.0, 0.0])
        copyto!(iv, [1, 2, 3])
        @test convert(Vector{Float64}, iv) == [1.0, 2.0, 3.0]
    end

    @testset "an Istensor stays symmetric" begin
        ist = Istensor(zeros(3, 3))
        copyto!(ist, t)
        @test convert(Matrix{Float64}, ist) == (t + t') / 2
    end

    @testset "constructors accept any real array" begin
        @test convert(Matrix{Float64}, Itensor(t')) == t'
        @test convert(Matrix{Float64}, Itensor([1 2 3; 4 5 6; 7 8 9])) == t
        @test convert(Matrix{Float64}, Istensor(t')) == (t + t') / 2
        @test convert(Vector{Float64}, Ivector(1:3)) == [1.0, 2.0, 3.0]
        @test convert(Array{Float64}, Itensor4(view(T, :, :, :, :))) == T
    end

    @testset "colon slices read the whole tensor" begin
        @test Itensor(t)[:, :] == t
    end
end
