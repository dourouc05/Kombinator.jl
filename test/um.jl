@testset "Uniform matroid" begin
    @testset "Interface" begin
        @test_throws ErrorException UniformMatroidInstance(Float64[5, 4, 3], -1)
        @test_throws ErrorException UniformMatroidInstance(Float64[5, 4, 3], 0)
    end

    @testset "Basic" begin
        m = 2
        i = UniformMatroidInstance(Float64[5, 4, 3], m)
        g = solve(i, GreedyAlgorithm())
        d = solve(i, DynamicProgramming())
        l = ! is_travis && msets_lp(i, solver=Gurobi.Optimizer)

        @test i.m == m

        @test value(g) == value(d)
        @test length(g.items) <= m
        @test length(d.items) <= m

        @test g.instance == i
        @test d.instance == i

        if ! is_travis
            @test value(g) == value(l)
            @test length(l.items) <= m
            @test l.instance == i
        end
    end
end

@testset "Budgeted uniform matroid" begin
    @testset "Interface" begin
        # Errors when building the UniformMatroidInstance.
        @test_throws ErrorException MinimumBudget(UniformMatroidInstance(Float64[5, 4, 3], -1), Int[1, 1, 1])
        @test_throws ErrorException MinimumBudget(UniformMatroidInstance(Float64[5, 4, 3], 0), Int[1, 1, 1])

        # TODO: these errors are no more caught after the refactor.
        # @test_throws ErrorException MinimumBudget(UniformMatroidInstance(Float64[5, 4, 3], 2), Int[1, 1, 1], -1)
        # @test_throws ErrorException MinimumBudget(UniformMatroidInstance(Float64[5, 4, 3], 2), Int[1, -1, 1])

        # Different number of items between the matroid and the new constraint.
        @test_throws ErrorException MinimumBudget(UniformMatroidInstance(Float64[5, 4, 3], 0), Int[1, 1])
        @test_throws ErrorException MinimumBudget(UniformMatroidInstance(Float64[5, 4], 0), Int[1, 1, 1])
    end

    function test_solution_at(s::MinBudgetedUniformMatroidSolution{Float64, Int}, kv::Dict{Int, Float64})
        for (k, v) in kv
            @test value(s, k) ≈ v
        end
    end

    function test_items_at(s::MinBudgetedUniformMatroidSolution{Float64, Int}, kv::Dict{Int, Vector{Int}})
        for (k, v) in kv
            @test items(s, k) == v
        end
    end

    @testset "Basic" begin
        m = 2
        i = MinimumBudget(UniformMatroidInstance(Float64[5, 4, 3], m), Int[1, 1, 1], 3, compute_all_values=true)
        d = solve(i, DynamicProgramming())
        l = ! is_travis && solve(i, DefaultLinearFormulation(), solver=Gurobi.Optimizer)

        @test i.instance.m == m
        @test d.instance == i

        @test d.state[m, 0 + 1, 0 + 1] == 9.0
        @test d.state[m, 0 + 1, 1 + 1] == 9.0
        @test d.state[m, 0 + 1, 2 + 1] == 9.0
        @test d.state[m, 0 + 1, 3 + 1] == -Inf

        @test d.solutions[m, 0, 0] == [1, 2]
        @test d.solutions[m, 0, 1] == [1, 2]
        @test d.solutions[m, 0, 2] == [1, 2]
        @test d.solutions[m, 0, 3] == [-1]

        if ! is_travis
            for i in 0:3
                @test l.state[m, 0 + 1, i + 1] ≈ d.state[m, 0 + 1, i + 1]
                @test l.solutions[m, 0, i] == d.solutions[m, 0, i]
            end
        end

        # Accessors.
        expected_items = Dict{Int, Vector{Int}}(0 => [1, 2], 1 => [1, 2], 2 => [1, 2], 3 => [-1])
        test_items_at(d, expected_items)
        ! is_travis && test_items_at(l, expected_items)

        expected = Dict{Int, Float64}(0 => 9.0, 1 => 9.0, 2 => 9.0, 3 => -Inf)
        test_solution_at(d, expected)
        ! is_travis && test_solution_at(l, expected)
    end

    # @testset "Conformity" begin
    #     # More advanced tests to ensure the algorithm works as expected.

    #     # 1
    #     a = 3.612916190062782
    #     b = 7.225832380125564
    #     v = Float64[a, a, b, b, b, b, b, b, b, b]
    #     w = Int[32, 32, 32, 32, 0, 32, 32, 32, 0, 32]
    #     m = 3

    #     i = MinimumBudget(UniformMatroidInstance(v, m), w, 3, compute_all_values=true)
    #     d = solve(i, DynamicProgramming())
    #     # TODO: stop the algorithm in this case? Don't waste too much time on this part of the table.
    #     l = ! is_travis && solve(i, DefaultLinearFormulation(), solver=Gurobi.Optimizer)
    #     expected = Dict{Int, Float64}(0 => 3 * b, 96 => 3 * b, 96 + 1 => -Inf, 320 => -Inf) # No more solutions after 96.
    #     test_solution_at(d, expected)
    #     ! is_travis && test_solution_at(l, expected)

    #     # 2
    #     v = [7.840854066284411, 3.9204270331422055, 7.840854066284411, 3.9204270331422055, 7.840854066284411, 7.840854066284411, 7.840854066284411, 7.840854066284411, 15.681708132568822, 5.227236044189607]
    #     w = [16, 32, 16, 24, 16, 16, 0, 16, 0, 32]
    #     m = 3

    #     i = MinimumBudget(UniformMatroidInstance(v, m), w, compute_all_values=true)
    #     d = solve(i, DynamicProgramming())
    #     l = ! is_travis && solve(i, DefaultLinearFormulation(), solver=Gurobi.Optimizer)

    #     a = 31.363416265137644
    #     b = 28.74979824304284
    #     c = 24.829371209900632
    #     e = 16.988517143616225
    #     expected = Dict{Int, Float64}(
    #         0 => a, 4 => a, 20 => a, 24 => a, 25 => a, 32 => a,
    #         33 => b, 40 => b, 41 => b, 48 => b,
    #         49 => c, 72 => e, 73 => e,
    #         96 => -Inf, 97 => -Inf, 280 => -Inf, 319 => -Inf, 320 => -Inf
    #     )
    #     test_solution_at(d, expected)
    #     ! is_travis && test_solution_at(l, expected)
    # end
end
