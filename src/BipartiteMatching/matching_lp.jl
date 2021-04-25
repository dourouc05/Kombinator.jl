function formulation(i::BipartiteMatchingInstance{Int}, ::DefaultLinearFormulation; solver=nothing)
    indices = collect((src(e), dst(e)) for e in edges(i.graph))

    model = Model(solver)
    x = @variable(solver.model, [indices], binary=true)

    for i in 1:n_arms # Left nodes.
        @constraint(solver.model, sum(solver.x[(i, j)] for j in 1:n_arms) == 1)
    end
    for j in 1:n_arms # Right nodes.
        @constraint(solver.model, sum(solver.x[(i, j)] for i in 1:n_arms) == 1)
    end

    @objective(model, Max, sum(rewards[(i, j)] * solver.x[(i, j)] for (i, j) in keys(rewards)))
    @constraint(model, sum(x) <= i.m)

    set_silent(model)

    return m, x
end