function _elementary_path_lazy_callback(graph, source, destination, m, x, cb_data)
    # Callback to generate subtour-elimination constraints.

    # Based on the hypothesis that the strengthening constraints have been 
    # added beforehand! I.e. at most one edge incoming and at most one outgoing 
    # (except for source/destination).
    x = Dict(e => callback_value(cb_data, x[e]) for e in edges(graph))
  
    # This callback is sometimes called for noninteger nodes! Just let the 
    # solver go on for these nodes (finding a loop does not really make sense).
    # Use this loop to count nonzero values in the solution, this will be 
    # useful later to get out of a loop sooner.
    n_x_nonzero = 0
    for e in edges(graph)
        # Test for a quite forgiving tolerance.
        ε = 0.01
        if x[e] >= ε && x[e] <= 1.0 - ε
            # The value for x[e] is clearly not integer.
            return
        end
    
        # Count nonzero values.
        if x[e] >= 0.5
            n_x_nonzero += 1
        end
    end
  
    # Helper methods.
    inedges(g, v) = (edgetype(g)(x, v) for x in inneighbors(g, v))
    outedges(g, v) = (edgetype(g)(v, x) for x in outneighbors(g, v))
  
    # Find a subtour. Start from the source, use edges until the destination
    # is found.
    # This is ensured to be correct, because only one outgoing edge from the 
    # current node, as per the constraints (and this value is integer).
    current_node = source # TODO: factor this loop out? Also useful for sorting edges.
    while current_node != destination
        for e in outedges(graph, current_node)
            if x[e] >= .5
                x[e] = 0.0
                current_node = dst(e)
                n_x_nonzero -= 1
                break
            end
        end
    
        # If all nonzero values have been found, stop iterating.
        if n_x_nonzero == 0
            break
        end
    end
  
    # Find the edges that remain after the path is removed.
    lhs_edges = Edge[]
    for e in edges(graph)
        # Don't consider edges adjacent to the source or the destination
        if src(e) == source || dst(e) == destination
            continue
        end
    
        if x[e] >= .5
            push!(lhs_edges, e)
        end
    end
  
    # Nothing left? No subtour!
    if length(lhs_edges) == 0
        return
    end
  
    # Add lazy constraints (subtour elimination). Separate all subtours to 
    # generate constraints that are as tight as possible.
    while length(lhs_edges) > 0
        # Find one subtour among these edges. Same technique as above: start
        # from a node of the tour, use edges until you find the starting point.
        first_edge = copy(lhs_edges[1])
        deleteat!(lhs_edges, 1)

        src_node = src(first_edge) # Memorise the source for this iteration.
        cur_node = dst(lhs_edges[1]) # First node to explore.
        con_edges = Edge[first_edge] # List of edges in the loop.
    
        while cur_node != src_node # While not back to the source...
            for (i, e) in enumerate(lhs_edges) # Go through all edges...
                if src(e) == cur_node # If this one starts from the current node:
                    cur_node = dst(e)
                    push!(con_edges, e)
                    deleteat!(lhs_edges, i)
                    break
                end
            end
        end
    
        # Build the corresponding constraint.
        con = @build_constraint(sum(x[e] for e in con_edges) <= length(con_edges) - 1)
        MOI.submit(m, MOI.LazyConstraint(cb_data), con)
    end
end

function _sort_path(path::Vector{Tuple{Int, Int}}, source::Int, destination::Int, n_vertices::Int)
    sorted = Tuple{Int, Int}[]
    current_node = source
    edges = copy(path)
  
    i = 0
    while length(edges) > 0
        # Find the corresponding edge (or the first one that matches).
        for i in 1:length(edges)
            e = edges[i]
            if e[1] == current_node
            push!(sorted, e)
            current_node = e[2]
            deleteat!(edges, i)
            break
            end
        end
    
        if current_node == destination
            break
        end
    
        # Safety: ensure this loop does not make too many iterations.
        i += 1
        if i > n_vertices
            error("Assertion failed: infinite loop when sorting the edges of the path $path")
        end
    end
  
    if length(edges) > 0
        error("Edges remaining after sorting the edges: the solution is likely to contain at least a subtour, $edges")
    end
  
    return sorted
end

function formulation(i::ElementaryPathInstance{Int, Maximise}, ::DefaultLinearFormulation; solver=nothing)
    n = nv(i.graph)
  
    # Helper methods.
    inedges(g, v) = (edgetype(g)(x, v) for x in inneighbors(g, v))
    outedges(g, v) = (edgetype(g)(v, x) for x in outneighbors(g, v))
  
    # List all the vertices that are not the source nor the destination.
    other_nodes = collect(filter(vertices(i.graph)) do v; v != i.src && v != i.dst; end)
  
    # Build the optimisation model behind solve_linear.
    model = Model(solver)
    set_silent(model)

    x = @variable(model, [e in edges(i.graph)], binary=true)
    # Normally, with this formulation, explicitly having binary variables 
    # is not necessary, but this is only valid if minimising a linear function. 
    # In all other cases, there is no guarantee to have an integer-feasible 
    # solution. Moreover, adding new constraints may make this definition 
    # required (especially budget constraints).
  
    # Set the names, due to the use of anonymous variables with JuMP.
    for e in edges(i.graph)
        set_name(x[e], "x_$(src(e))_$(dst(e))")
    end
  
    # For a vertex in: ∑ input flow - ∑ output flow.
    function edge_incidence(v)
        if length(inedges(i.graph, v)) > 0
            ins = sum(x[e] for e in inedges(i.graph, v))
        else
            ins = 0.0
        end
    
        if length(outedges(i.graph, v)) > 0
            outs = sum(x[e] for e in outedges(i.graph, v))
        else
            outs = 0.0
        end
    
        return ins - outs
    end
  
    # Ensure that the unit flow goes from the source to the destination.
    @constraint(model, edge_incidence(i.src) == -1)
    @constraint(model, edge_incidence(i.dst) == 1)

    # Flow conservation at each node (except source and destination).
    @constraint(model, [v in other_nodes], edge_incidence(v) == 0)
  
    # Eliminate a large number of simple subtours.
    @constraint(model, sum(x[e] for e in inedges(i.graph, i.src)) == 0)
    @constraint(model, sum(x[e] for e in outedges(i.graph, i.src)) == 1)
    @constraint(model, sum(x[e] for e in inedges(i.graph, i.dst)) == 1)
    @constraint(model, sum(x[e] for e in outedges(i.graph, i.dst)) == 0)

    for v in other_nodes
        @constraint(model, sum(x[e] for e in inedges(i.graph, v)) <= 1)
        @constraint(model, sum(x[e] for e in outedges(i.graph, v)) <= 1)
    end

    # Objective function.
    @objective(model, Max, sum(i.rewards[e] * x[e] for e in keys(i.rewards)))
  
    # Set the lazy-constraint callback to ensure the solution is always an elementary path.
    MOI.set(model, MOI.LazyConstraintCallback(), cb_data -> _elementary_path_lazy_callback(i.graph, i.src, i.dst, model, x, cb_data))

    return model, x
end

function solve(i::ElementaryPathInstance{Int, Maximise}, ::DefaultLinearFormulation; solver=nothing)
    m, x = formulation(i, DefaultLinearFormulation(), solver=solver)
    optimize!(m)
    return ElementaryPathSolution(i, _extract_lp_solution(i, x))
end
