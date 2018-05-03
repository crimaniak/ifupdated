SCRIPT_DIR="$( cd "$( dirname "$0" )" && pwd )"
FLAGS="-O -release -noboundscheck -I=$SCRIPT_DIR/../../src"
ifupdated -t=app.o    dmd -c $FLAGS ../../src/app.d
ifupdated -t=runner.o dmd -c $FLAGS ../../src/ifupdated/runner.d
ifupdated -t=db.o     dmd -c $FLAGS ../../src/ifupdated/db.d
ifupdated -t=ifup dmd -of=ifup $FLAGS app.o runner.o db.o
