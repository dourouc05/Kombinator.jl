using Cbc
using Hungarian
using JuMP
using Kombinator
using LightGraphs
using Munkres
using Test

is_travis = "TRAVIS_JULIA_VERSION" in keys(ENV) || true
# TODO: need for optional dependencies for this to work, I suppose.
# https://github.com/JuliaLang/Pkg.jl/issues/1285
if ! is_travis
    using JuMP
    # Why Gurobi?
    # - Need support for lazy constraints (elementary paths):
    #   - Mosek does not support them
    # - Need support for MISOCP
    #   - Pajarito is not yet ported to MOI
    using Gurobi
end

@testset "Kombinator.jl" begin
    include("um.jl")
    include("st.jl")
    include("ep.jl")
    # include("matching.jl")

    include("nlcop.jl")
end
