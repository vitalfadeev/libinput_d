import std.stdio             : writeln,writefln;
import std.string            : fromStringz;
import core.sys.posix.fcntl  : open;
import core.sys.posix.unistd : close;
import core.sys.posix.poll   : poll,pollfd,POLLIN,POLLHUP,POLLERR;
import core.sys.posix.time   : clock_gettime,timespec,CLOCK_MONOTONIC;
import core.stdc.errno       : errno;
import core.stdc.stdio       : printf;
import libinput_d;
import udev_d;


struct
LibInput {
    libinput*           _li;
    udev*               _udev;
    libinput_interface _interface;
    Event              event;

    this (libinput* _li) {
        if (_li is null)
            _init ();
    }

    ~this () {
        _quit ();
    }

    int
    opApply (int delegate (Event event) dg) {
        pollfd fds;

        fds.fd = get_fd ();
        fds.events = POLLIN;
        fds.revents = 0;

        do {
            for (dispatch (), event = get_event (); 
                event != null; 
                event.destroy (), dispatch (), event = get_event ()
            ) {
                // dg
                if (auto result = dg (event)) {
                    event.destroy ();
                    return result;  // EXIT
                }
 
                // add device for listen
                switch (event.type) {
                    case LIBINPUT_EVENT_DEVICE_ADDED: {
                        auto _dev =  event.device;
                        _dev.config.send_events_set_mode (LIBINPUT_CONFIG_SEND_EVENTS_ENABLED);
                        if (_dev.has_capability (LIBINPUT_DEVICE_CAP_TOUCH))
                            _dev.ref_ ();
                        break;
                    }
                    default:
                }
            }
        } while (poll (&fds, 1, -1) >= 0);

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
        _interface.open_restricted  = &_open_restricted;
        _interface.close_restricted = &_close_restricted;

        _li = udev_create_context (&_interface, null, _udev);

        if (!_li)
            throw new Exception ("libevent: udev: init [FAIL] ");

        udev_assign_seat ("seat0");
    }

    void
    _quit () {
        unref ();       
    }


    pragma (inline,true):
    int         dispatch ()  { return libinput_dispatch (_li); }
    Event       get_event () { return cast (Event) (libinput_get_event (_li)); }
    libinput*   unref ()     { return libinput_unref (_li); }
    int         get_fd ()    { return libinput_get_fd (_li); }
    int         udev_assign_seat (const(char)* seat_id) { return libinput_udev_assign_seat (_li,seat_id); }
    libinput*   udev_create_context (const(libinput_interface)* interface_,void* user_data,udev* udev) { return libinput_udev_create_context (interface_,user_data,udev); }

}

struct
Event {
    libinput_event* event;
    alias event this;

    libinput_event_type type ()    { return libinput_event_get_type (event); }
    Device              device  () { return (cast (Device)  (libinput_event_get_device (event))); }
    Pointer             pointer () { return (cast (Pointer) (libinput_event_get_pointer_event (event))); }
    void                destroy () {        libinput_event_destroy (event); }
}

struct
Device {
    libinput_device* device;
    alias device this;
    
    pragma (inline,true):
    libinput_device*                        ref_ ()                         { return libinput_device_ref (device); }
    libinput_device*                        unref ()                        { return libinput_device_unref (device); }
    void                                    user_data (void* user_data)     {        libinput_device_set_user_data (device, user_data); }
    void*                                   user_data ()                    { return libinput_device_get_user_data (device); }
    libinput*                               get_context ()                  { return libinput_device_get_context (device); }
    libinput_device_group*                  device_group ()                 { return libinput_device_get_device_group (device); }
    const(char)*                            sysname ()                      { return libinput_device_get_sysname (device); }
    const(char)*                            name ()                         { return libinput_device_get_name (device); }
    uint                                    id_product ()                   { return libinput_device_get_id_product (device); }
    uint                                    id_vendor ()                    { return libinput_device_get_id_vendor (device); }
    const(char)*                            output_name ()                  { return libinput_device_get_output_name (device); }
    libinput_seat*                          seat ()                         { return libinput_device_get_seat (device); }
    int                                     set_seat_logical_name (const(char)* name) { return libinput_device_set_seat_logical_name (device,name); }
    udev_device*                            get_udev_device ()              { return libinput_device_get_udev_device (device); }
    void                                    led_update (libinput_led leds)  {        libinput_device_led_update (device, leds); }
    int                                     has_capability (libinput_device_capability capability) { return libinput_device_has_capability (device, capability); }
    int                                     get_size (double* width,double* height)                         { return libinput_device_get_size (device,width,height); }
    int                                     pointer_has_button (uint code)          { return libinput_device_pointer_has_button (device, code); }
    int                                     keyboard_has_key (uint code)    { return libinput_device_keyboard_has_key (device, code); }
    Config                                  config () { return (cast (Config) device); }
}

