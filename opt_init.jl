using AllocationOpt
using SemioticOpt
using JSON3
using InvertedIndices
using Random

import AllocationOpt: optimize
import SemioticOpt: bestswap

include("console_logger.jl")

function optimize(::Val{:optimal}, Ω, ψ, σ, K, Φ, Ψ, g, rixs)

    rixs = 1:length(Ω)

    K = length(Ω)

    # Only use the eligible subgraphs
    _Ω = @view Ω[rixs]
    _ψ = @view ψ[rixs]

    _xopt = AllocationOpt.optimizeanalytic(_Ω, _ψ, σ)

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

    alg = PairwiseGreedyOpt(;
        kmax=K,
        x=_xopt,
        xinit=_xopt,
        f=f,
        a=makeanalytic,
        hooks=[
            StopWhen((a; kws...) -> kws[:f](kws[:z]) ≥ kws[:f](SemioticOpt.x(a)) && length(SemioticOpt.nonzeroixs(SemioticOpt.x(a))) ≤ SemioticOpt.kmax(a)),
            StopWhen(stop_full),
            # ConsoleLogger(name="f(x)", f=(a; kws...) -> -kws[:f](SemioticOpt.x(a)), frequency=1),
            # ConsoleLogger(name="f(z)", f=(a; kws...) -> -kws[:f](kws[:z]), frequency=1),
            # ConsoleLogger(name="k", f=(a; kws...) -> length(SemioticOpt.nonzeroixs(SemioticOpt.x(a))), frequency=1),
            # ConsoleLogger(name="kmax", f=(a; kws...) -> SemioticOpt.kmax(a), frequency=1),
            logger,
        ],
    )
    sol = minimize!(obj, alg)

    @show SemioticOpt.data(logger)[end]

    _x[rixs, 1] .= SemioticOpt.x(sol)
    nonzeros[1] = _x[:, 1] |> AllocationOpt.nonzero |> length
    profits[:, 1] .= AllocationOpt.profit.(AllocationOpt.indexingreward.(_x[:, 1], Ω, ψ, Φ, Ψ), g)

    @show nonzeros[end]

    _xopt = AllocationOpt.optimizeanalytic(_Ω, _ψ, σ)
    @show _xopt |> AllocationOpt.nonzero |> length
    @show AllocationOpt.profit.(AllocationOpt.indexingreward.(_xopt, _Ω, _ψ, Φ, Ψ), g) |> sum

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

function bestswap(xinit::AbstractVector{T}, supports::AbstractMatrix{<:Integer}, selection, f, fa) where {T<:Real}
    if isempty(supports)
        return xinit, selection(xinit)
    end

    # Pre-allocate
    npossibilities = size(supports, 2)
    xs = repeat(xinit, 1, npossibilities)
    os = zeros(npossibilities)

    # Compute optimal swap
    _ = map(eachcol(xs), eachcol(supports), 1:npossibilities) do x, support, i  # In-place so don't need to return or assign
        x[Not(support)] .= zero(T)
        v = SemioticOpt.swap!(x, support, f, fa)
        os[i] = selection(v)
        return nothing
    end

    # Find best objective value and return it and the corresponding vector
    o, ix = findmin(os)
    return xs[:, ix], o
end
