import std.stdio             : writeln,writefln;
import std.string            : fromStringz;
import std.conv              : to;
import core.sys.posix.fcntl  : open;
import core.sys.posix.unistd : close;
import core.sys.posix.poll   : poll,pollfd,POLLIN,POLLHUP,POLLERR;
import core.sys.posix.time   : clock_gettime,timespec,CLOCK_MONOTONIC;
import core.stdc.errno       : errno;
import core.stdc.stdio       : printf;
import libinput_d;
import udev_d;


void
main () {
	foreach (libinput_event; LibInput (""))
		writeln (libinput_event.type);
}

struct
LibInput {
	libinput*       	_li;
	udev*           	_udev;
	libinput_interface _interface;
	libinput_event* 	event;

	this (string args) {
		_init ();
	}

	~this () {
		_quit ();
	}

	int
	opApply (int delegate (LibInput_Event event) dg) {
		pollfd fds;

		fds.fd = libinput_get_fd (_li);
		fds.events = POLLIN;
		fds.revents = 0;

		while (/*!stop && */poll (&fds, 1, -1) > -1) {
			for (libinput_dispatch (_li), event = libinput_get_event (_li); event != null; libinput_event_destroy (event), libinput_dispatch (_li), event = libinput_get_event (_li)) {
				// dg
				if (auto result = dg (cast (LibInput_Event) event)) {
					libinput_event_destroy (event);
				    return result;  // EXIT
				}
 
				// add device for listen
				auto type = libinput_event_get_type (event);
				switch (type) {
					case LIBINPUT_EVENT_DEVICE_ADDED: {
					    libinput_device* _dev = libinput_event_get_device (event);
					    printf ("%s added\n",libinput_device_get_name (_dev));
					    libinput_device_config_send_events_set_mode (_dev, LIBINPUT_CONFIG_SEND_EVENTS_ENABLED);
					    if (libinput_device_has_capability (_dev, LIBINPUT_DEVICE_CAP_TOUCH)) {
					        printf ("has cap touch\n");
					        libinput_device_ref (_dev);
					    }
					    break;
					}
					default:
				}
            }
		} 

	    return 0;
	}	

	extern (C)
	static int 
	_open_restricted (const char *path, int flags, void *user_data) {
	    int fd = open (path, flags);
	    return fd < 0 ? -errno : fd;
	}

	extern (C)
	static void 
	_close_restricted (int fd, void *user_data) {
	    close (fd);
	}

	// add input devices
	void
	_init () {
	    _udev = udev_new ();
	    _interface = libinput_interface (
	        &_open_restricted,
	        &_close_restricted,
	    );

	    _li = libinput_udev_create_context (&_interface, null, _udev);

	    if (!_li)
	        throw new Exception ("libevent: udev: init [FAIL] ");

	    libinput_udev_assign_seat (_li, "seat0");
	}

	void
	_quit () {
		libinput_unref (_li);	    
	}
}

struct
LibInput_Event {
    libinput_event* _super;
    alias _super this;

    string
    type () {
    	auto type = libinput_event_get_type (_super);
    	return (cast (libinput_event_type) type).to!string;
    }
}
