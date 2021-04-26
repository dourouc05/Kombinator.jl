struct SpanningTreeInstance{T <: Real, O <: CombinatorialObjective} <: CombinatorialInstance
    graph::AbstractGraph{T}
    rewards::Dict{Edge{T}, Float64}
    objective::O

    function SpanningTreeInstance(graph::AbstractGraph{T}, rewards::Dict{Edge{T}, Float64}, objective::O=Maximise()) where {T <: Real, O <: CombinatorialObjective}
        return new{T, O}(graph, rewards, objective)
    end
end

function dimension(i::SpanningTreeInstance{T}) where T
    return ne(i.graph)
end

function reward(i::SpanningTreeInstance{T}, e::Edge{T}) where T
    if e in keys(i.rewards)
        return i.rewards[e]
    end
    return i.rewards[reverse(e)]
end

struct SpanningTreeSolution{T, O} <: CombinatorialSolution
    instance::SpanningTreeInstance{T, O}
    tree::Vector{Edge{T}}
end

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
