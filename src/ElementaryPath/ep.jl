struct ElementaryPathInstance{T} <: CombinatorialInstance
    graph::AbstractGraph{T}
    costs::Dict{Edge{T}, Float64}
    src::T
    dst::T
end

dimension(i::ElementaryPathInstance{T}) where T = ne(i.graph)

struct ElementaryPathSolution{T} <: CombinatorialInstance
    instance::ElementaryPathInstance{T}
    path::Vector{Edge{T}}
    states::Dict{T, Float64}
    solutions::Dict{T, Vector{Edge{T}}}
end

# Budgeted

struct BudgetedElementaryPathSolution{T} <: CombinatorialSolution
    instance::MinimumBudget{ElementaryPathInstance{T}, T}
    path::Vector{Edge{T}}
    states::Dict{Tuple{T, Int}, Float64}
    solutions::Dict{Tuple{T, Int}, Vector{Edge{T}}}
end

function paths_all_budgets(s::BudgetedElementaryPathSolution{T}, max_budget::Int) where T
    if max_budget > budget(s.instance)
        @warn "The asked maximum budget $max_budget is higher than the instance budget $(budget(s.instance)). Therefore, some values have not been computed and are unavailable."
    end

    mb = min(max_budget, budget(s.instance))
    return Dict{Int, Vector{Edge{T}}}(
        budget => s.solutions[s.instance.instance.dst, budget] for budget in 0:mb)
end

function paths_all_budgets_as_tuples(s::BudgetedElementaryPathSolution{T}, max_budget::Int) where T
    if max_budget > budget(s.instance)
        @warn "The asked maximum budget $max_budget is higher than the instance budget $(budget(s.instance)). Therefore, some values have not been computed and are unavailable."
    end

    mb = min(max_budget, budget(s.instance))
    return Dict{Int, Vector{Tuple{T, T}}}(
        budget => [(src(e), dst(e)) for e in s.solutions[s.instance.instance.dst, budget]]
        for budget in 0:mb)
end
