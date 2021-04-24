function _budgeted_spanning_tree_compute_weight(i::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, tree::Vector{Edge{T}}) where {T, U}
    if length(tree) == 0
        return 0
    end
    return sum(i.weights[(e in keys(i.weights)) ? e : reverse(e)] for e in tree)
end

function _budgeted_spanning_tree_compute_value(i::SpanningTreeInstance{T}, tree::Vector{Edge{T}}) where {T, U}
    if length(tree) == 0
        return 0
    end
    return sum(i.rewards[(e in keys(i.rewards)) ? e : reverse(e)] for e in tree)
end
function _budgeted_spanning_tree_compute_value(i::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, tree::Vector{Edge{T}}) where {T, U}
    if length(tree) == 0
        return 0
    end
    return sum(i.instance.rewards[(e in keys(i.instance.rewards)) ? e : reverse(e)] for e in tree)
end