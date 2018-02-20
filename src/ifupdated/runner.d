module ifupdated.runner;

import std.stdio;
import std.conv: to;

import ifupdated.db;

int run(string[] args)
{
	import std.file;
	
	// Calculate hash of parameters and db name
	// string dbName = Db.getName(makeHash(args));
	auto db = Db(args);
	
	// check if database file exists for it
	// if exists - check input files for timestamps
	// if no db file of input files updated
	if(db.wasUpdated())
	{
		//  then run command and recreate db
		return runAndCollectInfo(db); 
	}

	return 0;
}

int runAndCollectInfo(Db db)
{
	import core.stdc.stdio: tmpnam;
	import std.range: drop;
	import std.file;
	import std.process;
	import std.container.rbtree;
	import std.regex;
	import std.string: split;
	
	string logFilename = tmpnam(null).to!string;
	
	// strace -q -o logFilename -f -e trace=open ...
	const(char)[][] fullArgs;
	fullArgs ~= ["strace", "-q", "-o", cast(char[]) logFilename, "-f", "-e", "trace=open"];
	foreach(arg; db.args.drop(1))
		fullArgs ~= cast(char[]) arg;

	auto p = spawnProcess(fullArgs);
	p.wait;

	RedBlackTree!string sources = new RedBlackTree!string;
	RedBlackTree!string derived = new RedBlackTree!string;
	
	// 16565 open("/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
	auto mask = ctRegex!`^(?:\d+\s+)?open\("([^"]+)", (\S+)(,\s+\d+)?\)\s+=\s+(\d+)`;
	
nextLine:	
	foreach(line; logFilename.File.byLine)
	{
		// writeln(line);
		auto result = line.matchFirst(mask);
		if(result.empty())
			continue;
			
		auto attrs = result[2].split('|');
		
		foreach(attr; attrs)
			if(attr == "O_RDONLY")
			{
				sources.insert(result[1].to!string);
				continue nextLine;		
			} else if(attr == "O_WRONLY" || attr == "O_CREAT" || attr == "O_RDWR")
			{
				derived.insert(result[1].to!string);
				continue nextLine;
			}
		throw new Exception("Can't parse attributes: " ~ line.to!string); 	
	}
	
	logFilename.remove;
	
	auto nonSource = ctRegex!`^/(:?etc|proc|dev)/`;
	foreach(file; sources)
		if(!file.matchFirst(nonSource).empty)
			derived.insert(file);

	foreach(file; derived)
		sources.removeKey(file);

	db.update(sources);

	return 0;
}


