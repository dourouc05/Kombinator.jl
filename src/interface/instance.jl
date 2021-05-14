"""
    abstract type CombinatorialInstance

An instance of a combinatorial problem. An instance of this type only contains 
the data required to solve a problem (e.g., the weights, the costs), and no
solver-specific data.
"""
abstract type CombinatorialInstance end

"""
    abstract type CombinatorialObjective

A specific objective function for a combinatorial problem. In general, the 
objective is to either minimise or maximise the natural objective function, 
but more specific objectives can be provided with other subtypes.

Objects of type `CombinatorialObjective` are supposed to be given as arguments
when building a `CombinatorialInstance`. In any case, 
`objective(::CombinatorialInstance)` can be used to retrieve the objective of 
an instance.
"""
abstract type CombinatorialObjective end

"""
    abstract type CombinatorialSolution

The solution returned by a solver when calling the `solve` function. 
This type should be specified for each combinatorial instance to have 
a unified solution type.

Two fields must be implemented: `instance` must be the instance that has been
solved, and `variables` must indicate the actual solution. `variables` can only
contain the discrete items that are chosen as part of the solution (i.e., the 
elements of this object can be used as indices for the rewards of a 
`CombinatorialInstance`). Solution objects can define more properties 
if needed.
"""
abstract type CombinatorialSolution end

"""
    abstract type CombinatorialAlgorithm

One specific combinatorial algorithm to solve an instance. Given as a parameter 
to `solve`, it specifies the way the instance should be solved. 

As often as possible, generic objects are provided with usual names (e.g., 
a greedy algorithm can be proposed for many different problems: the actual 
implementation will depend on the type of the combinatorial instance at hand).
"""
abstract type CombinatorialAlgorithm end

"""
    abstract type CombinatorialLinearFormulation

The base type for a linear formulation (LP, IP) for a given combinatorial
problem. The same problem might have several different formulations.
"""
abstract type CombinatorialLinearFormulation <: CombinatorialAlgorithm end

"""
    abstract type CombinatorialVariation

Variations of the base combinatorial set, e.g. to include other constraints.
A variation is an object that is built on top of a combinatorial instance
that contains all the required information for the supplementary constraints
"""
abstract type CombinatorialVariation <: CombinatorialInstance end

"""
    solve(i::CombinatorialInstance, algo::CombinatorialAlgorithm)

Solve the given combinatorial instance `i` using the provided algorithm
`algo` (potentially containing parameters for the solving process). The 
returned value is a `CombinatorialSolution`. 

If the requested algorithm is not available for this type of instance, 
a `MethodError` is thrown.
"""
function solve end

"""
    objective(i::CombinatorialInstance)

Returns the objective associated with this instance. 

By default, instances are supposed to provide an `objective` member, but this
function can be overridden otherwise (for instance, when only one objective
is supported).
"""
function objective(i::CombinatorialInstance)
    return i.objective
end

function objective(i::CombinatorialVariation)
    return objective(i.instance)
end

"""
    dimension(i::CombinatorialInstance)

Returns the dimension of this instance. 

All instances should implement this method.
"""
function dimension end # i::CombinatorialInstance

function dimension(i::CombinatorialVariation)
    return dimension(i.instance)
end

"""
    formulation(i::CombinatorialInstance, f::CombinatorialLinearFormulation)

Returns the LP formulation `f` for this combinatorial instance. It returns 
two arguments: 

- the JuMP model
- the decision variables

For `CombinatorialVariation`, it also returns a third argument: the 
supplementary constraint encoded by the `CombinatorialVariation` on top fo the 
`CombinatorialInstance`.
"""
function formulation end # i::CombinatorialInstance, f::CombinatorialLinearFormulation; solver=nothing

"""
    value(s::CombinatorialSolution)

Returns the value of a solution, i.e. its total reward. For a maximisation
problem, an infeasible solution has a `value` of `-Inf`.

    value(s::MinBudgetedSolution, budget::Int)

Returns the value of the solution corresponding to the given budget. This 
function is likely to throw an error for `SingleMinBudgetedSolution`, but is 
ensured not to for `MultipleMinBudgetedSolution`.
"""
function value(s::CombinatorialSolution)
    # TODO: define the `reward` interface and implement this in terms of the new interface. This will generalised the ST implementation.
    if -1 in s.variables || length(s.variables) == 0
        return -Inf
    end

    return sum(s.instance.rewards[i] for i in s.variables)
end

"""
    make_solution(::CombinatorialInstance, ::Dict{K, Float64}) where {K}

Creates a solution object of the right type for the given combinatorial 
instance. The dictionary gives the solution that should be included in the 
returned object. 

As only binary decision variables are supported, the caller of this function 
may provide a dictionary such that *either* only the variables that are 
included in the solution (i.e. `variable => 1.0` entries) *or* all the 
variables, with associated values of 0 (not in the solution) or 1
(in the solution). For instance, if the solution contains only the edge 
`1`-`2` out of the two possible edges (the other one being `1`-`3`), there are
two equivalent dictionaries that can be passed: either 
`Dict(Edge(1, 2) => 1.0)` or `Dict(Edge(1, 2) => 1.0, Edge(1, 3) => 0.0)`.
"""
function make_solution end # i::CombinatorialInstance, vals::Dict{K, Float64}
