using DataFrames

warmup_filename = ARGS[1]
filename = ARGS[2]

val1, t1, bytes1, gctime1, memallocs1 = @timed(readtable(warmup_filename))

GC.gc(); GC.gc(); GC.gc()

val2, t2, bytes2, gctime2, memallocs2 = @timed(readtable(filename))

GC.gc(); GC.gc(); GC.gc()

val3, t3, bytes3, gctime3, memallocs3 = @timed(readtable(filename))

println(t1)
println(t2)
println(t3)
println(bytes1)
println(bytes2)
println(bytes3)
