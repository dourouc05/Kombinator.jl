solve(i::UniformMatroidInstance, ::LinearProgramming; kwargs...) = msets_lp(i; kwargs...)

function msets_lp(i::UniformMatroidInstance; solver=nothing)
  model = Model(solver)
  @variable(model, x[1:length(values(i))], Bin)
  @objective(model, Max, dot(x, values(i)))
  @constraint(model, sum(x) <= m(i))

  set_silent(model)
  optimize!(model)

  return UniformMatroidSolution(i, findall(JuMP.value.(x) .>= 0.5))
end