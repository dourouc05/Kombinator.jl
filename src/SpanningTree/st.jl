struct SpanningTreeInstance{T} <: CombinatorialInstance
    graph::AbstractGraph{T}
    rewards::Dict{Edge{T}, Float64}
    objective::CombinatorialObjective

    function SpanningTreeInstance(graph::AbstractGraph{T}, rewards::Dict{Edge{T}, Float64}, objective::O=Maximise()) where {T <: Real, O <: CombinatorialObjective}
        return new{T, O}(graph, rewards, objective)
    end
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
    # instance::BudgetedSpanningTreeInstance{T, U}
    # tree::Vector{Edge{T}}
end

struct SimpleBudgetedSpanningTreeSolution{T, U} <: BudgetedSpanningTreeSolution{T, U}
    instance::BudgetedSpanningTreeInstance{T, U}
    tree::Vector{Edge{T}}

    function SimpleBudgetedSpanningTreeSolution(instance::BudgetedSpanningTreeInstance{T, U}, tree::Vector{Edge{T}}) where {T, U}
        return new{T, U}(instance, tree)
    end

    function SimpleBudgetedSpanningTreeSolution(instance::BudgetedSpanningTreeInstance{T, U}) where {T, U}
        # No feasible solution.
        return new{T, U}(instance, edgetype(instance.graph)[])
    end
end

struct BudgetedSpanningTreeLagrangianSolution{T, U} <: BudgetedSpanningTreeSolution{T, U}
    # Used to store important temporary results from solving the Lagrangian dual.
    instance::BudgetedSpanningTreeInstance{T, U}
    tree::Vector{Edge{T}}
    λ::Float64 # Optimum dual multiplier.
    value::Float64 # Optimum value of the dual problem (i.e. with penalised constraint).
    λmax::Float64 # No dual value higher than this is useful (i.e. they all yield the same solution).
end
