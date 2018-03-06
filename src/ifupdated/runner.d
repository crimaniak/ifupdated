module ifupdated.runner;

import std.stdio;
import std.conv: to;

import ifupdated.db;

int run(string[] args)
{
	import std.file;
	
	Db db = Db(args);
	
	if(db.wasUpdatedOrNew())
		return runAndCollectInfo(db); 

	return 0;
}

int runAndCollectInfo(Db db)
{
	import core.stdc.stdio : tmpnam;
	import std.range : drop;
	import std.file : remove;
	import std.process : spawnProcess, wait;
	import std.container.rbtree : RedBlackTree;
	import std.regex : ctRegex, matchFirst;
	import std.string: split;
	import std.algorithm: map, filter, each;
	import std.array: array;
	
	
	// File itself will be created by external utility so tmpnam is used
	string logFilename = tmpnam(null).to!string;
	
	// strace -q -o logFilename -f -e trace=open ...
	const(char)[][] fullArgs = ["strace", "-q", "-o", cast(char[]) logFilename, "-f", "-e", "trace=open"];
	
	fullArgs ~= db.args.drop(1).map!(arg => cast(char[]) arg).array;

	auto p = fullArgs.spawnProcess;
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
	
	// @todo: read from config
	auto nonSource = ctRegex!`^/(:?etc|proc|dev)/`;
	
	// no range interface for RBTree
	foreach(file; sources)
		if(!file.matchFirst(nonSource).empty)
			derived.insert(file);

	foreach(file; derived)
		sources.removeKey(file);

	db.update(sources);

	return 0;
}


