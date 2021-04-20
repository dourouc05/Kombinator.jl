"""
An instance of the uniform-matroid problem. It is sometimes called the m-set
problem. 

Any set of `m` values or fewer is a solution. More formally, the independent 
sets are the sets containing at most `m` elements.

It can be formalised as follows:

``\\max \\sum_i \\mathrm{values}_i x_i``
``\\mathrm{s.t.} \\sum_i x_i \\leq m, \\quad x \\in \\{0, 1\\}^d``
"""
struct MSetInstance{T <: Real} <: CombinatorialInstance
  values::Vector{T}
  m::Int

  function MSetInstance(values::Vector{T}, m::Int) where {T <: Real}
    # Error checking.
    if m < 0
      error("m is less than zero: there is no solution.")
    end

    if m == 0
      error("m is zero: the only solution is to take no items.")
    end

    # Return a new instance.
    return new(values, m)
  end
end

values(i::MSetInstance{T}) where {T} = i.values
m(i::MSetInstance) = i.m
dimension(i::MSetInstance) = length(values(i))

value(i::MSetInstance{T}, o::Int) where {T} = values(i)[o]
values(i::MSetInstance{T}, o) where {T} = values(i)[o]

struct MSetSolution{T <: Real} <: CombinatorialSolution
  instance::MSetInstance{T}
  items::Vector{Int} # Indices to the chosen items.
end

function value(s::MSetSolution{T}) where {T <: Real}
  return sum(s.instance.values[i] for i in s.items)
end
