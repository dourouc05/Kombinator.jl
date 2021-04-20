solve(i::UniformMatroidInstance, ::GreedyAlgorithm; kwargs...) = msets_greedy(i; kwargs...)

function msets_greedy(instance::UniformMatroidInstance)
  # Algorithm: sort the weights, take the m largest ones, this is the optimum m-set solution.
  # Implementation: no need for sorting, partialsortperm returns the largest items.
  items = collect(partialsortperm(instance.values, 1:instance.m, rev=true))
  return UniformMatroidSolution(instance, items)
end