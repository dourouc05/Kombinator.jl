struct ExactNonlinearSolver <: NonlinearCombinatorialAlgorithm
    solver # MINLP solver with support for the nonlinear function.
end

function solve(i::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver)
    li = i.combinatorial_structure()
    return solve(i, algo, Val(i.nonlinear_function))
end

function solve(i::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver, ::Val{SquareRoot})
end

function solve(i::NonlinearCombinatorialInstance, algo::ExactNonlinearSolver, ::Val{Square})
end
