@testset "SpanningTree" begin
    @testset "Symmetric difference" begin
        a = [Edge(1, 2), Edge(1, 3)]
        b = [Edge(1, 3), Edge(1, 4)]
        @test Kombinator._solution_symmetric_difference_size(a, b) == 2
        res_a, res_b = Kombinator._solution_symmetric_difference(a, b)
        @test res_a == [Edge(1, 2)] # Elements that are in a but not in b
        @test res_b == [Edge(1, 4)] # Elements that are in b but not in a
    end

    @testset "Maximum spanning tree" begin
        @testset "Interface" begin
            graph = complete_graph(5)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.5, Edge(2, 3) => 3.0)

            @testset "Global interface" begin
                i = SpanningTreeInstance(graph, rewards)
                @test objective(i) == Maximise()
            end

            @testset "Copying" begin
                i = SpanningTreeInstance(graph, rewards)
                i2 = copy(i)
                @test i.graph == i2.graph
                @test i.rewards == i2.rewards
                @test i.objective == i2.objective
            end

            @testset "Reward accessor" begin
                i = SpanningTreeInstance(graph, rewards)

                @test reward(i, Edge(1, 2)) == reward(i, Edge(2, 1))
            end

            @testset "Approximation" begin
                i = SpanningTreeInstance(graph, rewards)

                @test approximation_ratio(i, PrimAlgorithm()) == 1.0
                @test approximation_term(i, PrimAlgorithm()) == 0.0

                @test approximation_ratio(i, DynamicProgramming()) == 1.0
                @test approximation_term(i, DynamicProgramming()) == 0.0

                @test approximation_ratio(i, DefaultLinearFormulation(Cbc.Optimizer)) == 1.0
                @test approximation_term(i, DefaultLinearFormulation(Cbc.Optimizer)) == 0.0
            end

            @testset "Make solution" begin
                i = SpanningTreeInstance(graph, rewards)
                d = Dict(Edge(1, 2) => 0.8, Edge(1, 3) => 0.2, Edge(2, 3) => 1.0)
                s = make_solution(i, d)

                @test s.instance == i
                @test length(s.variables) == 2
                @test Edge(1, 2) ∈ s.variables
                @test Edge(1, 3) ∉ s.variables
                @test Edge(2, 3) ∈ s.variables

                @test value(s) == 4.0
            end

            @testset "Solution helpers" begin
                i = SpanningTreeInstance(graph, rewards)

                # Infeasible solution.
                s = SpanningTreeSolution(i, Edge{Int}[])
                @test value(s) == -Inf

                # Valid solution.
                d = Dict(Edge(1, 2) => 0.8, Edge(1, 3) => 0.2, Edge(2, 3) => 1.0)
                s = make_solution(i, d)
                @test value(s) == 4

                # Valid solution with reversed edges.
                s = SpanningTreeSolution(i, [Edge(2, 1), Edge(3, 2)])
                @test value(s) == 4
            end
        
            @testset "Value of a raw tree" begin
                i = SpanningTreeInstance(graph, rewards)
        
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(
                    i,
                    Edge{Int}[],
                ) == 0
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(
                    i,
                    [Edge(1, 2)],
                ) == 1.0
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(
                    i,
                    [Edge(1, 2), Edge(1, 3)],
                ) == 1.5
            end
        end

        @testset "Basic" begin
            graph = complete_graph(5)
            rewards = Dict(
                Edge(1, 2) => 121.0,
                Edge(1, 3) => 10.0,
                Edge(1, 4) => 10.0,
                Edge(1, 5) => 10.0,
                Edge(2, 3) => 121.0,
                Edge(2, 4) => 10.0,
                Edge(2, 5) => 10.0,
                Edge(3, 4) => 121.0,
                Edge(3, 5) => 10.0,
                Edge(4, 5) => 121.0,
            )

            i = SpanningTreeInstance(graph, rewards)
            p = solve(i, PrimAlgorithm())
            g = solve(i, GreedyAlgorithm()) # Same as Prim.
            d = solve(i, DynamicProgramming())
            l = solve(i, DefaultLinearFormulation(Cbc.Optimizer))

            for s in [p, g, d, l]
                @test s.instance == i
                @test length(s.variables) == 4
                @test Edge(1, 2) in s.variables
                @test Edge(2, 3) in s.variables
                @test Edge(3, 4) in s.variables
                @test Edge(4, 5) in s.variables
            end
        end

        @testset "Conformity" begin
            graph = complete_graph(5)
            rewards = Dict(
                Edge(2, 5) => 0.0,
                Edge(3, 5) => 0.0,
                Edge(4, 5) => 1.0,
                Edge(1, 2) => 0.0,
                Edge(2, 3) => 0.0,
                Edge(1, 4) => 0.0,
                Edge(2, 4) => 0.0,
                Edge(1, 5) => 0.0,
                Edge(1, 3) => 0.0,
                Edge(3, 4) => 0.0,
            )

            i = SpanningTreeInstance(graph, rewards)
            p = solve(i, PrimAlgorithm())
            g = solve(i, GreedyAlgorithm()) # Same as Prim.
            d = solve(i, DynamicProgramming())
            l = solve(i, DefaultLinearFormulation(Cbc.Optimizer))

            for s in [p, g, d, l]
                @test s.instance == i
                @test length(s.variables) == 4 # Five nodes in the graph.
                @test length(unique(s.variables)) == 4 # Only unique edges.
                @test Edge(4, 5) in s.variables || Edge(5, 4) in s.variables # Only edge with nonzero cost.
            end
        end
    end

    @testset "Budgeted maximum spanning tree" begin
        @testset "Interface" begin
            graph = complete_graph(3)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.5, Edge(2, 3) => 3.0)
            weights = Dict(Edge(1, 2) => 0, Edge(1, 3) => 2, Edge(2, 3) => 0)
            i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)

            @testset "Global interface" begin
                i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)
                @test objective(i) == Maximise()
            end

            @testset "Copying" begin
                i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)
                i2 = copy(i)
                @test i.weights == i2.weights
                @test i.min_budget == i2.min_budget
                @test i.compute_all_values == i2.compute_all_values
                @test i.instance.graph == i2.instance.graph
                @test i.instance.rewards == i2.instance.rewards
                @test i.instance.objective == i2.instance.objective
            end

            @testset "Reward accessor" begin
                i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)

                @test reward(i, Edge(1, 2)) == reward(i, Edge(2, 1))
            end

            @testset "Approximation" begin
                i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)

                @test approximation_ratio(i, DynamicProgramming()) == 1.0
                @test approximation_term(i, DynamicProgramming()) == 0.0

                @test approximation_ratio(i, DefaultLinearFormulation(Cbc.Optimizer)) == 1.0
                @test approximation_term(i, DefaultLinearFormulation(Cbc.Optimizer)) == 0.0

                @test isnan(approximation_ratio(i, LagrangianAlgorithm()))
                @test isnan(approximation_term(i, LagrangianAlgorithm()))

                @test isnan(approximation_ratio(i, LagrangianRefinementAlgorithm()))
                @test approximation_term(i, LagrangianRefinementAlgorithm()) == 3.0 # Depends on the instance.

                @test approximation_ratio(i, IteratedLagrangianRefinementAlgorithm()) == 0.5
                @test isnan(approximation_term(i, IteratedLagrangianRefinementAlgorithm()))
            end

            @testset "Make solution" begin
                i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)
                d = Dict(Edge(1, 2) => 0.8, Edge(1, 3) => 0.2, Edge(2, 3) => 1.0)
                s = make_solution(i, d)

                @test s.instance == i
                @test length(s.variables) == 2
                @test Edge(1, 2) ∈ s.variables
                @test Edge(1, 3) ∉ s.variables
                @test Edge(2, 3) ∈ s.variables

                @test value(s) == 4.0
            end

            @testset "Solution helpers" begin
                i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)

                # Infeasible solution.
                s = SimpleBudgetedSpanningTreeSolution(i, Edge{Int}[])
                @test value(s) == -Inf

                # Valid solution.
                d = Dict(Edge(1, 2) => 0.8, Edge(1, 3) => 0.2, Edge(2, 3) => 1.0)
                s = make_solution(i, d)
                @test value(s) == 4

                # Valid solution with reversed edges.
                s = SimpleBudgetedSpanningTreeSolution(i, [Edge(2, 1), Edge(3, 2)])
                @test value(s) == 4
            end

            @testset "Value of a tree" begin
                i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)
        
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(
                    i,
                    Edge{Int}[],
                ) == 0
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(
                    i,
                    [Edge(1, 2)],
                ) == 1.0
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(
                    i,
                    [Edge(1, 2), Edge(1, 3)],
                ) == 1.5
        
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                    i,
                    Edge{Int}[],
                ) == 0
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                    i,
                    [Edge(1, 2)],
                ) == 0
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                    i,
                    [Edge(1, 2), Edge(1, 3)],
                ) == 2
            end

            @testset "Approximation: Lagrangian refinement" begin
                graph = complete_graph(3)
                rewards = Dict(
                    Edge(1, 2) => 1.0,
                    Edge(1, 3) => 0.5,
                    Edge(2, 3) => 3.0,
                )
                weights =
                    Dict(Edge(1, 2) => 0, Edge(1, 3) => 2, Edge(2, 3) => 0)
                i = MinimumBudget(
                    SpanningTreeInstance(graph, rewards),
                    weights,
                    0,
                )

                @test_throws ErrorException solve(
                    i,
                    LagrangianRefinementAlgorithm(),
                    ζ⁻=1.0,
                )
                @test_throws ErrorException solve(
                    i,
                    LagrangianRefinementAlgorithm(),
                    ζ⁻=2.0,
                )
                @test_throws ErrorException solve(
                    i,
                    LagrangianRefinementAlgorithm(),
                    ζ⁺=1.0,
                )
                @test_throws ErrorException solve(
                    i,
                    LagrangianRefinementAlgorithm(),
                    ζ⁺=0.2,
                )
            end
        end

        @testset "Basic" begin
            graph = complete_graph(3)
            rewards =
                Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.5, Edge(2, 3) => 3.0)
            weights = Dict(Edge(1, 2) => 0, Edge(1, 3) => 2, Edge(2, 3) => 0)
            # weights = Dict(Edge(1, 2) => 1, Edge(1, 3) => 2, Edge(2, 3) => 1)

            ε = 0.0001
            budget = 1

            i = MinimumBudget(
                SpanningTreeInstance(graph, rewards),
                weights,
                budget,
            )

            @test dimension(SpanningTreeInstance(graph, rewards)) == 3
            @test dimension(i) == 3

            @testset "Lagrangian relaxation" begin
                lagrangian = solve(i, LagrangianAlgorithm(), ε=ε)
                @test lagrangian.λ ≈ 0.25 atol = ε
                @test lagrangian.value ≈ 3.75 atol = ε
                @test length(lagrangian.variables) == 2

                # Two solutions have this Lagrangian cost: a feasible one and an infeasible one.
                if Edge(1, 3) in lagrangian.variables # Strictly feasible solution.
                    @test Edge(1, 3) in lagrangian.variables
                    @test Edge(2, 3) in lagrangian.variables
                    @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                        i,
                        lagrangian.variables,
                    ) > budget
                else # Infeasible solution.
                    @test Edge(1, 2) in lagrangian.variables
                    @test Edge(2, 3) in lagrangian.variables
                    @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                        i,
                        lagrangian.variables,
                    ) < budget
                end
            end

            @testset "Lagrangian refinement (additive approximation)" begin
                sol = solve(i, LagrangianRefinementAlgorithm())
                @test sol !== nothing
                @test sol.instance == i
                s = sol.variables
                @test length(s) == 2
                @test Edge(1, 3) in s # Only important edge in this instance: the only one to have a non-zero weight.
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                    i,
                    s,
                ) >= budget
            end

            @testset "Iterated Lagrangian refinement (multiplicative approximation algorithm)" begin
                sol = solve(i, IteratedLagrangianRefinementAlgorithm())
                @test sol !== nothing
                @test sol.instance == i
                s = sol.variables
                @test length(s) == 2
                @test Edge(1, 3) in s # Only important edge in this instance: the only one to have a non-zero weight.
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                    i,
                    s,
                ) >= budget
            end

            @testset "Dynamic programming" begin
                # Mostly like the multiplicate approximation algorithm.
                sol = solve(i, DynamicProgramming())
                @test sol !== nothing
                @test sol.instance == i
                s = sol.variables
                @test length(s) == 2
                @test Edge(1, 3) in s # Only important edge in this instance: the only one to have a non-zero weight.
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                    i,
                    s,
                ) >= budget
            end

            @testset "Linear programming" begin
                # Mostly like the multiplicate approximation algorithm.
                sol = solve(i, DefaultLinearFormulation(Cbc.Optimizer))
                @test sol !== nothing
                @test sol.instance == i
                s = sol.variables
                @test length(s) == 2
                @test Edge(1, 3) in s # Only important edge in this instance: the only one to have a non-zero weight.
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(
                    i,
                    s,
                ) >= budget
            end
        end

        @testset "Conformity" begin
            graph = complete_graph(2)
            r = Dict(Edge(1, 2) => 0.0)
            w = Dict(Edge(1, 2) => 5)

            @testset "Feasible budget" begin
                i = MinimumBudget(SpanningTreeInstance(graph, r), w, 0)

                @testset "Lagrangian refinement" begin
                    s = solve(i, LagrangianRefinementAlgorithm())
                    @test s !== nothing
                    @test s.variables == [Edge(1, 2)]
                end

                @testset "Iterated Lagrangian refinement" begin
                    s = solve(i, IteratedLagrangianRefinementAlgorithm())
                    @test s !== nothing
                    @test s.variables == [Edge(1, 2)]
                end

                @testset "Dynamic programming" begin
                    s = solve(i, DynamicProgramming())
                    @test s !== nothing
                    @test s.variables == [Edge(1, 2)]
                end
            end

            @testset "Infeasible budget" begin
                i = MinimumBudget(SpanningTreeInstance(graph, r), w, 20)

                @testset "Lagrangian refinement" begin
                    s = solve(i, LagrangianRefinementAlgorithm())
                    @test s !== nothing
                    @test s.variables == Edge{Int}[]
                end

                @testset "Iterated Lagrangian refinement" begin
                    s = solve(i, IteratedLagrangianRefinementAlgorithm())
                    @test s !== nothing
                    @test s.variables == Edge{Int}[]
                end

                @testset "Dynamic programming" begin
                    s = solve(i, DynamicProgramming())
                    @test s !== nothing
                    @test s.variables == Edge{Int}[]
                end
            end
        end
    end
end
