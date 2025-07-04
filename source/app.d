import std.conv        : to;
import std.stdio       : writeln,writefln;
import libinput_struct : LibInput;
import libinput_d;



void
main () {
	foreach (event; LibInput (null))
		switch (event.type) {
			case LIBINPUT_EVENT_DEVICE_ADDED:
				writefln ("%s: %s added", event.type.to!string, event.device.name.to!string); break;
			case LIBINPUT_EVENT_KEYBOARD_KEY:
				writefln ("%s: %d: %s", event.type.to!string, event.keyboard.get_key, event.keyboard.get_key_state.to!string); break;
			case LIBINPUT_EVENT_POINTER_MOTION:
			case LIBINPUT_EVENT_POINTER_MOTION_ABSOLUTE:
				writefln ("%s", event.type.to!string); break;
			case LIBINPUT_EVENT_POINTER_BUTTON:
				writefln ("%s: %d", event.type.to!string, event.pointer.button); break;
			case LIBINPUT_EVENT_POINTER_AXIS:
				writefln ("%s", event.type.to!string); break;
			case LIBINPUT_EVENT_TOUCH_DOWN:
			case LIBINPUT_EVENT_TOUCH_UP:
			case LIBINPUT_EVENT_TOUCH_MOTION:
			case LIBINPUT_EVENT_TOUCH_CANCEL:
			case LIBINPUT_EVENT_TOUCH_FRAME:
				writefln ("%s", event.type.to!string); break;
			case LIBINPUT_EVENT_TABLET_TOOL_AXIS:
			case LIBINPUT_EVENT_TABLET_TOOL_PROXIMITY:
			case LIBINPUT_EVENT_TABLET_TOOL_TIP:
			case LIBINPUT_EVENT_TABLET_TOOL_BUTTON:
				writefln ("%s", event.type.to!string); break;
			case LIBINPUT_EVENT_GESTURE_SWIPE_BEGIN:
			case LIBINPUT_EVENT_GESTURE_SWIPE_UPDATE:
			case LIBINPUT_EVENT_GESTURE_SWIPE_END:
			case LIBINPUT_EVENT_GESTURE_PINCH_BEGIN:
			case LIBINPUT_EVENT_GESTURE_PINCH_UPDATE:
			case LIBINPUT_EVENT_GESTURE_PINCH_END:
				writefln ("%s", event.type.to!string); break;
			default:
				writeln (event.type);
		}
}

