"""
An instance of the uniform-matroid problem. It is sometimes called the m-set
problem. 

Any set of `m` values or fewer is a solution. More formally, the independent 
sets are the sets containing at most `m` elements.

It can be formalised as follows:

``\\max \\sum_i \\mathrm{values}_i x_i``
``\\mathrm{s.t.} \\sum_i x_i \\leq m, \\quad x \\in \\{0, 1\\}^d``
"""
struct UniformMatroidInstance{T <: Real, O <: CombinatorialObjective} <: CombinatorialInstance
  values::Vector{T}
  m::Int
  objective::CombinatorialObjective

  function UniformMatroidInstance(values::Vector{T}, m::Int, objective::O=Maximise) where {T <: Real, O <: CombinatorialObjective}
    # Error checking.
    if m < 0
      error("m is less than zero: there is no solution.")
    end

    if m == 0
      error("m is zero: the only solution is to take no items.")
    end

    # Return a new instance.
    return new{T, O}(values, m, objective)
  end
end

values(i::UniformMatroidInstance{T}) where {T} = i.values
m(i::UniformMatroidInstance) = i.m
dimension(i::UniformMatroidInstance) = length(values(i))

value(i::UniformMatroidInstance{T}, o::Int) where {T} = values(i)[o]
values(i::UniformMatroidInstance{T}, o) where {T} = values(i)[o]

struct UniformMatroidSolution{T <: Real} <: CombinatorialSolution
  instance::UniformMatroidInstance{T}
  items::Vector{Int} # Indices to the chosen items.
end

function value(s::UniformMatroidSolution{T}) where {T <: Real}
  return sum(s.instance.values[i] for i in s.items)
end
