approximation_term(::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, ::LagrangianAlgorithm) where {T, U} = NaN
approximation_ratio(::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, ::LagrangianAlgorithm) where {T, U} = NaN

function _budgeted_spanning_tree_compute_weight(i::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, tree::Vector{Edge{T}}) where {T, U}
    return sum(i.weights[(e in keys(i.weights)) ? e : reverse(e)] for e in tree)
end

function _budgeted_spanning_tree_compute_value(i::SpanningTreeInstance{T}, tree::Vector{Edge{T}}) where {T, U}
    return sum(i.rewards[(e in keys(i.rewards)) ? e : reverse(e)] for e in tree)
end
function _budgeted_spanning_tree_compute_value(i::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, tree::Vector{Edge{T}}) where {T, U}
    return sum(i.instance.rewards[(e in keys(i.instance.rewards)) ? e : reverse(e)] for e in tree)
end

function _st_prim_budgeted_lagrangian(i::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, λ::Float64) where {T, U}
    # Solve the subproblem for one value of the dual multiplier λ:
    #     l(λ) = \max_{x spanning tree} (rewards + λ weights) x - λ budget.
    sti_rewards = Dict{Edge{T}, Float64}(e => i.instance.rewards[e] + λ * i.weights[e] for e in keys(i.instance.rewards))
    sti = SpanningTreeInstance(i.instance.graph, sti_rewards)
    sti_sol = solve(sti, PrimAlgorithm())
    return _budgeted_spanning_tree_compute_value(sti, sti_sol.tree) - λ * i.min_budget, sti_sol.tree
end

function solve(i::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, ::LagrangianAlgorithm; ε::Float64) where {T, U}
    # Approximately solve the problem \min_{l ≥ 0} l(λ), where
    #     l(λ) = \max_{x spanning tree} (rewards + λ weights) x - λ budget.
    # This problem is the Lagrangian dual of the budgeted maximum spanning-tree problem:
    #     \max_{x spanning tree} rewards x  s.t.  weights x >= budget.
    # This algorithm provides no guarantee on the optimality of the solution.

    # Initial set of values for λ. The optimum is guaranteed to be contained in this interval.
    weights_norm_inf = maximum(values(i.weights)) # Maximum weight.
    m = nv(i.instance.graph) - 1 # Maximum number of items in a solution. Easy to compute for a spanning tree!
    λmax = Float64(weights_norm_inf * m + 1)

    λlow = 0.0
    λhigh = λmax

    # Perform a golden-ratio search.
    while (λhigh - λlow) > ε
        λmidlow = λhigh - (λhigh - λlow) / MathConstants.φ
        λmidhigh = λlow + (λhigh - λlow) / MathConstants.φ
        vmidlow, _ = _st_prim_budgeted_lagrangian(i, λmidlow)
        vmidhigh, _ = _st_prim_budgeted_lagrangian(i, λmidhigh)

        if vmidlow < vmidhigh
            λhigh = λmidhigh
            vhigh = vmidhigh
        else
            λlow = λmidlow
            vlow = vmidlow
        end
    end

    vlow, stlow = _st_prim_budgeted_lagrangian(i, λlow)
    vhigh, sthigh = _st_prim_budgeted_lagrangian(i, λhigh)
    if vlow < vhigh
        return BudgetedSpanningTreeLagrangianSolution(i, stlow, λlow, vlow, λmax)
    else
        return BudgetedSpanningTreeLagrangianSolution(i, sthigh, λhigh, vhigh, λmax)
    end
end
