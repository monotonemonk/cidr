module cidr;

import std.stdio;
import std.exception;
import core.sys.posix.arpa.inet;

struct IP {
private:
	uint _value;
	ubyte _netmask;
public:
	alias _value this;
	static IP fromString(string s) {
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

		IP ret;
		with (ret) {
			if (components.length == 4) {
				ubyte[] arr = (cast(ubyte*)&_value)[0 .. 4];
				foreach (i, n; components) {
					arr[3-i] = std.conv.to!ubyte(n);
				}
			} else {
				enforce(0, "err, ipv6 not supported");
			}
		}
		return ret;
	}
	void mask(string maskaddr) {
		auto addr = IP.fromString(maskaddr);
		uint counter = addr._value;
		while ((counter & 1) == 0) {
			counter >>= 1;
		}
		while ((counter & 1) == 1) {
			_netmask += 1;
			counter >>= 1;
		}
	}
	void mask(ubyte v) {
		enforce(v <= 32, "netmask max is 32");
		_netmask = v;
	}
	IP netmask() {
		return IP(mask());
	}
	IP id() {
		return IP(mask & _value);
	}
	alias network = id;
	IP broadcast() {
		return IP((~mask) | id);
	}
	IP ip() {
		return IP(_value);
	}
	uint mask() {
		enforce(_netmask <= 32, "netmask max is 32");
		uint ret;
		for (int i=0; i < _netmask; i++) {
			ret <<= 1;
			ret |= 1;
			//writefln("%d %.32b", _netmask, ret);
		}
		ret <<= (32-_netmask);
		//writefln("---%d %.32b", _netmask, ret);
		return ret;
	}
	bool contains(IP other) {
		//auto bytes = cast(ubyte[])this;
		//writefln("%.32b %.32b", _value, _value&mask);
		//writefln("%.32b %.32b %s", other._value, other._value&mask, (_value&mask) == (other._value&mask));
		//writefln("%.32b %.32b", _value.htonl, _value.htonl&mask);
		//writefln("%.32b %.32b %s", other._value.htonl, other._value.htonl&mask, (_value.htonl&mask)==(other._value.htonl&mask));
		//writefln("\t%.8b\t%.8b\t%.8b\t%.8b", bytes[0], bytes[1], bytes[2], bytes[3]);
		//bytes = cast(ubyte[])other;
		//writefln("\t%.8b\t%.8b\t%.8b\t%.8b", bytes[0], bytes[1], bytes[2], bytes[3]);
		//auto tmp = _value.htonl;
		//bytes = (cast(ubyte*)&tmp)[0 .. 4];
		//writefln("\t%.8b\t%.8b\t%.8b\t%.8b", bytes[0], bytes[1], bytes[2], bytes[3]);
		//tmp = other._value.htonl;
		//bytes = (cast(ubyte*)&tmp)[0 .. 4];
		//writefln("\t%.8b\t%.8b\t%.8b\t%.8b", bytes[0], bytes[1], bytes[2], bytes[3]);


		writefln("=====");
		writefln("\t%.32b\n\t%.32b\n\t%.32b\n\t%.32b", other._value, _value, (other|_value), ((other&mask)|id));

		return ((other&mask)|id) == id;
	}

	

	void print() {
		import std.stdio;
		writefln("======print:%s========", this);
		ubyte[] arr = cast(ubyte[])this;
		if (_netmask != 0) {
			writefln("%.8b.%.8b.%.8b.%.8b/%d", arr[0], arr[1], arr[2], arr[3], _netmask);
		} else {
			writefln("%.8b.%.8b.%.8b.%.8b", arr[0], arr[1], arr[2], arr[3]);
		}
		writefln("mask: %.32b - %s", mask(), netmask);
		writefln("id:   %.32b - %s", id()._value, id);
		writefln("ip:   %.32b - %s", ip()._value, ip);
		writefln("=====printed:%s=======", this);
	}
	string toString() {
		import std.format;
		ubyte[] arr = cast(ubyte[])this;
		if (_netmask != 0) {
			return "%d.%d.%d.%d/%d".format(arr[3], arr[2], arr[1], arr[0], _netmask);
		} else {
			return "%d.%d.%d.%d".format(arr[3], arr[2], arr[1], arr[0]);
		}
	}

	ubyte[] opCast(T)() if (is(T == ubyte[])) {
		return (cast(ubyte*)&_value)[0 .. 4];
	}
	uint opCast(T)() if (is(T == uint)) {
		return _value;
	}
}

unittest {
	import testdata;
	auto ip = IP.fromString(network_input.ip);
	writeln("ip: ", ip);
	assert(ip.toString() == network_input.ip);
	ip.print();
	ip.mask("255.255.255.252");
	ip.print();
	writeln("ip: ", ip);
	ip.mask(30);
	ip.print();
	writeln("ip: ", ip);
	assert(ip.id.toString == network_input.id);
	writeln("broadcast: ", ip.broadcast.toString);
	assert(ip.broadcast.toString == network_input.broadcast);
	assert(ip.contains(IP.fromString(network_input.ip_host)));
	assert(!ip.contains(IP.fromString(network_input.ip_host_fail)));

	//ip = IP.fromString("255.255.255.0");
	//writeln("ip: ", ip);
	//assert(ip.toString() == "255.255.255.0");
	//ip.print();
}