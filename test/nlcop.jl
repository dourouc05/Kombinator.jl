@testset "NLCOP" begin
    if ! is_travis
        @testset "Exact" begin
            @testset "Basic" begin
                m = 2
                lw = Float64[1, 2, 3, 4, 5]
                nlw = Float64[5, 4, 3, 2, 1]
                # Maximum value for the sqrt(sum of the two chosen nlw): sqrt(5 + 4) = 3.0.
                # Minimum value for the sqrt(sum of the two chosen nlw): sqrt(2 + 1) ≈ 1.73.

                li = UniformMatroidInstance(lw, m, Maximise())
                nli = NonlinearCombinatorialInstance(li, lw, nlw, SquareRoot, 0.01, DefaultLinearFormulation())
                s = solve(nli, ExactNonlinearSolver(Gurobi.Optimizer))

                @test s.instance == li
                @test Set(s.items) == Set([4, 5])
            end
        end
    end

    @testset "Approximate" begin
    end
end