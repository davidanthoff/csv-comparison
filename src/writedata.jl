using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using Dates, Printf, ProgressMeter, Random

include("common.jl")

largefile_coln = 20
space_per_row = 64 * 20 # 64 bit (for a Float64) times 20 columns
space_per_row = space_per_row / 8 / 1024 / 1024 / 1024 # Convert to GB
largefile_rown = convert(Int, round(10 / space_per_row)) # We want to use 10 GB for the results

if isfile(joinpath(@__DIR__), "local_writeconfig.jl")
    include("local_writeconfig.jl")
end

function our_copy(source, dest)
    if Sys.iswindows()
        readlines(`cmd /c copy $source $dest`)
    else
        readlines(`cp $source $dest`)
    end
end

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
                elseif col_types[c] == :float64short
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
                elseif col_types[c] == :stringcat
                    if !withna || rand(Bool)
                        print(f, '"', "Categorical string ", rand(1:5), '"')
                    end
                elseif col_types[c] == :stringescaped
                    if !withna || rand(Bool)
                        print(f, '"', randstring(20), "\"\"", randstring(10), '"')
                    end
                end
            end
            println(f)
        end
    end
    make_warmup_copy && our_copy(file_path, warmup_file_path)
end

uniform_types = [:float64, :float64short, :int64, :datetime, :string, :stringcat, :stringescaped]

for n in ns, c in cs, withna in [true,false]
    println("Writing rows=$n, columns=$c, withna=$withna")
    for typ in uniform_types
        println("    $typ")
        write_file(fill(typ, c), n, withna, string("uniform_", lowercase(string(typ)), ".csv"))
    end
    println("    mixed")
    write_file(repeat(uniform_types, div(c, length(uniform_types)) + 1)[1:c], n, withna, "mixed.csv")
end

write_file(fill(:float64, 20), largefile_rown, true, "float64.csv", make_warmup_copy = false, folder_path = joinpath(@__DIR__, "..", "data", "large"))
