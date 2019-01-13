using Pkg
pkg"activate ."

using Printf, Dates, Queryverse
include("common.jl")

const tests_to_run = [:textparse, :csvfiles, :textparse06, :csv, :csv06, :pandas, :rfreads, :rfreadp, :rreadr, :dataframes]


runid = "master"

const jl06bin = if Sys.iswindows()
    `$(joinpath(homedir(), "AppData", "Local", "Julia-0.6.4", "bin", "julia.exe"))`
elseif Sys.isapple()
    `/Applications/Julia-0.6.app/Contents/Resources/julia/bin/julia`
else
    error("OS not yet supported")
end

const jlbin = if Sys.iswindows()
    `$(joinpath(homedir(), "AppData", "Local", "Julia-1.0.3", "bin", "julia.exe"))`
elseif Sys.isapple()
    `/Applications/Julia-1.0.app/Contents/Resources/julia/bin/julia`
else
    error("OS not yet supported")
end

function read_specific_file(df, runid, rows, cols, withna, filename, samples)
    filename_for_label = filename
    warmup_filename = joinpath(ourpath(rows, cols, withna), "warmup_" * filename)
    filename = joinpath(ourpath(rows, cols, withna), filename)  

    t::Float64 = 0.

    if :textparse in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jlbin --project=. textparse_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="TextParse.jl", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :csvfiles in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jlbin --project=. csvfiles_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="CSVFiles.jl", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :textparse06 in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jl06bin textparse_julia06_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="TextParse.jl; 0.6", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :csv06 in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jl06bin csv_julia06_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="CSV.jl; 0.6", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :csv in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jlbin --project=. csv_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="CSV.jl", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :dataframes in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jlbin --project=. dataframes_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="DataFrames.jl", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end    

    if :pandas in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jlbin --project=. pandas_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="Pandas.jl", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :rfreads in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jlbin --project=. rfreads_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="R fread", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end


    if :rfreadp in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jlbin --project=. rfreadp_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="R fread parallel", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    if :rreadr in tests_to_run
        try
            for i in 1:samples
                run(`./EmptyStandbyList.exe`)
                t = parse(Float64, first(readlines(`$jlbin --project=. rreadr_script.jl $warmup_filename $filename`)))
                push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package="R readr", sample=i, timing=t))
            end
        catch err
            @info err
        end
    end

    nothing
end

df = DataFrame(runid=String[], file=String[], rows=Int[], cols=Int[], withna=Bool[], package=String[], sample=Int[], timing=Float64[])

for n in ns, c in cs, withna in [true, false]
    for filename in filter(i->endswith(i, ".csv") && !startswith(i, "warmup"), readdir(ourpath(n, c, withna)))
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
