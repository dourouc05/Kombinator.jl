function _extract_lp_solution_sub(graph, x)
    solution = Edge{Int}[]
    for e in edges(graph)
        if JuMP.value(x[e]) >= 0.5
            push!(solution, e)
        elseif JuMP.value(x[reverse(e)]) >= 0.5
            push!(solution, reverse(e))
        end
    end
    return solution
end

function _extract_lp_solution(i::SpanningTreeInstance{Int, Maximise}, x)
    return _extract_lp_solution_sub(i.graph, x)
end

function _extract_lp_solution(
    i::MinimumBudget{SpanningTreeInstance{Int, Maximise}, Int},
    x,
)
    return _extract_lp_solution_sub(i.instance.graph, x)
end
