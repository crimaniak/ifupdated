module ifupdated.runner;

import std.conv : to;

import ifupdated.db;

int run(const string[] args, string[] targets, string cwd)
{
    Db db = Db(args, cwd);

    if (db.wasUpdatedOrNew || targets.someMissing)
        return runAndCollectInfo(db);

    return 0;
}

int runAndCollectInfo(ref Db db)
{
    import core.stdc.stdio : tmpnam;
    import std.algorithm : map;
    import std.array : array;
    import std.process : spawnProcess, wait, ProcessException;
    import std.stdio : stderr;

    // File itself will be created by external utility so tmpnam is used
    string logFilename = tmpnam(null).to!string;

    // strace -q -o logFilename -f -e trace=open ...
    const(char)[][] fullArgs = [
        "strace", "-q", "-o", cast(char[]) logFilename, "-f", "-e", "trace=open"
    ];

    fullArgs ~= db.args.map!(arg => cast(char[]) arg).array;

    try
    {
        auto p = fullArgs.spawnProcess;

        auto exitCode = p.wait;
        if (exitCode == 0)
            collectInfo(db, logFilename);
        return exitCode;

    }
    catch (ProcessException e)
    {
        if (e.msg == "Executable file not found: strace")
        {
            stderr.writeln("Error: strace utility is not found");
            stderr.writeln("Please install strace utility to continue");
            return 1;
        }
        throw e;
    }
}

void collectInfo(ref Db db, string logFilename)
{
    import std.container.rbtree : RedBlackTree;
    import std.file : remove;
    import std.regex : ctRegex, matchFirst;
    import std.stdio : File;
    import std.string : split;

    RedBlackTree!string sources = new RedBlackTree!string;
    RedBlackTree!string targets = new RedBlackTree!string;

    // example: 16565 open("/lib/x86_64-linux-gnu/libc.so.6", O_RDONLY|O_CLOEXEC) = 3
    auto mask = ctRegex!`^(?:\d+\s+)?open\("([^"]+)", (\S+)(,\s+\d+)?\)\s+=\s+(\d+)`;

    nextLine: foreach (line; logFilename.File.byLine)
    {
        auto result = line.matchFirst(mask);
        if (result.empty())
            continue;

        foreach (attr; result[2].split('|'))
            if (attr == "O_RDONLY")
            {
                sources.insert(result[1].to!string);
                continue nextLine;
            }
            else if (attr == "O_WRONLY" || attr == "O_CREAT" || attr == "O_RDWR")
            {
                targets.insert(result[1].to!string);
                continue nextLine;
            }
        throw new Exception("Can't parse attributes: " ~ line.to!string);
    }

    logFilename.remove;

    // @todo: read from config
    auto nonSource = ctRegex!`^/(:?etc|proc|dev|tmp)/`;

    // no range interface for RBTree

    foreach (file; targets)
        sources.removeKey(file);

    SavedData toSave;

    foreach (file; sources)
        if (file.matchFirst(nonSource).empty)
            toSave.sources ~= file;

    foreach (file; targets)
        if (file.matchFirst(nonSource).empty)
            toSave.targets ~= file;

    db.update(toSave);
}

bool someMissing(const string[] targets)
{
    import std.file : exists;
    import std.algorithm : any;

    return targets.any!(t => !t.exists);
}
