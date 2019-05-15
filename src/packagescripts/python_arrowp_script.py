from pyarrow import csv
from timeit import default_timer as timer
import sys

warmup_filename = sys.argv[0]
filename = sys.argv[1]

start = timer()
table = csv.read_csv(warmup_filename).to_pandas()
end = timer()
t1 = end - start

start = timer()
table = csv.read_csv(filename).to_pandas()
end = timer()
t2 = end - start

start = timer()
table = csv.read_csv(filename).to_pandas()
end = timer()
t3 = end - start

print(t1)
print(t2)
print(t3)
print('NaN')
print('NaN')
print('NaN')
