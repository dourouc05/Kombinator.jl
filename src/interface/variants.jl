# Minimum budget.

"""
    struct MinimumBudget{CI <: CombinatorialInstance, T <: Real}

Implement a minimum-budget constraint, i.e. a minimum quantity of a resource 
that must be used.

``\\sum_i x_i \\times \\mathtt{weights}_i \\geq \\mathtt{min\\_budget}``
"""
struct MinimumBudget{CI <: CombinatorialInstance, T <: Real} <:
       CombinatorialVariation
    instance::CI
    weights::Union{Vector{T}, Dict{<:Any, T}}
    min_budget::T
    compute_all_values::Bool # Solutions will be output for all budget values, 
    # usually with the same time complexity as a single solve.

    function MinimumBudget(instance::CI, weights::Vector{T}, min_budget::T, compute_all_values::Bool) where {CI <: CombinatorialInstance, T <: Real}
        # There should be as many weights as the inner instance has rewards.
        if length(weights) != dimension(instance)
            error("The MinimumBudget constraint has $(length(weights)) weights, but the combinatorial instance has dimension $(dimension(instance)).")
        end

        # Ensure that important properties of the algorithms are respected.
        if any(weights .< zero(T))
            error("Some weights are negative, which is not allowed.")
        end
        if min_budget < zero(T)
            error("The minimum budget is negative, which is not allowed.")
        end

        return new{CI, T}(instance, weights, min_budget, compute_all_values)
    end

    function MinimumBudget(instance::CI, weights::Dict{<:Any, T}, min_budget::T, compute_all_values::Bool) where {CI <: CombinatorialInstance, T <: Real}
        # There should be as many weights as the inner instance has rewards.
        if length(weights) != dimension(instance)
            error("The MinimumBudget constraint has $(length(weights)) weights, but the combinatorial instance has dimension $(dimension(instance)).")
        end

        # Ensure that important properties of the algorithms are respected.
        if any(values(weights) .< zero(T))
            error("Some weights are negative, which is not allowed.")
        end
        if min_budget < zero(T)
            error("The minimum budget is negative, which is not allowed.")
        end

        return new{CI, T}(instance, weights, min_budget, compute_all_values)
    end
end

function MinimumBudget(
    i::CI,
    weights::Union{Vector{T}, Dict{<:Any, T}},
    min_budget::T=zero(T);
    compute_all_values::Bool=false,
) where {CI, T}
    return MinimumBudget(i, weights, min_budget, compute_all_values)
end

function copy(
    i::MinimumBudget;
    instance::CI=i.instance,
    weights::Union{Vector{T}, Dict{<:Any, T}}=i.weights,
    min_budget::T=i.min_budget,
    compute_all_values::Bool=i.compute_all_values,
) where {CI <: CombinatorialInstance, T <: Real}
    return MinimumBudget(instance, weights, min_budget, compute_all_values)
end

"""
    abstract type MinBudgetedSolution

A type of solution that is specifically tailored for the minimum-budget 
variant.
"""
abstract type MinBudgetedSolution <: CombinatorialSolution end

"""
    abstract type SingleMinBudgetedSolution

A type of `MinBudgetedSolution` when only one solution is available, to the 
single value of the budget that is defined in the related instance. Objects
of this type do not have to implement more fields than any 
`CombinatorialSolution`.
"""
abstract type SingleMinBudgetedSolution <: MinBudgetedSolution end

"""
    abstract type MultipleMinBudgetedSolution

A type of `MinBudgetedSolution` when several solutions are available, with 
the several values of the budget that are specified by the combinatorial 
instance (typically, from zero to a maximum value). 

Objects of this type have to implement the usual fields of 
`CombinatorialSolution`, but also `solutions`, a mapping from a budget value
to the corresponding solution (`solutions`[i]` corresponds to a minimum budget
of `i`).
"""
abstract type MultipleMinBudgetedSolution <: MinBudgetedSolution end

# Maximum budget.

"""
    struct MaximumBudget{CI <: CombinatorialInstance, T <: Real}

Implement a maximum-budget constraint, i.e. a maximum quantity of a resource 
that can be used.

``\\sum_i x_i \\times \\mathtt{weights}_i \\leq \\mathtt{max\\_budget}``
"""
struct MaximumBudget{CI <: CombinatorialInstance, T <: Real} <:
       CombinatorialVariation
    instance::CI
    weights::Union{Vector{T}, Dict{<:Any, T}}
    max_budget::T
    compute_all_values::Bool
end

function MaximumBudget(
    i::CI,
    weights::Union{Vector{T}, Dict{<:Any, T}},
    max_budget::T;
    compute_all_values::Bool=false,
) where {CI, T}
    return MaximumBudget(i, weights, max_budget, compute_all_values)
end

function copy(
    i::MaximumBudget;
    instance::CI=i.instance,
    weights::Union{Vector{T}, Dict{<:Any, T}}=i.weights,
    max_budget::T=i.max_budget,
    compute_all_values::Bool=i.compute_all_values,
) where {CI <: CombinatorialInstance, T <: Real}
    return MaximumBudget(ci, weights, max_budget, compute_all_values)
end

"""
    abstract type MaxBudgetedSolution

A type of solution that is specifically tailored for the maximum-budget 
variant.
"""
abstract type MaxBudgetedSolution <: CombinatorialSolution end

"""
    abstract type SingleMaxBudgetedSolution

A type of `MaxBudgetedSolution` when only one solution is available, to the 
single value of the budget that is defined in the related instance. Objects
of this type do not have to implement more fields than any 
`CombinatorialSolution`.
"""
abstract type SingleMaxBudgetedSolution <: MaxBudgetedSolution end

"""
    abstract type MultipleMaxBudgetedSolution

A type of `MaxBudgetedSolution` when several solutions are available, with 
the several values of the budget that are specified by the combinatorial 
instance (typically, from zero to a maximum value). 

Objects of this type have to implement the usual fields of 
`CombinatorialSolution`, but also `solutions`, a mapping from a budget value
to the corresponding solution (`solutions`[i]` corresponds to a maximum budget
of `i`).
"""
abstract type MultipleMaxBudgetedSolution <: MaxBudgetedSolution end
