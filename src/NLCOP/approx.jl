struct ApproximateNonlinearSolver <: NonlinearCombinatorialAlgorithm
    subproblem_algorithm::CombinatorialAlgorithm
end

function solve(
    nli::NonlinearCombinatorialInstance,
    algo::ApproximateNonlinearSolver,
)
    # This technique is valid implemented for maximising. Use Holy traits 
    # to support minimisation?
    @assert nli.combinatorial_structure.objective == Maximise()

    # TODO: what if the budgeted term in the objective doesn't have integer components? 
    # TODO: what about ε?

    # Transform the enumerated nonlinearity as a true function.
    function sum_over_linear(x)
        return sum(
            nli.linear_coefficients[i] for
            i in eachindex(nli.linear_coefficients) if i in x
        )
    end
    function sum_over_nonlinear(x)
        return sum(
            nli.nonlinear_coefficients[i] for
            i in eachindex(nli.nonlinear_coefficients) if i in x
        )
    end
    if nli.nonlinear_function == Square
        nl_func = (x) -> sum_over_linear(x) + (sum_over_nonlinear(x))^2
    elseif nli.nonlinear_function == SquareRoot
        nl_func = (x) -> sum_over_linear(x) + sqrt(sum_over_nonlinear(x))
    else
        error("Nonlinear function not recognised: $(nli.nonlinear_function).")
    end

    # Get an upper bound on the budget.
    max_budget = _upper_bound_budget(nli)::Int

    # Make a linear instance with the linear coefficients 
    # (`nli.combinatorial_structure` does not always have this property).
    li = copy(nli.combinatorial_structure, rewards=nli.linear_coefficients)
    bi = MinimumBudget(
        li,
        _round_coefficients(nli.nonlinear_coefficients, nli),
        max_budget,
    )

    # Compute all interesting budgeted solutions, depending on how it is requested to be done.
    solutions = Dict{Int, Vector}[]
    if nli.all_budgets_at_once
        bbi = copy(bi, compute_all_values=true)
        sols = solve(bbi, nli.linear_algo)::MultipleMinBudgetedSolution
        solutions = sols.solutions
    else
        for budget in 0:max_budget
            bbi = copy(bi, min_budget=budget)
            solutions[budget] = solve(bbi, nli.linear_algo).variables
        end
    end

    # Return the best solution.
    best_sol, _ = _pick_best_solution(solutions, nl_func)
    best_sol_dict = Dict(x => 1.0 for x in best_sol)
    return make_solution(nli.combinatorial_structure, best_sol_dict)
end

function _round_coefficients(x::Vector{Int}, ::NonlinearCombinatorialInstance)
    return x
end

function _round_coefficients(
    x::Vector{T},
    nli::NonlinearCombinatorialInstance,
) where {T <: Real}
    return Int[round(Int, v / nli.ε) for v in x]
end

function _round_coefficients(
    x::Dict{K, Int},
    ::NonlinearCombinatorialInstance,
) where {K}
    return x
end

function _round_coefficients(
    x::Dict{K, T},
    nli::NonlinearCombinatorialInstance,
) where {K, T <: Real}
    return Dict{K, Int}(k => round(Int, v / nli.ε) for (k, v) in x)
end

function _float_coefficients(x::Vector{T}) where {T}
    return Float64.(x)
end

function _float_coefficients(x::Dict{K, T}) where {K, T}
    return Dict{K, Float64}(k => v for (k, v) in x)
end

function _upper_bound_budget(nli::NonlinearCombinatorialInstance)
    # Make a linear instance to maximise the total weight.
    nlw = _float_coefficients(_round_coefficients(nli.nonlinear_coefficients, nli))
    li = copy(nli.combinatorial_structure, rewards=nlw)
    x = solve(li, nli.linear_algo).variables
    return Int(
        sum(
            nlw[i] for
            i in eachindex(nli.nonlinear_coefficients) if i in x
        ),
    )
end

function _pick_best_solution(
    solutions::Dict{Int, Vector{T}},
    nl_func::Function,
) where {T}
    best_solution = Int[]
    best_objective = -Inf
    for (budget, sol) in solutions
        # Ignore infeasible cases.
        # TODO: unify representation of infeasible solutions.
        if length(sol) == 0 || sol == [-1]
            continue
        end

        # Compute the maximum.
        f_x = nl_func(sol)
        if f_x > best_objective
            best_solution = sol
            best_objective = f_x
        end
    end

    return best_solution, best_objective
end
