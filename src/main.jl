using Pkg
Pkg.activate(joinpath(@__DIR__, ".."))

using Printf, Dates, Query, DataFrames, CSVFiles, VegaLite
include("common.jl")

tests_to_run = [
    :textparse,
    :csvfiles,
    :textparse06,
    :csv_single,
    :csv_copycols_single,
    :csv_parallel,
    :csv_copycols_parallel,
    :csv06,
    :csvreader,
    :tablereader,
    :pandas,
    :rfreads,
    :rfreadp,
    :rreadr,
    :dataframes,
    :pythonpandas,
    :pythonarrows,
    :pythonarrowp
]

runid = "master"

jl06bin = if Sys.iswindows()
    `$(joinpath(homedir(), "AppData", "Local", "Julia-0.6.4", "bin", "julia.exe"))`
elseif Sys.isapple()
    `/Applications/Julia-0.6.app/Contents/Resources/julia/bin/julia`
else
    `julia-0.6`
end

jlbin = joinpath(Sys.BINDIR, Base.julia_exename())

rbin = haskey(ENV, "R_HOME") ? joinpath(ENV["R_HOME"], "bin", Sys.iswindows() ? "RScript.exe" : "RScript") : Sys.iswindows() ? "RScript.exe" : "RScript"

pythonbin = "python"

platform = Sys.iswindows() ? "Windows" : Sys.isapple() ? "MacOS" : Sys.islinux() ? "Linux" : "Unknown"

if isfile(joinpath(@__DIR__), "local_config.jl")
    include("local_config.jl")
end

experiment_date = now()

output_folder_name = joinpath(@__DIR__, "..", "output", replace("run_$experiment_date", ":" => "_"))
mkpath(output_folder_name)