struct
Config {
    libinput_device* device;
    alias device this;

    int                                     tap_get_finger_count ()  { return libinput_device_config_tap_get_finger_count (device); }
    libinput_config_status                  tap_set_enabled (libinput_config_tap_state enable)                      { return libinput_device_config_tap_set_enabled (device,enable); }
    libinput_config_tap_state               tap_get_enabled ()       { return libinput_device_config_tap_get_enabled (device); }
    libinput_config_tap_state               tap_get_default_enabled ()              { return libinput_device_config_tap_get_default_enabled (device); }
    libinput_config_status                  tap_set_drag_lock_enabled (libinput_config_drag_lock_state enable)            { return libinput_device_config_tap_set_drag_lock_enabled (device, enable); }
    libinput_config_drag_lock_state         tap_get_drag_lock_enabled ()    { return libinput_device_config_tap_get_drag_lock_enabled (device); }
    libinput_config_drag_lock_state         tap_get_default_drag_lock_enabled () { return libinput_device_config_tap_get_default_drag_lock_enabled (device); }
    int                                     calibration_has_matrix ()       { return libinput_device_config_calibration_has_matrix (device); }
    libinput_config_status                  calibration_set_matrix (ref const(float)[6] matrix)       { return libinput_device_config_calibration_set_matrix (device, matrix); }
    int                                     calibration_get_matrix (ref float[6] matrix)       { return libinput_device_config_calibration_get_matrix (device, matrix); }
    int                                     calibration_get_default_matrix (ref float[6] matrix) { return libinput_device_config_calibration_get_default_matrix (device, matrix); }
    uint                                    send_events_get_modes ()        { return libinput_device_config_send_events_get_modes (device); }
    libinput_config_status                  send_events_set_mode (uint mode)         { return libinput_device_config_send_events_set_mode (device,mode); }
    uint                                    send_events_get_mode ()         { return libinput_device_config_send_events_get_mode (device); }
    uint                                    send_events_get_default_mode () { return libinput_device_config_send_events_get_default_mode (device); }
    int                                     accel_is_available ()           { return libinput_device_config_accel_is_available (device); }
    libinput_config_status                  accel_set_speed (double speed)              { return libinput_device_config_accel_set_speed (device, speed); }
    double                                  accel_get_speed ()              { return libinput_device_config_accel_get_speed (device); }
    double                                  accel_get_default_speed ()      { return libinput_device_config_accel_get_default_speed (device); }
    uint                                    accel_get_profiles ()           { return libinput_device_config_accel_get_profiles (device); }
    libinput_config_status                  accel_set_profile (libinput_config_accel_profile mode)            { return libinput_device_config_accel_set_profile (device, mode); }
    libinput_config_accel_profile           accel_get_profile ()            { return libinput_device_config_accel_get_profile (device); }
    libinput_config_accel_profile           config_accel_get_default_profile ()    { return libinput_device_config_accel_get_default_profile (device); }
    int                                     scroll_has_natural_scroll ()    { return libinput_device_config_scroll_has_natural_scroll (device); }
    libinput_config_status                  scroll_set_natural_scroll_enabled (int enable) { return libinput_device_config_scroll_set_natural_scroll_enabled (device,enable); }
    int                                     scroll_get_natural_scroll_enabled () { return libinput_device_config_scroll_get_natural_scroll_enabled (device); }
    int                                     scroll_get_default_natural_scroll_enabled () { return libinput_device_config_scroll_get_default_natural_scroll_enabled (device); }
    int                                     left_handed_is_available ()     { return libinput_device_config_left_handed_is_available (device); }
    libinput_config_status                  left_handed_set (int left_handed)              { return libinput_device_config_left_handed_set (device,left_handed); }
    int                                     left_handed_get ()              { return libinput_device_config_left_handed_get (device); }
    int                                     left_handed_get_default ()      { return libinput_device_config_left_handed_get_default (device); }
    uint                                    click_get_methods ()            { return libinput_device_config_click_get_methods (device); }
    libinput_config_status                  click_set_method (libinput_config_click_method method)             { return libinput_device_config_click_set_method (device, method); }
    libinput_config_click_method            click_get_method ()             { return libinput_device_config_click_get_method (device); }
    libinput_config_click_method            click_get_default_method ()     { return libinput_device_config_click_get_default_method (device); }
    int                                     middle_emulation_is_available () { return libinput_device_config_middle_emulation_is_available (device); }
    libinput_config_status                  middle_emulation_set_enabled (libinput_config_middle_emulation_state enable) { return libinput_device_config_middle_emulation_set_enabled (device, enable); }
    libinput_config_middle_emulation_state  middle_emulation_get_enabled () { return libinput_device_config_middle_emulation_get_enabled (device); }
    libinput_config_middle_emulation_state  middle_emulation_get_default_enabled () { return libinput_device_config_middle_emulation_get_default_enabled (device); }
    uint                                    scroll_get_methods ()           { return libinput_device_config_scroll_get_methods (device); }
    libinput_config_status                  scroll_set_method (libinput_config_scroll_method method)            { return libinput_device_config_scroll_set_method (device, method); }
    libinput_config_scroll_method           scroll_get_method ()            { return libinput_device_config_scroll_get_method (device); }
    libinput_config_scroll_method           scroll_get_default_method ()    { return libinput_device_config_scroll_get_default_method (device); }
    libinput_config_status                  scroll_set_button (uint button) { return libinput_device_config_scroll_set_button (device, button); }
    uint                                    scroll_get_button ()            { return libinput_device_config_scroll_get_button (device); }
    uint                                    scroll_get_default_button ()    { return libinput_device_config_scroll_get_default_button (device); }
    int                                     dwt_is_available ()             { return libinput_device_config_dwt_is_available (device); }
    libinput_config_status                  dwt_set_enabled (libinput_config_dwt_state enable)              { return libinput_device_config_dwt_set_enabled (device, enable); }
    libinput_config_dwt_state               dwt_get_enabled ()              { return libinput_device_config_dwt_get_enabled (device); }
    libinput_config_dwt_state               dwt_get_default_enabled ()      { return libinput_device_config_dwt_get_default_enabled (device); }
}

