@testset "ElementaryPath" begin
    @testset "Transforming a solution" begin
        g = path_digraph(3)
        add_edge!(g, 1, 3)
        rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0, Edge(1, 3) => 1.0)
        weights = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1, Edge(1, 3) => 4)

        i = MinimumBudget(ElementaryPathInstance(g, rewards, 1, 3), weights, 4)
        path = [Edge(1, 3)]
        solutions = Dict{Int, Vector{Edge{Int}}}(
            0 => [Edge(1, 2), Edge(2, 3)],
            1 => [Edge(1, 2), Edge(2, 3)],
            2 => [Edge(1, 2), Edge(2, 3)],
            3 => [Edge(1, 3)],
            4 => [Edge(1, 3)],
        )
        d = BudgetedElementaryPathSolution(i, path, solutions)

        warn_msg = "The requested maximum budget 5 is higher than the instance's minimum budget 4. Therefore, some values have not been computed and are unavailable."
        @test_logs (:warn, warn_msg) Kombinator.paths_all_budgets_as_tuples(
            d,
            5,
        )
        sol = Dict(
            0 => [(1, 2), (2, 3)],
            1 => [(1, 2), (2, 3)],
            2 => [(1, 2), (2, 3)],
            3 => [(1, 3)],
            4 => [(1, 3)],
        )
        @test Kombinator.paths_all_budgets_as_tuples(d, 4) == sol

        @test_logs (:warn, warn_msg) Kombinator.paths_all_budgets(d, 5)
        sol = Dict(
            0 => [Edge(1, 2), Edge(2, 3)],
            1 => [Edge(1, 2), Edge(2, 3)],
            2 => [Edge(1, 2), Edge(2, 3)],
            3 => [Edge(1, 3)],
            4 => [Edge(1, 3)],
        )
        @test Kombinator.paths_all_budgets(d, 4) == sol
    end

    @testset "Elementary paths" begin
        @testset "Interface" begin
            g = path_digraph(3)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0)

            @testset "Global interface" begin
                i = ElementaryPathInstance(g, rewards, 1, 2)
                @test objective(i) == Maximise()
            end

            @testset "Source not in graph" begin
                @test_throws ErrorException ElementaryPathInstance(g, rewards, 50, 2)
            end

            @testset "Destination not in graph" begin
                @test_throws ErrorException ElementaryPathInstance(g, rewards, 1, 50)
            end

            @testset "Source is destination" begin
                @test_throws ErrorException ElementaryPathInstance(g, rewards, 1, 1)
            end

            @testset "Source is destination" begin
                @test_throws ErrorException ElementaryPathInstance(g, rewards, 1, 1)
            end

            @testset "An edge has a reward but is not in the graph" begin
                rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0, Edge(1, 3) => 1.0)
                @test_throws ErrorException ElementaryPathInstance(g, rewards, 1, 2)
            end

            @testset "Positive-reward cycle" begin
                g = path_digraph(3)
                add_edge!(g, 2, 1)
                rewards = Dict(
                    Edge(1, 2) => 1.0,
                    Edge(2, 3) => 3.0,
                    Edge(2, 1) => 25.0,
                )

                i = ElementaryPathInstance(g, rewards, 1, 3)
                @test_logs (
                    :warn,
                    "The graph contains a positive-cost cycle around edge 2 -> 1.",
                ) solve(i, BellmanFordAlgorithm())
            end
            
            @testset "Copy" begin
                g = path_digraph(3)
                add_edge!(g, 2, 1)
                rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 3.0, Edge(2, 1) => 25.0)
        
                i = ElementaryPathInstance(g, rewards, 1, 3)
                i2 = copy(i)
                @test i.graph == i2.graph
                @test i.rewards == i2.rewards
                @test i.src == i2.src
                @test i.dst == i2.dst
                @test i.objective == i2.objective
            end

            @testset "Approximation" begin
                i = ElementaryPathInstance(g, rewards, 1, 3)

                @test approximation_ratio(i, DynamicProgramming()) == 1.0
                @test approximation_term(i, DynamicProgramming()) == 0.0

                @test approximation_ratio(i, DefaultLinearFormulation(Cbc.Optimizer)) == 1.0
                @test approximation_term(i, DefaultLinearFormulation(Cbc.Optimizer)) == 0.0
            end

            @testset "Make solution" begin
                i = ElementaryPathInstance(g, rewards, 1, 3)
                d = Dict(Edge(1, 3) => 0.4, Edge(1, 2) => 0.8, Edge(2, 3) => 0.7)
                s = make_solution(i, d)

                @test s.instance == i
                @test length(s.variables) == 2
                @test Edge(1, 3) ∉ s.variables
                @test Edge(1, 2) ∈ s.variables
                @test Edge(2, 3) ∈ s.variables
            end

            @testset "Solution helpers" begin
                i = ElementaryPathInstance(g, rewards, 1, 3)

                # Infeasible solution.
                s = ElementaryPathSolution(i, Edge{Int}[])
                @test value(s) == -Inf

                # Valid solution.
                d = Dict(Edge(1, 3) => 0.4, Edge(1, 2) => 0.8, Edge(2, 3) => 0.7)
                s = make_solution(i, d)

                @test value(s) == 4
            end
        end

        @testset "Basic" begin
            @testset "Directed path graph" begin
                g = path_digraph(3)
                rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0)
                i = ElementaryPathInstance(g, rewards, 1, 3)

                @testset "Bellman-Ford" begin
                    s = solve(i, BellmanFordAlgorithm())
                    @test s.instance == i
                    @test s.variables == [Edge(1, 2), Edge(2, 3)]
                end

                if !is_travis
                    @testset "Linear programming" begin
                        s = solve(
                            i,
                            DefaultLinearFormulation(Gurobi.Optimizer), # Cbc unsupported.
                        )
                        @test s.instance == i
                        @test s.variables == [Edge(1, 2), Edge(2, 3)]
                    end
                end
            end

            @testset "High-weight edge" begin
                g = path_digraph(3)
                add_edge!(g, 1, 3)
                rewards = Dict(
                    Edge(1, 2) => 1.0,
                    Edge(2, 3) => 1.0,
                    Edge(1, 3) => 4.0,
                )
                weights =
                    Dict(Edge(1, 2) => 1, Edge(2, 3) => 1, Edge(1, 3) => 4)

                i = ElementaryPathInstance(g, rewards, 1, 3)

                @testset "Bellman-Ford" begin
                    s = solve(i, BellmanFordAlgorithm())
                    @test s.instance == i
                    @test s.variables == [Edge(1, 3)]
                end

                if !is_travis
                    @testset "Linear programming" begin
                        s = solve(
                            i,
                            DefaultLinearFormulation(Gurobi.Optimizer),
                        ) # Cbc unsupported.
                        @test s.instance == i
                        @test s.variables == [Edge(1, 3)]
                    end
                end
            end
        end
    end

    @testset "Budgeted elementary paths" begin
        @testset "Interface" begin
            graph = path_digraph(3)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0)
            weights = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1)

            @testset "Global interface" begin
                i = MinimumBudget(ElementaryPathInstance(graph, rewards, 1, 2), weights)
                @test objective(i) == Maximise()
            end
            
            @testset "More edges have rewards than weights" begin
                g = path_digraph(4)
                r = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0, Edge(4, 1) => 1.0)
                w = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1)
                @test_throws ErrorException MinimumBudget(ElementaryPathInstance(g, r, 1, 2), w)
            end

            @testset "Negative weight or budget" begin
                w = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1)
                @test_throws ErrorException MinimumBudget(ElementaryPathInstance(graph, rewards, 1, 2), w, -1)

                w[Edge(4, 2)] = 1
                @test_throws ErrorException MinimumBudget(ElementaryPathInstance(graph, rewards, 1, 2), w)
                w[Edge(4, 2)] = -1
                @test_throws ErrorException MinimumBudget(ElementaryPathInstance(graph, rewards, 1, 2), w)
            end
            
            @testset "Copy" begin
                i = MinimumBudget(ElementaryPathInstance(graph, rewards, 1, 2), weights)
                i2 = copy(i)
                @test i.weights == i2.weights
                @test i.min_budget == i2.min_budget
                @test i.compute_all_values == i2.compute_all_values
                @test i.instance.graph == i2.instance.graph
                @test i.instance.rewards == i2.instance.rewards
                @test i.instance.src == i2.instance.src
                @test i.instance.dst == i2.instance.dst
                @test i.instance.objective == i2.instance.objective
            end

            @testset "Approximation" begin
                i = MinimumBudget(ElementaryPathInstance(graph, rewards, 1, 2), weights)

                @test approximation_ratio(i, DynamicProgramming()) == 1.0
                @test approximation_term(i, DynamicProgramming()) == 0.0

                @test approximation_ratio(i, DefaultLinearFormulation(Cbc.Optimizer)) == 1.0
                @test approximation_term(i, DefaultLinearFormulation(Cbc.Optimizer)) == 0.0
            end

            @testset "Make solution" begin
                i = MinimumBudget(ElementaryPathInstance(graph, rewards, 1, 2), weights)
                d = Dict(Edge(1, 3) => 0.4, Edge(1, 2) => 0.8, Edge(2, 3) => 0.7)
                s = make_solution(i, d)

                @test s.instance == i
                @test length(s.variables) == 2
                @test Edge(1, 3) ∉ s.variables
                @test Edge(1, 2) ∈ s.variables
                @test Edge(2, 3) ∈ s.variables
            end

            @testset "Solution helpers" begin
                i = MinimumBudget(ElementaryPathInstance(graph, rewards, 1, 2), weights)

                # Infeasible solution.
                s = BudgetedElementaryPathSolution(i, Edge{Int}[])
                @test value(s) == -Inf

                # Valid solution.
                d = Dict(Edge(1, 3) => 0.4, Edge(1, 2) => 0.8, Edge(2, 3) => 0.7)
                s = make_solution(i, d)

                @test value(s) == 2
            end
        end

        @testset "Basic" begin
            @testset "Directed path graph" begin
                g = path_digraph(3)
                rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0)
                weights = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1)

                i = MinimumBudget(
                    ElementaryPathInstance(g, rewards, 1, 3),
                    weights,
                    4,
                )

                @testset "Bellman-Ford" begin
                    d = solve(i, BellmanFordAlgorithm())

                    @test d.instance == i
                    @test d.variables == [] # No path with a total weight of at least 4.

                    for β in [0, 1, 2]
                        @test d.solutions[β] == [Edge(1, 2), Edge(2, 3)]
                    end
                    for β in [3, 4]
                        @test d.solutions[β] == []
                    end
                end

                if !is_travis
                    @testset "Linear programming" begin
                        s = solve(
                            i,
                            DefaultLinearFormulation(Gurobi.Optimizer),
                        ) # Cbc unsupported.
                        @test s.instance == i
                        @test s.variables == []
                    end
                end
            end

            @testset "High-weight edge" begin
                g = path_digraph(3)
                add_edge!(g, 1, 3)
                rewards = Dict(
                    Edge(1, 2) => 1.0,
                    Edge(2, 3) => 1.0,
                    Edge(1, 3) => 1.0,
                )
                weights =
                    Dict(Edge(1, 2) => 1, Edge(2, 3) => 1, Edge(1, 3) => 4)

                i = MinimumBudget(
                    ElementaryPathInstance(g, rewards, 1, 3),
                    weights,
                    4,
                )

                @testset "Bellman-Ford" begin
                    s = solve(i, BellmanFordAlgorithm())
                    @test s.instance == i
                    @test s.variables == [Edge(1, 3)]
                end

                if !is_travis
                    @testset "Linear programming" begin
                        s = solve(
                            i,
                            DefaultLinearFormulation(Gurobi.Optimizer),
                        ) # Cbc unsupported.
                        @test s.instance == i
                        @test s.variables == [Edge(1, 3)]
                    end
                end
            end
        end

        @testset "Conformity" begin
            # More advanced tests to ensure the algorithm works as expected.
            g = complete_digraph(3)
            rewards = Dict(
                Edge(1, 2) => 1.0,
                Edge(3, 1) => -1.0,
                Edge(3, 2) => -1.0,
                Edge(2, 3) => 1.0,
                Edge(2, 1) => -1.0,
                Edge(1, 3) => 0.0,
            )
            weights = Dict(
                Edge(1, 2) => 0,
                Edge(3, 1) => 0,
                Edge(3, 2) => 0,
                Edge(2, 3) => 0,
                Edge(2, 1) => 0,
                Edge(1, 3) => 2,
            )
            i = MinimumBudget(
                ElementaryPathInstance(g, rewards, 1, 3),
                weights,
                2,
                compute_all_values=true,
            )

            @testset "Bellman-Ford" begin
                warn_msg = "The graph contains a positive-cost cycle around edge 3 -> 1."
                d = @test_logs (:warn, warn_msg) solve(
                    i,
                    BellmanFordAlgorithm(),
                )

                @test d.variables == [Edge(1, 3)]

                @test d.solutions[0] == [Edge(1, 2), Edge(2, 3)]
                @test d.solutions[1] == [Edge(1, 3)]
                @test d.solutions[2] == [Edge(1, 3)]
            end

            if !is_travis
                @testset "Linear programming" begin
                    l = solve(
                        i,
                        DefaultLinearFormulation(Gurobi.Optimizer),
                    ) # Cbc unsupported.
                    # All solutions have the same destination! Only paths from 1 to 3, unlike DP.
                    @test l.solutions[0] == [Edge(1, 2), Edge(2, 3)]
                    @test l.solutions[1] == [Edge(1, 3)]
                    @test l.solutions[2] == [Edge(1, 3)]
                end
            end
        end
    end
end
