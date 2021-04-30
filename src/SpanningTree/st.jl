struct SpanningTreeInstance{T <: Real, O <: CombinatorialObjective} <: CombinatorialInstance
    graph::AbstractGraph{T}
    rewards::Dict{Edge{T}, Float64}
    objective::O

    function SpanningTreeInstance(graph::AbstractGraph{T}, rewards::Dict{Edge{T}, Float64}, objective::O=Maximise()) where {T <: Real, O <: CombinatorialObjective}
        return new{T, O}(graph, rewards, objective)
    end
end

function dimension(i::SpanningTreeInstance{T, O}) where {T, O}
    return ne(i.graph)
end

function copy(i::SpanningTreeInstance{T, O}; graph::AbstractGraph{T}=i.graph, rewards::Dict{Edge{T}, Float64}=i.rewards, objective::CombinatorialObjective=i.objective) where {T, O <: CombinatorialObjective}
    return SpanningTreeInstance(graph, rewards, objective)
end

function reward(i::SpanningTreeInstance{T}, e::Edge{T}) where T
    if e in keys(i.rewards)
        return i.rewards[e]
    end
    return i.rewards[reverse(e)]
end

# Solution.

struct SpanningTreeSolution{T, O} <: CombinatorialSolution
    instance::SpanningTreeInstance{T, O}
    tree::Vector{Edge{T}}
end

function make_solution(i::SpanningTreeInstance{T, O}, tree::Dict{Edge{T}, Float64}) where {T, O}
    tree_edges = Edge{T}[]
    for (k, v) in tree
        if v >= 0.5
            push!(tree_edges, k)
        end
    end

    return SpanningTreeSolution(i, tree_edges)
end

# Budgeted solution.

abstract type BudgetedSpanningTreeSolution{T, U} <: CombinatorialSolution
    # instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}
    # tree::Vector{Edge{T}}
end

struct SimpleBudgetedSpanningTreeSolution{T, U} <: BudgetedSpanningTreeSolution{T, U}
    instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}
    tree::Vector{Edge{T}}

    function SimpleBudgetedSpanningTreeSolution(instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}, tree::Vector{Edge{T}}) where {T, U}
        return new{T, U}(instance, tree)
    end

    function SimpleBudgetedSpanningTreeSolution(instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}) where {T, U}
        # No feasible solution.
        return new{T, U}(instance, edgetype(instance.instance.graph)[])
    end
end

struct BudgetedSpanningTreeLagrangianSolution{T, U} <: BudgetedSpanningTreeSolution{T, U}
    # Used to store important temporary results from solving the Lagrangian dual.
    instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}
    tree::Vector{Edge{T}}
    λ::Float64 # Optimum dual multiplier.
    value::Float64 # Optimum value of the dual problem (i.e. with penalised constraint).
    λmax::Float64 # No dual value higher than this is useful (i.e. they all yield the same solution).
end

struct BudgetedSpanningTreeDynamicProgrammingSolution{T, U} <: BudgetedSpanningTreeSolution{T, U}
    # Used to store important temporary results from dynamic programming.
    instance::MinimumBudget{SpanningTreeInstance{T, Maximise}, U}
    tree::Vector{Edge{T}}
    states::Dict{Tuple{T, Int}, Float64}
    solutions::Dict{Tuple{T, Int}, Vector{Edge{T}}}
end

function make_solution(i::MinimumBudget{SpanningTreeInstance{T, O}, U}, tree::Dict{Edge{T}, Float64}) where {T, O, U}
    tree_edges = Edge{T}[]
    for (k, v) in tree
        if v >= 0.5
            push!(tree_edges, k)
        end
    end

    return SimpleBudgetedSpanningTreeSolution(i, tree_edges)
end
