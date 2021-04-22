module Kombinator
# TODO: introduce a graph problem in the abstract hierarchy? Graph-related functions could be defined on it.
# TODO: document the generic functions.
# TODO: refactor the package further to remove the old st_prim()-like names? Only solve(::CombinatorialInstance, ::CombinatorialAlgorithm)::CombinatorialSolution should be used. At least, don't export all these names.
# TODO: rename matching to "perfect matching" and introduce "imperfect matching".
# TODO: add a note to rather use LightGraph's algorithms instead of these in this package for anything serious. 
# TODO: add a link to other packages like LightGraph for the corresponding algorithms, so that they seamlessly integrate with the others?
# TODO: how to add a link to functions like budgeted_msets_lp_select, budgeted_msets_lp_all? They can be quite useful (but do not bring much in terms of performance)

using DataStructures
using Hungarian
using JuMP
using LinearAlgebra
using LightGraphs
using Munkres
using Reexport

import Base: values
import LightGraphs: src, dst
import JuMP: value, solve

include("helpers.jl")

include("interface/instance.jl")
include("interface/objective.jl")
include("interface/algorithm.jl")
include("interface/variants.jl")

include("BipartiteMatching/matching.jl")
include("BipartiteMatching/matching_hungarian.jl")
include("BipartiteMatching/matching_dp.jl")
include("BipartiteMatching/matching_budgeted.jl")
include("BipartiteMatching/matching_budgeted_dp.jl")
include("BipartiteMatching/matching_budgeted_lagrangian.jl")

include("ElementaryPath/ep.jl")
include("ElementaryPath/ep_dp.jl")
include("ElementaryPath/ep_budgeted.jl")
include("ElementaryPath/ep_budgeted_dp.jl")

# Export all symbols. Code copied from JuMP.
symbols_to_exlude = [Symbol(@__MODULE__), :eval, :include]

for sym in names(@__MODULE__, all=true)
    sym_string = string(sym)
    if sym in symbols_to_exlude || startswith(sym_string, "_")
        continue
    end
    if !(Base.isidentifier(sym) || (startswith(sym_string, "@") && Base.isidentifier(sym_string[2:end])))
        continue
    end
    @eval export $sym
end

# Include internal extensions.
include("UniformMatroid/UniformMatroid.jl")
@reexport using .UniformMatroid
include("SpanningTree/SpanningTree.jl")
@reexport using .SpanningTree
include("ElementaryPath/ElementaryPath.jl")
@reexport using .ElementaryPath

end
