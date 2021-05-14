struct SpanningTreeInstance{T <: Real, O <: CombinatorialObjective} <:
       CombinatorialInstance
    graph::AbstractGraph{T}
    rewards::Dict{Edge{T}, Float64}
    objective::O

    function SpanningTreeInstance(
        graph::AbstractGraph{T},
        rewards::Dict{Edge{T}, Float64},
        objective::O=Maximise(),
    ) where {T <: Real, O <: CombinatorialObjective}
        return new{T, O}(graph, rewards, objective)
    end
end

function dimension(i::SpanningTreeInstance{T, O}) where {T, O}
    return ne(i.graph)
end

function copy(
    i::SpanningTreeInstance{T, O};
    graph::AbstractGraph{T}=i.graph,
    rewards::Dict{Edge{T}, Float64}=i.rewards,
    objective::CombinatorialObjective=i.objective,
) where {T, O <: CombinatorialObjective}
    return SpanningTreeInstance(graph, rewards, objective)
end

function reward(i::SpanningTreeInstance{T}, e::Edge{T}) where {T}
    if e in keys(i.rewards)
        return i.rewards[e]
    end
    return i.rewards[reverse(e)]
end

fastest_exact(::SpanningTreeInstance) = PrimAlgorithm()

# Solution.

struct SpanningTreeSolution{T, O} <: CombinatorialSolution
    instance::SpanningTreeInstance{T, O}
    variables::Vector{Edge{T}}
end

function value(s::SpanningTreeSolution{T, O}) where {T <: Real, O}
    if -1 in s.variables || length(s.variables) == 0
        return -Inf
    end

    return sum(s.instance.rewards[(e in keys(s.instance.rewards)) ? e : reverse(e)] for e in s.variables)
end

function make_solution(
    i::SpanningTreeInstance{T, O},
    tree::Dict{Edge{T}, Float64},
) where {T, O}
    tree_edges = Edge{T}[]
    for (k, v) in tree
        if v >= 0.5
            push!(tree_edges, k)
        end
    end

    return SpanningTreeSolution(i, tree_edges)
end

# Budgeted solution.

struct SimpleBudgetedSpanningTreeSolution{T, U} <: SingleMinBudgetedSolution
    instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}
    variables::Vector{Edge{T}}

    function SimpleBudgetedSpanningTreeSolution(
        instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U},
        variables::Vector{Edge{T}},
    ) where {T, U}
        return new{T, U}(instance, variables)
    end

    function SimpleBudgetedSpanningTreeSolution(
        instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U},
    ) where {T, U}
        # No feasible solution.
        return new{T, U}(instance, edgetype(instance.instance.graph)[])
    end
end

struct BudgetedSpanningTreeLagrangianSolution{T, U} <: SingleMinBudgetedSolution
    # Used to store important temporary results from solving the Lagrangian dual.
    instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}
    variables::Vector{Edge{T}}
    λ::Float64 # Optimum dual multiplier.
    value::Float64 # Optimum value of the dual problem (i.e. with penalised constraint).
    λmax::Float64 # No dual value higher than this is useful (i.e. they all yield the same solution).
end

struct BudgetedSpanningTreeDynamicProgrammingSolution{T, U} <:
       MultipleMinBudgetedSolution
    # Used to store important temporary results from dynamic programming.
    instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}
    variables::Vector{Edge{T}}
    solutions::Dict{Int, Vector{Edge{T}}}
end

function make_solution(
    i::MinimumBudget{SpanningTreeInstance{T, O}, U},
    tree::Dict{Edge{T}, Float64},
) where {T, O, U}
    tree_edges = Edge{T}[]
    for (k, v) in tree
        if v >= 0.5
            push!(tree_edges, k)
        end
    end

    return SimpleBudgetedSpanningTreeSolution(i, tree_edges)
end