struct
Pointer {
    libinput_event_pointer* event;
    alias event this;

    pragma (inline,true):
    uint                         time ()                                          { return libinput_event_pointer_get_time (event); }
    ulong                        time_usec ()                                     { return libinput_event_pointer_get_time_usec (event); }
    double                       dx ()                                            { return libinput_event_pointer_get_dx (event); }
    double                       dy ()                                            { return libinput_event_pointer_get_dy (event); }
    double                       dx_unaccelerated ()                              { return libinput_event_pointer_get_dx_unaccelerated (event); }
    double                       dy_unaccelerated ()                              { return libinput_event_pointer_get_dy_unaccelerated (event); }
    double                       absolute_x ()                                    { return libinput_event_pointer_get_absolute_x (event); }
    double                       absolute_y ()                                    { return libinput_event_pointer_get_absolute_y (event); }
    double                       absolute_x_transformed (uint width)              { return libinput_event_pointer_get_absolute_x_transformed (event, width); }
    double                       absolute_y_transformed (uint height)             { return libinput_event_pointer_get_absolute_y_transformed (event, height); }
    uint                         button ()                                        { return libinput_event_pointer_get_button (event); }
    libinput_button_state        button_state ()                                  { return libinput_event_pointer_get_button_state (event); }
    uint                         seat_button_count ()                             { return libinput_event_pointer_get_seat_button_count (event); }
    int                          has_axis (libinput_pointer_axis axis)            { return libinput_event_pointer_has_axis (event,axis); }
    double                       axis_value (libinput_pointer_axis axis)          { return libinput_event_pointer_get_axis_value (event,axis); }
    libinput_pointer_axis_source axis_source ()                                   { return libinput_event_pointer_get_axis_source (event); }
    double                       axis_value_discrete (libinput_pointer_axis axis) { return libinput_event_pointer_get_axis_value_discrete (event,axis); }
    libinput_event*              base_event ()                                    { return libinput_event_pointer_get_base_event (event); }
}
