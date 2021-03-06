function solve(
    instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U},
    ::DynamicProgramming,
) where {T, U}
    # A dynamic-programming stance on Prim's algorithm.

    # Base case: one edge, the solution is either to take it or not based 
    # on the weight.
    if ne(instance.instance.graph) == 1
        e = collect(edges(instance.instance.graph))[1]
        v = instance.weights[e]
        w = reward(instance.instance, e)

        S = Dict{Int, Vector{Edge{T}}}(β => ifelse(w < β, Edge{T}[], [e]) for β in 0:(instance.min_budget))

        return BudgetedSpanningTreeDynamicProgrammingSolution(
            instance,
            S[instance.min_budget],
            S,
        )
    end

    # Get an indexed list of *all* edges, sorted by increasing value.
    sorted_edges = Tuple{Edge, Float64, Int}[]
    for e in edges(instance.instance.graph)
        push!(
            sorted_edges,
            (e, reward(instance.instance, e), instance.weights[e]),
        )
    end
    sort!(sorted_edges, by=(p) -> -p[2])

    # Fill the DP table, considering edges one by one (from the best to the
    # poorest), Prim-like.
    # Index: 
    # - min budget, starting at 0
    # - considering edges up to that index (included), starting at 1
    V = Dict{Tuple{T, Int}, Float64}()
    S = Dict{Tuple{T, Int}, Vector{Edge{T}}}()
    LD = Dict{Tuple{T, Int}, LoopDetector}()

    for β in 0:(instance.min_budget)
        for v in 1:ne(instance.instance.graph)
            LD[β, v] = LoopDetector(nv(instance.instance.graph))
        end
    end

    first_edge, first_edge_value, first_edge_weight = sorted_edges[1]
    V[0, 1] = first_edge_value
    S[0, 1] = Edge{T}[first_edge]
    visit_edge(LD[0, 1], src(first_edge), dst(first_edge))

    # Initialisation for a zero min-budget (i.e. no constraint).
    for i in 2:ne(instance.instance.graph)
        # Can edges_sorted[i] be taken?
        edge, edge_value, edge_weight = sorted_edges[i]

        if edge_would_create_loop(LD[0, i - 1], src(edge), dst(edge)) # Don't take i.
            V[0, i] = V[0, i - 1]
            S[0, i] = S[0, i - 1]
            copy!(LD[0, i], LD[0, i - 1])
        else # Take i.
            V[0, i] = V[0, i - 1] + edge_value
            S[0, i] = copy(S[0, i - 1])
            push!(S[0, i], edge)

            copy!(LD[0, i], LD[0, i - 1])
            visit_edge(LD[0, i], src(edge), dst(edge))
        end
    end

    # Dynamic part.
    for β in 1:(instance.min_budget)
        # First edge (base case).
        if first_edge_weight >= β
            # The first edge is allowable on its own: take it.
            V[β, 1] = V[0, 1]
            S[β, 1] = S[0, 1]

            visit_edge(LD[β, 1], src(first_edge), dst(first_edge))
        else
            # The first edge is not allowable on its own, it does not have 
            # a sufficient weight.
            V[β, 1] = -1
            S[β, 1] = Edge{T}[]
        end

        # Other edges (recursive cases).
        for i in 2:ne(instance.instance.graph)
            # Can edges_sorted[i] be taken?
            edge, edge_value, edge_weight = sorted_edges[i]

            remaining_budget = β - edge_weight
            if remaining_budget < 0
                remaining_budget = 0
            end

            if V[remaining_budget, i - 1] == -1 || length(S[remaining_budget, i - 1]) == 0
                # Are the previous solutions infeasible (recursive call)? If so, 
                # don't consider using it.
                V[β, i] = V[β, i - 1]
                S[β, i] = S[β, i - 1]
            elseif edge_would_create_loop(LD[remaining_budget, i - 1], edge)
                # Don't take i with that previous solution, it would create a 
                # loop.
                # Rather, try to build solutions without one of the ends of i, 
                # to ensure there will be no loop when combining. Use the 
                # remaining budget 
                g_up_to_i = copy(instance.instance.graph)
                for j in i:ne(instance.instance.graph)
                    rem_edge!(g_up_to_i, sorted_edges[j][1])
                end

                g_no_src = copy(g_up_to_i)
                rem_vertex!(g_no_src, src(edge)) # Changes indices!
                @assert nv(g_no_src) < nv(g_up_to_i)
                @assert ne(g_no_src) < ne(g_up_to_i)
                map_index = (idx) -> ifelse(idx < src(edge), idx, idx - 1)
                map_edge = (e) -> Edge(map_index(src(e)), map_index(dst(e)))
                unmap_index = (idx) -> ifelse(idx < src(edge), idx, idx + 1)
                unmap_edge =
                    (e) -> Edge(unmap_index(src(e)), unmap_index(dst(e)))
                r_no_src = Dict(
                    filter(map(map_edge, collect(keys(instance.instance.rewards))) .=> values(instance.instance.rewards)) do r
                        r[1] ∈ edges(g_no_src)
                    end
                )
                w_no_src = Dict(
                    filter(map(map_edge, collect(keys(instance.weights))) .=> values(instance.weights)) do r
                        r[1] ∈ edges(g_no_src)
                    end
                )
                i_no_src = MinimumBudget(
                    SpanningTreeInstance(g_no_src, r_no_src),
                    w_no_src,
                    remaining_budget,
                )
                s_no_src = solve(i_no_src, DynamicProgramming())
                t_no_src = Edge{T}[unmap_edge(e) for e in s_no_src.variables]
                v_no_src =
                    _budgeted_spanning_tree_compute_value(instance, t_no_src)

                g_no_dst = copy(g_up_to_i)
                rem_vertex!(g_no_dst, dst(edge)) # Changes indices!
                @assert nv(g_no_dst) < nv(g_up_to_i)
                @assert ne(g_no_dst) < ne(g_up_to_i)
                map_index = (idx) -> ifelse(idx < dst(edge), idx, idx - 1)
                map_edge = (e) -> Edge(map_index(src(e)), map_index(dst(e)))
                unmap_index = (idx) -> ifelse(idx < dst(edge), idx, idx + 1)
                unmap_edge =
                    (e) -> Edge(unmap_index(src(e)), unmap_index(dst(e)))
                r_no_dst = Dict(
                    filter(map(map_edge, collect(keys(instance.instance.rewards))) .=> values(instance.instance.rewards)) do r
                        r[1] ∈ edges(g_no_dst)
                    end
                )
                w_no_dst = Dict(
                    filter(map(map_edge, collect(keys(instance.weights))) .=> values(instance.weights)) do r
                        r[1] ∈ edges(g_no_dst)
                    end
                )
                i_no_dst = MinimumBudget(
                    SpanningTreeInstance(g_no_dst, r_no_dst),
                    w_no_dst,
                    remaining_budget,
                )
                s_no_dst = solve(i_no_dst, DynamicProgramming())
                t_no_dst = Edge{T}[unmap_edge(e) for e in s_no_dst.variables]
                v_no_dst =
                    _budgeted_spanning_tree_compute_value(instance, t_no_dst)

                if length(t_no_src) == 0 && length(t_no_dst) == 0
                    V[β, i] = V[β, i - 1]
                    S[β, i] = S[β, i - 1]
                    copy!(LD[β, i], LD[β, i - 1])
                elseif length(t_no_src) == 0 ||
                       (length(t_no_src) > 0 && v_no_dst >= v_no_src)
                    # Includes the case where both subproblems have the same 
                    # value. Pick to continue with t_no_src arbitrarily.
                    V[β, i] = v_no_dst + edge_value
                    S[β, i] = t_no_dst
                    push!(S[β, i], edge)

                    # No available data structure to copy, as this solution 
                    # has not been built within the dynamic-programming 
                    # mechanism, regenerate it from scratch.
                    for e in S[β, i]
                        visit_edge(LD[β, i], e)
                    end
                elseif length(t_no_dst) == 0 ||
                       (length(t_no_dst) > 0 && v_no_src > v_no_dst)
                    V[β, i] = v_no_src + edge_value
                    S[β, i] = t_no_src
                    push!(S[β, i], edge)

                    # No available data structure to copy, regenerate it from 
                    # scratch.
                    for e in S[β, i]
                        visit_edge(LD[β, i], e)
                    end
                else
                    error("Assertion failed")
                end
            else
                # Take i, there is no chance of it adding a loop.
                V[β, i] = V[remaining_budget, i - 1] + edge_value
                S[β, i] = copy(S[remaining_budget, i - 1])
                push!(S[β, i], edge)

                copy!(LD[β, i], LD[remaining_budget, i - 1])
                visit_edge(LD[β, i], edge)
            end
        end
    end

    S_refined =
        Dict(β => S[β, dimension(instance)] for β in 0:(instance.min_budget))
    return BudgetedSpanningTreeDynamicProgrammingSolution(
        instance,
        S[instance.min_budget, dimension(instance)],
        S_refined,
    )
end
