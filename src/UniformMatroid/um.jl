"""
An instance of the uniform-matroid problem. It is sometimes called the m-set
problem. 

Any set of `m` values or fewer is a solution. More formally, the independent 
sets are the sets containing at most `m` elements.

It can be formalised as follows:

``\\max \\sum_i \\mathrm{rewards}_i x_i``
``\\mathrm{s.t.} \\sum_i x_i \\leq m, \\quad x \\in \\{0, 1\\}^d``
"""
struct UniformMatroidInstance{T <: Real, O <: CombinatorialObjective} <:
       CombinatorialInstance
    rewards::Vector{T} # TODO: rename as rewards for more consistency.
    m::Int
    objective::O

    function UniformMatroidInstance(
        rewards::Vector{T},
        m::Int,
        objective::O=Maximise(),
    ) where {T <: Real, O <: CombinatorialObjective}
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

function copy(
    i::UniformMatroidInstance{T, O};
    rewards::Vector{T}=i.rewards,
    m::Int=i.m,
    objective::CombinatorialObjective=i.objective,
) where {T <: Real, O <: CombinatorialObjective}
    return UniformMatroidInstance(rewards, m, objective)
end

fastest_exact(::UniformMatroidInstance) = GreedyAlgorithm()

# Solution.

struct UniformMatroidSolution{T <: Real, O <: CombinatorialObjective} <:
       CombinatorialSolution
    instance::UniformMatroidInstance{T, O}
    variables::Vector{Int} # Indices to the chosen items.
end

function make_solution(
    i::UniformMatroidInstance{T, O},
    item::Dict{Int, Float64},
) where {T <: Real, O <: CombinatorialObjective}
    items_vector = Int[]
    for (k, v) in item
        if v >= 0.5
            push!(items_vector, k)
        end
    end

    return UniformMatroidSolution(i, items_vector)
end

# Budgeted solution.

struct MinBudgetedUniformMatroidSolution{T <: Real, U <: Real} <:
       MultipleMinBudgetedSolution
    instance::MinimumBudget{UniformMatroidInstance{T, Maximise}, U}
    variables::Vector{Int} # Indices to the chosen items for the min_budget.
    solutions::Dict{Int, Vector{Int}}
end

function MinBudgetedUniformMatroidSolution(
    instance::MinimumBudget{UniformMatroidInstance{T, O}, U},
    items::Vector{Int},
) where {T, O <: CombinatorialObjective, U}
    return MinBudgetedUniformMatroidSolution(
        instance,
        items,
        Dict{Int, Vector{Int}}(),
    )
end

function _check_has_solution_for_each_budget(s::MinBudgetedUniformMatroidSolution{T, U}) where {T, U}
    if length(s.solutions) == 0
        error("The provided solution object does not have one solution " * 
              "per value of the budget.")
    end
    return
end

function value(s::MinBudgetedUniformMatroidSolution{T, U}) where {T, U}
    if -1 in s.variables || length(s.variables) == 0
        return -Inf
    end

    return sum(s.instance.instance.rewards[i] for i in s.variables)
end

function items(
    s::MinBudgetedUniformMatroidSolution{T, U},
    budget::Int,
) where {T, U}
    _check_has_solution_for_each_budget(s)
    return s.solutions[budget]
end

function items_all_budgets(
    s::MinBudgetedUniformMatroidSolution{T, U},
    max_budget::Int,
) where {T, U}
    _check_has_solution_for_each_budget(s)
    sol = Dict{Int, Vector{Int}}()
    m = s.instance.instance.m
    for budget in 0:max_budget
        sol[budget] = s.solutions[budget]
    end
    return sol
end

function value(
    s::MinBudgetedUniformMatroidSolution{T, U},
    budget::Int,
) where {T, U}
    _check_has_solution_for_each_budget(s)

    its = items(s, budget)
    if -1 in its || length(its) == 0
        return -Inf
    end
    return sum(s.instance.instance.rewards[i] for i in its)
end

function make_solution(
    i::MinimumBudget{UniformMatroidInstance{T, O}, U},
    item::Dict{Int, Float64},
) where {T, O, U}
    items_vector = Int[]
    for (k, v) in item
        if v >= 0.5
            push!(items_vector, k)
        end
    end

    return MinBudgetedUniformMatroidSolution(i, items_vector)
end
