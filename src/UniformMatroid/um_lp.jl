function formulation(
    i::UniformMatroidInstance{Float64, Maximise},
    f::DefaultLinearFormulation
)
    dim = dimension(i)

    model = Model(f.solver)
    x = @variable(model, [1:dim], Bin)
    @objective(model, Max, sum(x[j] * i.rewards[j] for j in 1:dim))
    @constraint(model, sum(x) <= i.m)

    set_silent(model)

    return model, x
end

function solve(
    i::UniformMatroidInstance{Float64, Maximise},
    f::DefaultLinearFormulation
)
    m, x = formulation(i, f)
    optimize!(m)
    return UniformMatroidSolution(i, findall(JuMP.value.(x) .>= 0.5))
end
