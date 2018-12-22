using CSV

warmup_filename = ARGS[1]
filename = ARGS[2]

CSV.read(warmup_filename)

gc(); gc(); gc()

t = @elapsed(CSV.read(filename))

println(t)
