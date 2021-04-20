"""

"""
struct MinimumBudget{CI <: CombinatorialInstance, T <: Real} <: CombinatorialVariation
    instance::CI
    weights::Vector{T}
    min_budget::T
end

struct MaximumBudget{CI <: CombinatorialInstance, T <: Real} <: CombinatorialVariation
    instance::CI
    weights::Vector{T}
    min_budget::T
end
