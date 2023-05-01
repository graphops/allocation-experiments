using AllocationOpt

function main()
    config = "config.toml" |> AllocationOpt.readconfig |> AllocationOpt.configuredefaults! |> AllocationOpt.formatconfig!
    
    # Read data
    i, a, s, n = AllocationOpt.read(config)

    # Write the data if it was queried rather than read from file
    isnothing(config["readdir"]) && AllocationOpt.write(i, a, s, n, config)
end