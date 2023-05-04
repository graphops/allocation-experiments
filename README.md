# allocation-experiments

This repository documents experiments for the pairwise-greedy optimisation algorithm for the indexing allocation optimisation problem.
For now, see the [blog post](https://semiotic.ai/articles/indexer-allocation-optimisation/) for a description of the problem.

## Zeros Initialisation

In this experiment, we initialise PGO iterations with zeros.
We then report back both the profit and number of iterations it takes to converge.

In this initial experiment, we see that PGO successfully reaches the analytic optimum.

``` julia
julia> include("zero_init.jl"); main()
Gas: 0
Max Allocations: 341
Iterations to converge: 169
Number of nonzeros: 164
PGO Profit: 259934.0887313822
Analytic optimum nonzeros: 164
Analytic optimum profit: 259934.08873138228
```

If we decrease the max allocations, as expected, profit decreases

``` julia
julia> include("zero_init.jl"); main()
Gas: 0
Max Allocations: 100
Iterations to converge: 105
Number of nonzeros: 100
PGO Profit: 257541.37924125863
Analytic optimum nonzeros: 164
Analytic optimum profit: 259934.08873138228
```

If we increase gas enough, PGO outperforms analytic

``` julia
julia> include("zero_init.jl"); main()
Gas: 100
Max Allocations: 341
Iterations to converge: 106
Number of nonzeros: 102
PGO Profit: 247506.17506435083
Analytic optimum nonzeros: 164
Analytic optimum profit: 243534.08873138228
```

## Random Initialisations

In this set of experiments, we randomly initialise PGO's initial value, which determines the first set of swaps.

``` julia
julia> include("random_init.jl"); main()
Gas: 0
Max Allocations: 341
Initial number of nonzeros: 341
Iterations to converge: 2
Number of nonzeros: 164
PGO Profit: 259934.0887313822

Gas: 0
Max Allocations: 341
Initial number of nonzeros: 341
Iterations to converge: 2
Number of nonzeros: 164
PGO Profit: 259934.0887313822

Gas: 0
Max Allocations: 341
Initial number of nonzeros: 341
Iterations to converge: 2
Number of nonzeros: 164
PGO Profit: 259934.0887313822
```

If these all look identical, it's because, from the perspective of PGO, they are.
The initialisation of PGO doesn't matter so much as the support of the initialisation of PGO.
These all have identical supports.
A more interesting experiment would be to limit the length of the supports.

``` julia
julia> include("random_init.jl"); main()
Gas: 0
Max Allocations: 341
Initial number of nonzeros: 111
Iterations to converge: 111
Number of nonzeros: 164
PGO Profit: 259934.0887313822

Gas: 0
Max Allocations: 341
Initial number of nonzeros: 62
Iterations to converge: 129
Number of nonzeros: 164
PGO Profit: 259934.0887313822

Gas: 0
Max Allocations: 341
Initial number of nonzeros: 46
Iterations to converge: 146
Number of nonzeros: 164
PGO Profit: 259934.0887313822
```

The profit matches what we saw from *Zero Initialisation*.

We continue this experiment by limiting `max_allocations` as we did for *Zero Initialisation*

**TODO: For some reason, this runs super slowly. Need to investigate further. It consistently improved, but asymptotically.**

And similarly setting `gas`

``` julia
julia> include("random_init.jl"); main()
Gas: 100
Max Allocations: 341
Initial number of nonzeros: 215
Iterations to converge: 39
Number of nonzeros: 139
PGO Profit: 244968.7897643766

Gas: 100
Max Allocations: 341
Initial number of nonzeros: 254
Iterations to converge: 22
Number of nonzeros: 148
PGO Profit: 244601.89014100385

Gas: 100
Max Allocations: 341
Initial number of nonzeros: 129
Iterations to converge: 64
Number of nonzeros: 127
PGO Profit: 245923.27479783745
```

**This converges to different values. We need to understand this further.
As a reminder, for Zero Initialisation: PGO Profit: 247506.17506435083
**

## Halpern Initialisation

In this series of experiments we begin with the solution found using Halpern.

``` julia
julia> include("halpern_init.jl"); main()
Gas: 0
Max Allocations: 341
Halpern profit: 7625.694224963155
Halpern nonzeros: 1
Iterations to converge: 169
Number of nonzeros: 164
PGO Profit: 259934.0887313822
```

This turns out to be one of those situations in which Halpern performs quite badly and falls into a bad local optimum.

Limiting `max_allocations`

``` julia
julia> include("halpern_init.jl"); main()
Gas: 0
Max Allocations: 100
Halpern profit: 7625.694224963155
Halpern nonzeros: 1
Iterations to converge: 105
Number of nonzeros: 100
PGO Profit: 257541.37924125863
```

And now `gas`

``` julia
julia> include("halpern_init.jl"); main()
Gas: 100
Max Allocations: 341
Halpern profit: 7525.694224963155
Halpern nonzeros: 1
Iterations to converge: 106
Number of nonzeros: 102
PGO Profit: 247506.17506435083
```

## Opt Initialisation

Here we start from the analytic solution.

``` julia
julia> include("opt_init.jl"); main()
Gas: 0
Max Allocations: 341
Iterations to converge: 1
Number of nonzeros: 164
PGO Profit: 259934.0887313822
```

`max_allocations`

**TODO: Again, this runs prohibitively slowly.**

`gas`

``` julia
julia> include("opt_init.jl"); main()
Gas: 100
Max Allocations: 341
f(z): 243534.08873138228
k: 164
Iterations to converge: 1
Number of nonzeros: 164
PGO Profit: 243534.0887313822
```

