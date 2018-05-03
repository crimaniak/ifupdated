module ifupdated.db;

import std.conv : to;

ubyte[16] makeHash(const string[] args, string cwd)
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
	digest.put(cast(ubyte[])cwd);
	return digest.finish;
}

unittest
{
	auto a = makeHash(["command1","-a","-b"], "");
	auto b = makeHash(["command1","-a-","b"], "");
	auto c = makeHash(["command1","-a","-b"], "/");
	
	assert(a != b);
	assert(a != c);
}

struct Db
{
	import std.file : exists, isFile, timeLastModified, mkdirRecurse;
	import std.stdio : File;
	import std.digest.digest: toHexString;
	
	const string[] args;   // command and arguments
	string cwd;
	string filename; // database filename for this command/arguments combo
	
	this(const string[] args, string cwd)
	{
		this.args = args;
		this.cwd = cwd;
		filename = getName(makeHash(args, cwd));
	}

	static string getBaseDir()
	{
		return (getHome~"/.ifupdated/").to!string;
	}

	static string getName(const ubyte[16] hash)
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
