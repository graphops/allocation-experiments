using AllocationOpt
using SemioticOpt
using JSON3
using LinearAlgebra
using Random

import AllocationOpt: optimize, optimizek

include("console_logger.jl")

function optimize(::Val{:optimal}, Ω, ψ, σ, K, Φ, Ψ, g, rixs)

    rixs = 1:length(Ω)

    xhalp, nhalp, phalp = AllocationOpt.optimize(Val(:fast), Ω, ψ, σ, K, Φ, Ψ, g, rixs)
    halpprofit, ihalp = findmax(col -> col |> sum, eachcol(phalp))
    xhalpopt = xhalp[:, ihalp]

    @show halpprofit
    @show nhalp[ihalp]

    # Only use the eligible subgraphs
    _Ω = @view Ω[rixs]
    _ψ = @view ψ[rixs]

    # Helper function to compute profit
    obj = x -> -AllocationOpt.profit.(AllocationOpt.indexingreward.(x, _Ω, _ψ, Φ, Ψ), g) |> sum

    # Preallocate solution vectors for in-place operations
    _x = zeros(length(ψ), 1)
    profits = Matrix{Float64}(undef, length(ψ), 1)
    nonzeros = Vector{Int32}(undef, 1)

    f(x, ixs) = ixs

    # Set up optimizer
    function makeanalytic(x)
        return AllocationOpt.AnalyticOpt(;
            x=x, Ω=_Ω, ψ=_ψ, σ=σ, hooks=[StopWhen((a; kws...) -> kws[:i] > 1)]
        )
    end

    logger = VectorLogger(name="i", data=Int32[], f=(a; kws...) -> kws[:i])
    clogger = ConsoleLogger(name="i", f=(a; kws...) -> kws[:i], frequency=1000)

    alg = PairwiseGreedyOpt(;
        kmax=K,
        x=zeros(length(_ψ)),
        xinit=xhalpopt[rixs],
        f=f,
        a=makeanalytic,
        hooks=[
            StopWhen((a; kws...) -> kws[:f](kws[:z]) ≥ kws[:f](SemioticOpt.x(a))),
            StopWhen(
                (a; kws...) -> length(kws[:z]) == length(SemioticOpt.nonzeroixs(kws[:z]))
            ),
            logger,
            clogger,
        ],
    )
    sol = minimize!(obj, alg)

    @show SemioticOpt.data(logger)[end]

    _x[rixs, 1] .= SemioticOpt.x(sol)
    nonzeros[1] = _x[:, 1] |> AllocationOpt.nonzero |> length
    profits[:, 1] .= AllocationOpt.profit.(AllocationOpt.indexingreward.(_x[:, 1], Ω, ψ, Φ, Ψ), g)

    return _x, nonzeros, profits
end

function main()
    profits = Float64[]
    AllocationOpt.main("config.toml")
    d = readlines("data/report.json") |> first |> JSON3.read |> copy
    push!(profits, d[:strategies][1][:profit])
    @show profits
    return nothing
end

"""
    optimizek(Ω, ψ, σ, k, Φ, Ψ)

Find the optimal `k` sparse vector given allocations of other indexers `Ω`, signals
`ψ`, available stake `σ`, new tokens issued `Φ`, and total signal `Ψ`.

```julia
julia> using AllocationOpt
julia> xopt = [2.5, 2.5]
julia> Ω = [1.0, 1.0]
julia> ψ = [10.0, 10.0]
julia> σ = 5.0
julia> k = 1
julia> Φ = 1.0
julia> Ψ = 20.0
julia> AllocationOpt.optimizek(xopt, Ω, ψ, σ, k, Φ, Ψ)
2-element Vector{Float64}:
 5.0
 0.0
```
"""
function optimizek(xopt, Ω, ψ, σ, k, Φ, Ψ)
    @show k
    clogger = ConsoleLogger(name="i", f=(a; kws...) -> kws[:i], frequency=1000)
    stoplogger = ConsoleLogger(name="stop", f=(a; kws...) -> norm(x(a) - kws[:z]), frequency=1000)

    projection = x -> gssp(x, k, σ)
    alg = ProjectedGradientDescent(;
        x=xopt,
        η=stepsize(AllocationOpt.lipschitzconstant(ψ, Ω)),
        hooks=[
            StopWhen((a; kws...) -> norm(x(a) - kws[:z]) < 1e-2),
            StopWhen((a; kws...) -> kws[:i] > 10000),
            HalpernIteration(; x₀=xopt, λ=i -> 1.0 / i),
            # clogger,
            # stoplogger,
        ],
        t=projection,
    )
    f = x -> AllocationOpt.indexingreward(x, ψ, Ω, Φ, Ψ)
    sol = minimize!(f, alg)
    return floor.(SemioticOpt.x(sol); digits=1)
end