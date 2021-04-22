approximation_term(i::BudgetedSpanningTreeInstance{T}, ::LagrangianRefinementAlgorithm) where T = maximum(values(i.rewards))
approximation_ratio(::BudgetedSpanningTreeInstance{T}, ::LagrangianRefinementAlgorithm) where T = NaN

function solve(i::BudgetedSpanningTreeInstance{T, U}, ::LagrangianRefinementAlgorithm;
               ε::Float64=1.0e-3, ζ⁻::Float64=0.2, ζ⁺::Float64=5.0, stalling⁻::Float64=1.0e-5) where {T, U}
    # Approximately solve the following problem:
    #     \max_{x spanning tree} rewards x  s.t.  weights x >= budget
    # This algorithm provides an additive approximation to this problem. If x* is the optimum solution and x~ the one
    # returned by this algorithm,
    #     weights x* >= budget   and   weights x~ >= budget                 (the returned solution is feasible)
    #     rewards x~ >= rewards x* - \max{e edge} reward[e]                 (additive approximation)

    # Check assumptions.
    if ζ⁻ >= 1.0
        error("ζ⁻ must be strictly less than 1.0: the dual multiplier λ is multiplied by ζ⁻ to reach an infeasible solution by less penalising the budget constraint.")
    end
    if ζ⁺ <= 1.0
        error("ζ⁺ must be strictly greater than 1.0: the dual multiplier λ is multiplied by ζ⁺ to reach a feasible solution by penalising more the budget constraint.")
    end

    # Ensure the problem is feasible by only considering the budget constraint.
    feasible_rewards = Dict{Edge{T}, Float64}(e => i.weights[e] for e in keys(i.rewards))
    feasible_instance = SpanningTreeInstance(i.graph, feasible_rewards)
    feasible_solution = st_prim(feasible_instance)
    if _budgeted_spanning_tree_compute_value(feasible_instance, feasible_solution.tree) < i.budget
        # By maximising the left-hand side of the budget constraint, impossible to reach the target budget. No solution!
        return SimpleBudgetedSpanningTreeSolution(i)
    end

    # Solve the Lagrangian relaxation to optimality.
    lagrangian = _st_prim_budgeted_lagrangian_search(i, ε)
    λ0, v0, st0 = lagrangian.λ, lagrangian.value, lagrangian.tree
    λmax = lagrangian.λmax
    b0 = _budgeted_spanning_tree_compute_weight(i, st0) # Budget consumption of this first solution.

    # If already respecting the budget constraint exactly, done!
    if b0 == i.budget
        return SimpleBudgetedSpanningTreeSolution(i, st0)
    end

    # Find two solutions: one above the budget x⁺ (i.e. respecting the constraint), the other not x⁻.
    x⁺, x⁻ = nothing, nothing

    λi = λ0
    if b0 > i.budget
        x⁺ = st0
        @assert _budgeted_spanning_tree_compute_weight(i, x⁺) > i.budget

        stalling = false
        while true
            # Penalise less the constraint: it should no more be satisfied.
            λi *= ζ⁻
            _, sti = _st_prim_budgeted_lagrangian(i, λi)
            if _budgeted_spanning_tree_compute_weight(i, sti) < i.budget
                x⁻ = sti
                break
            end

            # Is the process stalling?
            if λi <= stalling⁻
                stalling = true
                break
            end
        end

        # Specific handling of stallings.
        if stalling # First test: don't penalise the constraint at all.
            _, sti = _st_prim_budgeted_lagrangian(i, 0.0)
            new_budget = _budgeted_spanning_tree_compute_weight(i, sti)
            if new_budget < i.budget
                x⁻ = sti
                stalling = false
            end
        end

        if stalling # Second test: minimise the left-hand side of the budget constraint, in hope of finding a feasible solution.
            # This process is highly similar to the computation of feasible_solution, but with a reverse objective function.
            infeasible_rewards = Dict{Edge{T}, Float64}(e => - i.weights[e] for e in keys(i.weights))
            infeasible_solution = st_prim(SpanningTreeInstance(i.graph, infeasible_rewards)).tree

            if _budgeted_spanning_tree_compute_weight(i, infeasible_solution) < i.budget
                x⁻ = infeasible_solution
                stalling = false
            end
        end

        if stalling # Third: decide there is no solution strictly below the budget. No refinement is possible.
            # As x⁺ is feasible, return it.
            return SimpleBudgetedSpanningTreeSolution(i, x⁺)
        end
    else
        x⁻ = st0
        @assert _budgeted_spanning_tree_compute_weight(i, x⁻) < i.budget

        while true
            # Penalise more the constraint: it should become satisfied at some point.
            λi *= ζ⁺
            _, sti = _st_prim_budgeted_lagrangian(i, λi)
            if _budgeted_spanning_tree_compute_weight(i, sti) >= i.budget
                x⁺ = sti
                break
            end

            # Is the process stalling? If so, reuse feasible_solution, which is guaranteed to be feasible.
            if λi >= λmax
                x⁺ = feasible_solution.tree
                break
            end
        end
    end

    # Normalise the solutions: the input graph is undirected, the direction of the edges is not important.
    # In case one solution has the edge v -> w and the other one w -> v, make them equal. s
    sort_edge(e::Edge{T}) where T = (src(e) < dst(e)) ? e : reverse(e)
    x⁺ = [sort_edge(e) for e in x⁺]
    x⁻ = [sort_edge(e) for e in x⁻]

    # Iterative refinement. Stop as soon as there is a difference of at most one edge between the two solutions.
    while _solution_symmetric_difference_size(x⁺, x⁻) > 2
        # Enforce the loop invariant.
        @assert x⁺ !== nothing
        @assert x⁻ !== nothing
        @assert _budgeted_spanning_tree_compute_weight(i, x⁺) >= i.budget # Feasible.
        @assert _budgeted_spanning_tree_compute_weight(i, x⁻) < i.budget # Infeasible.

        # Switch elements from one solution to another.
        only_in_x⁺, only_in_x⁻ = _solution_symmetric_difference(x⁺, x⁻)
        e1 = first(only_in_x⁺)
        e2 = first(only_in_x⁻)

        # Create the new solution (don't erase x⁺ nor x⁻: only one of the two will be forgotten, the other will be kept).
        new_x = copy(x⁺)
        filter!(e -> e != e1, new_x)
        push!(new_x, e2)

        # Replace one of the two solutions, depending on whether this solution is feasible (x⁺) or not (x⁻).
        if _budgeted_spanning_tree_compute_weight(i, new_x) >= i.budget
            x⁺ = new_x
        else
            x⁻ = new_x
        end
    end

    # Done!
    return SimpleBudgetedSpanningTreeSolution(i, x⁺)
end