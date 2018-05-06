int main(string[] args)
{
    import std.stdio : writeln;
    import std.file : getcwd;
    import std.conv : to;
    import std.regex : ctRegex, matchFirst;
    
    import ifupdated.runner : run;

    if (args.length < 2)
    {
        writeln("Syntax: ifupdated [-t=<target file>]... command_to_run [command_parameters]");
        return 0;
    }

    auto targetMask = ctRegex!"^-t=(.*)$";
    string[] additionalTargets;

    // check for additional targets
    for (args = args[1 .. $];; args = args[1 .. $])
    {
        auto captures = args[0].matchFirst(targetMask);
        if (captures.empty)
            break;
        additionalTargets ~= captures[1];
    }

    return run(args, additionalTargets, getcwd);
}
