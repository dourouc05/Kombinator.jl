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

# How to ensure that adding an edge will not create loops? 
# Partition the graph into components, based on the already added edges. 
# All the nodes with the same component ID are reachable one from the 
# other: adding an edge within that component would create a loop.
# Use -1 for nodes that are currently in no component.
mutable struct LoopDetector
    node_done::Vector{Int}
    next_value::Int

    function LoopDetector(n_vertices::Int)
        return new([-1 for _ in 1:n_vertices], 1)
    end
end

function visit_edge(ld::LoopDetector, e::Edge{Int})
    return visit_edge(ld, src(e), dst(e))
end

function visit_edge(ld::LoopDetector, s::Int, t::Int)
    if ld.node_done[s] == -1
        # Put the source (no currently assigned component) into the 
        # same component as the destination.
        if ld.node_done[t] == -1
            ld.node_done[s] = ld.next_value
            ld.node_done[t] = ld.next_value
            ld.next_value += 1
        else
            ld.node_done[s] = ld.node_done[t]
        end
    elseif ld.node_done[t] == -1
        # Put the destination (no currently assigned component) into 
        # the same component as the source.
        # No need to check if s already has a component, this is done in 
        # the first case.
        ld.node_done[t] = ld.node_done[s]
    else
        # Merge components so that they have the lowest component ID of 
        # the two components.
        if ld.node_done[t] < ld.node_done[s]
            ld.node_done[ld.node_done .== ld.node_done[s]] .= ld.node_done[t]
        else
            ld.node_done[ld.node_done .== ld.node_done[t]] .= ld.node_done[s]
        end
    end
    return 
end

function edge_would_create_loop(ld::LoopDetector, e::Edge{Int})
    return edge_would_create_loop(ld, src(e), dst(e))
end

function edge_would_create_loop(ld::LoopDetector, s::Int, t::Int)
    # One of the ends of the edge has not yet been visited: impossible to have 
    # a loop.
    if ld.node_done[s] == -1 || ld.node_done[t] == -1
        return false
    end

    # Both ends have been visited: are they in the same component?
    return ld.node_done[s] == ld.node_done[t]
end

function reset!(ld::LoopDetector)
    ld.node_done .= -1
    ld.next_value = 1
    return
end

function Base.copy!(dst::LoopDetector, src::LoopDetector)
    dst.node_done .= src.node_done
    dst.next_value = src.next_value
    return
end
