set -o pipefail

function run {
        echo "Testing command: $*"
        { "$@" | sed 's/^/\t/' ; } || { echo "[38;2;255;0;0mERROR in command: $*[m" && exit 1 ; } 
}
 
run perl run.pl --size smallest --args 16 16 3 32 32
run perl run.pl --size smallest --debug
run perl run.pl --size smallest --nobuild
run perl run.pl --size smallest
run perl run.pl --size smallest --nodavid
run perl run.pl --size smallest --nodavid --benchmark --count 5
run perl run.pl --size smallest --benchmark
run perl run.pl --size smallest --benchmark --count 10
run perl run.pl --size smallest --plot --backend python
run perl run.pl --size smallest --plot --backend gnuplot
