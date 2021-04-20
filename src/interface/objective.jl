"""
    struct Minimise <: CombinatorialObjective end

Minimises the natural objective function for this combinatorial problem.
(Typically, it corresponds to the cost of the solution.)
"""
struct Minimise <: CombinatorialObjective end

"""
    struct Maximise <: CombinatorialObjective end

Maximises the natural objective function for this combinatorial problem.
(Typically, it corresponds to the cost of the solution.)
"""
struct Maximise <: CombinatorialObjective end
