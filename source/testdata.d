struct IPTest {
	string input;
	string output;
}
struct NetworkTestInput {
	string ip, network;
	string id;
	string broadcast;
	string ip_host;
	string ip_host_fail;
	string mask;
}
struct NetworkTestOutput {
	string network;
	string network_string;
	string netmask;
	ubyte netmask_int;
	string[] hosts;
	string[] range;
}
struct NetworkTest {
	NetworkTestInput input;
	NetworkTestOutput output;
}
struct Tests {
	IPTest ip;
	NetworkTest network;
}
enum static IPTest ip = {
	input: `192.168.10.102`,
	output: `192.168.10.102`,
};

enum static NetworkTestInput network_input = {
	ip: `12.168.45.192`,
	network: `12.168.45.192/30`,
	id: `12.168.45.192`,
	ip_host: `12.168.45.193`,
	broadcast: `12.168.45.195`,
	ip_host_fail: `12.168.45.196`,
	mask: `255.255.255.252`,
};

enum static NetworkTestOutput network_output = {
	network: `12.168.45.192`,
	network_string: `12.168.45.192/30`,
	netmask: `255.255.255.252`,
	netmask_int: 30,
	range: [
		`12.168.45.192`,
		`12.168.45.193`,
		`12.168.45.194`,
		`12.168.45.195`,
	],
	hosts: [
		`12.168.45.193`,
		`12.168.45.194`,
	],
};
