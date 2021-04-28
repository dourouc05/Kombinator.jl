struct ElementaryPathInstance{T, O <: CombinatorialObjective} <: CombinatorialInstance
    graph::AbstractGraph{T}
    rewards::Dict{Edge{T}, Float64}
    src::T
    dst::T
    objective::O

    function ElementaryPathInstance(graph::AbstractGraph{T}, rewards::Dict{Edge{T}, Float64}, src::T, dst::T, objective::O=Maximise()) where {T <: Real, O <: CombinatorialObjective}
        # Error checking.
        if src < 0 || src > nv(graph)
          error("The requested source is not a vertex of the given graph.")
        end

        if dst < 0 || dst > nv(graph)
            error("The requested destination is not a vertex of the given graph.")
        end

        # TODO: check values of rewards?

        # Return a new instance.
        return new{T, O}(graph, rewards, src, dst, objective)
    end
end

dimension(i::ElementaryPathInstance{T, O}) where {T, O} = ne(i.graph)

function copy(i::ElementaryPathInstance{T, O}; graph::AbstractGraph{T}=i.graph, rewards::Dict{Edge{T}, Float64}=i.rewards, src::T=i.src, dst::T=i.dst, objective::CombinatorialObjective=i.objective) where {T, O <: CombinatorialObjective}
    return ElementaryPathInstance(graph, rewards, src, dst, objective)
end

# Solution.

struct ElementaryPathSolution{T, O <: CombinatorialObjective} <: CombinatorialInstance
    instance::ElementaryPathInstance{T, O}
    path::Vector{Edge{T}}
    states::Dict{T, Float64}
    solutions::Dict{T, Vector{Edge{T}}}
end

function ElementaryPathSolution(instance::ElementaryPathInstance{T, O}, path::Vector{Edge{T}}) where {T, O <: CombinatorialObjective}
    return ElementaryPathSolution(instance, path, Dict{T, Float64}(), Dict{T, Vector{Edge{T}}}())
end

function create_solution(i::ElementaryPathInstance{T, O}, path::Dict{Edge{T}, Float64}) where {T, O}
    path_edges = Edge{T}[]
    for (k, v) in path
        if v >= 0.5
            push!(path_edges, k)
        end
    end

    return ElementaryPathSolution(i, path_edges)
end

# Budgeted solution.

struct BudgetedElementaryPathSolution{T, O} <: CombinatorialSolution
    instance::MinimumBudget{ElementaryPathInstance{T, O}, T}
    path::Vector{Edge{T}}
    states::Dict{Tuple{T, Int}, Float64}
    solutions::Dict{Tuple{T, Int}, Vector{Edge{T}}}
end

function BudgetedElementaryPathSolution(instance::MinimumBudget{ElementaryPathInstance{T, O}, T}, path::Vector{Edge{T}}) where {T, O <: CombinatorialObjective}
    return BudgetedElementaryPathSolution(instance, path, Dict{Tuple{T, Int}, Float64}(), Dict{Tuple{T, Int}, Vector{Edge{T}}}())
end

function create_solution(i::MinimumBudget{ElementaryPathInstance{T, O}, T}, path::Dict{Edge{T}, Float64}) where {T, O}
    path_edges = Edge{T}[]
    for (k, v) in path
        if v >= 0.5
            push!(path_edges, k)
        end
    end

    return BudgetedElementaryPathSolution(i, path_edges)
end

function _check_and_warn_budget_too_high(s::BudgetedElementaryPathSolution{T, O}, max_budget::Int) where {T, O}
    if max_budget > budget(s.instance)
        @warn "The requested maximum budget $max_budget is higher than the instance's minimum budget $(budget(s.instance)). Therefore, some values have not been computed and are unavailable."
    end
end

function paths_all_budgets(s::BudgetedElementaryPathSolution{T, O}, max_budget::Int) where {T, O}
    _check_and_warn_budget_too_high(s, max_budget)
    mb = min(max_budget, budget(s.instance))
    return Dict{Int, Vector{Edge{T}}}(
        budget => s.solutions[s.instance.instance.dst, budget] for budget in 0:mb)
end

function paths_all_budgets_as_tuples(s::BudgetedElementaryPathSolution{T, O}, max_budget::Int) where {T, O}
    _check_and_warn_budget_too_high(s, max_budget)
    mb = min(max_budget, budget(s.instance))
    return Dict{Int, Vector{Tuple{T, T}}}(
        budget => [(src(e), dst(e)) for e in s.solutions[s.instance.instance.dst, budget]]
        for budget in 0:mb)
end
