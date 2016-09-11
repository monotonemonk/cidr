import std.stdio;

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
}


auto to(T = IPAddress)(string s) if (is(T == IPAddress)) {
	import std.exception;
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
