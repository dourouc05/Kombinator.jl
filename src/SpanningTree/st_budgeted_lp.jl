function formulation(
    i::MinimumBudget{SpanningTreeInstance{Int, Maximise}, Int},
    ::DefaultLinearFormulation;
    solver=nothing,
)
    m, x = formulation(i.instance, DefaultLinearFormulation(), solver=solver)
    @constraint(
        m,
        c,
        sum((x[e] + x[reverse(e)]) * i.weights[e] for e in keys(i.weights)) >=
        0
    )
    return m, x, c
end

function solve(
    i::MinimumBudget{SpanningTreeInstance{Int, Maximise}, Int},
    ::DefaultLinearFormulation;
    solver=nothing,
)
    model, x, c = formulation(i, DefaultLinearFormulation(), solver=solver)

    budgets = if i.compute_all_values == false
        [i.min_budget]
    else
        0:(i.min_budget)
    end

    V = Dict{Tuple{Int, Int}, Float64}()
    S = Dict{Int, Vector{Edge{Int}}}()

    for budget in budgets
        set_normalized_rhs(c, budget)
        optimize!(model)

        if termination_status(model) == MOI.OPTIMAL
            V[budget, dimension(i)] = objective_value(model)
            S[budget] = _extract_lp_solution(i, x)
        else
            V[budget, dimension(i)] = -Inf
            S[budget] = Int[-1]
        end
    end

    return BudgetedSpanningTreeDynamicProgrammingSolution(
        i,
        S[i.min_budget],
        V,
        S,
    )
end
