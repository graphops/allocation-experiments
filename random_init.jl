using AllocationOpt
using SemioticOpt
using JSON3
using Random
using LinearAlgebra
using StatsBase
using InvertedIndices

import AllocationOpt: optimize, optimizek

function optimizek(::Val{:optimal}, x₀, Ω, ψ, σ, k, Φ, Ψ, g)

    println("k: $k")

    # Helper function to compute profit
    obj = x -> -AllocationOpt.profit.(AllocationOpt.indexingreward.(x, Ω, ψ, Φ, Ψ), g) |> sum

    # Function to get support for analytic optimisation
    f(x, ixs) = ixs

    # Set up optimizer
    function makeanalytic(x)
        return AllocationOpt.AnalyticOpt(;
            x=x, Ω=Ω, ψ=ψ, σ=σ, hooks=[StopWhen((a; kws...) -> kws[:i] > 1)]
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

    logger = VectorLogger(name="i", frequency=1, data=Int32[], f=(a; kws...) -> kws[:i])

    alg = PairwiseGreedyOpt(;
        kmax=k,
        x=x₀,
        xinit=x₀,
        f=f,
        a=makeanalytic,
        hooks=[
            StopWhen((a; kws...) -> kws[:f](kws[:z]) ≥ kws[:f](SemioticOpt.x(a))),
            StopWhen(stop_full),
            logger,
        ]
    )
    sol = minimize!(obj, alg)

    return floor.(SemioticOpt.x(sol); digits=1), SemioticOpt.data(logger)[end] - 1
end

function optimize(val::Val{:optimal}, Ω, ψ, σ, K, Φ, Ψ, g, rixs)


    # Helper function to compute profit
    f = x -> AllocationOpt.profit.(AllocationOpt.indexingreward.(x, Ω, ψ, Φ, Ψ), g)

    # Only use the eligible subgraphs
    _Ω = @view Ω[rixs]
    _ψ = @view ψ[rixs]

    v = zeros(length(ψ))
    _v = @view v[rixs]
    sampleixs = sample(1:length(_ψ), rand(1:length(_ψ)), replace=false)
    _v[sampleixs] .= rand(Float64, length(sampleixs))

    # Preallocate solution vectors for in-place operations
    x = Matrix{Float64}(undef, length(Ω), K)
    profits = zeros(length(Ω), K)
    # Nonzeros defaults to ones and not zeros because the optimiser will always find
    # at least one non-zero, meaning that the ones with zero profits will be filtered out
    # during reporting. In other words, this prevents the optimiser from reporting or
    # executing something that was never run.
    nonzeros = ones(Int32, K)

    counts = zeros(Int32, K)

    # Optimize
    @inbounds for k in 1:K
        x[:, k] .= k == 1 ? v : x[:, k-1]
        v, i = AllocationOpt.optimizek(val, x[rixs, k], _Ω, _ψ, σ, k, Φ, Ψ, g)
        x[rixs, k] .= v
        counts[k] = k == 1 ? i : counts[k-1] + i
        nonzeros[k] = x[:, k] |> AllocationOpt.nonzero |> length
        profits[:, k] .= f(x[:, k])
        # Early stoppping if converged
        if k > 1
            if norm(x[:, k] - x[:, k-1]) ≤ 0.1
                break
            end
        end
    end

    bestprofit, bestix = dropdims(sum(profits, dims=1); dims=1) |> findmax

    println("Gas: $g")
    println("Max Allocations: $K")

    println("PGO profit: $bestprofit")
    println("PGO nonzeros: $(nonzeros[bestix])")
    println("Iterations to Converge: $(counts[bestix])")

    return x, nonzeros, profits
end

function main()
    AllocationOpt.main("config.toml")
    return nothing
end
