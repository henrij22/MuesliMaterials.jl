@testset "Test Tensors" begin
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

    @test_throws "Input has to be a 3 vector." Ivector(rand(4))
    @test_throws "Input has to be a 3 x 3 matrix." Itensor(rand(4, 4))
end
