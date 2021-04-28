@testset "ElementaryPath" begin
    @testset "Copying" begin
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

    @testset "Transforming a solution" begin
        g = path_digraph(3)
        add_edge!(g, 1, 3)
        rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0, Edge(1, 3) => 1.0)
        weights = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1, Edge(1, 3) => 4)
        
        i = MinimumBudget(ElementaryPathInstance(g, rewards, 1, 3), weights, 4)
        path = [Edge(1, 3)]
        states = Dict((1, 2) => 0.0, (3, 1) => 2.0, (1, 3) => 0.0, (1, 4) => 0.0, (3, 2) => 2.0, (2, 0) => 1.0, (3, 3) => 1.0, (2, 1) => 1.0, (3, 4) => 1.0, (2, 2) => -Inf, (2, 3) => -Inf, (1, 0) => 0.0, (2, 4) => -Inf, (1, 1) => 0.0, (3, 0) => 2.0)
        solutions = Dict{Tuple{Int, Int}, Vector{Edge{Int}}}((1, 2) => [], (3, 1) => [Edge(1, 2), Edge(2, 3)], (1, 3) => [], (1, 4) => [], (3, 2) => [Edge(1, 2), Edge(2, 3)], (2, 0) => [Edge(1, 2)], (3, 3) => [Edge(1, 3)], (2, 1) => [Edge(1, 2)], (3, 4) => [Edge(1, 3)], (2, 2) => [], (2, 3) => [], (1, 0) => [], (2, 4) => [], (1, 1) => [], (3, 0) => [Edge(1, 2), Edge(2, 3)])
        d = BudgetedElementaryPathSolution(i, path, states, solutions)

        warn_msg = "The requested maximum budget 5 is higher than the instance's minimum budget 4. Therefore, some values have not been computed and are unavailable."
        @test_logs (:warn, warn_msg) Kombinator.paths_all_budgets_as_tuples(d, 5)
        sol = Dict(0 => [(1, 2), (2, 3)], 1 => [(1, 2), (2, 3)], 2 => [(1, 2), (2, 3)], 3 => [(1, 3)], 4 => [(1, 3)])
        @test Kombinator.paths_all_budgets_as_tuples(d, 4) == sol

        @test_logs (:warn, warn_msg) Kombinator.paths_all_budgets(d, 5)
        sol = Dict(0 => [Edge(1, 2), Edge(2, 3)], 1 => [Edge(1, 2), Edge(2, 3)], 2 => [Edge(1, 2), Edge(2, 3)], 3 => [Edge(1, 3)], 4 => [Edge(1, 3)])
        @test Kombinator.paths_all_budgets(d, 4) == sol
    end

    @testset "Elementary paths" begin
        @testset "Interface" begin
            @testset "Positive-reward cycle" begin
                g = path_digraph(3)
                add_edge!(g, 2, 1)
                rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 3.0, Edge(2, 1) => 25.0)

                i = ElementaryPathInstance(g, rewards, 1, 3)
                @test_logs (:warn, "The graph contains a positive-cost cycle around edge 2 -> 1.") solve(i, BellmanFordAlgorithm())
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
                    @test s.path == [Edge(1, 2), Edge(2, 3)]
                end

                if ! is_travis
                    @testset "Linear programming" begin
                        s = solve(i, DefaultLinearFormulation(), solver=Gurobi.Optimizer) # Cbc unsupported.
                        @test s.instance == i
                        @test s.path == [Edge(1, 2), Edge(2, 3)]
                    end
                end
            end
            
            @testset "High-weight edge" begin
                g = path_digraph(3)
                add_edge!(g, 1, 3)
                rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0, Edge(1, 3) => 4.0)
                weights = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1, Edge(1, 3) => 4)

                i = ElementaryPathInstance(g, rewards, 1, 3)

                @testset "Bellman-Ford" begin
                    s = solve(i, BellmanFordAlgorithm())
                    @test s.instance == i
                    @test s.path == [Edge(1, 3)]
                end

                if ! is_travis
                    @testset "Linear programming" begin
                        s = solve(i, DefaultLinearFormulation(), solver=Gurobi.Optimizer) # Cbc unsupported.
                        @test s.instance == i
                        @test s.path == [Edge(1, 3)]
                    end
                end
            end
        end
    end

    @testset "Budgeted elementary paths" begin
        @testset "Interface" begin
            # TODO: these consistency checks cannot be performed within MinimumBudget...
            g = path_digraph(3)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0)
            weights = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1)
            # @test_throws ErrorException MinimumBudget(ElementaryPathInstance(g, rewards, 1, 1), weights)
            # @test_throws ErrorException MinimumBudget(ElementaryPathInstance(g, rewards, 1, 2), weights, -1)

            rewards[Edge(4, 1)] = 1.0
            # @test_throws ErrorException MinimumBudget(ElementaryPathInstance(g, rewards, 1, 1), weights)
            weights[Edge(4, 1)] = 1
            weights[Edge(4, 2)] = 1
            # @test_throws ErrorException MinimumBudget(ElementaryPathInstance(g, rewards, 1, 1), weights)
            weights[Edge(4, 2)] = -1
            # @test_throws ErrorException MinimumBudget(ElementaryPathInstance(g, rewards, 1, 1), weights)
        end

        @testset "Basic" begin
            @testset "Directed path graph" begin
                g = path_digraph(3)
                rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0)
                weights = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1)

                i = MinimumBudget(ElementaryPathInstance(g, rewards, 1, 3), weights, 4)

                @testset "Bellman-Ford" begin
                    d = solve(i, BellmanFordAlgorithm())

                    @test d.instance == i
                    @test d.path == [] # No path with a total weight of at least 4.

                    for β in [0, 1, 2]
                        @test d.solutions[1, β] == []
                        @test d.solutions[2, β] == ((β == 2) ? [] : [Edge(1, 2)])
                        @test d.solutions[3, β] == [Edge(1, 2), Edge(2, 3)]
                    end
                    for β in [3, 4]
                        for v in [1, 2, 3]
                            @test d.solutions[v, β] == []
                        end
                    end
                end

                if ! is_travis
                    @testset "Linear programming" begin
                        s = solve(i, DefaultLinearFormulation(), solver=Gurobi.Optimizer) # Cbc unsupported.
                        @test s.instance == i
                        @test s.path == []
                    end
                end
            end

            @testset "High-weight edge" begin
                g = path_digraph(3)
                add_edge!(g, 1, 3)
                rewards = Dict(Edge(1, 2) => 1.0, Edge(2, 3) => 1.0, Edge(1, 3) => 1.0)
                weights = Dict(Edge(1, 2) => 1, Edge(2, 3) => 1, Edge(1, 3) => 4)

                i = MinimumBudget(ElementaryPathInstance(g, rewards, 1, 3), weights, 4)
                
                @testset "Bellman-Ford" begin
                    s = solve(i, BellmanFordAlgorithm())
                    @test s.instance == i
                    @test s.path == [Edge(1, 3)]
                end

                if ! is_travis
                    @testset "Linear programming" begin
                        s = solve(i, DefaultLinearFormulation(), solver=Gurobi.Optimizer) # Cbc unsupported.
                        @test s.instance == i
                        @test s.path == [Edge(1, 3)]
                    end
                end
            end
        end

        @testset "Conformity" begin
            # More advanced tests to ensure the algorithm works as expected.
            g = complete_digraph(3)
            rewards = Dict(Edge(1, 2) => 1.0, Edge(3, 1) => -1.0, Edge(3, 2) => -1.0, Edge(2, 3) => 1.0, Edge(2, 1) => -1.0, Edge(1, 3) => 0.0)
            weights = Dict(Edge(1, 2) => 0, Edge(3, 1) => 0, Edge(3, 2) => 0, Edge(2, 3) => 0, Edge(2, 1) => 0, Edge(1, 3) => 2)
            i = MinimumBudget(ElementaryPathInstance(g, rewards, 1, 3), weights, 2, compute_all_values=true)
            
            @testset "Bellman-Ford" begin
                warn_msg = "The graph contains a positive-cost cycle around edge 3 -> 1."
                d = @test_logs (:warn, warn_msg) solve(i, BellmanFordAlgorithm())

                @test d.path == [Edge(1, 3)]

                @test d.solutions[1, 0] == []
                @test d.solutions[2, 0] == [Edge(1, 2)]
                @test d.solutions[3, 0] == [Edge(1, 2), Edge(2, 3)]
                @test d.states[1, 0] == 0.0
                @test d.states[2, 0] == 1.0
                @test d.states[3, 0] == 2.0

                @test d.solutions[1, 1] == []
                @test d.solutions[2, 1] == [Edge(1, 3), Edge(3, 2)]
                @test d.solutions[3, 1] == [Edge(1, 3)]
                @test d.states[1, 1] == 0.0
                @test d.states[2, 1] == -1.0
                @test d.states[3, 1] == 0.0

                @test d.solutions[1, 2] == []
                @test d.solutions[2, 2] == [Edge(1, 3), Edge(3, 2)]
                @test d.solutions[3, 2] == [Edge(1, 3)]
                @test d.states[1, 2] == 0.0
                @test d.states[2, 2] == -1.0
                @test d.states[3, 2] == 0.0
            end

            if ! is_travis
                @testset "Linear programming" begin
                    l = solve(i, DefaultLinearFormulation(), solver=Gurobi.Optimizer) # Cbc unsupported.
                    # All solutions have the same destination! Only paths from 1 to 3, unlike DP.
                    @test l.solutions[3, 0] == [Edge(1, 2), Edge(2, 3)]
                    @test l.solutions[3, 1] == [Edge(1, 3)]
                    @test l.solutions[3, 2] == [Edge(1, 3)]
                    @test l.states[3, 0] == 2.0
                    @test l.states[3, 1] == 0.0
                    @test l.states[3, 2] == 0.0
                end
            end
        end
    end
end
