using Pkg
pkg"activate ."

using DataFrames, CSV, TextParse, CSVFiles, VegaLite, BenchmarkTools, Tables, Printf, RCall, Dates, Queryverse
import Pandas
include("common.jl")

const ns = [100, 10_000, 1_000_000];
const samples = 5;
const jl06bin = if Sys.iswindows()
    `C:\\Users\\david\\AppData\\Local\\Julia-0.6.4\\bin\\julia.exe`
elseif Sys.isapple()
    `/Applications/Julia-0.6.app/Contents/Resources/julia/bin/julia`
else
    error("OS not yet supported")
end

R"""
memory.limit(size=32000)
library(data.table)
library(readr)
options(readr.num_columns = 0)
""";

function read_specific_file(df, rows, withna, filename, samples)
    filename_for_label = filename
    filename = joinpath(ourpath(rows, withna), filename)
    
    t::Float64 = 0.
        
    csvread(filename)
    for i in 1:samples
        GC.gc(); GC.gc(); GC.gc()
        t = @elapsed csvread(filename)        
        push!(df, (file=filename_for_label, rows=rows, withna=withna, package="TextParse.jl", sample=i, timing=t))
    end

    DataFrame(load(filename))
    for i in 1:samples
        GC.gc(); GC.gc(); GC.gc()
        t = @elapsed DataFrame(load(filename))
        push!(df, (file=filename_for_label, rows=rows, withna=withna, package="CSVFiles.jl", sample=i, timing=t))
    end

    try
        ts = parse.(Float64, readlines(`$jl06bin textparsejulia06script.jl $filename $samples`))
        for (i,t) in enumerate(ts)
            push!(df, (file=filename_for_label, rows=rows, withna=withna, package="TextParse.jl; 0.6", sample=i, timing=t))
        end
    catch err
    end

    try
        ts = parse.(Float64, readlines(`$jl06bin csvjulia06script.jl $filename $samples`))
        for (i,t) in enumerate(ts)
            push!(df, (file=filename_for_label, rows=rows, withna=withna, package="CSV.jl; 0.6", sample=i, timing=t))
        end
    catch err
    end
    
    CSV.File(filename) |> DataFrame
    for i in 1:samples
        GC.gc(); GC.gc(); GC.gc()
        t = @elapsed CSV.File(filename) |> DataFrame
        push!(df, (file=filename_for_label, rows=rows, withna=withna, package="CSV.jl", sample=i, timing=t))
    end    
    
    Pandas.read_csv(filename)
    for i in 1:samples
        GC.gc(); GC.gc(); GC.gc()
        t = @elapsed Pandas.read_csv(filename)
        push!(df, (file=filename_for_label, rows=rows, withna=withna, package="Pandas.jl", sample=i, timing=t))
    end
    
    R"""
        fread($filename, nThread=1)
    """
    for i in 1:samples
        t = convert(Float64, R"""
            start_time = Sys.time()
            fread($filename, nThread=1)
            end_time = Sys.time()
            elap = end_time - start_time
            """)    
        push!(df, (file=filename_for_label, rows=rows, withna=withna, package="R fread", sample=i, timing=t))
    end
    
    
    R"""
        fread($filename, nThread=15)
    """
    for i in 1:samples
        t = convert(Float64, R"""
            start_time = Sys.time()
            fread($filename, nThread=15)
            end_time = Sys.time()
            elap = end_time - start_time
            """)    
            push!(df, (file=filename_for_label, rows=rows, withna=withna, package="R fread parallel", sample=i, timing=t))
    end
        
    R"""
        suppressMessages(read_csv($filename, progress = FALSE))
    """
    for i in 1:samples
        t = convert(Float64, R"""
            start_time = Sys.time()
            suppressMessages(read_csv($filename, progress = FALSE))
            end_time = Sys.time()
            elap = end_time - start_time
            """)    
            push!(df, (file=filename_for_label, rows=rows, withna=withna, package="R readr", sample=i, timing=t))
    end    
    
    nothing
end

df = DataFrame(file=String[], rows=Int[], withna=Bool[], package=String[], sample=Int[], timing=Float64[])

for n in ns, withna in [true, false]
    for filename in filter(i->endswith(i, ".csv"), readdir(ourpath(n, withna)))
        @info "$filename, n=$n, withna=$withna"
        read_specific_file(df, n, withna, filename, samples)
    end
end

output_folder_name = joinpath("output", replace("run_$(now())", ":" => "_"))
mkdir(output_folder_name)

df |> save(joinpath(output_folder_name, "timings.csv"))

df |>
@filter(!_.withna) |>
@vlplot(facet={row={field=:file, typ=:nominal, title=nothing}, column={field=:rows, typ=:ordinal}}, resolve={scale={x=:independent}}, title="Without missing data") +
    (
        @vlplot(y={"package:n", title=nothing}, resolve={scale={x=:shared}}) +
        @vlplot(:bar,  x={"min(timing)", title="seconds"}, color=:package) +
        @vlplot(:rule, x="min(timing)", x2="max(timing)") +
        @vlplot(:tick, x=:timing)
    ) |>
@tee(save(joinpath(output_folder_name, "withoutna.pdf"))) |>
save(joinpath(output_folder_name, "withoutna.png"))

df |>
@filter(_.withna) |>
@vlplot(facet={row={field=:file, typ=:nominal, title=nothing}, column={field=:rows, typ=:ordinal}}, resolve={scale={x=:independent}}, title="With missing data") +
    (
        @vlplot(y={"package:n", title=nothing}, resolve={scale={x=:shared}}) +
        @vlplot(:bar,  x={"min(timing)", title="seconds"}, color=:package) +
        @vlplot(:rule, x="min(timing)", x2="max(timing)") +
        @vlplot(:tick, x=:timing)
    ) |>
@tee(save(joinpath(output_folder_name, "withna.pdf"))) |>
save(joinpath(output_folder_name, "withna.png"))
