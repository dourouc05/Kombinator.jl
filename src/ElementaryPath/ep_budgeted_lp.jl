function formulation(i::MinimumBudget{ElementaryPathInstance{Int, Maximise}, Int}, ::DefaultLinearFormulation; solver=nothing)
    m, x = formulation(i.instance, DefaultLinearFormulation(), solver=solver)
    @constraint(m, c, sum(x[e] * i.weights[e] for e in keys(i.weights)) >= 0)
    return m, x, c
end

function solve(i::MinimumBudget{ElementaryPathInstance{Int, Maximise}, Int}, ::DefaultLinearFormulation; solver=nothing)
    model, x, c = formulation(i, DefaultLinearFormulation(), solver=solver)

    budgets = if i.compute_all_values == false
            [i.min_budget]
        else
            0:i.min_budget
        end
        
    V = Dict{Tuple{Int, Int}, Float64}()
    S = Dict{Tuple{Int, Int}, Vector{Edge{Int}}}() 
    
    for budget in budgets
        set_normalized_rhs(c, budget)
        optimize!(model)

        if termination_status(model) == MOI.OPTIMAL
            V[dimension(i) + 1, budget + 1] = objective_value(model)
            S[dimension(i) + 1, budget + 1] = _extract_lp_solution(i, x)
        else
            V[dimension(i) + 1, budget + 1] = -Inf
            S[dimension(i) + 1, budget + 1] = Int[-1]
        end
    end

    return BudgetedElementaryPathSolution(i, S[dimension(i) + 1, i.min_budget + 1], V, S)
end
