approximation_term(::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, ::IteratedLagrangianRefinementAlgorithm) where {T, U} = NaN
approximation_ratio(::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, ::IteratedLagrangianRefinementAlgorithm) where {T, U} = 0.5

function solve(i::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, ::IteratedLagrangianRefinementAlgorithm) where {T, U}
    # Approximately solve the following problem:
    #     \max_{x spanning tree} rewards x  s.t.  weights x >= budget
    # This algorithm provides a multiplicative approximation to this problem. If x* is the optimum solution and x~ the one
    # returned by this algorithm,
    #     weights x* >= budget   and   weights x~ >= budget                 (the returned solution is feasible)
    #     rewards x~ >= rewards x* / 2                                      (multiplicative approximation)

    # Based on the same ideas as https://doi.org/10.1007/s10107-009-0307-4

    # If there are too few edges, not much to do.
    if ne(i.instance.graph) <= 2
        return solve(i, LagrangianRefinementAlgorithm())
    end

    # For each pair of edges, force these two edges to be part of the solution and discard all edges with a higher value.
    best_sol = nothing
    best_sol_value = -Inf
    for e1 in edges(i.instance.graph)
        for e2 in edges(i.instance.graph)
            # (e1, e2) must be a pair of distinct edges.
            if (src(e1) == src(e2) && dst(e1) == dst(e2)) || (src(e1) == dst(e2) && src(e1) == dst(e2))
                continue
            end

            # Filter out the edges that have a higher value than any of these two edges. Give a very large reward to them both.
            cutoff = min(i.instance.rewards[e1], i.instance.rewards[e2])
            rewards = filter(kv -> kv[2] < cutoff, i.instance.rewards)
            rewards[e1] = rewards[e2] = prevfloat(Inf)

            graph = SimpleGraph(nv(i.instance.graph))
            for e in keys(rewards)
                add_edge!(graph, e)
            end

            weights = Dict(e => i.weights[e] for e in keys(rewards))

            # No other simplification can be made, unfortunately: all other edges might participate in the optimum solution.
            # (Only exception: e1 and e2 are incident to the same vertex; any edge linking the other extremities of these edges
            # can be removed, but that's only one edge at most.)
            # As e1 and e2 have the best reward (as they are really bumped), they must be in any optimum solution.

            # Solve this subproblem.
            bsti = MinimumBudget(SpanningTreeInstance(graph, rewards), weights, i.min_budget)
            sol = solve(bsti, LagrangianRefinementAlgorithm())

            # This subproblem is infeasible. Maybe it's because the overall problem is infeasible or just because too many
            # edges were removed.
            if length(sol.tree) == 0
                continue
            end

            # Impossible to have a feasible solution with these two edges, probably because of the budget constraint.
            # Due to the direction of the budget constraint (>= budget), it is not possible to check for feasibility
            # before solving an instance.
            if ! (e1 in sol.tree) || ! (e2 in sol.tree)
                continue
            end

            # Only keep the best solution.
            sol_value = _budgeted_spanning_tree_compute_value(i, sol.tree)
            if sol_value > best_sol_value
                # sol's instance is the one used internally for the subproblems.
                best_sol = SimpleBudgetedSpanningTreeSolution(i, sol.tree)
                best_sol_value = sol_value
            end
        end
    end

    if best_sol !== nothing
        return best_sol
    else
        return SimpleBudgetedSpanningTreeSolution(i)
    end
end