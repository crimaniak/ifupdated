SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
FLAGS="-O -release -noboundscheck -I=$SCRIPT_DIR/../../src"
./ifupdated dmd -c $FLAGS ../../src/app.d
./ifupdated dmd -c $FLAGS ../../src/ifupdated/runner.d
./ifupdated dmd -c $FLAGS ../../src/ifupdated/db.d
./ifupdated dmd -of=ifup $FLAGS app.o runner.o db.o
