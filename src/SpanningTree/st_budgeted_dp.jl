function solve(instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, ::DynamicProgramming) where {T, U}
    # A dynamic-programming stance on Prim's algorithm.

    # Get an indexed list of *all* edges, sorted by increasing value.
    sorted_edges = Tuple{Edge, Float64, Int}[]
    for e in edges(instance.instance.graph)
        push!(sorted_edges, (e, reward(instance.instance, e), instance.weights[e]))
    end
    sort!(sorted_edges, by=(p) -> - p[2])

    # Fill the DP table, considering edges one by one (from the best to the
    # poorest), Prim-like.
    # Index: 
    # - min budget, starting at 0
    # - considering edges up to that index (included), starting at 1
    V = Dict{Tuple{T, Int}, Float64}()
    S = Dict{Tuple{T, Int}, Vector{Edge{T}}}()
    LD = Dict{Tuple{T, Int}, LoopDetector}()

    for β in 0:instance.min_budget
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

    println("=============== INIT")
    @show S
    println("===============")

    # Dynamic part.
    println("=============== DYNAMIC")
    for β in 1:instance.min_budget
        println("=-=-=-=-=-=-=-= $(β)")

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

        println("First edge $first_edge: ")
        @show V[β, 1]
        @show S[β, 1]
        @show LD[β, 1].node_done

        # Other edges (recursive cases).
        for i in 2:ne(instance.instance.graph)
            # Can edges_sorted[i] be taken?
            edge, edge_value, edge_weight = sorted_edges[i]
            
            remaining_budget = β - edge_weight
            if remaining_budget < 0
                remaining_budget = 0
            end

            println("Edge $i == $edge")
            @show LD[remaining_budget, i - 1].node_done
            @show LD[β, i - 1].node_done
            @show remaining_budget

            if V[remaining_budget, i - 1] == -1
                # Are the previous solutions infeasible (recursive call)? If so, 
                # don't consider using it.
                V[β, i] = V[β, i - 1]
                S[β, i] = S[β, i - 1]
                println("  Not taken: prev infeasible remaining_budget")
            elseif edge_would_create_loop(LD[remaining_budget, i - 1], edge) 
                # Don't take i with that previous solution, it would create a 
                # loop.
                # Rather, try to build solutions without one of the ends of i, 
                # to ensure there will be no loop when combining. Use the 
                # remaining budget 
                g_no_src = copy(instance.instance.graph)
                rem_vertex!(g_no_src, src(edge)) # Changes indices!
                map_index = (idx) -> ifelse(idx < src(edge), idx, idx - 1)
                map_edge = (e) -> Edge(map_index(src(e)), map_index(dst(e)))
                unmap_index = (idx) -> ifelse(idx < src(edge), idx, idx + 1)
                unmap_edge = (e) -> Edge(unmap_index(src(e)), unmap_index(dst(e)))
                r_no_src = Dict(map(map_edge, collect(keys(instance.instance.rewards))) .=> values(instance.instance.rewards))
                w_no_src = Dict(map(map_edge, collect(keys(instance.weights))) .=> values(instance.weights))
                i_no_src = MinimumBudget(SpanningTreeInstance(g_no_src, r_no_src), w_no_src, remaining_budget)
                s_no_src = solve(i_no_src, DynamicProgramming())
                t_no_src = [unmap_edge(e) for e in s_no_src.tree]
                v_no_src = _budgeted_spanning_tree_compute_value(instance, t_no_src)
                
                g_no_dst = copy(instance.instance.graph)
                rem_vertex!(g_no_dst, dst(edge)) # Changes indices!
                map_index = (idx) -> ifelse(idx < dst(edge), idx, idx - 1)
                map_edge = (e) -> Edge(map_index(src(e)), map_index(dst(e)))
                unmap_index = (idx) -> ifelse(idx < dst(edge), idx, idx + 1)
                unmap_edge = (e) -> Edge(unmap_index(src(e)), unmap_index(dst(e)))
                r_no_dst = Dict(map(map_edge, collect(keys(instance.instance.rewards))) .=> values(instance.instance.rewards))
                w_no_dst = Dict(map(map_edge, collect(keys(instance.weights))) .=> values(instance.weights))
                i_no_dst = MinimumBudget(SpanningTreeInstance(g_no_dst, r_no_dst), w_no_dst, remaining_budget)
                s_no_dst = solve(i_no_dst, DynamicProgramming())
                t_no_dst = [unmap_edge(e) for e in s_no_dst.tree]
                v_no_dst = _budgeted_spanning_tree_compute_value(instance, t_no_dst)

                println("  Loop!")
                if length(t_no_src) == 0 && length(t_no_dst) == 0
                    V[β, i] = V[β, i - 1]
                    S[β, i] = S[β, i - 1]
                    copy!(LD[β, i], LD[β, i - 1])
                    println("  Not taken: infeasible subproblems")
                elseif length(t_no_src) == 0 || (length(t_no_src) > 0 && v_no_dst > v_no_src)
                    V[β, i] = v_no_dst + edge_value
                    S[β, i] = t_no_dst
                    push!(S[β, i], edge)
            
                    # No available data structure to copy, regenerate it from 
                    # scratch.
                    for e in S[β, i]
                        visit_edge(LD[β, i], e)
                    end

                    println("  Taken: subproblem dst")
                elseif length(t_no_dst) == 0 || (length(t_no_dst) > 0 && v_no_src > v_no_dst)
                    V[β, i] = v_no_src + edge_value
                    S[β, i] = t_no_src
                    push!(S[β, i], edge)
            
                    # No available data structure to copy, regenerate it from 
                    # scratch.
                    for e in S[β, i]
                        visit_edge(LD[β, i], e)
                    end
                    
                    println("  Taken: subproblem src")
                else
                    println("WHAT THE FUCK?")
                    @show g_no_src
                    @show t_no_src
                    @show v_no_src
                    @show g_no_dst
                    @show t_no_dst
                    @show v_no_dst
                end
            else 
                # Take i, there is no chance of it adding a loop.
                V[β, i] = V[remaining_budget, i - 1] + edge_value
                S[β, i] = copy(S[remaining_budget, i - 1])
                push!(S[β, i], edge)
                println("  Taken")
            
                copy!(LD[β, i], LD[remaining_budget, i - 1])
                visit_edge(LD[β, i], edge)

                @show S[remaining_budget, i - 1]
                @show LD[β, i].node_done
            end
                
            @show V[β, i]
            @show S[β, i]

            if length(S[β, i]) > 0
                @show sum(instance.weights[e] for e in S[β, i])
                @show β
            end

            println("----------")
        end
    end
    println("===============")

    @show S
    @show S[instance.min_budget, ne(instance.instance.graph)]

    # TODO: return all the available information.
    # return SpanningTreeSolution(instance.instance, S[instance.min_budget, ne(instance.instance.graph)])
    return SimpleBudgetedSpanningTreeSolution(instance, S[instance.min_budget, ne(instance.instance.graph)])
end