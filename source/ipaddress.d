import std.stdio;
import std.exception;

enum check_ = () {
	assert(uint.sizeof == 4);
	return true;
}();
struct IPAddress {
	bool empty = true;
	uint[4] inet6;

	enum Type { ipv4, ipv6};
	Type type() {
		return cast(Type)(cast(int)inet6[0] != 0);
	}

	string toString() {
		import std.format;
		if (type == Type.ipv4) {
			ubyte[] buf = (cast(ubyte*)&inet6[3])[0..uint.sizeof];
			//return "%s - %s (%s)".format(inet6[3], buf, inet6);
			return "%s".format(buf);
		} else {
			assert(0);
		}
	}
	//string toStringExtended() { // make a separate struct that contains more data than just the ipaddress
	//	import std.string : format;
	//	return "%s %s netmask %s".format(
	//		type==Type.ipv6 ? "inet6" : "inet",
	//		toString(),
	//		"(netmask not set)",
	//	);
	//}

	auto opUnary(string op)() if (op=="++") {
		union Incr {
			ubyte[uint.sizeof*inet6.length] bytes;
			uint[4] inet6;
		}
		Incr incr;
		incr.inet6 = inet6;
		ubyte min_index = type == Type.ipv6 ? 0 : incr.bytes.length - 1 - uint.sizeof;
		ubyte index = incr.bytes.length-1;
		while (incr.bytes[index] == ubyte.max && index > min_index) {
			incr.bytes[index] = 0;
			index--;
		}
		assert(index>=min_index, "no more addresses");
		incr.bytes[index]++;
		inet6 = incr.inet6;
	}


	Network network(IPAddress netmask) {
		return Network(this, netmask);
	}
}

struct Network {
	@disable this();
	this(IPAddress network, IPAddress netmask) {
		enforce(network.type == netmask.type, "invalid netmask for network");
		this.netmask = netmask;
		this.network = network;
	}
	//static opCall(IPAddress netmask) {
	//	Network ret;
	//	ret.netmask = netmask;
	//	return ret;
	//}
	//static opCall(string netmask) {
	//	return Network(to!IPAddress(netmask));
	//}
	IPAddress network;
	IPAddress netmask;
	auto hosts() {
		struct Ret {
			IPAddress front;
			IPAddress network;
			IPAddress netmask;
			bool empty;
			void popFront() {
				front++;
				//empty=true;
				//return;
				 //TODO: detect if still within netmask
				final switch (front.type) {
					case IPAddress.Type.ipv4:
						import core.sys.posix.arpa.inet;
						auto a1 = network.inet6[3].htonl();
						auto a2 = netmask.inet6[3].htonl();
						auto a3 = front.inet6[3].htonl();
						//writefln("%32.b\n%32.b\n%32.b", a1, a2, a3);
						empty = (a1 & a2) != (a2 & a3);
						//writefln("empty:%s s:%s", empty, front); // this is right
						//writefln("& %32.b %b %b", a1 & a2, a1, a2);
						//writefln("& %32.b %b %b", a2 & a3, a2, a3);
						//writefln("^ %32.b", a1 ^ a2);
						//writefln("| %32.b", a1 | a2);
						//writeln((a1 & a2) == a3);
						//writefln("%32.b\n%32.b\n%32.b", front.inet6[3], netmask.inet6[3], front.inet6[3]);
						//writefln("%s T", (front.inet6[3] & netmask.inet6[3]) == (network.inet6[3] && netmask.inet6[3]));
						//writefln("%32.b", (front.inet6[3] & netmask.inet6[3]));
						//writefln("%32.b", (front.inet6[3] ^ netmask.inet6[3]));
						//writefln("%32.b", (front.inet6[3] | netmask.inet6[3]));
						//writeln((front.inet6[3] & netmask.inet6[3]) == netmask.inet6[3]);
						break;
					case IPAddress.Type.ipv6:
						assert(0, "ipv6 not implemented");
						//break;
				}
			}
		}
		auto ret = Ret();
		ret.network.inet6[3] = this.network.inet6[3] & netmask.inet6[3]; // set the network to the first address in the network
		ret.front = ret.network;
		ret.netmask = netmask;
		return ret;
	}
}


auto to(T = IPAddress)(string s) if (is(T == IPAddress)) {
	import std.string;
	import std.algorithm : canFind;
	import std.conv;

	string[] components;
	if (s.canFind('.')) {
		components = s.split('.');
	} else if (s.canFind(':')) {
		components = s.split(':');
	} else {
		enforce(0, "not an ipaddress");
	}

	IPAddress ret;
	with (ret) {
		if (components.length == 4) {
			ubyte[] arr = (cast(ubyte*)&inet6[3])[0 .. 4];
			foreach (i, n; components) {
				arr[i] = to!ubyte(n);
			}
		} else {
			
		}
	}
	return ret;
}

unittest {
	enum tests = [
		"192.168.0.1"
	];
	foreach (test; tests) {
		//assert(to!IPAddress(test).toString == "192.168.0.1");
		writeln("a: ", to!IPAddress(test).toString);
	}
}
