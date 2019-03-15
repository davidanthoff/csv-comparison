library(readr)
options(readr.num_columns = 0)

args = commandArgs(trailingOnly=TRUE)

warmup_filename = args[1]
filename = args[2]

start_time = Sys.time()
x1 <- read_csv(warmup_filename, progress = FALSE)
end_time = Sys.time()
t1 = end_time - start_time


start_time = Sys.time()
x2 <- read_csv(filename, progress = FALSE)
end_time = Sys.time()
t2 = end_time - start_time


start_time = Sys.time()
x3 <- read_csv(filename, progress = FALSE)
end_time = Sys.time()
t3 = end_time - start_time

cat(as.numeric(t1))
cat('\n')
cat(t2)
cat('\n')
cat(t3)
cat('\n')
