function solve(i::SpanningTreeInstance{T, Maximise}, ::DynamicProgramming) where T
    # A dynamic-programming stance on Prim's algorithm.

    # Get an indexed list of *all* edges, sorted by increasing value.
    sorted_edges = Pair{Edge, Float64}[]
    for e in edges(i.graph)
        push!(sorted_edges, e => reward(i, e))
    end
    sort!(sorted_edges, by=(p) -> - p[2])

    # Fill the DP table, considering edges one by one (from the best to the
    # poorest), Prim-like.
    # Index: considering edges up to that index (included).
    V = Vector{Float64}(undef, ne(i.graph))
    S = Vector{Vector{Edge{T}}}(undef, ne(i.graph))

    first_edge = sorted_edges[1][1]
    V[1] = sorted_edges[1][2]
    S[1] = Edge{T}[first_edge]

    # Partition the graph into components, based on the already added edges. 
    # All the nodes with the same component ID are reachable one from the 
    # other: adding an edge within that component would create a loop.
    # Use -1 for nodes that are currently in no component.
    node_done = [-1 for _ in 1:nv(i.graph)]
    node_done[src(first_edge)] = 1
    node_done[dst(first_edge)] = 1

    for i in 2:ne(i.graph)
        # Can edges_sorted[i] be taken?
        edge = sorted_edges[i][1]
        i_would_create_loop = node_done[src(edge)] == node_done[dst(edge)]

        if i_would_create_loop # Don't take i.
            V[i] = V[i - 1]
            S[i] = S[i - 1]
        else # Take i.
            V[i] = V[i - 1] + sorted_edges[i][2]
            S[i] = copy(S[i - 1])
            push!(S[i], edge)

            if node_done[src(edge)] == -1
                # Put the source (no currently assigned component) into the 
                # same component as the destination.
                node_done[src(edge)] = node_done[dst(edge)]
            elseif node_done[dst(edge)] == -1
                # Put the destination (no currently assigned component) into 
                # the same component as the source.
                node_done[dst(edge)] = node_done[src(edge)]
            else
                # Merge components so that they have the lowest component ID of 
                # the two components.
                if node_done[dst(edge)] < node_done[src(edge)]
                    node_done[node_done .== node_done[src(edge)]] = node_done[dst(edge)]
                else
                    node_done[node_done .== node_done[dst(edge)]] = node_done[src(edge)]
                end
            end
        end
    end

    return SpanningTreeSolution(i, S[end])
end