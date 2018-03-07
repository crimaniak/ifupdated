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
	import std.file : exists, isFile, timeLastModified, mkdirRecurse;
	import std.stdio : File;
	import std.digest.digest: toHexString;
	
	string[] args;   // command and arguments
	string filename; // database filename for this command/arguments combo
	
	this(string[] args)
	{
		this.args = args;
		filename = getName(args.makeHash);
	}

	static string getBaseDir()
	{
		return (getHome~"/.ifupdated/").to!string;
	}

	static string getName(ubyte[16] hash)
	{
		return (getBaseDir~hash.toHexString).to!string;
	}

	void update(T)(T files)
	{
		mkdirRecurse(getBaseDir);
		
		auto file = filename.File("w+");
		
		foreach(name; files)
			file.writeln(name);
		file.close;	
	}	

	bool wasUpdatedOrNew()
	{
		import std.algorithm: any;
		
		if(!filename.exists || !filename.isFile)
			return true;
			
		auto lastRun = filename.timeLastModified;
		
		return filename.File.byLine.any!(name => !name.exists || name.timeLastModified > lastRun);
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
