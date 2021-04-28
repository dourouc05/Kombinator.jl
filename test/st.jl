@testset "SpanningTree" begin
    @testset "Symmetric difference" begin
        a = [Edge(1, 2), Edge(1, 3)]
        b = [Edge(1, 3), Edge(1, 4)]
        @test Kombinator._solution_symmetric_difference_size(a, b) == 2
        res_a, res_b = Kombinator._solution_symmetric_difference(a, b)
        @test res_a == [Edge(1, 2)] # Elements that are in a but not in b
        @test res_b == [Edge(1, 4)] # Elements that are in b but not in a
    end

    @testset "Copying" begin
        graph = complete_graph(5)
        rewards = Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.5, Edge(2, 3) => 3.0)

        i = SpanningTreeInstance(graph, rewards)
        i2 = copy(i)
        @test i.graph == i2.graph
        @test i.rewards == i2.rewards
        @test i.objective == i2.objective
    end

    @testset "Value of a tree" begin
        @testset "Vanilla" begin
            graph = complete_graph(5)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.5, Edge(2, 3) => 3.0)
            i = SpanningTreeInstance(graph, rewards)

            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(i, Edge{Int}[]) == 0
            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(i, [Edge(1, 2)]) == 1.0
            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(i, [Edge(1, 2), Edge(1, 3)]) == 1.5
        end

        @testset "Budgeted" begin
            graph = complete_graph(3)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.5, Edge(2, 3) => 3.0)
            weights = Dict(Edge(1, 2) => 0, Edge(1, 3) => 2, Edge(2, 3) => 0)
            i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)

            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(i, Edge{Int}[]) == 0
            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(i, [Edge(1, 2)]) == 1.0
            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_value(i, [Edge(1, 2), Edge(1, 3)]) == 1.5

            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, Edge{Int}[]) == 0
            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, [Edge(1, 2)]) == 0
            @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, [Edge(1, 2), Edge(1, 3)]) == 2
        end
    end

    @testset "Maximum spanning tree" begin
        @testset "Basic" begin
            graph = complete_graph(5)
            rewards = Dict(Edge(1, 2) => 121.0, Edge(1, 3) => 10.0, Edge(1, 4) => 10.0, Edge(1, 5) => 10.0, Edge(2, 3) => 121.0, Edge(2, 4) => 10.0, Edge(2, 5) => 10.0, Edge(3, 4) => 121.0, Edge(3, 5) => 10.0, Edge(4, 5) => 121.0)

            i = SpanningTreeInstance(graph, rewards)
            p = solve(i, PrimAlgorithm())
            g = solve(i, GreedyAlgorithm()) # Same as Prim.
            d = solve(i, DynamicProgramming())
            l = solve(i, DefaultLinearFormulation(), solver=Cbc.Optimizer)

            for s in [p, g, d, l]
                @test s.instance == i
                @test length(s.tree) == 4
                @test Edge(1, 2) in s.tree
                @test Edge(2, 3) in s.tree
                @test Edge(3, 4) in s.tree
                @test Edge(4, 5) in s.tree
            end
        end

        @testset "Conformity" begin
            graph = complete_graph(5)
            rewards = Dict(Edge(2, 5) => 0.0, Edge(3, 5) => 0.0, Edge(4, 5) => 1.0, Edge(1, 2) => 0.0, Edge(2, 3) => 0.0, Edge(1, 4) => 0.0, Edge(2, 4) => 0.0, Edge(1, 5) => 0.0, Edge(1, 3) => 0.0, Edge(3, 4) => 0.0)

            i = SpanningTreeInstance(graph, rewards)
            p = solve(i, PrimAlgorithm())
            g = solve(i, GreedyAlgorithm()) # Same as Prim.
            d = solve(i, DynamicProgramming())
            l = solve(i, DefaultLinearFormulation(), solver=Cbc.Optimizer)

            for s in [p, g, d, l]
                @test s.instance == i
                @test length(s.tree) == 4 # Five nodes in the graph.
                @test length(unique(s.tree)) == 4 # Only unique edges.
                @test Edge(4, 5) in s.tree # Only edge with nonzero cost.
            end
        end
    end

    @testset "Budgeted maximum spanning tree" begin
        @testset "Interface" begin
            @testset "Approximation: Lagrangian refinement" begin
                graph = complete_graph(3)
                rewards = Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.5, Edge(2, 3) => 3.0)
                weights = Dict(Edge(1, 2) => 0, Edge(1, 3) => 2, Edge(2, 3) => 0)
                i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, 0)

                @test_throws ErrorException solve(i, LagrangianRefinementAlgorithm(), ζ⁻=1.0)
                @test_throws ErrorException solve(i, LagrangianRefinementAlgorithm(), ζ⁻=2.0)
                @test_throws ErrorException solve(i, LagrangianRefinementAlgorithm(), ζ⁺=1.0)
                @test_throws ErrorException solve(i, LagrangianRefinementAlgorithm(), ζ⁺=0.2)
            end
        end

        @testset "Basic" begin
            graph = complete_graph(3)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.5, Edge(2, 3) => 3.0)
            weights = Dict(Edge(1, 2) => 0, Edge(1, 3) => 2, Edge(2, 3) => 0)
            # weights = Dict(Edge(1, 2) => 1, Edge(1, 3) => 2, Edge(2, 3) => 1)

            ε = 0.0001
            budget = 1
            
            i = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, budget)

            @testset "Lagrangian relaxation" begin
                lagrangian = solve(i, LagrangianAlgorithm(), ε=ε)
                @test lagrangian.λ ≈ 0.25 atol=ε
                @test lagrangian.value ≈ 3.75 atol=ε
                @test length(lagrangian.tree) == 2
                
                # Two solutions have this Lagrangian cost: a feasible one and an infeasible one.
                if Edge(1, 3) in lagrangian.tree # Strictly feasible solution.
                    @test Edge(1, 3) in lagrangian.tree
                    @test Edge(2, 3) in lagrangian.tree
                    @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, lagrangian.tree) > budget
                else # Infeasible solution.
                    @test Edge(1, 2) in lagrangian.tree
                    @test Edge(2, 3) in lagrangian.tree
                    @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, lagrangian.tree) < budget
                end
            end

            @testset "Lagrangian refinement (additive approximation)" begin
                sol = solve(i, LagrangianRefinementAlgorithm())
                @test sol !== nothing
                @test sol.instance == i
                s = sol.tree
                @test length(s) == 2
                @test Edge(1, 3) in s # Only important edge in this instance: the only one to have a non-zero weight.
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, s) >= budget
            end

            @testset "Iterated Lagrangian refinement (multiplicative approximation algorithm)" begin
                sol = solve(i, IteratedLagrangianRefinementAlgorithm())
                @test sol !== nothing
                @test sol.instance == i
                s = sol.tree
                @test length(s) == 2
                @test Edge(1, 3) in s # Only important edge in this instance: the only one to have a non-zero weight.
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, s) >= budget
            end

            @testset "Dynamic programming" begin
                # Mostly like the multiplicate approximation algorithm.
                sol = solve(i, DynamicProgramming())
                @test sol !== nothing
                @test sol.instance == i
                s = sol.tree
                @test length(s) == 2
                @test Edge(1, 3) in s # Only important edge in this instance: the only one to have a non-zero weight.
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, s) >= budget
            end

            @testset "Linear programming" begin
                # Mostly like the multiplicate approximation algorithm.
                sol = solve(i, DefaultLinearFormulation(), solver=Cbc.Optimizer)
                @test sol !== nothing
                @test sol.instance == i
                s = sol.tree
                @test length(s) == 2
                @test Edge(1, 3) in s # Only important edge in this instance: the only one to have a non-zero weight.
                @test Kombinator.SpanningTree._budgeted_spanning_tree_compute_weight(i, s) >= budget
            end
        end
        
        # More advanced tests to ensure the algorithm works as expected.

        @testset "Conformity" begin
            graph = complete_graph(2)
            r = Dict(Edge(1, 2) => 0.0)
            w = Dict(Edge(1, 2) => 5)

            @testset "Feasible budget" begin
                i = MinimumBudget(SpanningTreeInstance(graph, r), w, 0)

                @testset "Lagrangian refinement" begin
                    s = solve(i, LagrangianRefinementAlgorithm())
                    @test s !== nothing
                    @test s.tree == [Edge(1, 2)]
                end

                @testset "Iterated Lagrangian refinement" begin
                    s = solve(i, IteratedLagrangianRefinementAlgorithm())
                    @test s !== nothing
                    @test s.tree == [Edge(1, 2)]
                end

                @testset "Dynamic programming" begin
                    s = solve(i, DynamicProgramming())
                    @test s !== nothing
                    @test s.tree == [Edge(1, 2)]
                end
            end

            @testset "Infeasible budget" begin
                i = MinimumBudget(SpanningTreeInstance(graph, r), w, 20)

                @testset "Lagrangian refinement" begin                
                    s = solve(i, LagrangianRefinementAlgorithm())
                    @test s !== nothing
                    @test s.tree == Edge{Int}[]
                end

                @testset "Iterated Lagrangian refinement" begin
                    s = solve(i, IteratedLagrangianRefinementAlgorithm())
                    @test s !== nothing
                    @test s.tree == Edge{Int}[]
                end

                @testset "Dynamic programming" begin
                    s = solve(i, DynamicProgramming())
                    @test s !== nothing
                    @test s.tree == Edge{Int}[]
                end
            end
        end
    end
end
