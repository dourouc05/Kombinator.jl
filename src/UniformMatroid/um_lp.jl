function solve(i::UniformMatroidInstance, ::DefaultLinearFormulation; solver=nothing)
  model = Model(solver)
  
  @variable(model, x[1:length(values(i))], Bin)
  @objective(model, Max, dot(x, values(i)))
  @constraint(model, sum(x) <= m(i))

  set_silent(model)
  optimize!(model)

  return UniformMatroidSolution(i, findall(JuMP.value.(x) .>= 0.5))
end