using CSV

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(CSV.read(warmup_filename))

gc(); gc(); gc()

t2 = @elapsed(CSV.read(filename))

gc(); gc(); gc()

t3 = @elapsed(CSV.read(filename))

println(t1)
println(t2)
println(t3)