function run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, runtime, packagename, filename_for_label, script_filename)
    error_log_path = joinpath(output_folder_name, "errs.txt")

    open(error_log_path, "a") do f
        println(f)
        println(f, "NOW DOING $script_filename with runid=$runid, rows=$rows, cols=$cols, withna=$withna, filename=$filename, warmup_filename=$warmup_filename, samples=$samples, runtime=$runtime, packagename=$packagename, filename_for_label=$filename_for_label")
        println(f)
    end
    
    try
        for i in 1:samples
            if Sys.iswindows()
                path_to_esl = joinpath(@__DIR__, "..", "deps", "EmptyStandbyList.exe")
                run(`$path_to_esl`)
            elseif Sys.isapple()
                run(`sudo purge`)
            elseif Sys.islinux()
                run(`sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'`)
            end
            t1 = 0.0
            t2 = 0.0
            t3 = 0.0
            bytes1 = 0.0
            bytes2 = 0.0
            bytes3 = 0.0
            if runtime==:julia_1_single
                script_path = joinpath(@__DIR__, "packagescripts", script_filename)
                proj_env_path = joinpath(@__DIR__, "..")
                timings_as_string = readlines(pipeline(`$jlbin --startup-file=no --project=$proj_env_path $script_path $warmup_filename $filename`, stderr=error_log_path, append=true))
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
                bytes1 = parse(Float64, timings_as_string[4])
                bytes2 = parse(Float64, timings_as_string[5])
                bytes3 = parse(Float64, timings_as_string[6])
            elseif runtime==:julia_1_parallel
                script_path = joinpath(@__DIR__, "packagescripts", script_filename)
                proj_env_path = joinpath(@__DIR__, "..")
                timings_as_string = withenv("JULIA_NUM_THREADS"=>Sys.CPU_THREADS) do
                     return readlines(pipeline(`$jlbin --startup-file=no --project=$proj_env_path $script_path $warmup_filename $filename`, stderr=error_log_path, append=true))
                end
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
                bytes1 = parse(Float64, timings_as_string[4])
                bytes2 = parse(Float64, timings_as_string[5])
                bytes3 = parse(Float64, timings_as_string[6])                
            elseif runtime==:julia_0_6
                script_path = joinpath(@__DIR__, "packagescripts", script_filename)
                timings_as_string = readlines(pipeline(`$jl06bin --startup-file=no $script_path $warmup_filename $filename`, stderr=error_log_path, append=true))
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
                bytes1 = parse(Float64, timings_as_string[4])
                bytes2 = parse(Float64, timings_as_string[5])
                bytes3 = parse(Float64, timings_as_string[6])
            elseif runtime==:r_project
                script_path = joinpath(@__DIR__, "packagescripts", script_filename)
                timings_as_string = readlines(pipeline(`$rbin $script_path $warmup_filename $filename`, stderr=error_log_path, append=true))
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
                bytes1 = parse(Float64, timings_as_string[4])
                bytes2 = parse(Float64, timings_as_string[5])
                bytes3 = parse(Float64, timings_as_string[6])
            elseif runtime==:python
                script_path = joinpath(@__DIR__, "packagescripts", script_filename)
                timings_as_string = readlines(pipeline(`$pythonbin $script_path $warmup_filename $filename`, stderr=error_log_path, append=true))
                t1 = parse(Float64, timings_as_string[1])
                t2 = parse(Float64, timings_as_string[2])
                t3 = parse(Float64, timings_as_string[3])
                bytes1 = parse(Float64, timings_as_string[4])
                bytes2 = parse(Float64, timings_as_string[5])
                bytes3 = parse(Float64, timings_as_string[6])
            else
                error("Incorrect julia version specified.")
            end
            push!(df, (runid=runid, attempt = :warmup, file=filename_for_label, rows=rows, cols=cols, withna=withna, package=packagename, sample=i, timing=t1, bytes=bytes1))
            push!(df, (runid=runid, attempt = :first, file=filename_for_label, rows=rows, cols=cols, withna=withna, package=packagename, sample=i, timing=t2, bytes=bytes2))
            push!(df, (runid=runid, attempt = :second, file=filename_for_label, rows=rows, cols=cols, withna=withna, package=packagename, sample=i, timing=t3, bytes=bytes3))
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
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_single, "Julia TextParse.jl", filename_for_label, "textparse_script.jl")
    end

    if :csvfiles in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_single, "Julia CSVFiles.jl", filename_for_label, "csvfiles_script.jl")
    end

    if :textparse06 in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_0_6, "Julia v0.6 TextParse.jl", filename_for_label, "textparse_julia06_script.jl")
    end

    if :csv06 in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_0_6, "Julia v0.6 CSV.jl", filename_for_label, "csv_julia06_script.jl")
    end

    if :csv_single in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_single, "Julia CSV.jl", filename_for_label, "csv_s_script.jl")
    end

    if :csv_copycols_single in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_single, "Julia CSV.jl copycols", filename_for_label, "csv_copycols_s_script.jl")
    end

    if :csv_parallel in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_parallel, "Julia CSV.jl parallel", filename_for_label, "csv_p_script.jl")
    end

    if :csv_copycols_parallel in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_parallel, "Julia CSV.jl copycols parallel", filename_for_label, "csv_copycols_p_script.jl")
    end

    if :dataframes in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_single, "Julia DataFrames.jl", filename_for_label, "dataframes_script.jl")
    end

    if :tablereader in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_single, "Julia TableReader.jl", filename_for_label, "tablereader_script.jl")
    end

    if :csvreader in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_single, "Julia CSVReader.jl", filename_for_label, "csvreader_script.jl")
    end

    if :pandas in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :julia_1_single, "Julia Pandas.jl", filename_for_label, "pandas_script.jl")
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

    if :pythonarrowp in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :python, "Python Arrow parallel", filename_for_label, "python_arrowp_script.py")
    end

    if :pythonarrows in tests_to_run
        run_script(df, runid, rows, cols, withna, filename, warmup_filename, samples, :python, "Python Arrow", filename_for_label, "python_arrows_script.py")
    end

    nothing
end

df = DataFrame(runid=String[], attempt=Symbol[], file=String[], rows=Int[], cols=Int[], withna=Bool[], package=String[], sample=Int[], timing=Float64[], bytes=Float64[])

