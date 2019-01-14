using RCall

R"""
memory.limit(size=32000)
library(data.table)
""";

warmup_filename = ARGS[1]
filename = ARGS[2]

t1 = convert(Float64, R"""
    start_time = Sys.time()
    fread($warmup_filename, nThread=15)
    end_time = Sys.time()
    elap = end_time - start_time
""")

GC.gc(); GC.gc(); GC.gc()

t2 = convert(Float64, R"""
    start_time = Sys.time()
    fread($filename, nThread=15)
    end_time = Sys.time()
    elap = end_time - start_time
""")

GC.gc(); GC.gc(); GC.gc()

t3 = convert(Float64, R"""
    start_time = Sys.time()
    fread($filename, nThread=15)
    end_time = Sys.time()
    elap = end_time - start_time
""")

println(t1)
println(t2)
println(t3)
