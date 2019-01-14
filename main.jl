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

function run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, juliaversion, packagename, filename_for_label, script_filename)
    try
        for i in 1:samples
            run(`./EmptyStandbyList.exe`)
            t = if juliaversion==:julia_1_0
                parse(Float64, first(readlines(pipeline(`$jlbin --project=. $script_filename $warmup_filename $filename`, stderr="errs.txt", append=true))))
            elseif juliaversion==:julia_0_6
                t = parse(Float64, first(readlines(pipeline(`$jl06bin $script_filename $warmup_filename $filename`, stderr="errs.txt", append=true))))
            else
                error("Incorrect julia version specified.")
            end
            push!(df, (runid=runid, file=filename_for_label, rows=rows, cols=cols, withna=withna, package=packagename, sample=i, timing=t))
        end
    catch err
        @info err
    end

end

function read_specific_file(df, runid, rows, cols, withna, filename, samples)
    filename_for_label = filename
    warmup_filename = joinpath(ourpath(rows, cols, withna), "warmup_" * filename)
    filename = joinpath(ourpath(rows, cols, withna), filename)  

    if :textparse in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "TextParse.jl", filename_for_label, "textparse_script.jl")
    end

    if :csvfiles in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "CSVFiles.jl", filename_for_label, "csvfiles_script.jl")
    end

    if :textparse06 in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_0_6, "TextParse.jl; 0.6", filename_for_label, "textparse_julia06_script.jl")
    end

    if :csv06 in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_0_6, "CSV.jl; 0.6", filename_for_label, "csv_julia06_script.jl")
    end

    if :csv in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "CSV.jl", filename_for_label, "csv_script.jl")
    end

    if :dataframes in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "DataFrames.jl", filename_for_label, "dataframes_script.jl")
    end    

    if :pandas in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "Pandas.jl", filename_for_label, "pandas_script.jl")
    end

    if :rfreads in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "R fread", filename_for_label, "rfreads_script.jl")
    end

    if :rfreadp in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "R fread parallel", filename_for_label, "rfreadp_script.jl")
    end

    if :rreadr in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "R readr", filename_for_label, "rreadr_script.jl")
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
