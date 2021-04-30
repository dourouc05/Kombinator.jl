"""
An instance of the uniform-matroid problem. It is sometimes called the m-set
problem. 

Any set of `m` values or fewer is a solution. More formally, the independent 
sets are the sets containing at most `m` elements.

It can be formalised as follows:

``\\max \\sum_i \\mathrm{rewards}_i x_i``
``\\mathrm{s.t.} \\sum_i x_i \\leq m, \\quad x \\in \\{0, 1\\}^d``
"""
struct UniformMatroidInstance{T <: Real, O <: CombinatorialObjective} <: CombinatorialInstance
    rewards::Vector{T} # TODO: rename as rewards for more consistency.
    m::Int
    objective::O

    function UniformMatroidInstance(rewards::Vector{T}, m::Int, objective::O=Maximise()) where {T <: Real, O <: CombinatorialObjective}
        # Error checking.
        if m < 0
          error("m is less than zero: there is no solution.")
        end

        if m == 0
          error("m is zero: the only solution is to take no items.")
        end

        # Return a new instance.
        return new{T, O}(rewards, m, objective)
    end
end

dimension(i::UniformMatroidInstance) = length(i.rewards)

function copy(i::UniformMatroidInstance{T, O}; rewards::Vector{T}=i.rewards, m::Int=i.m, objective::CombinatorialObjective=i.objective) where {T <: Real, O <: CombinatorialObjective}
    return UniformMatroidInstance(rewards, m, objective)
end

# Solution.

struct UniformMatroidSolution{T <: Real, O <: CombinatorialObjective} <: CombinatorialSolution
    instance::UniformMatroidInstance{T, O}
    items::Vector{Int} # Indices to the chosen items.
end

function value(s::UniformMatroidSolution{T, O}) where {T <: Real, O}
    return sum(s.instance.rewards[i] for i in s.items)
end

function create_solution(i::UniformMatroidInstance{T, O}, item::Dict{Int, Float64}) where {T <: Real, O <: CombinatorialObjective}
    items_vector = Int[]
    for (k, v) in item
        if v >= 0.5
            push!(items_vector, k)
        end
    end

    return UniformMatroidSolution(i, items_vector)
end

# Budgeted solution.

struct MinBudgetedUniformMatroidSolution{T <: Real, U <: Real} <: CombinatorialSolution
    instance::MinimumBudget{UniformMatroidInstance{T, Maximise}, U}
    items::Vector{Int} # Indices to the chosen items for the min_budget.
    state::Array{Float64, 3} # Data structure built by the dynamic-programming recursion.
    solutions::Dict{Tuple{Int, Int, Int}, Vector{Int}} # From the indices of state to the corresponding solution.
end

function MinBudgetedUniformMatroidSolution(instance::MinimumBudget{UniformMatroidInstance{T, O}, U}, items::Vector{Int}) where {T, O <: CombinatorialObjective, U}
    return MinBudgetedUniformMatroidSolution(instance, items, zeros(0, 0, 0), Dict{Tuple{Int, Int, Int}, Vector{Int}}())
end

function value(s::MinBudgetedUniformMatroidSolution{T, U}) where {T, U}
    return sum(s.instance.instance.rewards[i] for i in s.items)
end

function items(s::MinBudgetedUniformMatroidSolution{T, U}, budget::Int) where {T, U}
    return s.solutions[s.instance.instance.m, 0, budget]
end

function items_all_budgets(s::MinBudgetedUniformMatroidSolution{T, U}, max_budget::Int) where {T, U}
    sol = Dict{Int, Vector{Int}}()
    m = s.instance.instance.m
    for budget in 0:max_budget
        sol[budget] = s.solutions[m, 0, budget]
    end
    return sol
end
  
function value(s::MinBudgetedUniformMatroidSolution{T, U}, budget::Int) where {T, U}
    its = items(s, budget)
    if -1 in its
        return -Inf
    end
    return sum(s.instance.instance.rewards[i] for i in its)
end

function create_solution(i::MinimumBudget{UniformMatroidInstance{T, O}, U}, item::Dict{Int, Float64}) where {T, O, U}
    items_vector = Int[]
    for (k, v) in item
        if v >= 0.5
            push!(items_vector, k)
        end
    end

    return MinBudgetedUniformMatroidSolution(i, items_vector)
end
