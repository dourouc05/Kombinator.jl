# ============================================================
# = First, generic-named algorithms (dynamic, greedy, etc.). =
# ============================================================

"""
    struct DynamicProgramming <: CombinatorialAlgorithm

Use dynamic programming to solve the instance. 

Some DP algorithms have a common name, such as `BellmanFordAlgorithm`.
"""
struct DynamicProgramming <: CombinatorialAlgorithm end

"""
    struct GreedyAlgorithm <: CombinatorialAlgorithm

Use a greedy algorithm to solve the instance. 

Some greedy algorithms have a common name, such as `PrimAlgorithm`.
"""
struct GreedyAlgorithm <: CombinatorialAlgorithm end

"""
    struct LagrangianAlgorithm <: CombinatorialAlgorithm

Use Lagrangian relaxation to solve the instance. This is especially useful 
to build an algorithm for a problem with a new constraint based on other 
algorithms. These techniques do not always yield good approximation guarantees.
"""
struct LagrangianAlgorithm <: CombinatorialAlgorithm end

"""
    struct LagrangianAlgorithm <: CombinatorialAlgorithm

Use Lagrangian relaxation to solve the instance, followed by a refinement step. 
This is especially useful to build an algorithm for a problem with a new 
constraint based on other algorithms. These techniques often yield an constant
additive approximation, based on Lagrangian relaxation.
"""
struct LagrangianRefinementAlgorithm <: CombinatorialAlgorithm end

"""
    struct LagrangianAlgorithm <: CombinatorialAlgorithm

Use Lagrangian relaxation to solve the instance, followed by a refinement step 
and more iterations as required. This is especially useful to build an algorithm 
for a problem with a new constraint based on other algorithms. These techniques 
often yield an constant multiplicative approximation, based on Lagrangian 
relaxation and refinement.
"""
struct IteratedLagrangianRefinementAlgorithm <: CombinatorialAlgorithm end

"""
    struct DefaultLinearFormulation <: CombinatorialAlgorithm

Use the default LP formulation to solve the instance. For problems where 
there are multiple common formulations, there should be no default formulation
defined. 
"""
struct DefaultLinearFormulation <: CombinatorialLinearFormulation end

# ===============================================================
# = Then, the ones with a recognised name (think Bellman-Ford). =
# ===============================================================

"""
    struct BellmanFordAlgorithm <: CombinatorialAlgorithm

Use the Bellman-Ford algorithm to solve the instance. Bellman-Ford is a special
case of dynamic programming. 

This algorithm is sometimes called the Bellman-Ford-Moore algorithm.
"""
struct BellmanFordAlgorithm <: CombinatorialAlgorithm end

"""
    struct HungarianAlgorithm <: CombinatorialAlgorithm

Use the Hungarian algorithm to solve the instance. 

This algorithm is sometimes called the Kuhn-Munkres algorithm.
"""
struct HungarianAlgorithm <: CombinatorialAlgorithm end

"""
    struct PrimAlgorithm <: CombinatorialAlgorithm

Use Prim's algorithm to solve the instance. Prim is a special case of greedy 
algorithm.
"""
struct PrimAlgorithm <: CombinatorialAlgorithm end

# ==============================================================
# = Functions about the approximation guarantees of algorithms =
# ==============================================================

"""
    approximation_ratio(::CombinatorialInstance, ::CombinatorialAlgorithm)

Returns the approximation ratio for this algorithm when run on the input instance. When the problem is minimising 
a function (e.g., finding the minimum-cost path), the ratio is defined as one constant ``r \\le 1.0``
(ideally, the lowest) such that 

``f(x^\\star) \\leq f(x) \\leq r \\cdot f(x^\\star),``

where ``f(x^\\star)`` is the cost of the optimum solution and ``f(x)`` the one of the returned solution. On the 
contrary, for a maximisation problem, the definition is reversed (with ``r \\le 1.0``):

``r \\cdot f(x^\\star) \\geq f(x) \\geq f(x^\\star).``

For an exact algorithm, the ratio is always ``1.0``, for both minimisation and maximisation problems. 

The returned ratio might be constant, if the algorithm provides a constant ratio; if the ratio is not constant (i.e.
instance-dependent), it may either be a worst-case value or a truly instance-dependent ratio. Depending on the 
algorithm, this behaviour might be tuneable. 

If the algorithm has no guarantee, it should return `NaN`. 
"""
function approximation_ratio(::CombinatorialInstance, ::CombinatorialAlgorithm)
    return 1.0
end

"""
    approximation_term(::CombinatorialInstance, ::CombinatorialAlgorithm)

Returns the approximation term for this algorithm when run on the input instance. When the problem is minimising 
a function (e.g., finding the minimum-cost path), the term is defined as one constant ``t \\ge 0.0`` 
(ideally, the lowest) such that 

``f(x^\\star) \\leq f(x) \\leq f(x^\\star) + t,``

where ``f(x^\\star)`` is the cost of the optimum solution and ``f(x)`` the one of the returned solution. On the 
contrary, for a maximisation problem, the definition is reversed (with ``t \\ge 0.0``):

``f(x^\\star) \\leq f(x) \\leq f(x^\\star) - t.``

For an exact algorithm, the term is always ``0.0``, for both minimisation and maximisation problems. 

The returned term might be constant, if the algorithm provides a constant term; if the term is not constant (i.e.
instance-dependent), it may either be a worst-case value or a truly instance-dependent term. Depending on the 
algorithm, this behaviour might be tuneable. 

If the algorithm has no guarantee, it should return `NaN`. 
"""
function approximation_term(::CombinatorialInstance, ::CombinatorialAlgorithm)
    return 0.0
end
