using TextParse

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(csvread(warmup_filename))

gc(); gc(); gc()

t2 = @elapsed(csvread(filename))

gc(); gc(); gc()

t3 = @elapsed(csvread(filename))

println(t1)
println(t2)
println(t3)
