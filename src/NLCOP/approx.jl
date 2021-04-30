struct ApproximateNonlinearSolver <: NonlinearCombinatorialAlgorithm
    subproblem_algorithm::CombinatorialAlgorithm
end

function solve(nli::NonlinearCombinatorialInstance, algo::ApproximateNonlinearSolver)
    # This technique is valid implemented for maximising. Use Holy traits 
    # to support minimisation?
    @assert nli.combinatorial_structure.objective == Maximise()

    # Transform the enumerated nonlinearity as a true function.
    if nli.nonlinear_function == Square
        nl_func = (x) -> sum(nli.linear_coefficients[i] * x[i] for i in eachindex(nli.linear_coefficients)) + (sum(nli.nonlinear_coefficients[i] * x[i] for i in eachindex(nli.nonlinear_coefficients))) ^2
    elseif nli.nonlinear_function == SquareRoot
        nl_func = (x) -> sum(nli.linear_coefficients[i] * x[i] for i in eachindex(nli.linear_coefficients)) + sqrt(sum(nli.nonlinear_coefficients[i] * x[i] for i in eachindex(nli.nonlinear_coefficients)))
    else
        error("Nonlinear function not recognised: $(nli.nonlinear_function).")
    end
    # TODO: this function should rather take a CombinatorialSolution as argument, but it requires more details about the underlying data structures.

    # Get an upper bound on the budget.
    max_budget = _upper_bound_budget(nli)::Int

    # Make a linear instance with the linear coefficients 
    # (`nli.combinatorial_structure` does not always have this property).
    li = copy(nli.combinatorial_structure, values=nli.linear_coefficients)
    bi = MinimumBudget(li, nli.nonlinear_coefficients, max_budget)

    # Compute all interesting budgeted solutions, depending on how it is requested to be done.
    solutions = Pair{Int, CombinatorialSolution}[]
    if nli.all_budgets_at_once
        bbi = copy(bi, compute_all_values=true)
        solutions = solve(bbi, nli.linear_algo)::Vector{Pair{Int, CombinatorialSolution}}
    else
        for budget in 0:max_budget
            bbi = copy(bi, min_budget=budget)
            push!(solutions, (budget, solve(bbi, nli.linear_algo)))
        end
    end

    # Return the best solution.
    best_sol, _ = _pick_best_solution(solutions, nl_func)
    return make_solution(nli.combinatorial_structure, best_sol)
end

function _upper_bound_budget(nli::NonlinearCombinatorialInstance)
    # Make a linear instance to maximise the total weight.
    li = copy(nli.combinatorial_structure, rewards=nli.nonlinear_term)
    x = solve(li, nli.linear_algo)
    return sum(nli.nonlinear_coefficients[i] * x[i] for i in eachindex(nli.nonlinear_coefficients) if x[i] > 0.5)
end

function _pick_best_solution(solutions::Vector{Pair{Int, CombinatorialSolution}}, nl_func::Function)
    best_solution = Int[]
    best_objective = -Inf
    for (budget, sol) in solutions
        # Ignore infeasible cases.
        # TODO: unify representation of infeasible solutions.
        if length(sol) == 0 || sol == [-1]
            continue
        end

        # Compute the maximum.
        f_x = nl_func(sol, budget)
        if f_x > best_objective
            best_solution = sol
            best_objective = f_x
        end
    end

    return best_solution, best_objective
end
