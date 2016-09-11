import std.stdio;
import ipaddress;

void main(string[] args) {
	auto ip = to!IPAddress("192.168.0.100");
	writeln("ip: ", ip);

	auto network = ip.network(to!IPAddress("255.255.255.0"));
	writeln("network: ", network.network);
	foreach (n; network.hosts) {
		writeln(n);
	}

	auto start = to!IPAddress("192.168.73.22");
	writeln("start: ", start);
	start++;
	writeln("start+1: ", start);
	if (args.length>1) {
		import std.conv;
		foreach (i; 0 .. to!int(args[1])) {
			start++;
			write(start, "\n");
		}
		writeln();
	}
}