for n in ns, c in cs, withna in [true, false]
    for filename in filter(i->endswith(i, ".csv") && !startswith(i, "warmup"), readdir(ourpath(n, c, withna)))
        @info "$filename, n=$n, c=$c, withna=$withna"
        read_specific_file(df, runid, n, c, withna, filename, samples)
    end
end



df[!, :platform] .= platform
df[!, :experiment_date] .= experiment_date

df |> save(joinpath(output_folder_name, "csvreader.csv"))

df_versions = DataFrame(package=String[], version=String[])
pkg_ctx = Pkg.Types.Context()
for p in ["CSV", "CSVFiles", "DataFrames", "TextParse", "CSVReader", "Pandas", "TableReader"]
    if haskey(pkg_ctx.env.project.deps, p)
        push!(df_versions, ("Julia " * p * ".jl", string(pkg_ctx.env.manifest[pkg_ctx.env.project.deps[p]].version)))
    end
end
push!(df_versions, ("Julia v0.6 CSV.jl", "0.2.5"))
push!(df_versions, ("Julia v0.6 TextParse.jl", "0.5.0"))

try
    vers = readlines(pipeline(`$rbin $(joinpath("packagescripts", "rfread_version.R"))`, stderr=error_log_path, append=true))[1]
    push!(df_versions, ("R fread", vers))
catch err
end

try
    vers = readlines(pipeline(`$rbin $(joinpath("packagescripts", "rreadr_version.R"))`, stderr=error_log_path, append=true))[1]
    push!(df_versions, ("R readr", vers))
catch err
end

try
    vers = readlines(pipeline(`$pythonbin $(joinpath("packagescripts", "python_arrow_version.py"))`, stderr=error_log_path, append=true))[1]
    push!(df_versions, ("Python Arrow", vers))
catch err
end

try
    vers = readlines(pipeline(`$pythonbin $(joinpath("packagescripts", "python_pandas_version.py"))`, stderr=error_log_path, append=true))[1]
    push!(df_versions, ("Python Pandas", vers))
catch err
end

df_versions |> save(joinpath(output_folder_name, "csvreaderpackageversions.csv"))

for c in cs
    p1 = df |>
    @filter(_.attempt==:first) |>
    @filter(!_.withna && _.cols == c) |>
    @vlplot(facet={row={field=:file, typ=:nominal, title=nothing}, column={field=:rows, typ=:ordinal}}, resolve={scale={x=:independent}}, title="Without missing data ($c columns)", background=:white) +
        (
            @vlplot(y={"package:n", title=nothing}, resolve={scale={x=:shared}}) +
            @vlplot(:bar,  x={"min(timing):q", title="seconds"}, color={"package:n", scale={scheme=:category20}}) +
            @vlplot(:rule, x="min(timing):q", x2="max(timing):q") +
            @vlplot(:tick, x="timing:q")
        )
    p1 |> save(joinpath(output_folder_name, "cols_$(c)_withoutna.pdf"))
    p1 |> save(joinpath(output_folder_name, "cols_$(c)_withoutna.png"))

    p2 = df |>
    @filter(_.attempt==:first) |>
    @filter(_.withna && _.cols == c) |>
    @vlplot(facet={row={field=:file, typ=:nominal, title=nothing}, column={field=:rows, typ=:ordinal}}, resolve={scale={x=:independent}}, title="With missing data ($c columns)", background=:white) +
        (
            @vlplot(y={"package:n", title=nothing}, resolve={scale={x=:shared}}) +
            @vlplot(:bar,  x={"min(timing):q", title="seconds"}, color={"package:n", scale={scheme=:category20}}) +
            @vlplot(:rule, x="min(timing):q", x2="max(timing):q") +
            @vlplot(:tick, x="timing:q")
        )
    p2 |> save(joinpath(output_folder_name, "cols_$(c)_withna.pdf"))
    p2 |> save(joinpath(output_folder_name, "cols_$(c)_withna.png"))
end
