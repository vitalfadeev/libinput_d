import std.conv        : to;
import std.stdio       : writeln,writefln;
import libinput_struct : LibInput;
import libinput_d      : LIBINPUT_EVENT_DEVICE_ADDED;



void
main () {
	foreach (event; LibInput (null))
		switch (event.type) {
			case LIBINPUT_EVENT_DEVICE_ADDED:
				writefln ("%s: %s added", event.type.to!string, event.device.name.to!string); break;
			default:
				writeln (event.type);
		}
}

