function _budgeted_spanning_tree_compute_value(i::Union{SpanningTreeInstance{T}, BudgetedSpanningTreeInstance{T, U}}, tree::Vector{Edge{T}}) where {T, U}
    return sum(i.rewards[(e in keys(i.rewards)) ? e : reverse(e)] for e in tree)
end
