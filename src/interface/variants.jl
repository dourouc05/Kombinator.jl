"""
    struct MinimumBudget{CI <: CombinatorialInstance, T <: Real}

Implement a minimum-budget constraint, i.e. a minimum quantity of a resource 
that must be used.

``\\sum_i x_i \\times \\mathtt{weights}_i \\geq \\mathtt{min\\_budget}``
"""
struct MinimumBudget{CI <: CombinatorialInstance, T <: Real} <: CombinatorialVariation
    instance::CI
    weights::Union{Vector{T}, Dict{<: Any, T}}
    min_budget::T
    compute_all_values::Bool # Solutions will be output for all budget values, 
    # usually with the same time complexity as a single solve.
end

function MinimumBudget(i::CI, weights::Union{Vector{T}, Dict{<: Any, T}}, min_budget::T=zero(T); compute_all_values::Bool=false) where {CI, T}
    return MinimumBudget(i, weights, min_budget, compute_all_values)
end

function weights(i::MinimumBudget) # TODO: remove me?
    return i.weights
end

function budget(i::MinimumBudget) # TODO: remove me?
    return i.min_budget
end

function copy(i::MinimumBudget; instance::CI=i.instance, weights::Union{Vector{T}, Dict{<: Any, T}}=i.weights, min_budget::T=i.min_budget, compute_all_values::Bool=i.compute_all_values) where {CI <: CombinatorialInstance, T <: Real}
    return MinimumBudget(instance, weights, min_budget, compute_all_values)
end

"""
    struct MaximumBudget{CI <: CombinatorialInstance, T <: Real}

Implement a maximum-budget constraint, i.e. a maximum quantity of a resource 
that can be used.

``\\sum_i x_i \\times \\mathtt{weights}_i \\leq \\mathtt{max\\_budget}``
"""
struct MaximumBudget{CI <: CombinatorialInstance, T <: Real} <: CombinatorialVariation
    instance::CI
    weights::Union{Vector{T}, Dict{<: Any, T}}
    max_budget::T
    compute_all_values::Bool
end

function MaximumBudget(i::CI, weights::Union{Vector{T}, Dict{<: Any, T}}, max_budget::T; compute_all_values::Bool=false) where {CI, T}
    return MaximumBudget(i, weights, max_budget, compute_all_values)
end

function weights(i::MaximumBudget) # TODO: remove me?
    return i.weights
end

function budget(i::MaximumBudget) # TODO: remove me?
    return i.max_budget
end

function copy(i::MaximumBudget; instance::CI=i.instance, weights::Union{Vector{T}, Dict{<: Any, T}}=i.weights, max_budget::T=i.max_budget, compute_all_values::Bool=i.compute_all_values) where {CI <: CombinatorialInstance, T <: Real}
    return MaximumBudget(ci, weights, max_budget, compute_all_values)
end
