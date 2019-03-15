using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))"

using Dates, Printf, ProgressMeter, Random

include("common.jl")

function write_file(col_types, rown, withna, filename; make_warmup_copy=true, folder_path=nothing)
    coln = length(col_types)
    if folder_path===nothing
        folder_path = ourpath(rown, coln, withna)
    end
    file_path = joinpath(folder_path, filename)
    warmup_file_path = joinpath(folder_path, "warmup_" * filename)
    mkpath(folder_path)
    open(file_path, "w") do f   
        # Write header
        for c in 1:coln
            c>1 && print(f, ",")
            print(f, "col", c)
        end
        println(f)
    
        # Write data
        @showprogress for r in 1:rown
            for c in 1:coln
                c>1 && print(f, ",")
                if col_types[c] == :float64
                    if !withna || rand(Bool)
                        print(f, rand(Float64))
                    end
                elseif col_types[c] == :shortfloat64
                    if !withna || rand(Bool)
                        print(f, @sprintf("%.4f", rand(Float64)))
                    end
                elseif col_types[c] == :int64
                    if !withna || rand(Bool)
                        print(f, rand(Int64))
                    end
                elseif col_types[c] == :datetime
                    if !withna || rand(Bool)
                        print(f, DateTime(rand(1950:2000), rand(1:12), rand(1:28), rand(1:23), rand(1:59), rand(1:50)))
                    end
                elseif col_types[c] == :string
                    if !withna || rand(Bool)
                        print(f, '"', randstring(20), '"')
                    end
                elseif col_types[c] == :catstring
                    if !withna || rand(Bool)
                        print(f, '"', "Categorical string ", rand(1:5), '"')
                    end
                elseif col_types[c] == :escapedstring
                    if !withna || rand(Bool)
                        print(f, '"', randstring(20), "\"\"", randstring(10), '"')
                    end
                end
            end
            println(f)
        end
    end
    make_warmup_copy && cp(file_path, warmup_file_path)
end

uniform_types = [:float64, :shortfloat64, :int64, :datetime, :string, :catstring, :escapedstring]

for n in ns, c in cs, withna in [true,false]    
    println("Writing rows=$n, columns=$c, withna=$withna")
    for typ in uniform_types
        println("    $typ")
        write_file(fill(typ, c), n, withna, string("uniform_", lowercase(string(typ)), ".csv"))
    end
    println("    mixed")
    write_file(repeat([:float64, :shortfloat64, :int64, :datetime, :string, :catstring, :escapedstring], div(c, 7) + 1)[1:c], n, withna, "mixed.csv")
end

# write_file(fill(typ, 20), 40_000_000, true, "shortfloat64.csv", false, joinpath(@__DIR__, "..", "data", "large", "shortfloat64.csv"))

write_file(fill(:shortfloat64, 20), 10_000, true, "shortfloat64.csv", make_warmup_copy = false, folder_path = joinpath(@__DIR__, "..", "data", "large"))
