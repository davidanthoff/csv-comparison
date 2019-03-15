using TextParse

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(csvread(warmup_filename))

GC.gc(); GC.gc(); GC.gc()

t2 = @elapsed(csvread(filename))

GC.gc(); GC.gc(); GC.gc()

t3 = @elapsed(csvread(filename))

println(t1)
println(t2)
println(t3)
