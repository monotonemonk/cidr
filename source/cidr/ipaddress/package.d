module cidr.ipaddress;
import cidr.exception;

import std.stdio;
import std.exception;
import core.sys.posix.arpa.inet;
import std.format;
import std.traits : isSomeString;

struct IP {
private:
	uint _value;
	ubyte _netmask;
public:
	import std.socket;
	this(uint address) {
		_value = address;
	}
	this(uint address, ubyte maskbits) {
		this(address);
		this._netmask = maskbits;
	}
	this(AddressT)(AddressT addr)
		if (__traits(compiles, addr.toAddrString=="")
			|| __traits(compiles, addr.addr == cast(uint)0)
			|| __traits(compiles, addr.addr == cast(ubyte[16])""))
	{
		static if (__traits(compiles, addr.addr == cast(ubyte[16])"")) {
			enforce!IPv6NotImplemented(0, "ipv6 not implemented");
		} else static if (__traits(compiles, addr.addr == cast(uint)0)) {
			this._value = addr.addr;
			return;
		} else if (__traits(compiles, addr.toAddrString=="")) {
			this = addr.toAddrString();
			return;
		}
		assert(0);
	}
	alias _value this;

	ref opAssign(T)(T s) if (isSomeString!T) {
		import std.exception;
		import std.string;
		import std.algorithm : canFind, countUntil;
		import std.conv;

		auto netmask_idx = s.countUntil("/");
		if (netmask_idx>=0) {
			enforce(netmask_idx<s.length-1, "netmask invalid");
			//writefln("mask: %d" , );
			setMask(to!ubyte(s[netmask_idx+1..$]));
			s = s[0..netmask_idx];
		}

		string[] components;
		if (s.canFind('.')) {
			components = s.split('.');
		} else if (s.canFind(':')) {
			components = s.split(':');
		} else {
			enforce(0, "not an ipaddress");
		}

		if (components.length == 4) {
			ubyte[] arr = (cast(ubyte*)&_value)[0 .. 4];
			foreach (i, n; components) {
				arr[3-i] = std.conv.to!ubyte(n);
			}
		} else {
			enforce(0, "err, ipv6 not supported");
		}
		return this;
	}
	static IP fromString(string s) {
		IP ret;
		ret = s;
		return ret;
	}
	void setMask(string maskaddr) {
		_netmask = 0;
		auto addr = IP.fromString(maskaddr);
		uint counter = addr._value;
		while ((counter & 1) == 0) {
			counter >>= 1;
		}
		while ((counter & 1) == 1) {
			_netmask += 1;
			counter >>= 1;
		}
		enforce(_netmask <= 32, "netmask max is 32: %d".format(_netmask));
	}
	void setMask(ubyte v) {
		enforce(v <= 32, "netmask max is 32: %d".format(_netmask));
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
		enforce(_netmask <= 32, "netmask max is 32: %d".format(_netmask));
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

		return (other&mask) == id;
	}
	bool usable(IP other) {
		return this.contains(other) && other._value != id._value && other._value != broadcast._value;
	}

	auto range() {
		struct Ret {
			IP network;
			bool empty;
			IP front;
			private uint _front;
			void popFront() {
				auto tmp = IP(_front);
				if (!network.contains(tmp)) {
					empty = true;
					return;
				}
				assert(_front < typeof(_front).max);
				_front++;
				front = tmp;
			}
			IP back() {
				return network.broadcast;
			}
			auto broadcast() {
				return network.broadcast;
			}
			size_t length;
			private typeof(this) prime() {
				// pretend an empty netmask is a network with just one ip
				if (network._netmask == 0) {
					network._netmask = 32;
				}
				_front = network._value;
				length = (~network.mask)+1;
				this.popFront();
				return this;
			}
		}
		return Ret(IP(id, _netmask)).prime;
	}
	auto hosts() {
		import std.traits : ReturnType;
		struct Ret1 {
			ReturnType!range inner;
			alias inner this;
			bool empty;
			void popFront() {
				inner.popFront();
				// don't include broadcast
				if (inner.empty || front._value == inner.broadcast._value) {
					empty = true;
				}
			}
			size_t length;
			private typeof(this) prime() {
				length = inner.length - 2;
				popFront(); // skip network
				return this;
			}
		}
		return Ret1(range()).prime;//.drop(1).filter!(a => a._value != broadcast._value);
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
		writefln("ip:   %.32b - %s", ip()._value, ip);
		if (_netmask) {
			writefln("mask: %.32b - %s", mask(), netmask);
			writefln("id:   %.32b - %s", id()._value, id);
			writefln("range: %s - %s", range.front, range.back);
		}
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
	import std.algorithm : map;
	import std.array;
	auto ip = IP.fromString(network_input.ip);
	assert(ip.toString() == network_input.ip);
	ip.print();
	ip = IP.fromString(network_input.network);
	assert(ip.netmask.toString == network_output.netmask);
	ip.setMask("255.255.255.252");
	ip.print();
	ip.setMask(30);
	ip.print();
	assert(ip.id.toString == network_input.id);
	assert(ip.broadcast.toString == network_input.broadcast);
	assert(ip.contains(IP.fromString(network_input.ip_host)));
	assert(!ip.contains(IP.fromString(network_input.ip_host_fail)));

	assert(ip.range.map!(a => a.toString).array == network_output.range);
	assert(ip.range.map!(a => a.toString).array != network_output.hosts);
	assert(ip.range.length == 4);
	assert(ip.hosts.length == 2);
	assert(ip.hosts.map!(a => a.toString).array == network_output.hosts);
	assert(!ip.usable(IP.fromString(network_input.ip)));
	assert(!ip.usable(IP.fromString(network_input.broadcast)));
	foreach (item; network_output.hosts) {
		assert(ip.usable(IP.fromString(item)));
	}

	ip = IP.fromString("255.255.255.0");
	assert(ip.toString() == "255.255.255.0");
	ip.print();
	
	ip = IP.fromString("10.255.0.0/8");
	assert(ip.id().toString == "10.0.0.0");
	ip.print();

	auto ip2 = IP.fromString("10.255.0.1");
	assert(ip.contains(ip2));
	assert(ip2.toString == "10.255.0.1");
}


unittest {
	import std.socket;
	auto ip = IP.fromString("10.255.0.0/8");
	auto ip3 = IP(InternetAddress.parse("10.255.0.1"));
	assert(ip.contains(ip3));

	import std.exception;
	assertThrown!IPv6NotImplemented(IP(new Internet6Address(Internet6Address.parse("::ffff:127.0.0.1"), cast(ushort)0)));
}


unittest {
	auto net = IP.fromString("216.239.32.0/19");
	auto ip = IP.fromString("192.168.0.1");
	net.print();
	ip.print();
	assert(!net.contains(ip));
}
