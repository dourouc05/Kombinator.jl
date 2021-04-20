# Define the algorithm types here, at the global level: some names might be shared by several algorithms. 
# This is also the reason why there is no supplementary abstraction layer (e.g. a base type for all 
# bipartite-matching algorithms).
# First, generic-named algorithms (dynamic, greedy, etc.); then, the ones with a recognised name (think Bellman-Ford). 
struct DynamicProgramming <: CombinatorialAlgorithm; end # When the DP algorithm has no more specific name exists, like Bellman-Ford
struct GreedyAlgorithm <: CombinatorialAlgorithm; end
struct LagrangianAlgorithm <: CombinatorialAlgorithm; end # Usually, for a crude approximation with no guarantee
struct LagrangianRefinementAlgorithm <: CombinatorialAlgorithm; end # Usually, for an approximation term
struct IteratedLagrangianRefinementAlgorithm <: CombinatorialAlgorithm; end # Usually, for a constant approximation ratio

struct BellmanFordAlgorithm <: CombinatorialAlgorithm; end
struct HungarianAlgorithm <: CombinatorialAlgorithm; end
struct PrimAlgorithm <: CombinatorialAlgorithm; end

struct DefaultLinearFormulation <: CombinatorialLinearFormulation; end

# The case of linear programming is usually a bit more complex: in some cases, there may be several formulations. 
struct LinearProgramming{T <: CombinatorialLinearFormulation} <: CombinatorialAlgorithm; end

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

  """
      linear_formulation(::CombinatorialInstance)

  Returns the default linear formulation for this combinatorial problem.
  """
  function linear_formulation(::CombinatorialInstance)
    return DefaultLinearFormulation()
  end