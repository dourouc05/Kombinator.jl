function solve(i::MinimumBudget{ElementaryPathInstance{T}, T}, ::DynamicProgramming) where T 
    return solve(i, BellmanFordAlgorithm())
end

function solve(i::MinimumBudget{ElementaryPathInstance{T}, T}, ::BellmanFordAlgorithm) where T
    V = Dict{Tuple{T, Int}, Float64}()
    S = Dict{Tuple{T, Int}, Vector{Edge{T}}}()

    # Initialise. For β = 0, this is exactly Bellman-Ford algorithm. 
    # Otherwise, use the same initialisation as Bellman-Ford.
    β0 = solve(i.instance, BellmanFordAlgorithm())
    for v in vertices(i.instance.graph)
        S[v, 0] = β0.solutions[v]
        V[v, 0] = length(S[v, 0]) == 0 ? 0 : sum(i.instance.costs[e] for e in S[v, 0])
    end

    for β in 1:i.min_budget
        for v in vertices(i.instance.graph)
            V[v, β] = -Inf
            S[v, β] = Edge{T}[]
        end

        V[i.instance.src, β] = 0.0
    end

    # Dynamic part.
    for β in 1:i.min_budget
        # Loop needed when at least a weight is equal to zero. TODO: remove it when all weights are nonzero?
        while true
            changed = false

            for v in vertices(i.instance.graph)
                for w in inneighbors(i.instance.graph, v)
                    # Compute the remaining part of the budget still to use.
                    remaining_budget = max(0, β - i.weights[Edge(w, v)])

                    # If the explored subproblem has no solution, skip it.
                    if V[w, remaining_budget] == -Inf
                        continue
                    end

                    # If using the solution to the currently explored subproblem would
                    # lead to a cycle, skip it.
                    if any(src(e) == v for e in S[w, remaining_budget])
                        continue
                    end

                    # Compute the amount of budget already used by the solution to the currently explored subproblem.
                    used_budget = 0
                    if length(S[w, remaining_budget]) > 0
                        used_budget = sum(i.weights[e] for e in S[w, remaining_budget])
                    end
                    if used_budget < remaining_budget
                        continue
                    end

                    # Compute the maximum: is passing through w advantageous?
                    if V[w, remaining_budget] + i.instance.costs[Edge(w, v)] > V[v, β] && used_budget >= remaining_budget
                        changed = true

                        V[v, β] = V[w, remaining_budget] + i.instance.costs[Edge(w, v)]
                        S[v, β] = vcat(S[w, remaining_budget], Edge(w, v))
                    end
                end
            end

            if ! changed
              break
            end
        end
    end

    return BudgetedElementaryPathSolution(i, S[i.instance.dst, i.min_budget], V, S)
end