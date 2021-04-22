function _budgeted_um_lp_model(i::MinimumBudget{UniformMatroidInstance{Float64, Maximise}, Int}, solver)
    model = Model(solver)
    @variable(model, x[1:length(values(i))], Bin)
    @objective(model, Max, dot(x, values(i)))
    @constraint(model, sum(x) <= m(i))
    @constraint(model, c, dot(x, weights(i)) >= 0)

    set_silent(model)

    return model, x, c
end

function solve(i::MinimumBudget{UniformMatroidInstance{Float64, Maximise}, Int}, ::DefaultLinearFormulation; solver=nothing)
    model, x, c = _budgeted_msets_lp_sub(i, solver)

    budgets = if i.compute_all_values == false
            [i.min_budget]
        else
            0:i.min_budget
        end
        
    V = Array{Float64, 3}(undef, m(i.instance), dimension(i.instance) + 1, i.min_budget + 1)
    S = Dict{Tuple{Int, Int, Int}, Vector{Int}}() 
    
    for budget in budgets
        set_normalized_rhs(c, budget)
        optimize!(model)

        if termination_status(model) == MOI.OPTIMAL
            sol = findall(JuMP.value.(x) .>= 0.5)
            V[m(i), 0 + 1, budget + 1] = objective_value(model)
            S[m(i), 0, budget] = sol
        else
            V[m(i), 0 + 1, budget + 1] = -Inf
            S[m(i), 0, budget] = Int[-1]
        end
    end

    return BudgetedUniformMatroidSolution(i, S[m(i), 0, maximum(budgets)], V, S)
end
