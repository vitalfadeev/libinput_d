import std.stdio             : writeln,writefln;
import std.string            : fromStringz;
import core.sys.posix.fcntl  : open;
import core.sys.posix.unistd : close;
import core.sys.posix.poll   : poll,pollfd,POLLIN,POLLHUP,POLLERR;
import core.sys.posix.time   : clock_gettime,timespec,CLOCK_MONOTONIC;
import core.stdc.errno       : errno;
import libinput_d;
import udev_d;

extern (C)
static int 
open_restricted (const char *path, int flags, void *user_data) {
    int fd = open (path, flags);
    return fd < 0 ? -errno : fd;
}

extern (C)
static void 
close_restricted (int fd, void *user_data) {
    close (fd);
}

const static 
libinput_interface 
_interface = libinput_interface (
    &open_restricted,
    &close_restricted,
);

void
main () {
	libinput* m_input;

	// add input devices
	{
	    libinput*       li;
	    libinput_event* event;

	    udev* dev = udev_new ();
	    li = libinput_udev_create_context (&_interface, null, dev);
	    if (!li)
	        return;
	    libinput_udev_assign_seat (li, "seat0");
	    libinput_dispatch (li);

	    bool successed = false;
	    while ((event = libinput_get_event (li)) != null) {
	        auto type = libinput_event_get_type (event);
	        switch (type) {
	        case libinput_event_type.LIBINPUT_EVENT_DEVICE_ADDED: {
	            libinput_device* _dev = libinput_event_get_device (event);
	            const char *name = libinput_device_get_name (_dev);
	            writefln ("%s added",name.fromStringz);
	            libinput_device_config_send_events_set_mode (_dev, libinput_config_send_events_mode.LIBINPUT_CONFIG_SEND_EVENTS_ENABLED);
	            if (libinput_device_has_capability (_dev, libinput_device_capability.LIBINPUT_DEVICE_CAP_TOUCH)) {
	                writeln ("has cap touch");
	                libinput_device_ref (_dev);
	                // config device?
	            }
	            break;
	        }
	        default:
	            writefln ("other event %d", type);
	            break;
	        }
	        libinput_event_destroy (event);
	        libinput_dispatch (li);

	        successed = true;
	    }

	    if (!successed)
	        writeln ("can not get devices, maybe permission problem.");

	    m_input = li;
	    writeln (li);
	}

	// monitor
	{
		libinput* 		li = m_input;
		libinput_event* event;

		pollfd fds;

		fds.fd = libinput_get_fd (li);
		fds.events = POLLIN;
		fds.revents = 0;
		/* time offset starts with our first received event */
		if (poll (&fds, 1, -1) > -1) {
		    timespec tp;

		    clock_gettime (CLOCK_MONOTONIC, &tp);
		    //start_time = tp.tv_sec * 1000 + tp.tv_nsec / 1000000;
		    do {
		        libinput_dispatch (li);
		        while ((event = libinput_get_event (li)) != null) {

		            // handle the event here
		            auto type = libinput_event_get_type (event);
		            //writeln("loop");
		            writeln (type);

		            switch (type) {
		            case libinput_event_type.LIBINPUT_EVENT_TOUCH_DOWN:
		            case libinput_event_type.LIBINPUT_EVENT_TOUCH_MOTION:
		            case libinput_event_type.LIBINPUT_EVENT_TOUCH_UP:
		            case libinput_event_type.LIBINPUT_EVENT_TOUCH_FRAME:
		            case libinput_event_type.LIBINPUT_EVENT_TOUCH_CANCEL: {
		                //writeln ("touch event %d", type);
		                //if (m_touchScreenGestureManager) {
		                //    m_touchScreenGestureManager.processEvent (event);
		                //}
	                    writeln ("m_touchScreenGestureManager");
		                break;
		            }

		            case libinput_event_type.LIBINPUT_EVENT_GESTURE_SWIPE_BEGIN:
		            case libinput_event_type.LIBINPUT_EVENT_GESTURE_SWIPE_UPDATE:
		            case libinput_event_type.LIBINPUT_EVENT_GESTURE_SWIPE_END:
		            case libinput_event_type.LIBINPUT_EVENT_GESTURE_PINCH_BEGIN:
		            case libinput_event_type.LIBINPUT_EVENT_GESTURE_PINCH_UPDATE:
		            case libinput_event_type.LIBINPUT_EVENT_GESTURE_PINCH_END: {
		                //TouchpadGestureManager::getManager().processEvent (event);
		                writeln ("TouchpadGestureManager");
		                break;
		            }
		            default:
		                //writeln ("other event %d\n", type);
		                break;
		            }
		            libinput_event_destroy (event);
		            libinput_dispatch (li);
		        }
		    } while (/*!stop && */poll (&fds, 1, -1) > -1);
		}

		libinput_unref (li);		
	}

	writeln ("Edit source/app.d to start your project.");
}
