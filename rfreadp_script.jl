using RCall

R"""
memory.limit(size=32000)
library(data.table)
""";

warmup_filename = ARGS[1]
filename = ARGS[2]

R"""
fread($warmup_filename, nThread=15)
"""

GC.gc(); GC.gc(); GC.gc()

t = convert(Float64, R"""
    start_time = Sys.time()
    fread($filename, nThread=15)
    end_time = Sys.time()
    elap = end_time - start_time
""")

println(t)
