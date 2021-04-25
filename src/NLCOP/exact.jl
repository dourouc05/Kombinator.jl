struct ExactNonlinearSolver <: NonlinearCombinatorialAlgorithm
    solver # MINLP solver with support for the nonlinear function.
end

function solve(i::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver)
    # TODO: better handling for nonlinear functions. Based on Convex.jl?
    return solve(i, algo, Val(i.nonlinear_function))
end

function solve(i::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver, ::Val{SquareRoot})
end

function solve(i::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver, ::Val{Square})
end
