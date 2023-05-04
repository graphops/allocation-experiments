# allocation-experiments

- [x] Random initialization versus x1 = 0. 
    - Same output?
    - Same time to converge? 
    - Same number of iterations?

- [x] If x1 = Halpern output, does the algorithm progress? (If so, then we have anecdotal improvement evidence)

If there are multiple swaps for each iteration
- [ ] Brute force (on small problem) versus PGO. Same output? 

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

