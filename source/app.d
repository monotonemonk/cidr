import std.stdio;
import ipaddress;

void main(string[] args) {
	auto ip = to!IPAddress("192.168.0.1");
	writeln("ip: ", ip);
	auto start = to!IPAddress("192.168.73.22");
	writeln("start: ", start);
	start++;
	writeln("start+1: ", start);
	if (args.length) {
		import std.conv;
		foreach (i; 0 .. to!int(args[1])) {
			start++;
			write(start, "\r");
		}
		writeln();
	}
}
