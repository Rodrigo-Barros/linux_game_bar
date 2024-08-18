#! /usr/bin/env -S vala --pkg gtk+-3.0

public class MainWindow : Gtk.Application {
    private Pulse pulse;
    private Joystick joystick;
    private MainLoop loop;

    protected override void activate () {
        this.loop = new GLib.MainLoop ();
        // this.joystick = new Joystick ();
        this.pulse = new Pulse ();
        Gtk.ApplicationWindow window = new Gtk.ApplicationWindow (this);
        this.setup_window (window);

        // read joystick events
        // var timeout = new GLib.TimeoutSource (200);
        // timeout.set_callback (() => {
        // this.joystick.readEvents ();
        // return true;
        // });
        // timeout.attach (this.loop.get_context ());

        window.show_all ();
    }

    public void setup_window (Gtk.ApplicationWindow window) {
        window.title = "Linux Game Bar";
        // window.window_position = Gtk.WindowPosition.CENTER;
        window.destroy.connect (Gtk.main_quit);
        window.default_width = 1366;
        window.default_height = 768;
        window.decorated = true;
        window.set_gravity (Gdk.Gravity.CENTER);
        // window.fullscreen ();
        // window.opacity = 0;

        // sections
        Gtk.Box left = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        Gtk.Box center = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        Gtk.Box rigth = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);

        Gtk.Box layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);

        // widgets
        // Global Widgets

        // Left menu widgets
        Pulse.DefaultSink default_sink = this.pulse.get_default_sink ();
        Gtk.Label label = new Gtk.Label ("System " + default_sink.name);
        Gtk.Scale volume = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);

        volume.set_value (default_sink.volume);
        volume.value_changed.connect ((scale) => {
            int volume_old = default_sink.volume;
            int volume_current = (int) scale.get_value ();
            int volume_diff = volume_current - volume_old;

            if (volume_diff < 0) {
                print ("diminuindo o volume do sistema em %f\n", volume_diff);
                this.pulse.volume_down_sink (default_sink, volume_diff);
            } else {
                print ("aumentando o volume do sistema\n");
                this.pulse.volume_up_sink (default_sink, volume_diff);
            }
            default_sink.volume = volume_old + volume_diff;
            print ("Novo Volume %d\n", default_sink.volume);
        });

        // Pulse audio applications
        // TODO: For each of running applications

        Gtk.Expander expander = new Gtk.Expander ("Aplicações");
        // Gtk.Label label2 = new Gtk.Label ("Firefox");
        // Gtk.Scale volume2 = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);
        Gtk.Box box2 = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        // box2.add (label2);
        // box2.add (volume2);
        // expander.add (box2);
        foreach (var application in this.pulse.get_applications ()) {
            Gtk.Label label2 = new Gtk.Label (application.name);
            Gtk.Scale volume2 = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 100, 1);

            volume2.set_value (application.volume);
            volume2.value_changed.connect ((scale) => {
                int volume_old = application.volume;
                int volume_current = int.parse (scale.get_value ().to_string ());
                int volume_diff = volume_current - volume_old;

                print ("volume_diff: %d\n", volume_diff);
                if (volume_diff < 0) {
                    print ("diminuindo volume %s \n", application.name);
                    this.pulse.volume_down_application (application.id, volume_diff);
                } else {
                    print ("aumentando volume %s \n", application.name);
                    this.pulse.volume_up_application (application.id, volume_diff);
                }
                application.volume = volume_old + volume_diff;
                print ("Novo Volume %d\n", application.volume);
            });

            box2.add (label2);
            box2.add (volume2);
        }
        expander.add (box2);


        // Rigth menu widgets
        string now = new GLib.DateTime.now ().format ("%H:%M:%S");
        Gtk.Label clock = new Gtk.Label (now);

        var timeout = new GLib.TimeoutSource (1000);
        timeout.set_callback (() => {
            now = new GLib.DateTime.now ().format ("%H:%M:%S");
            clock.label = now;
            return true;
        });
        timeout.attach (this.loop.get_context ());


        // Left Menu
        left.add (label);
        left.add (volume);

        left.add (expander);

        // Center Menu

        // Right Menu
        rigth.add (clock);

        layout.add (left);
        layout.add (center);
        layout.add (rigth);
        layout.homogeneous = true;
        window.add (layout);
    }

    public static int render (string[] args) {
        MainWindow app = new MainWindow ();
        return app.run (args);
    }
}
