@testset "UniformMatroid" begin
    @testset "Uniform matroid" begin
        @testset "Interface" begin
            r = Float64[5, 4, 3]

            @testset "Global interface" begin
                i = UniformMatroidInstance(r, 1)
                @test objective(i) == Maximise()
            end

            @testset "Invalid parameter" begin
                @test_throws ErrorException UniformMatroidInstance(r, -1)
                @test_throws ErrorException UniformMatroidInstance(r, 0)
            end
        end

        @testset "Copy" begin
            i = UniformMatroidInstance(Float64[5, 4, 3], 1)
            i2 = copy(i)
            @test i.m == i2.m
            @test i.rewards == i2.rewards
            @test i.objective == i2.objective
        end

        @testset "Basic" begin
            m = 2
            i = UniformMatroidInstance(Float64[5, 4, 3], m)
            g = solve(i, GreedyAlgorithm())
            d = solve(i, DynamicProgramming())
            l =
                !is_travis &&
                solve(i, DefaultLinearFormulation(Gurobi.Optimizer))

            @test i.m == m

            @test value(g) == value(d)
            @test length(g.variables) <= m
            @test length(d.variables) <= m

            @test g.instance == i
            @test d.instance == i

            if !is_travis
                @test value(g) == value(l)
                @test length(l.variables) <= m
                @test l.instance == i
            end
        end
    end

    @testset "Budgeted uniform matroid" begin
        @testset "Interface" begin
            r = Float64[5, 4, 3]
            w = Int[1, 1, 1]

            @testset "Global interface" begin
                i = MinimumBudget(UniformMatroidInstance(r, 1), w, 1)
                @test objective(i) == Maximise()
            end

            @testset "Errors when building the UniformMatroidInstance should bubble up to MinimumBudget" begin
                @test_throws ErrorException MinimumBudget(
                    UniformMatroidInstance(r, -1),
                    w,
                )
                @test_throws ErrorException MinimumBudget(
                    UniformMatroidInstance(r, 0),
                    w,
                )
            end

            @testset "Negative weight or budget" begin
                @test_throws ErrorException MinimumBudget(UniformMatroidInstance(r, 2), w, -1)
                @test_throws ErrorException MinimumBudget(UniformMatroidInstance(r, 2), Int[1, -1, 1])
            end

            @testset "Different number of items between the matroid and the new constraint" begin
                @test_throws ErrorException MinimumBudget(
                    UniformMatroidInstance(r, 0),
                    w[1:2],
                )
                @test_throws ErrorException MinimumBudget(
                    UniformMatroidInstance(r[1:2], 0),
                    w,
                )
            end
        end

        function test_solution_at(
            s::MinBudgetedUniformMatroidSolution{Float64, Int},
            kv::Dict{Int, Float64},
        )
            for (k, v) in kv
                @test value(s, k) ≈ v
            end
        end

        function test_items_at(
            s::MinBudgetedUniformMatroidSolution{Float64, Int},
            kv::Dict{Int, Vector{Int}},
        )
            for (k, v) in kv
                @test items(s, k) == v
            end
        end

        @testset "Basic" begin
            m = 2
            i = MinimumBudget(
                UniformMatroidInstance(Float64[5, 4, 3], m),
                Int[1, 1, 1],
                3,
                compute_all_values=true,
            )
            d = solve(i, DynamicProgramming())
            l =
                !is_travis &&
                solve(i, DefaultLinearFormulation(Gurobi.Optimizer))

            expected_items = Dict{Int, Vector{Int}}(
                0 => [1, 2],
                1 => [1, 2],
                2 => [1, 2],
                3 => [-1],
            )
            expected =
                Dict{Int, Float64}(0 => 9.0, 1 => 9.0, 2 => 9.0, 3 => -Inf)

            @test i.instance.m == m

            @testset "Dynamic programming" begin
                @test d.instance == i

                @test d.state[m, 0 + 1, 0 + 1] == 9.0
                @test d.state[m, 0 + 1, 1 + 1] == 9.0
                @test d.state[m, 0 + 1, 2 + 1] == 9.0
                @test d.state[m, 0 + 1, 3 + 1] == -Inf

                @test d.solutions[0] == [1, 2]
                @test d.solutions[1] == [1, 2]
                @test d.solutions[2] == [1, 2]
                @test d.solutions[3] == [-1]

                test_items_at(d, expected_items)
                test_solution_at(d, expected)
            end

            if !is_travis
                @testset "Linear programming" begin
                    @test l.instance == i

                    for i in 0:3
                        @test l.state[m, 0 + 1, i + 1] ≈
                              d.state[m, 0 + 1, i + 1]
                        @test l.solutions[i] == d.solutions[i]
                    end

                    test_items_at(l, expected_items)
                    test_solution_at(l, expected)
                end
            end
        end

        # More advanced tests to ensure the algorithm works as expected.

        @testset "Conformity 1" begin
            a = 3.612916190062782
            b = 7.225832380125564
            v = Float64[a, a, b, b, b, b, b, b, b, b]
            w = Int[32, 32, 32, 32, 0, 32, 32, 32, 0, 32]
            m = 3

            i = MinimumBudget(
                UniformMatroidInstance(v, m),
                w,
                320,
                compute_all_values=true,
            )
            d = solve(i, DynamicProgramming())
            l =
                !is_travis &&
                solve(i, DefaultLinearFormulation(Gurobi.Optimizer))

            expected = Dict{Int, Float64}(
                0 => 3 * b,
                96 => 3 * b,
                96 + 1 => -Inf,
                320 => -Inf,
            ) # No more solutions after 96.

            @testset "Dynamic programming" begin
                test_solution_at(d, expected)
            end

            if !is_travis
                @testset "Linear programming" begin
                    test_solution_at(l, expected)
                end
            end
        end

        @testset "Conformity 2" begin
            v = [
                7.840854066284411,
                3.9204270331422055,
                7.840854066284411,
                3.9204270331422055,
                7.840854066284411,
                7.840854066284411,
                7.840854066284411,
                7.840854066284411,
                15.681708132568822,
                5.227236044189607,
            ]
            w = [16, 32, 16, 24, 16, 16, 0, 16, 0, 32]
            m = 3

            i = MinimumBudget(
                UniformMatroidInstance(v, m),
                w,
                320,
                compute_all_values=true,
            )
            d = solve(i, DynamicProgramming())
            l =
                !is_travis &&
                solve(i, DefaultLinearFormulation(Gurobi.Optimizer))

            a = 31.363416265137644
            b = 28.74979824304284
            c = 24.829371209900632
            e = 16.988517143616225
            expected = Dict{Int, Float64}(
                0 => a,
                4 => a,
                20 => a,
                24 => a,
                25 => a,
                32 => a,
                33 => b,
                40 => b,
                41 => b,
                48 => b,
                49 => c,
                72 => e,
                73 => e,
                96 => -Inf,
                97 => -Inf,
                280 => -Inf,
                319 => -Inf,
                320 => -Inf,
            )

            @testset "Dynamic programming" begin
                test_solution_at(d, expected)
            end

            if !is_travis
                @testset "Linear programming" begin
                    test_solution_at(l, expected)
                end
            end
        end
    end
end
