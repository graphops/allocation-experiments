# allocation-experiments

This repository documents experiments for the pairwise-greedy optimisation algorithm for the indexing allocation optimisation problem.
For now, see the [blog post](https://semiotic.ai/articles/indexer-allocation-optimisation/) for a description of the problem.

## TL;DR

|              | Zeros     | Random    | Halpern   |
|--------------|-----------|-----------|-----------|
| g=0; K=341   | 259934.00 | 259934.00  | 259934.00 |
| g=0; K=100   | 257541.33 | 257541.33 | 257541.33 |
| g=100; K=341 | 247551.28 | 247551.28 | 247551.28 |

## Zeros Initialisation

In this experiment, we initialise PGO iterations with zeros.
We then report back both the profit and number of iterations it takes to converge.

In this initial experiment, we see that PGO successfully reaches the analytic optimum.

``` julia
julia> include("zero_init.jl"); main()
Gas: 0
Max Allocations: 341
PGO profit: 259934.00827489613
PGO nonzeros: 164
Iterations to Converge: 174
Analytic optimum nonzeros: 164
Analytic optimum profit: 259934.08873138228
```

If we decrease the max allocations, as expected, profit decreases

``` julia
julia> include("zero_init.jl"); main()
Gas: 0
Max Allocations: 100
PGO profit: 257541.33283827585
PGO nonzeros: 100
Iterations to Converge: 109
Analytic optimum nonzeros: 164
Analytic optimum profit: 259934.08873138228
```

If we increase gas enough, PGO outperforms analytic

``` julia
julia> include("zero_init.jl"); main()
Gas: 100
Max Allocations: 341
PGO profit: 247551.28467965583
PGO nonzeros: 102
Iterations to Converge: 111
Analytic optimum nonzeros: 164
Analytic optimum profit: 243534.08873138228
```

## Random Initialisation

In this set of experiments, we randomly initialise PGO's initial value, which determines the first set of swaps.

``` julia
julia> include("random_init.jl"); main()
Gas: 0
Max Allocations: 341
PGO profit: 259934.00827489613
PGO nonzeros: 164
Iterations to Converge: 174
```

The profit matches what we saw from *Zero Initialisation*.

We continue this experiment by limiting `max_allocations` as we did for *Zero Initialisation*

``` julia
julia> include("random_init.jl"); main()
Gas: 0
Max Allocations: 100
PGO profit: 257541.33283827585
PGO nonzeros: 100
Iterations to Converge: 109
```

And similarly setting `gas`

``` julia
julia> include("random_init.jl"); main()
Gas: 100
Max Allocations: 341
PGO profit: 247551.28467965583
PGO nonzeros: 102
Iterations to Converge: 111
```

## Halpern Initialisation

In this series of experiments we begin with the solution found using Halpern.

``` julia
julia> include("halpern_init.jl"); main()
Gas: 0
Max Allocations: 341
PGO profit: 259934.00827489613
PGO nonzeros: 164
Iterations to Converge: 174
Halpern profit: 7625.694224963155
Halpern nonzeros: 1
```

This turns out to be one of those situations in which Halpern performs quite badly and falls into a bad local optimum.

Limiting `max_allocations`

``` julia
julia> include("halpern_init.jl"); main()
Gas: 0
Max Allocations: 100
PGO profit: 257541.33283827585
PGO nonzeros: 100
Iterations to Converge: 109
Halpern profit: 7625.694224963155
Halpern nonzeros: 1
```

And now `gas`

``` julia
julia> include("halpern_init.jl"); main()
Gas: 100
Max Allocations: 341
PGO profit: 247551.28467965583
PGO nonzeros: 102
Iterations to Converge: 111
Halpern profit: 7525.694224963155
Halpern nonzeros: 1
```
