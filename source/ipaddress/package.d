module ipaddress;
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
		import std.array;
		string[] ret;
		if (type == Type.ipv4) {
			ubyte[] buf = (cast(ubyte*)&inet6[3])[0..uint.sizeof];
			foreach (b; buf) {
				import std.conv;
				ret ~= std.conv.to!string(b);
			}
			return ret.join('.');
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
		this.network.inet6[3] = this.network.inet6[3] & this.netmask.inet6[3]; // set the network to the first address in the network
	}
	//this(string netmask) { // allow construction from strings too, perhaps use a cast?
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
				final switch (front.type) {
					case IPAddress.Type.ipv4:
						import core.sys.posix.arpa.inet;
						auto a1 = network.inet6[3].htonl();
						auto a2 = netmask.inet6[3].htonl();
						auto a3 = front.inet6[3].htonl();
						empty = (a1 & a2) != (a2 & a3);
						break;
					case IPAddress.Type.ipv6:
						assert(0, "ipv6 not implemented");
						//break;
				}
			}
		}
		auto ret = Ret();
		ret.front = network;
		ret.network = network;
		ret.netmask = netmask;
		return ret;
	}

	import std.traits : isIntegral;
	T opCast(T)() if (isIntegral!T) {
		import std.bitmanip : nativeToLittleEndian;
		T ret;
		with (IPAddress.Type) final switch (netmask.type) {
			case ipv4:
			auto bytes = netmask.inet6[3].nativeToLittleEndian!uint;
			uint* n = cast(uint*)bytes.ptr;
			while (*n>0 && (*n&1)) {
				//writefln("%.32b", *n);
				*n >>= 1;
				ret++;
			}
			break;
			case ipv6:
				assert(0, "ipv6");
				//break;
		}
		return ret;
	}

	string toString() {
		import std.format;
		return "%s/%d".format(network, cast(int)this);
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
				arr[i] = std.conv.to!ubyte(n);
			}
		} else {
			
		}
	}
	return ret;
}

unittest {
	import testdata;
	import std.format;
	import std.stdio;

	auto test = testdata.ip;
	assert(to!IPAddress(test.input).toString == test.output, "%s != %s".format(test.input, test.output));

	import std.array;
	import std.algorithm;
	import std.range;
	auto network = to!IPAddress(network_input.ip).network(to!IPAddress(network_input.mask));
	assert(network.netmask.toString == "255.255.255.0");
	assert(network.network.toString == network_output.network, "%s != %s".format(network.network.toString, network_output.network));
	assert(network.toString == network_output.network_string, "%s != %s".format(network.toString, network_output.network_string));
	try {
		assert(network.hosts().map!(a=>a.toString).array == network_output.hosts);
	} catch (Throwable t) {
		foreach (host, test; lockstep(network.hosts, network_output.hosts)) {
			writefln("%s == %s: %s", host, test, host.toString==test);
		}
	}
}
