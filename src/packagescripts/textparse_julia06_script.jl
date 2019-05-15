using TextParse

warmup_filename = ARGS[1]
filename = ARGS[2]

val1, t1, bytes1, gctime1, memallocs1 = @timed(csvread(warmup_filename))

gc(); gc(); gc()

val2, t2, bytes2, gctime2, memallocs2 = @timed(csvread(filename))

gc(); gc(); gc()

val3, t3, bytes3, gctime3, memallocs3 = @timed(csvread(filename))

println(t1)
println(t2)
println(t3)
println(bytes1)
println(bytes2)
println(bytes3)
