# TODO: better handling for nonlinear functions than an enumeration. Based on Convex.jl?
@enum NonlinearFunction begin
    SquareRoot
    Square
end

"""
    struct NonlinearCombinatorialInstance <: CombinatorialInstance

A nonlinear combinatorial-optimisation problem. Such a problem is built on top 
of a linear problem, `combinatorial_structure`, providing all the constants 
required for the problem (e.g., a graph); rewards from this object are ignored.
The optimisation sense is given by this object (i.e., minimise or maximise).

The nonlinearity is only contained in the nonlinear objective function, 
supposed to have the following expression: 

``a^T x + f(b^T x)``

where ``a`` is encoded as `linear_coefficients` and ``b`` as 
`nonlinear_coefficients`. The function `f` is indicated by 
`nonlinear_function`, currently a value of the enumeration `NonlinearFunction`.

`ε` is a parameter often used for nonlinear instances indicating the (additive)
precision at which the problem should be solved.
"""
struct NonlinearCombinatorialInstance <: CombinatorialInstance
    combinatorial_structure::CombinatorialInstance
    linear_coefficients::Union{Vector{Float64}, Dict{<:Any, Float64}}
    nonlinear_coefficients::Union{Vector{Float64}, Dict{<:Any, Float64}}
    nonlinear_function::NonlinearFunction
    # TODO: move these parameters to the specific algorithms (they are not really defining the problem to solve).
    ε::Float64 # Only for approximations.
    linear_algo::CombinatorialAlgorithm # Only for approximations.
    all_budgets_at_once::Bool # Only for approximation.
    formulation::CombinatorialLinearFormulation # Only for exact approach. Could be merged with linear_algo, but with a loss of precision in type (potentially useful for users).
end

abstract type NonlinearCombinatorialAlgorithm <: CombinatorialAlgorithm end
