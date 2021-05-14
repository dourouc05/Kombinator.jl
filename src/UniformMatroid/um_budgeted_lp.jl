function formulation(
    i::MinimumBudget{UniformMatroidInstance{Float64, Maximise}, Int},
    f::DefaultLinearFormulation
)
    m, x = formulation(i.instance, f)
    @constraint(m, c, sum(x[j] * i.weights[j] for j in 1:dimension(i)) >= 0)
    return m, x, c
end

function solve(
    i::MinimumBudget{UniformMatroidInstance{Float64, Maximise}, Int},
    f::DefaultLinearFormulation
)
    model, x, c = formulation(i, f)

    budgets = if i.compute_all_values == false
        [i.min_budget]
    else
        0:(i.min_budget)
    end

    V = Array{Float64, 3}(
        undef,
        i.instance.m,
        dimension(i) + 1,
        i.min_budget + 1,
    )
    S = Dict{Int, Vector{Int}}()

    for budget in budgets
        set_normalized_rhs(c, budget)
        optimize!(model)

        if termination_status(model) == MOI.OPTIMAL
            sol = findall(JuMP.value.(x) .>= 0.5)
            V[i.instance.m, 0 + 1, budget + 1] = objective_value(model)
            S[budget] = sol
        else
            V[i.instance.m, 0 + 1, budget + 1] = -Inf
            S[budget] = Int[-1]
        end
    end

    return MinBudgetedUniformMatroidSolution(i, S[maximum(budgets)], S)
end
