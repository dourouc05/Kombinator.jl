function formulation(
    i::UniformMatroidInstance{Float64, Maximise},
    ::DefaultLinearFormulation;
    solver=nothing,
)
    dim = dimension(i)

    model = Model(solver)
    x = @variable(model, [1:dim], Bin)
    @objective(model, Max, sum(x[j] * i.rewards[j] for j in 1:dim))
    @constraint(model, sum(x) <= i.m)

    set_silent(model)

    return model, x
end

function solve(
    i::UniformMatroidInstance{Float64, Maximise},
    ::DefaultLinearFormulation;
    solver=nothing,
)
    m, x = formulation(i, DefaultLinearFormulation(), solver=solver)
    optimize!(m)
    return UniformMatroidSolution(i, findall(JuMP.value.(x) .>= 0.5))
end
