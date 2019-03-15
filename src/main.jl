using Pkg
pkg"activate ./.."

using Printf, Dates, Queryverse
include("common.jl")

const tests_to_run = [:textparse, :csvfiles, :textparse06, :csv, :csv06, :pandas, :rfreads, :rfreadp, :rreadr, :dataframes, :tablereaders, :csvreader, :pythonpandas, :pythonarrow]

runid = "master"

const jl06bin = if Sys.iswindows()
    `$(joinpath(homedir(), "AppData", "Local", "Julia-0.6.4", "bin", "julia.exe"))`
elseif Sys.isapple()
    `/Applications/Julia-0.6.app/Contents/Resources/julia/bin/julia`
else
    `julia-0.6`
end

const jlbin = if Sys.iswindows()
    `$(joinpath(homedir(), "AppData", "Local", "Julia-1.1.0", "bin", "julia.exe"))`
elseif Sys.isapple()
    `/Applications/Julia-1.1.app/Contents/Resources/julia/bin/julia`
else
    `julia`
end

const rbin = joinpath(ENV["R_HOME"], "bin", Sys.iswindows() ? "RScript.exe" : "RScript")

const platform = Sys.iswindows() ? "Windows" : Sys.isapple() ? "MacOS" : Sys.islinux() ? "Linux" : "Unknown"

function run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, runtime, packagename, filename_for_label, script_filename)
    try
        for i in 1:samples
            if Sys.iswindows()
                run(`$(joinpath(@__DIR__, "..", "deps", "EmptyStandbyList.exe"))`)
            elseif Sys.isapple()
                run(`sudo purge`)
            elseif Sys.islinux()
                run(`sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'`)
            end
            t1 = 0.0
            t2 = 0.0
            t3 = 0.0
            if runtime==:julia_1_0
                timings_as_string = readlines(pipeline(`$jlbin --project=. $(joinpath("packagescripts", script_filename)) $warmup_filename $filename`, stderr="errs.txt", append=true))
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
            elseif runtime==:julia_0_6
                timings_as_string = readlines(pipeline(`$jl06bin $(joinpath("packagescripts", script_filename)) $warmup_filename $filename`, stderr="errs.txt", append=true))
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
            elseif runtime==:r_project
                timings_as_string = readlines(pipeline(`$rbin --vanilla $(joinpath("packagescripts", script_filename)) $warmup_filename $filename`, stderr="errs.txt", append=true))
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
            elseif runtime==:python
                timings_as_string = readlines(pipeline(`python $(joinpath("packagescripts", script_filename)) $warmup_filename $filename`, stderr="errs.txt", append=true))
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
            else
                error("Incorrect julia version specified.")
            end
            push!(df, (runid=runid, attempt = :warmup, file=filename_for_label, rows=rows, cols=cols, withna=withna, package=packagename, sample=i, timing=t1))
            push!(df, (runid=runid, attempt = :first, file=filename_for_label, rows=rows, cols=cols, withna=withna, package=packagename, sample=i, timing=t2))
            push!(df, (runid=runid, attempt = :second, file=filename_for_label, rows=rows, cols=cols, withna=withna, package=packagename, sample=i, timing=t3))
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

    if :tablereaders in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "TableReaders.jl", filename_for_label, "tablereaders_script.jl")
    end

    if :csvreader in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "CSVReader.jl", filename_for_label, "csvreader_script.jl")
    end

    if :pandas in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_0, "Pandas.jl", filename_for_label, "pandas_script.jl")
    end

    if :rfreads in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :r_project, "R fread", filename_for_label, "rfreads_script.R")
    end

    if :rfreadp in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :r_project, "R fread parallel", filename_for_label, "rfreadp_script.R")
    end

    if :rreadr in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :r_project, "R readr", filename_for_label, "rreadr_script.R")
    end

    if :pythonpandas in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :python, "Python Pandas", filename_for_label, "python_pandas_script.py")
    end

    if :pythonarrow in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :python, "Python Arrow", filename_for_label, "python_arrow_script.py")
    end

    nothing
end

df = DataFrame(runid=String[], attempt=Symbol[], file=String[], rows=Int[], cols=Int[], withna=Bool[], package=String[], sample=Int[], timing=Float64[])

for n in ns, c in cs, withna in [true, false]
    for filename in filter(i->endswith(i, ".csv") && !startswith(i, "warmup"), readdir(ourpath(n, c, withna)))
        @info "$filename, n=$n, c=$c, withna=$withna"
        read_specific_file(df, runid, n, c, withna, filename, samples)
    end
end

experiment_date = now()

output_folder_name = joinpath(@__DIR__, "..", "output", replace("run_$experiment_date", ":" => "_"))
mkpath(output_folder_name)

df[:platform] = platform
df[:experiment_date] = experiment_date

df |> save(joinpath(output_folder_name, "timings.csv"))

for c in cs
    df |>
    @filter(_.attempt==:first) |>
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
    @filter(_.attempt==:first) |>
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
