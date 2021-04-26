function formulation(i::SpanningTreeInstance{Int, Maximise}, ::DefaultLinearFormulation; solver=nothing)
    # Input graph supposed to be undirected.
    n = nv(i.graph)
    graph = DiGraph(n)

    # Build the equivalent directed graph.
    for e in edges(i.graph)
        add_edge!(graph, src(e), dst(e))
        add_edge!(graph, dst(e), src(e))
    end

    # Helper methods.
    inedges(g, v) = (edgetype(g)(x, v) for x in inneighbors(g, v))
    outedges(g, v) = (edgetype(g)(v, x) for x in outneighbors(g, v))

    # Choose a source arbitrarily.
    source = first(vertices(graph))
    other_nodes = filter(v -> v != source, vertices(graph))

    # Start building the optimisation model. Keep integer variables, because 
    # this formulation is not tight and, more importantly, there might be other
    # constraints later on that would destroy any interesting structure of the 
    # problem.
    # Based on Magnanti, T.L.; Wolsey, L. Optimal Trees, section Flow 
    # formulation (p. 38).
    m = Model(solver)
    set_silent(m)
    
    x = @variable(m, [e in edges(graph)], binary=true)
    flow = @variable(m, [e in edges(graph)], lower_bound=0)
    inflow(v) = length(inedges(graph, v)) == 0 ? 0 : sum(flow[e] for e in inedges(graph, v))
    outflow(v) = length(outedges(graph, v)) == 0 ? 0 : sum(flow[e] for e in outedges(graph, v))
    
    # Set the names, due to the use of anonymous variables with JuMP.
    for e in edges(graph)
        set_name(x[e], "x_$(src(e))_$(dst(e))")
        set_name(flow[e], "flow_$(src(e))_$(dst(e))")
    end

    # - Flow towards the source: zero. Flow from the source: one unit for each 
    #   vertex in the graph.
    @constraint(m, inflow(source) == 0)
    @constraint(m, outflow(source) == n - 1)

    # - When the flow exits one of the other nodes, the node keeps one unit 
    #   for itself and redistributes the rest.
    for v in other_nodes
        @constraint(m, inflow(v) - outflow(v) == 1)
    end

    # - (n - 1) edges must be taken for n vertices.
    @constraint(m, sum(x) == n - 1)

    # - Flow can flow in an edge only if the edge belongs to the tree.
    for e in edges(graph)
        @constraint(m, flow[e] <= (n - 1) * x[e])
    end

    # - Among direct and reverse edges, only one can be chosen.
    for e in edges(graph)
        @constraint(m, x[e] + x[reverse(e)] <= 1)
    end

    # Finally, the objective function.
    @objective(m, Max, sum(i.rewards[e] * (x[e] + x[reverse(e)]) for e in keys(i.rewards)))

    # Don't return flows, these are not really decision variables.
    return m, x
end

function solve(i::SpanningTreeInstance{Int, Maximise}, ::DefaultLinearFormulation; solver=nothing)
    m, x = formulation(i, DefaultLinearFormulation(), solver=solver)
    optimize!(m)
    return SpanningTreeSolution(i, _extract_lp_solution(i, x))
end
