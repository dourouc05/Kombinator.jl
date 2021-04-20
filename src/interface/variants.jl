"""
    struct MinimumBudget{CI <: CombinatorialInstance, T <: Real}

Implement a minimum-budget constraint, i.e. a minimum quantity of a resource 
that must be used.

``\\sum_i x_i \\times \\mathtt{weights}_i \\geq \\mathtt{min\\_budget}``
"""
struct MinimumBudget{CI <: CombinatorialInstance, T <: Real} <: CombinatorialVariation
    instance::CI
    weights::Vector{T}
    min_budget::T
    compute_all_values::Bool
end

function MinimumBudget(i::CI, weights::Vector{T}, min_budget::T; compute_all_values::Bool=false) where {CI, T}
    return MinimumBudget(i, weights, min_budget, compute_all_values)
end

"""
    struct MaximumBudget{CI <: CombinatorialInstance, T <: Real}

Implement a maximum-budget constraint, i.e. a maximum quantity of a resource 
that can be used.

``\\sum_i x_i \\times \\mathtt{weights}_i \\leq \\mathtt{max\\_budget}``
"""
struct MaximumBudget{CI <: CombinatorialInstance, T <: Real} <: CombinatorialVariation
    instance::CI
    weights::Vector{T}
    max_budget::T
    compute_all_values::Bool
end

function MaximumBudget(i::CI, weights::Vector{T}, max_budget::T; compute_all_values::Bool=false) where {CI, T}
    return MaximumBudget(i, weights, max_budget, compute_all_values)
end
