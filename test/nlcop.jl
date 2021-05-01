@testset "NLCOP" begin
    if ! is_travis
        @testset "Exact" begin
            @testset "Basic: uniform matroid" begin
                m = 2
                lw = Float64[1, 2, 3, 4, 5]
                nlw = Float64[5, 4, 3, 2, 1]
                # Maximum value for the sqrt(sum of the two chosen nlw): sqrt(5 + 4) = 3.0.
                # Minimum value for the sqrt(sum of the two chosen nlw): sqrt(2 + 1) ≈ 1.73.

                li = UniformMatroidInstance(lw, m, Maximise())
                nli = NonlinearCombinatorialInstance(li, lw, nlw, SquareRoot, 0.01, DefaultLinearFormulation(), true, DefaultLinearFormulation())
                s = solve(nli, ExactNonlinearSolver(Gurobi.Optimizer))

                @test s.instance == li
                @test Set(s.variables) == Set([4, 5])
            end
            
            @testset "Basic: spanning tree" begin
                graph = complete_graph(5)
                lw = Dict{Edge{Int}, Float64}(e => i for (i, e) in enumerate(edges(graph)))
                nlw = Dict{Edge{Int}, Float64}(e => ne(graph) - i for (i, e) in enumerate(edges(graph)))

                li = SpanningTreeInstance(graph, lw, Maximise())
                nli = NonlinearCombinatorialInstance(li, lw, nlw, SquareRoot, 0.01, DefaultLinearFormulation(), true, DefaultLinearFormulation())
                s = solve(nli, ExactNonlinearSolver(Gurobi.Optimizer))

                @test s.instance == li
                @show sum(lw[e] for e in [Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)]) + sqrt(sum(nlw[e] for e in [Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)]))
                @show sum(lw[e] for e in s.variables) + sqrt(sum(nlw[e] for e in s.variables))
                @test Set(s.variables) == Set([Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)])
                @test sum(lw[e] for e in s.variables) + sqrt(sum(nlw[e] for e in s.variables)) ≈ 33.16227766
            end
        end
    end

    @testset "Approximate" begin
        @testset "Basic: uniform matroid" begin
            m = 2
            lw = Float64[1, 2, 3, 4, 5]
            nlw = Float64[5, 4, 3, 2, 1]
            # Maximum value for the sqrt(sum of the two chosen nlw): sqrt(5 + 4) = 3.0.
            # Minimum value for the sqrt(sum of the two chosen nlw): sqrt(2 + 1) ≈ 1.73.

            li = UniformMatroidInstance(lw, m, Maximise())
            nli = NonlinearCombinatorialInstance(li, lw, nlw, SquareRoot, 0.01, DynamicProgramming(), true, DefaultLinearFormulation())
            s = solve(nli, ApproximateNonlinearSolver(DynamicProgramming()))

            @test s.instance == li
            @test Set(s.variables) == Set([4, 5])
        end

        @testset "Basic: spanning tree" begin
            graph = complete_graph(5)
            lw = Dict{Edge{Int}, Float64}(e => i for (i, e) in enumerate(edges(graph)))
            nlw = Dict{Edge{Int}, Float64}(e => ne(graph) - i for (i, e) in enumerate(edges(graph)))

            li = SpanningTreeInstance(graph, lw, Maximise())
            nli = NonlinearCombinatorialInstance(li, lw, nlw, SquareRoot, 0.01, DynamicProgramming(), true, DefaultLinearFormulation())
            s = solve(nli, ApproximateNonlinearSolver(DynamicProgramming()))

            @test s.instance == li
            @show sum(lw[e] for e in [Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)]) + sqrt(sum(nlw[e] for e in [Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)]))
            @show sum(lw[e] for e in s.variables) + sqrt(sum(nlw[e] for e in s.variables))
            @test Set(s.variables) == Set([Edge(1, 2), Edge(2, 3), Edge(3, 4), Edge(4, 5)])
            @test sum(lw[e] for e in s.variables) + sqrt(sum(nlw[e] for e in s.variables)) ≈ 33.16227766
        end
    end
end