function solve(
    i::SpanningTreeInstance{T, Maximise},
    ::GreedyAlgorithm,
) where {T}
    return solve(i, PrimAlgorithm())
end

function solve(i::SpanningTreeInstance{T, Maximise}, ::PrimAlgorithm) where {T}
    remaining_edges = PriorityQueue{Edge{T}, Float64}(Base.Reverse) # Easy retrieval of highest-reward edge.
    node_done = falses(nv(i.graph))

    # Helper methods.
    function edges_around(g, v)
        return (
            (v < x) ? edgetype(g)(v, x) : edgetype(g)(x, v) for
            x in neighbors(g, v)
        )
    end

    # Initialise with the source node (arbitrarily, the first one).
    first_node = first(vertices(i.graph))
    node_done[first_node] = true
    for e in edges_around(i.graph, first_node)
        enqueue!(remaining_edges, e => reward(i, e))
    end

    # Build the spanning tree.
    solution = Edge{T}[]
    while length(solution) < nv(i.graph) - 1 # While there is still an edge to add...
        # Find an admissible edge, starting with those of minimum reward.
        e = nothing
        new_node = nothing
        while isnothing(new_node)
            e = dequeue!(remaining_edges)

            if node_done[src(e)] && !node_done[dst(e)]
                new_node = dst(e)
            end
            if !node_done[src(e)] && node_done[dst(e)]
                new_node = src(e)
            end
        end

        @assert !node_done[new_node]

        # Use this edge in the solution.
        push!(solution, e)
        node_done[new_node] = true

        # Prepare to use the neighbours of this new node, but skip nodes already done.
        for ϵ in edges_around(i.graph, new_node)
            if haskey(remaining_edges, ϵ)
                # No need to update the priority, the edge still has the same reward.
                continue
            end

            # Ensure the edge links a node already in the tree and another one outside.
            if (node_done[src(ϵ)] && !node_done[dst(ϵ)]) ||
               (!node_done[src(ϵ)] && node_done[dst(ϵ)])
                enqueue!(remaining_edges, ϵ => reward(i, ϵ))
            end
        end
    end

    return SpanningTreeSolution(i, solution)
end
