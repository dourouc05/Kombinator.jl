@testset "NLCOP" begin
    if !is_travis
        @testset "Exact" begin
            @testset "Basic: uniform matroid" begin
                m = 2
                lw = Float64[1, 2, 3, 4, 5]
                nlw = Float64[5, 4, 3, 2, 1]
                # Maximum value for the sqrt(sum of the two chosen nlw): sqrt(5 + 4) = 3.0.
                # Minimum value for the sqrt(sum of the two chosen nlw): sqrt(2 + 1) ≈ 1.73.

                li = UniformMatroidInstance(lw, m, Maximise())
                nli = NonlinearCombinatorialInstance(
                    li,
                    lw,
                    nlw,
                    SquareRoot,
                    0.01,
                    DefaultLinearFormulation(nothing),
                    true,
                    DefaultLinearFormulation(nothing),
                )
                s = solve(nli, ExactNonlinearSolver(Gurobi.Optimizer))

                @test s.instance == li
                @test Set(s.variables) == Set([4, 5])
            end

            @testset "Basic: spanning tree" begin
                graph = complete_graph(5)
                lw = Dict{Edge{Int}, Float64}(e => src(e) for e in edges(graph))
                nlw = Dict{Edge{Int}, Float64}(
                    e => ne(graph) - src(e) for e in edges(graph)
                )

                li = SpanningTreeInstance(graph, lw, Maximise())
                nli = NonlinearCombinatorialInstance(
                    li,
                    lw,
                    nlw,
                    SquareRoot,
                    0.01,
                    DefaultLinearFormulation(nothing),
                    true,
                    DefaultLinearFormulation(nothing),
                )
                s = solve(nli, ExactNonlinearSolver(Gurobi.Optimizer))

                obj_lin = sum(lw[e] for e in s.variables)
                obj_nl = sqrt(sum(nlw[e] for e in s.variables))

                # There is a unique way to represent the solution, as the LP 
                # formulation ensures that 1 is the root of the tree. Thus, 
                # check explicitly the solution.
                @test s.instance == li
                @test Set(s.variables) ==
                      Set([Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)])
                @test obj_lin + obj_nl ≈ 15.47 atol = 1.0e-2
            end

            @testset "Basic: elementary path" begin
                graph = complete_digraph(5)
                lw = Dict{Edge{Int}, Float64}(
                    e => min(src(e), dst(e)) for e in edges(graph)
                )
                nlw = Dict{Edge{Int}, Float64}(
                    e => ne(graph) - min(src(e), dst(e)) for e in edges(graph)
                )

                li = ElementaryPathInstance(graph, lw, 1, 5, Maximise())
                nli = NonlinearCombinatorialInstance(
                    li,
                    lw,
                    nlw,
                    SquareRoot,
                    0.01,
                    DefaultLinearFormulation(nothing),
                    true,
                    DefaultLinearFormulation(nothing),
                )
                s = solve(nli, ExactNonlinearSolver(Gurobi.Optimizer))

                obj_lin = sum(lw[e] for e in s.variables)
                obj_nl = sqrt(sum(nlw[e] for e in s.variables))

                @test s.instance == li
                @test Set(s.variables) ==
                      Set([Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)])
                @test obj_lin + obj_nl ≈ 18.36 atol = 1.0e-2
            end
        end
    end

    @testset "Approximate" begin
        @testset "Basic: uniform matroid, DP-based" begin
            m = 2
            lw = Float64[1, 2, 3, 4, 5]
            nlw = Float64[5, 4, 3, 2, 1]
            # Maximum value for the sqrt(sum of the two chosen nlw): sqrt(5 + 4) = 3.0.
            # Minimum value for the sqrt(sum of the two chosen nlw): sqrt(2 + 1) ≈ 1.73.

            li = UniformMatroidInstance(lw, m, Maximise())
            nli = NonlinearCombinatorialInstance(
                li,
                lw,
                nlw,
                SquareRoot,
                0.01,
                DynamicProgramming(),
                true,
                DefaultLinearFormulation(nothing),
            )
            s = solve(nli, ApproximateNonlinearSolver(DynamicProgramming()))

            @test s.instance == li
            @test Set(s.variables) == Set([4, 5])
        end
        
        if !is_travis
            @testset "Basic: uniform matroid, LP-based" begin
                m = 2
                lw = Float64[1, 2, 3, 4, 5]
                nlw = Float64[5, 4, 3, 2, 1]
                # Maximum value for the sqrt(sum of the two chosen nlw): sqrt(5 + 4) = 3.0.
                # Minimum value for the sqrt(sum of the two chosen nlw): sqrt(2 + 1) ≈ 1.73.

                li = UniformMatroidInstance(lw, m, Maximise())
                nli = NonlinearCombinatorialInstance(
                    li,
                    lw,
                    nlw,
                    SquareRoot,
                    0.01,
                    DefaultLinearFormulation(Gurobi.Optimizer),
                    true,
                    DefaultLinearFormulation(nothing),
                )
                s = solve(nli, ApproximateNonlinearSolver(DefaultLinearFormulation(Gurobi.Optimizer)))

                @test s.instance == li
                @test Set(s.variables) == Set([4, 5])
            end
        end

        @testset "Basic: spanning tree, DP-based" begin
            graph = complete_graph(5)
            lw = Dict{Edge{Int}, Float64}(
                e => min(src(e), dst(e)) for e in edges(graph)
            )
            nlw = Dict{Edge{Int}, Float64}(
                e => ne(graph) - min(src(e), dst(e)) for e in edges(graph)
            )

            li = SpanningTreeInstance(graph, lw, Maximise())
            nli = NonlinearCombinatorialInstance(
                li,
                lw,
                nlw,
                SquareRoot,
                0.01,
                DynamicProgramming(),
                true,
                DefaultLinearFormulation(nothing),
            )
            s = solve(nli, ApproximateNonlinearSolver(DynamicProgramming()))

            obj_lin = sum(lw[e] for e in s.variables)
            obj_nl = sqrt(sum(nlw[e] for e in s.variables))

            @test s.instance == li
            @test obj_lin + obj_nl ≈ 15.47 atol = 1.0e-2
        end

        @testset "Basic: elementary path, DP-based" begin
            graph = complete_digraph(5)
            lw = Dict{Edge{Int}, Float64}(e => src(e) for e in edges(graph))
            nlw = Dict{Edge{Int}, Float64}(
                e => ne(graph) - src(e) for e in edges(graph)
            )

            li = ElementaryPathInstance(graph, lw, 1, 5, Maximise())
            nli = NonlinearCombinatorialInstance(
                li,
                lw,
                nlw,
                SquareRoot,
                0.01,
                DynamicProgramming(),
                true,
                DefaultLinearFormulation(nothing),
            )
            s = solve(nli, ApproximateNonlinearSolver(DynamicProgramming()))

            obj_lin = sum(lw[e] for e in s.variables)
            obj_nl = sqrt(sum(nlw[e] for e in s.variables))

            @test s.instance == li
            @test Set(s.variables) ==
                  Set([Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)])
            @test obj_lin + obj_nl ≈ 18.36 atol = 1.0e-2
        end
    end
end
