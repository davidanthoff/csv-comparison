# Comparing various CSV reading packages

## Overview

A CSV reader benchmark suite. Results are regularly published on the [Queryverse benchmark](https://www.queryverse.org/benchmarks/) page.

## Setup

You need Julia 1.1.0, Julia 0.6.4, Python 3.X and R installed.

For Julia 0.6.4, you need to install the CSV.jl and TextParse.jl package.

For Julia 1.1.0, activate the project in the root folder and instantiate it.

For Python, install pandas and pyarrow.

For R, install data.table and readr.

On Windows, run `deps/build.jl` to download `EmptyStandbyList.exe` executable.

## Generating test data

Run `src/writedata.jl` to generate the input data.

WARNING: The `writedata.jl` script generates _a lot_ of data, currently about 150 GB. Make sure you have enough disc space!

You can configure the details of the write process by adding a file `src/local_writeconfig.jl`, and then adding any of the following lines to configure various aspects:

```julia
# Configure what row number cases you want to generate
ns = [100, 10_000, 1_000_000]

# Configure what column number cases you want to generate
cs = [20, 200]

# Share of missing values in columns with missing data
missing_share = 0.5

# Configure how many rows one very large test file should have
largefile_rown = 150_000_000

# Configure what colun types you want to generate
uniform_types = [
    :float64,      # Float64 with all digits
    :float64short, # Float64 with only 4 digist after the decimal point
    :int64,        # Int64
    :datetime,     # DateTime
    :string,       # Random string
    :catstring,    # Randomly pick one out of 5 strings for each cell
    :escapedstring # A string that includes an escaped quote char
]
```

## Running the benchmarks

Run the `src/main.jl` script to run the benchmarks. You need to run the script in elevated mode, so on Windows as an administrator, on Mac and Linux with `sudo`.

You can configure the details of the benchmarking process by adding a file `src/local_config.jl`, and then adding any of the following lines to configure various aspects:

```julia
# Configure which row cases you want to benchmark
ns = [100, 10_000, 1_000_000]

# Configure which column cases you want to benchmark
cs = [20, 200]

# Configure how many samples you want to take per benchmarking case
samples = 5

# Configure which packages to run
tests_to_run = [
    :textparse,       # TextParse.jl
    :csvfiles,        # CSVFiles.jl
    :textparse06,     # TextParse.jl on Julia 0.6
    :csv,             # CSV.jl
    :csv06,           # CSV.jl on Julia 0.6
    # :csvreader,     # CSVReader.jl
    # :tablereaders,  # TableReaders.jl
    :pandas,          # Pandas.jl
    :rfreads,         # R data.table single threaded
    :rfreadp,         # R data.table parallel
    :rreadr,          # R readr
    :dataframes,      # DataFrames.jl
    :pythonpandas,    # Python pandas
    :pythonarrows,    # Python pyarrow single threaded
    :pythonarrowp     # Python pyarrow parallel
]

# Path to Julia 0.6 binary
jl06bin = "julia-0.6"

# Path to Julia 1.1 binary
jlbin = "julia"

# Path to Rscript binary
rbin = "Rscript"

# Path to Python binary
pythonbin = "python3"
```

## Contributing

Issues and PRs with contributions are most welcome!
