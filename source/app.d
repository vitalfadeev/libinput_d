import std.stdio : writeln,writefln;
import libinput_struct : LibInput;


void
main () {
	foreach (libinput_event; LibInput (""))
		writeln (libinput_event.type);
}

