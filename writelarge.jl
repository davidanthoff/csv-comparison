mkpath(joinpath(@__DIR__, "data", "large"))

open(joinpath(@__DIR__, "data", "large", "file1.csv"), "w") do f
    coln = 15
    rown = 100_000_000

    # Write header
    for c in 1:coln
        c>1 && print(f, ",")
        print(f, "col", c)
    end
    println(f)

    # Write data
    for r in 1:rown
        for c in 1:coln
            c>1 && print(f, ",")
            print(f, rand(Int))
        end
        println(f)
    end
end

open(joinpath(@__DIR__, "data", "large", "file2.csv"), "w") do f
    coln = 5
    rown = 1_000_000_000

    # Write header
    for c in 1:coln
        c>1 && print(f, ",")
        print(f, "col", c)
    end
    println(f)

    # Write data
    for r in 1:rown
        for c in 1:coln
            c>1 && print(f, ",")
            print(f, rand(Int))
        end
        println(f)
    end
end