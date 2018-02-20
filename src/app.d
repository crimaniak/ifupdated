import std.stdio;

import ifupdated.runner;

int main(string[] args)
{
    if (args.length < 2)
    {
        writeln("Syntax: ifupdated command_to_run");
        return 0;
    }
    return run(args);
}
