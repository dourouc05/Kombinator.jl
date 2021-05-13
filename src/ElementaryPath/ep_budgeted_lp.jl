function formulation(
    i::MinimumBudget{ElementaryPathInstance{Int, Maximise}, Int},
    f::DefaultLinearFormulation
)
    m, x = formulation(i.instance, f)
    @constraint(m, c, sum(x[e] * i.weights[e] for e in keys(i.weights)) >= 0)
    return m, x, c
end

function solve(
    i::MinimumBudget{ElementaryPathInstance{Int, Maximise}, Int},
    f::DefaultLinearFormulation
)
    model, x, c = formulation(i, f)

    budgets = if i.compute_all_values == false
        [i.min_budget]
    else
        0:(i.min_budget)
    end

    S = Dict{Int, Vector{Edge{Int}}}()

    for budget in budgets
        set_normalized_rhs(c, budget)
        optimize!(model)

        if termination_status(model) == MOI.OPTIMAL
            S[budget] = _extract_lp_solution(i, x)
        else
            S[budget] = Edge{Int}[]
        end
    end

    return BudgetedElementaryPathSolution(i, S[i.min_budget], S)
end
