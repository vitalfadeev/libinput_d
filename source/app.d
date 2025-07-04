import std.stdio : writeln,writefln;
import libinput_struct : LibInput;


void
main () {
	foreach (event; LibInput (""))
		switch (event.type) {
			case "LIBINPUT_EVENT_DEVICE_ADDED":
				writefln ("%s: %s added", event.type, event.device.name); break;
			default:
				writeln (event.type);
		}
}

