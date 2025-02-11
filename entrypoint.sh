#!/bin/sh
echo "Activating Julia environment..."
julia -e 'using Pkg; Pkg.activate("."); Pkg.instantiate()'

echo "Running migrations..."
julia db/DBInit.jl