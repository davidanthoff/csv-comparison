using CSV

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = @elapsed(CSV.read(warmup_filename, copycols=true))

GC.gc(); GC.gc(); GC.gc()

t2 = @elapsed(CSV.read(filename, copycols=true))

GC.gc(); GC.gc(); GC.gc()

t3 = @elapsed(CSV.read(filename, copycols=true))

println(t1)
println(t2)
println(t3)
