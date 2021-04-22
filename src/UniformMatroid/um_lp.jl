function solve(i::UniformMatroidInstance{Float64, Maximise}, ::DefaultLinearFormulation; solver=nothing)
    dim = dimension(i)

    model = Model(solver)
    @variable(model, x[1:dim], Bin)
    @objective(model, Max, sum(x[j] * i.values[j] for j in 1:dim))
    @constraint(model, sum(x) <= i.m)

    set_silent(model)
    optimize!(model)

    return UniformMatroidSolution(i, findall(JuMP.value.(x) .>= 0.5))
end