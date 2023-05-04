using AllocationOpt
using SemioticOpt
using JSON3
using InvertedIndices

using Random
using StatsBase
import AllocationOpt: optimize

include("console_logger.jl")


function optimize(::Val{:optimal}, Ω, ψ, σ, K, Φ, Ψ, g, rixs)
    println("Gas: $g")
    println("Max Allocations: $K")

    # rixs = 1:length(Ω)

    # Only use the eligible subgraphs
    _Ω = @view Ω[rixs]
    _ψ = @view ψ[rixs]

    x = zeros(length(_ψ))
    sampleixs = sample(1:length(_ψ), rand(1:length(_ψ)), replace=false)
    x[sampleixs] .= rand(Float64, length(sampleixs))


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

    # Can't make any more swaps, so stop. Also assign the final value of x.
    function stop_full(a; kws...)
        v = length(kws[:z]) == length(SemioticOpt.nonzeroixs(kws[:z]))
        if v
            kws[:op](a, kws[:z])
        end
        return v
    end

    logger = VectorLogger(name="i", data=Int32[], f=(a; kws...) -> kws[:i])

    println("Initial number of nonzeros: $(AllocationOpt.nonzero(x) |> length)")

    alg = PairwiseGreedyOpt(;
        kmax=K,
        x=x,
        xinit=zeros(length(_ψ)),
        f=f,
        a=makeanalytic,
        hooks=[
            StopWhen((a; kws...) -> kws[:f](kws[:z]) ≥ kws[:f](SemioticOpt.x(a))),
            StopWhen(stop_full),
            logger,
            # ConsoleLogger(name="i", f=(a; kws...) -> kws[:i], frequency=5),
            # ConsoleLogger(name="fcurr", f=(a; kws...) -> -kws[:f](SemioticOpt.x(a)), frequency=1),
            # ConsoleLogger(name="fnew", f=(a; kws...) -> -kws[:f](kws[:z]), frequency=5),
            # ConsoleLogger(name="nnz", f=(a; kws...) -> AllocationOpt.nonzero(kws[:z]) |> length, frequency=5)
        ]
    )
    sol = minimize!(obj, alg)


    println("Iterations to converge: $(SemioticOpt.data(logger)[end])")

    _x[rixs, 1] .= SemioticOpt.x(sol)
    nonzeros[1] = _x[:, 1] |> AllocationOpt.nonzero |> length
    profits[:, 1] .= AllocationOpt.profit.(AllocationOpt.indexingreward.(_x[:, 1], Ω, ψ, Φ, Ψ), g)

    println("Number of nonzeros: $(nonzeros[end])")
    println("PGO Profit: $(profits[:, end] |> sum)")
    println()

    return _x, nonzeros, profits
end

function main()
    profits = Float64[]
    for _ ∈ 1:3
        AllocationOpt.main("config.toml")
    end
    return nothing
end
