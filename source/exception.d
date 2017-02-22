module cidr.exception;

class IPv6NotImplemented : Throwable {
	this(string msg, Exception next, const string file=__FILE__, const size_t line=__LINE__) {
		super(msg, file, line, next);
	}
	this(string msg, const string file=__FILE__, const size_t line=__LINE__, Exception next=null) {
		super(msg, file, line, next);
	}
}
