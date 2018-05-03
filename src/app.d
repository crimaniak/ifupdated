
int main(string[] args)
{
	import std.stdio;
	import std.file: getcwd, readText;
	import ifupdated.runner: run;
	import std.conv: to;
	import std.regex;
	
    if (args.length < 2)
    {
        writeln("Syntax: ifupdated [-t=<target file>]... command_to_run [command_parameters]");
        return 0;
    }

	auto targetMask = ctRegex!"^-t=(.*)$";
	string[] targets;
	
	for(args = args[1..$];;args = args[1..$])
	{
		auto captures = args[0].matchFirst(targetMask);
		if(captures.empty) break;
		targets ~= captures[1];
	}
    
    return run(args, targets, getcwd);
}
