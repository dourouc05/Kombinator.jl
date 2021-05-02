using CSV
using DataFrames
using Gurobi
using Kombinator
using LightGraphs

n_repetitions = 10

run_um = true
run_st = true
run_ep = true

# Generic helpers.
function parse_algo_string(str::String)
    if str == "Exact"
        method = "Exact"
        algo = "Irrelevant"
        nls = ExactNonlinearSolver(Gurobi.Optimizer)
    elseif str == "Approx: DP"
        method = "NLCOP"
        algo = "Dynamic programming"
        nls = ApproximateNonlinearSolver(DynamicProgramming())
    elseif str == "Approx: LP"
        method = "NLCOP"
        algo = "Linear programming"
        nls = ApproximateNonlinearSolver(DefaultLinearFormulation(Gurobi.Optimizer))
    else
        error("Unrecognised algorithm: $(str).")
    end
    return method, algo, nls
end

# Uniform matroid. 
if run_um
    um = DataFrame(method=String[], algo=String[], name=String[], nonlinearity=String[], size=Int[], repetition=Int[], objective=Float64[], time_ms=Float64[])
    um_sizes = [2, 5, 10, 20, 50, 100, 200, 500, 1000, 2000]
    um_algos = ["Exact", "Approx: DP", "Approx: LP"]

    for repetition in 1:n_repetitions
        for size in um_sizes
            m = max(1, round(Int, size / 3))
            hi = 1.0
            lo = 0.5

            lw = [ifelse(i <= size / 2, hi, lo) for i in 1:size]
            nlw = [ifelse(i <= size / 2, lo, hi) for i in 1:size]

            for um_algo in um_algos
                method, algo, nls = parse_algo_string(um_algo)

                li = UniformMatroidInstance(lw, m, Maximise())
                nli = NonlinearCombinatorialInstance(
                    li,
                    lw,
                    nlw,
                    SquareRoot,
                    0.5,
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
    st = DataFrame(method=String[], algo=String[], name=String[], nonlinearity=String[], size=Int[], repetition=Int[], objective=Float64[], time_ms=Float64[])
    st_sizes = [2, 5, 10, 20, 50, 100, 200, 500]
    st_algos = ["Exact", "Approx: DP", "Approx: LP"]

    for repetition in 1:n_repetitions
        for size in st_sizes
            g = complete_graph(size)
            hi = 1.0
            lo = 0.5

            lw = Dict{Edge{Int}, Float64}(e => ifelse(i <= size / 2, hi, lo) for (i, e) in enumerate(edges(g)))
            nlw = Dict{Edge{Int}, Float64}(e => ifelse(i <= size / 2, lo, hi) for (i, e) in enumerate(edges(g)))

            for st_algo in st_algos
                method, algo, nls = parse_algo_string(st_algo)

                li = SpanningTreeInstance(g, lw, Maximise())
                nli = NonlinearCombinatorialInstance(
                    li,
                    lw,
                    nlw,
                    SquareRoot,
                    0.5,
                    DefaultLinearFormulation(Gurobi.Optimizer),
                    true,
                    DefaultLinearFormulation(Gurobi.Optimizer),
                )

                t0 = time_ns()
                s = solve(nli, nls)
                t1 = time_ns()

                time_ms = (t1 - t0) / 1_000_000
                obj_lin = sum(e in keys(lw) ? lw[e] : lw[reverse(e)] for e in s.variables)
                obj_nl = sum(e in keys(nlw) ? nlw[e] : nlw[reverse(e)] for e in s.variables)
                obj = obj_lin + sqrt(obj_nl)

                push!(st, Dict(:method => method, :algo => algo, :name => st_algo, :nonlinearity => "Square root", :size => size, :repetition => repetition, :objective => obj, :time_ms => time_ms))
            end
        end
    end

    CSV.write(@__DIR__() * "/st.csv", st)
end

# Elementary path.
if run_ep
    ep = DataFrame(method=String[], algo=String[], name=String[], nonlinearity=String[], size=Int[], repetition=Int[], objective=Float64[], time_ms=Float64[])
    ep_sizes = [2, 5, 10, 20, 50, 100, 200, 500]
    ep_algos = ["Exact", "Approx: DP", "Approx: LP"]

    for repetition in 1:n_repetitions
        for size in ep_sizes
            g0 = complete_graph(size) # Only for determining the edges
            g = complete_digraph(size)
            hi = 1.0
            lo = 0.5

            lw = Dict{Edge{Int}, Float64}(e => ifelse(i <= size / 2, hi, lo) for (i, e) in enumerate(edges(g0)))
            nlw = Dict{Edge{Int}, Float64}(e => ifelse(i <= size / 2, lo, hi) for (i, e) in enumerate(edges(g0)))

            for ep_algo in ep_algos
                method, algo, nls = parse_algo_string(ep_algo)

                li = ElementaryPathInstance(g, lw, 1, size, Maximise())
                nli = NonlinearCombinatorialInstance(
                    li,
                    lw,
                    nlw,
                    SquareRoot,
                    0.5,
                    DefaultLinearFormulation(Gurobi.Optimizer),
                    true,
                    DefaultLinearFormulation(Gurobi.Optimizer),
                )

                t0 = time_ns()
                s = solve(nli, nls)
                t1 = time_ns()

                time_ms = (t1 - t0) / 1_000_000
                obj_lin = sum(e in keys(lw) ? lw[e] : lw[reverse(e)] for e in s.variables)
                obj_nl = sum(e in keys(nlw) ? nlw[e] : nlw[reverse(e)] for e in s.variables)
                obj = obj_lin + sqrt(obj_nl)

                push!(ep, Dict(:method => method, :algo => algo, :name => ep_algo, :nonlinearity => "Square root", :size => size, :repetition => repetition, :objective => obj, :time_ms => time_ms))
            end
        end
    end

    CSV.write(@__DIR__() * "/ep.csv", ep)
end
