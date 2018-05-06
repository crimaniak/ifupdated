module ifupdated.db;

import std.conv : to;

enum formatVersion="1.0";

@safe @nogc ubyte[16] makeHash(const string[] args, string cwd)
{
    import std.digest.md : MD5;
    import std.algorithm : each;
    import std.string : representation;

    MD5 digest;

    digest.start;
    digest.put(formatVersion.representation);
    foreach (s; args)
    {
        digest.put(s.representation);
        digest.put(0);
    }
    digest.put(cwd.representation);
    return digest.finish;
}

unittest
{
    auto a = makeHash(["command1", "-a", "-b"], "");
    auto b = makeHash(["command1", "-a-", "b"], "");
    auto c = makeHash(["command1", "-a", "-b"], "/");

    assert(a != b);
    assert(a != c);
}

struct SavedData
{
    import std.stdio : File;
	import std.container.rbtree : RedBlackTree;
	
	string[] sources, targets;
	
	this(string filename)
	{
        import std.algorithm : each;

		bool toSources;
		filename.File.byLineCopy.each!((string name){
			if(name.length == 0)
			{
				toSources = true;
				return;
			}	
			if(toSources)
				sources ~= name;
			else	
				targets ~= name;	
		});
	}
	
	
	@safe void saveTo(string filename) const
	{
        auto file = filename.File("w+");
		
        foreach (name; targets)
            file.writeln(name);
        file.writeln("");    
        foreach (name; sources)
            file.writeln(name);
            
        file.close;
	}
	
} 

struct Db
{
    import std.file : exists, isFile, timeLastModified, mkdirRecurse;
    import std.stdio : File;
    import std.digest.digest : toHexString;

    const string[] args; // command and arguments
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
        return (getHome ~ "/.ifupdated/").to!string;
    }

    static string getName(const ubyte[16] hash)
    {
        return (getBaseDir ~ hash.toHexString).to!string;
    }

    void update(const ref SavedData data)
    {
        mkdirRecurse(getBaseDir);

		data.saveTo(filename);
    }

    bool wasUpdatedOrNew()
    {
        import std.algorithm : any;

        if (!filename.exists || !filename.isFile)
            return true;

        auto lastRun = filename.timeLastModified;

		SavedData data = SavedData(filename);

        return data.sources.any!(name => !name.exists || name.timeLastModified > lastRun) 
	        || data.targets.any!(name => !name.exists);
    }
}

/**
 * Get current user's home directory
 * UNIX - only
 */
string getHome()
{
    import std.c.stdlib : getenv;
    import std.string : toStringz;

    return getenv("HOME".toStringz).to!string;
}
