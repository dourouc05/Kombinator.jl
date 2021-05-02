function solve(
    i::SpanningTreeInstance{T, Maximise},
    ::DynamicProgramming,
) where {T}
    # A dynamic-programming stance on Prim's algorithm.

    # Get an indexed list of *all* edges, sorted by increasing value.
    sorted_edges = Pair{Edge, Float64}[]
    for e in edges(i.graph)
        push!(sorted_edges, e => reward(i, e))
    end
    sort!(sorted_edges, by=(p) -> -p[2])

    # Fill the DP table, considering edges one by one (from the best to the
    # poorest), Prim-like.
    # Index: considering edges up to that index (included).
    V = Vector{Float64}(undef, ne(i.graph))
    S = Vector{Vector{Edge{T}}}(undef, ne(i.graph))

    first_edge, first_edge_value = sorted_edges[1]
    V[1] = first_edge_value
    S[1] = Edge{T}[first_edge]

    ld = LoopDetector(nv(i.graph))
    visit_edge(ld, src(first_edge), dst(first_edge))

    # Dynamic part.
    for i in 2:ne(i.graph)
        # Can edges_sorted[i] be taken?
        edge, edge_value = sorted_edges[i]

        if edge_would_create_loop(ld, src(edge), dst(edge)) # Don't take i.
            V[i] = V[i - 1]
            S[i] = S[i - 1]
        else # Take i.
            V[i] = V[i - 1] + edge_value
            S[i] = copy(S[i - 1])
            push!(S[i], edge)

            visit_edge(ld, src(edge), dst(edge))
        end
    end

    return SpanningTreeSolution(i, S[end])
end
