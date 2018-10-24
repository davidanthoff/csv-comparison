using Pkg
pkg"activate ."

using DataFrames, CSVFiles, Dates, Printf

include("common.jl")

struct ShortFloat64
end

struct CatString
end

function getrandomcolumn(typ, rows, withna)
    if withna
        return [rand() > (1-missing_share) ? missing : rand(typ) for i=1:rows]
    else
        return rand(typ, rows)
    end
end

function getrandomcolumn(typ::Type{String}, rows, withna)
    if withna
        return [rand() > (1-missing_share) ? missing : string("test string ", rand(Int64)) for r in 1:rows]
    else
        return [string("test string ", rand(Int64)) for r in 1:rows]
    end
end

function getrandomcolumn(typ::Type{CatString}, rows, withna)
    n = Int(round(rows * 0.02))

    vals = [string("test string ", rand(Int64)) for v in 1:n]

    if withna
        return [rand() > (1-missing_share) ? missing : vals[rand(1:n)] for r in 1:rows]
    else
        return [vals[rand(1:n)] for r in 1:rows]
    end
end

function getrandomcolumn(typ::Type{ShortFloat64}, rows, withna)
    if withna
        return [rand() > (1-missing_share) ? missing : @sprintf("%.4f", rand(Float64)) for r in 1:rows]
    else
        return [@sprintf("%.4f", rand(Float64)) for r in 1:rows]
    end
end

function getrandomcolumn(typ::Type{DateTime}, rows, withna)
    if withna
        return [rand() > (1-missing_share) ? missing : DateTime(rand(1950:2000), rand(1:12), rand(1:28), rand(1:23), rand(1:59), rand(1:50)) for r in 1:rows]
    else
        return [DateTime(rand(1950:2000), rand(1:12), rand(1:28), rand(1:23), rand(1:59), rand(1:50)) for r in 1:rows]
    end
end

function write_uniform_csv(typ, rows, cols, withna)
    mkpath(ourpath(rows, cols, withna))
    filename = string("uniform_data_", lowercase(string(typ)), ".csv")
    DataFrame([getrandomcolumn(typ, rows, withna) for c in 1:cols], [Symbol("col", c) for c in 1:cols]) |> save(joinpath(ourpath(rows, cols, withna), filename), nastring="")
end

function write_mixed_csv(rows, cols, filename, types, withna)
    mkpath(ourpath(rows, cols, withna))
    col_types = Iterators.take(Iterators.cycle(types), cols)
    DataFrame([getrandomcolumn(typ, rows, withna) for typ in col_types],
              [Symbol("col", c) for c in 1:cols]) |>
              save(joinpath(ourpath(rows, cols, withna), filename), nastring="")
end

for n in ns, c in cs, withna in [true,false]
    write_uniform_csv(DateTime, n, c, withna)
    write_uniform_csv(String, n, c, withna)
    write_uniform_csv(CatString, n, c, withna)
    write_uniform_csv(Int64, n, c, withna)
    write_uniform_csv(Float64, n, c, withna)
    write_uniform_csv(ShortFloat64, n, c, withna)
    write_mixed_csv(n, c, "mixed_data.csv", [Float64, Int64, String, DateTime, CatString], withna)
    write_mixed_csv(n, c, "mixed_data_shortfloat64.csv", [ShortFloat64, Int, String, DateTime, CatString], withna)
end
