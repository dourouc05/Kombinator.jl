using CSV
using DataFrames
using Gurobi
using Kombinator

n_repetitions = 10

run_um = true
run_st = true
run_ep = true

# Uniform matroid. 
if run_um
    um = DataFrame(method=String[], algo=String[], name=String[], nonlinearity=String[], size=Int[], repetition=Int[], objective=Float64[], time_ms=Float64[])
    um_sizes = [2, 5, 10, 20, 50, 100, 200, 500, 1000]
    um_algos = ["Exact", "Approx: DP", "Approx: LP"]

    for repetition in 1:n_repetitions
        for size in um_sizes
            m = max(1, round(Int, size / 3))
            hi = 1.0
            lo = 0.1

            lw = [ifelse(i <= size / 2, hi, lo) for i in 1:size]
            nlw = [ifelse(i <= size / 2, lo, hi) for i in 1:size]

            for um_algo in um_algos
                if um_algo == "Exact"
                    method = "Exact"
                    algo = "Irrelevant"
                    nls = ExactNonlinearSolver(Gurobi.Optimizer)
                elseif um_algo == "Approx: DP"
                    method = "NLCOP"
                    algo = "Dynamic programming"
                    nls = ApproximateNonlinearSolver(DynamicProgramming())
                elseif um_algo == "Approx: LP"
                    method = "NLCOP"
                    algo = "Linear programming"
                    nls = ApproximateNonlinearSolver(DefaultLinearFormulation(Gurobi.Optimizer))
                else
                    error("Unrecognised algorithm for uniform matroid: $(um_algo).")
                end

                li = UniformMatroidInstance(lw, m, Maximise())
                nli = NonlinearCombinatorialInstance(
                    li,
                    lw,
                    nlw,
                    SquareRoot,
                    0.01,
                    DefaultLinearFormulation(Gurobi.Optimizer),
                    true,
                    DefaultLinearFormulation(Gurobi.Optimizer),
                )

                t0 = time_ns()
                s = solve(nli, nls)
                t1 = time_ns()

                time_ms = (t1 - t0) / 1_000_000
                obj_lin = sum(lw[e] for e in s.variables)
                obj_nl = sum(nlw[e] for e in s.variables)
                obj = obj_lin + sqrt(obj_nl)

                push!(um, Dict(:method => method, :algo => algo, :name => um_algo, :nonlinearity => "Square root", :size => size, :repetition => repetition, :objective => obj, :time_ms => time_ms))
            end
        end
    end

    CSV.write(@__DIR__() * "/um.csv", um)
end

# Spanning tree. 
if run_st
end

# Elementary path.
if run_ep
end
