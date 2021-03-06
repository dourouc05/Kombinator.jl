struct ElementaryPathInstance{T, O <: CombinatorialObjective} <:
       CombinatorialInstance
    graph::AbstractGraph{T}
    rewards::Dict{Edge{T}, Float64}
    src::T
    dst::T
    objective::O

    function ElementaryPathInstance(
        graph::AbstractGraph{T},
        rewards::Dict{Edge{T}, Float64},
        src::T,
        dst::T,
        objective::O=Maximise(),
    ) where {T <: Real, O <: CombinatorialObjective}
        # Source and destination vertices are allowable.
        if src < 0 || src > nv(graph)
            error("The requested source is not a vertex of the given graph.")
        end

        if dst < 0 || dst > nv(graph)
            error("The requested destination is not a vertex of the given " * 
                  "graph.")
        end

        # Source is different from destination.
        if dst == src
            error("The requested source and destination are the same vertex.")
        end

        # Each reward is associated to an existing edge.
        for e in keys(rewards)
            if e ∉ edges(graph)
                error("The edge $(e) has a reward, but is not present in the " * 
                      "graph.")
            end
        end

        # Return a new instance.
        return new{T, O}(graph, rewards, src, dst, objective)
    end
end

dimension(i::ElementaryPathInstance{T, O}) where {T, O} = ne(i.graph)

function copy(
    i::ElementaryPathInstance{T, O};
    graph::AbstractGraph{T}=i.graph,
    rewards::Dict{Edge{T}, Float64}=i.rewards,
    src::T=i.src,
    dst::T=i.dst,
    objective::CombinatorialObjective=i.objective,
) where {T, O <: CombinatorialObjective}
    return ElementaryPathInstance(graph, rewards, src, dst, objective)
end

# Solution.

struct ElementaryPathSolution{T, O <: CombinatorialObjective} <:
       CombinatorialSolution
    instance::ElementaryPathInstance{T, O}
    variables::Vector{Edge{T}}
    solutions::Dict{T, Vector{Edge{T}}}
end

function ElementaryPathSolution(
    instance::ElementaryPathInstance{T, O},
    variables::Vector{Edge{T}},
) where {T, O <: CombinatorialObjective}
    return ElementaryPathSolution(
        instance,
        variables,
        Dict{T, Vector{Edge{T}}}(),
    )
end

function make_solution(
    i::ElementaryPathInstance{T, O},
    path::Dict{Edge{T}, Float64},
) where {T, O}
    path_edges = Edge{T}[]
    for (k, v) in path
        if v >= 0.5
            push!(path_edges, k)
        end
    end

    return ElementaryPathSolution(i, path_edges)
end

# Budgeted solution.

struct BudgetedElementaryPathSolution{T, O} <: MultipleMinBudgetedSolution
    instance::MinimumBudget{ElementaryPathInstance{T, O}, T}
    variables::Vector{Edge{T}}
    solutions::Dict{Int, Vector{Edge{T}}}
end

function BudgetedElementaryPathSolution(
    instance::MinimumBudget{ElementaryPathInstance{T, O}, T},
    variables::Vector{Edge{T}},
) where {T, O <: CombinatorialObjective}
    return BudgetedElementaryPathSolution(
        instance,
        variables,
        Dict{Int, Vector{Edge{T}}}(),
    )
end

function make_solution(
    i::MinimumBudget{ElementaryPathInstance{T, O}, T},
    path::Dict{Edge{T}, Float64},
) where {T, O}
    path_edges = Edge{T}[]
    for (k, v) in path
        if v >= 0.5
            push!(path_edges, k)
        end
    end

    return BudgetedElementaryPathSolution(i, path_edges)
end

function _check_and_warn_budget_too_high(
    s::BudgetedElementaryPathSolution{T, O},
    max_budget::Int,
) where {T, O}
    if max_budget > s.instance.min_budget
        @warn "The requested maximum budget $max_budget is higher than the instance's minimum budget $(s.instance.min_budget). Therefore, some values have not been computed and are unavailable."
    end
end

function paths_all_budgets(
    s::BudgetedElementaryPathSolution{T, O},
    max_budget::Int,
) where {T, O}
    _check_and_warn_budget_too_high(s, max_budget)
    mb = min(max_budget, s.instance.min_budget)
    return Dict{Int, Vector{Edge{T}}}(
        budget => s.solutions[budget] for budget in 0:mb
    )
end

function paths_all_budgets_as_tuples(
    s::BudgetedElementaryPathSolution{T, O},
    max_budget::Int,
) where {T, O}
    _check_and_warn_budget_too_high(s, max_budget)
    mb = min(max_budget, s.instance.min_budget)
    return Dict{Int, Vector{Tuple{T, T}}}(
        budget => [(src(e), dst(e)) for e in s.solutions[budget]] for
        budget in 0:mb
    )
end
