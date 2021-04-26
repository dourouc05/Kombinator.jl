function _extract_lp_solution_sub(graph, x)
    # Same as for SpanningTree, but for a natively directed graph (no check 
    # for reverse edges).
    solution = Edge{Int}[]
    for e in edges(graph)
        if JuMP.value(x[e]) >= 0.5
            push!(solution, e)
        end
    end
    return solution
end

function _extract_lp_solution(i::ElementaryPathInstance{Int, Maximise}, x)
    return _extract_lp_solution_sub(i.graph, x)
end

function _extract_lp_solution(i::MinimumBudget{ElementaryPathInstance{Int, Maximise}, Int}, x)
    return _extract_lp_solution_sub(i.instance.graph, x)
end
