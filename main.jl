using Pkg
pkg"activate ."

using CSV, TextParse, Tables, Printf, RCall, Dates, Queryverse
import Pandas
include("common.jl")

const tests_to_run = [:textparse, :csvfiles, :textparse06, :csv, :csv06, :pandas, :rfreads, :rfreadp, :rreadr]

runid = "master"

const jl06bin = if Sys.iswindows()
    `$(joinpath(homedir(), "AppData", "Local", "Julia-0.6.4", "bin", "julia.exe"))`
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

function read_specific_file(df, runid, rows, cols, withna, filename, samples)
    filename_for_label = filename
    filename = joinpath(ourpath(rows, cols, withna), filename)

    t::Float64 = 0.

    if :textparse in tests_to_run
        csvread(filename)
        for i in 1:samples
            GC.gc(); GC.gc(); GC.gc()
            t = @elapsed csvread(filename)
            push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="TextParse.jl", sample=i, timing=t))
        end
    end

    if :csvfiles in tests_to_run
        DataFrame(load(filename))
        for i in 1:samples
            GC.gc(); GC.gc(); GC.gc()
            t = @elapsed DataFrame(load(filename))
            push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="CSVFiles.jl", sample=i, timing=t))
        end
    end

    if :textparse06 in tests_to_run
        try
            ts = parse.(Float64, readlines(`$jl06bin textparsejulia06script.jl $filename $samples`))
            for (i,t) in enumerate(ts)
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="TextParse.jl; 0.6", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :csv06 in tests_to_run
        try
            ts = parse.(Float64, readlines(`$jl06bin csvjulia06script.jl $filename $samples`))
            for (i,t) in enumerate(ts)
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="CSV.jl; 0.6", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :csv in tests_to_run
        CSV.File(filename) |> DataFrame
        for i in 1:samples
            GC.gc(); GC.gc(); GC.gc()
            t = @elapsed CSV.File(filename) |> DataFrame
            push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="CSV.jl", sample=i, timing=t))
        end
    end

    if :pandas in tests_to_run
        Pandas.read_csv(filename)
        for i in 1:samples
            GC.gc(); GC.gc(); GC.gc()
            t = @elapsed Pandas.read_csv(filename)
            push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="Pandas.jl", sample=i, timing=t))
        end
    end

    if :rfreads in tests_to_run
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
            push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="R fread", sample=i, timing=t))
        end
    end


    if :rfreadp in tests_to_run
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
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="R fread parallel", sample=i, timing=t))
        end
    end

    if :rreadr in tests_to_run
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
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="R readr", sample=i, timing=t))
        end
    end

    nothing
end

df = DataFrame(runid=String[], file=String[], rows=Int[], cols=Int[], withna=Bool[], package=String[], sample=Int[], timing=Float64[])

for n in ns, c in cs, withna in [true, false]
    for filename in filter(i->endswith(i, ".csv"), readdir(ourpath(n, c, withna)))
        @info "$filename, n=$n, c=$c, withna=$withna"
        read_specific_file(df, runid, n, c, withna, filename, samples)
    end
end

output_folder_name = joinpath("output", replace("run_$(now())", ":" => "_"))
mkpath(output_folder_name)

df |> save(joinpath(output_folder_name, "timings.csv"))

for c in cs
    df |>
    @filter(!_.withna && _.cols == c) |>
    @vlplot(facet={row={field=:file, typ=:nominal, title=nothing}, column={field=:rows, typ=:ordinal}}, resolve={scale={x=:independent}}, title="Without missing data ($c columns)", background=:white) +
        (
            @vlplot(y={"package:n", title=nothing}, resolve={scale={x=:shared}}) +
            @vlplot(:bar,  x={"min(timing)", title="seconds"}, color=:package) +
            @vlplot(:rule, x="min(timing)", x2="max(timing)") +
            @vlplot(:tick, x=:timing)
        ) |>
    @tee(save(joinpath(output_folder_name, "cols_$(c)_withoutna.pdf"))) |>
    save(joinpath(output_folder_name, "cols_$(c)_withoutna.png"))

    df |>
    @filter(_.withna && _.cols == c) |>
    @vlplot(facet={row={field=:file, typ=:nominal, title=nothing}, column={field=:rows, typ=:ordinal}}, resolve={scale={x=:independent}}, title="With missing data ($c columns)", background=:white) +
        (
            @vlplot(y={"package:n", title=nothing}, resolve={scale={x=:shared}}) +
            @vlplot(:bar,  x={"min(timing)", title="seconds"}, color=:package) +
            @vlplot(:rule, x="min(timing)", x2="max(timing)") +
            @vlplot(:tick, x=:timing)
        ) |>
    @tee(save(joinpath(output_folder_name, "cols_$(c)_withna.pdf"))) |>
    save(joinpath(output_folder_name, "cols_$(c)_withna.png"))
end
