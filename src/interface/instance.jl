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
abstract type CombinatorialLinearFormulation end

"""
    abstract type CombinatorialVariation

Variations of the base combinatorial set, e.g. to include other constraints.
A variation is an object that is built on top of a combinatorial instance
that contains all the required information for the supplementary constraints
"""
abstract type CombinatorialVariation end

"""
    function objective(i::CombinatorialInstance)

Returns the objective associated with this instance. 

By default, instances are supposed to provide an `objective` member, but this
function can be overridden otherwise (for instance, when only one objective
is supported).
"""
function objective(i::CombinatorialInstance)
end
