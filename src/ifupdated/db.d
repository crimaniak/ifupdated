module ifupdated.db;

import std.conv : to;

ubyte[16] makeHash(string[] args)
{
	import std.digest.md : MD5;
	import std.algorithm : each;
	
	MD5 digest;
	digest.start;
	foreach(s; args)
	{
		digest.put(cast(ubyte[])s);
		digest.put(0);
	}
	return digest.finish;
}

unittest
{
	auto a = makeHash(["command1","-a","-b"]);
	auto b = makeHash(["command1","-a-","b"]);
	
	assert(a != b);
}

struct Db
{
	import std.file;
	import std.stdio;
	
	string[] args;
	string filename;
	
	this(string[] args)
	{
		this.args = args;
		filename = getName(makeHash(args));
	}

	static string getBase()
	{
		import std.digest.digest: toHexString;
		
		return (getHome~"/.ifupdated/").to!string;
	}

	static string getName(ubyte[16] hash)
	{
		import std.digest.digest: toHexString;
		
		return (getBase~hash.toHexString).to!string;
	}

	void update(T)(T files)
	{
		
		mkdirRecurse(getBase);
		
		auto file = filename.File("w+");
		
		foreach(name; files)
			file.writeln(name);
		file.close;	
	}	

	bool wasUpdated()
	{
		import std.algorithm: any;
		
		if(!filename.exists || !filename.isFile)
			return true;
			
		auto lastRun = filename.timeLastModified;
		
		return filename.File.byLine.any!(name => name.timeLastModified > lastRun);
	}	
}

/**
 * Get current user's home directory
 * UNIX - only
 */
string getHome()
{
	import std.c.stdlib: getenv;
	import std.string: toStringz;
	
	return getenv("HOME".toStringz).to!string;
}
