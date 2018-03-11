
int main(string[] args)
{
	import std.stdio: writeln;
	import std.file: getcwd;
	import ifupdated.runner: run;
	
    if (args.length < 2)
    {
        writeln("Syntax: ifupdated command_to_run");
        return 0;
    }
    return run(args[1..$], getcwd);
}
