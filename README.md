# allocation-experiments

- [x] Random initialization versus x1 = 0. 
    - Same output?
    - Same time to converge? 
    - Same number of iterations?

    ```julia
    julia> include("zero_init.jl"); main()
    (SemioticOpt.data(logger))[end] = 52
    nonzeros[end] = 50
    (_xopt |> AllocationOpt.nonzero) |> length = 347
    AllocationOpt.profit.(AllocationOpt.indexingreward.(_xopt, _Ω, _ψ, Φ, Ψ), g) |> sum = 564769.1563178975
    profits = [548419.544944366]

    julia> include("opt_init.jl"); main()
    (SemioticOpt.data(logger))[end] = 1
    nonzeros[end] = 347
    (_xopt |> AllocationOpt.nonzero) |> length = 347
    AllocationOpt.profit.(AllocationOpt.indexingreward.(_xopt, _Ω, _ψ, Φ, Ψ), g) |> sum = 564769.1563178975
    profits = [564769.1563178975]

    julia> include("random_init.jl"); main()
    (SemioticOpt.data(logger))[end] = 52
    profits = [548419.544944366, 548419.544944366, 548419.544944366, 548419.544944366, 548419.544944366, 548419.544944366, 548419.544944366, 548419.544944366, 548419.544944366, 548419.544944366]
    ```
    
    Q: Is it strange that all random init converges to the same local minimum?
    
- [x] If x1 = Halpern output, does the algorithm progress? (If so, then we have anecdotal improvement evidence)

    ```julia
    julia> include("halpern_init.jl"); main()
    k = 341
    halpprofit = 564753.3465765668
    nhalp[ihalp] = 156
    (SemioticOpt.data(logger))[end] = 169
    profits = [564769.1563178975]
    ```
  
If there are multiple swaps for each iteration
- [ ] Brute force (on small problem) versus PGO. Same output? 