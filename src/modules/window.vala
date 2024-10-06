public class MainWindow : Gtk.Application {
    public Pulse pulse;
    private Joystick joystick;
    private MediaPlayer media_player;
    private MainLoop loop;
    private Gtk.ApplicationWindow window;
    private Settings settings;
    public Action action;

    protected override void activate () {
        this.loop = new GLib.MainLoop ();
        this.pulse = new Pulse ();
        Gtk.ApplicationWindow window = new Gtk.ApplicationWindow (this);
        this.action = new Action (this);
        this.joystick = new Joystick (this);
        this.media_player = new MediaPlayer ();
        this.setup_window (window);
        this.settings = new Settings ();
        window.show_all ();

        this.window = window;
    }

    public void setup_window (Gtk.ApplicationWindow window) {
        try {
            var cssProvider = new Gtk.CssProvider ();
            cssProvider.load_from_path ("../src/app.css");
            Gtk.StyleContext.add_provider_for_screen (Gdk.Screen.get_default (), cssProvider, Gtk.STYLE_PROVIDER_PRIORITY_USER);
        } catch (Error e) {
            print ("O arquivo de estilo não foi encontrado");
        }

        Gdk.Screen screen = Gdk.Screen.get_default ();

        int pulse_audio_max_volume = (int) Settings.get ("modules.pulseaudio.max_volume").get_int ();

        window.title = "Linux Game Bar";

        // window.window_position = Gtk.WindowPosition.CENTER;
        window.default_width = screen.get_width ();
        window.default_height = screen.get_height ();

        window.destroy.connect (Gtk.main_quit);

        // sections
        Gtk.Box left = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        Gtk.Box center = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        Gtk.Box rigth = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);

        Gtk.Box layout = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 5);

        // widgets
        // Global Widgets

        string player_title = this.media_player.get_title ();
        string player_image = this.media_player.get_image ();

        // Left menu widgets
        Pulse.DefaultSink default_sink = this.pulse.get_default_sink ();
        Gtk.Label label = new Gtk.Label ("System " + default_sink.name);
        Gtk.Scale volume = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, pulse_audio_max_volume, 1);
        Gtk.Box pulse_audio = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
        Gtk.Box media_control = new Gtk.Box (Gtk.Orientation.VERTICAL, 1);
        Gtk.Scale media_control_time = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, 60, 1);
        Gtk.Box media_control_h = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 1);
        Gtk.Box actions_menu = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 1);
        Gtk.Image media_control_image = new Gtk.Image ();
        Gtk.Label media_control_label = new Gtk.Label ("No Media");
        Gtk.Button media_prev = new Gtk.Button.from_icon_name ("media-skip-backward-symbolic", Gtk.IconSize.BUTTON);
        Gtk.Button media_play_pause = new Gtk.Button.from_icon_name (this.media_player.get_play_image (), Gtk.IconSize.BUTTON);
        Gtk.Button media_next = new Gtk.Button.from_icon_name ("media-skip-forward-symbolic", Gtk.IconSize.BUTTON);
        Gtk.Button battery = new Gtk.Button.from_icon_name (this.joystick.get_battery_icon (), Gtk.IconSize.LARGE_TOOLBAR);
        battery.get_style_context ().add_class ("battery");

        media_prev.clicked.connect (this.media_player.prev);
        media_play_pause.clicked.connect (this.media_player.play_pause);
        media_next.clicked.connect (this.media_player.next);
        media_control_time.format_value.connect (this.media_player.format_track);


        media_control_image.set_from_file (player_image);
        media_control_label.set_label (player_title);
        volume.set_value (default_sink.volume);

        volume.value_changed.connect ((scale) => {
            int volume_old = default_sink.volume;
            int volume_current = (int) scale.get_value ();
            int volume_diff = volume_current - volume_old;

            if (volume_current == pulse_audio_max_volume || volume_current == 0) {
                volume.error_bell ();
            }

            if (volume_diff < 0) {
                if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                    print ("diminuindo o volume do sistema em %f\n", volume_diff);
                }
                this.pulse.volume_down_sink (default_sink, volume_diff);
            } else {
                if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                    print ("aumentando o volume do sistema\n");
                }
                this.pulse.volume_up_sink (default_sink, volume_diff);
            }
            default_sink.volume = volume_old + volume_diff;
            if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                print ("Novo Volume %d\n", default_sink.volume);
            }
        });

        media_control_time.value_changed.connect (this.media_player.set_position);

        // Pulse audio applications

        Gtk.Expander expander = new Gtk.Expander ("Aplicações");

        Gtk.Box box2 = new Gtk.Box (Gtk.Orientation.VERTICAL, 5);
        this.render_pulse (box2, pulse_audio_max_volume);
        expander.add (box2);


        // Rigth menu widgets
        string clock_format = Settings.get ("modules.clock.format").get_string ();
        int clock_update_interval = (int) Settings.get ("modules.clock.update_interval").get_int ();
        int joystick_read_buttons_interval = (int) Settings.get ("modules.joystick.read_buttons_interval").get_int ();

        string now = new GLib.DateTime.now ().format (clock_format);
        Gtk.Label clock = new Gtk.Label (now);
        clock.get_style_context ().add_class ("clock");

        this.media_player.update_track_time (media_control_time);

        // update clock
        var timeout = new GLib.TimeoutSource (clock_update_interval);
        timeout.set_callback (() => {
            now = new GLib.DateTime.now ().format (clock_format);
            clock.label = now;
            string? player_bus_name = this.media_player.getPlayer ();
            if (player_bus_name != null) {
                this.media_player.setupPlayer (player_bus_name);
                player_bus_name = this.media_player.getPlayer ();
            }

            player_title = this.media_player.get_title ();
            player_image = this.media_player.get_image ();
            player_title = player_title == null ? "No Media" : player_title;

            var img = new Gtk.Image ();
            img.set_from_icon_name (this.media_player.get_play_image (), Gtk.IconSize.BUTTON);
            media_play_pause.set_image (img);
            // media_play_pause = new Gtk.Button.from_icon_name (this.media_player.get_play_image (), Gtk.IconSize.BUTTON);

            media_control_label.set_label (player_title);
            media_control_image.set_from_file (player_image);
            this.render_pulse (box2, pulse_audio_max_volume);
            this.media_player.update_track_time (media_control_time);
            return true;
        });

        timeout.attach (this.loop.get_context ());

        var timeout_joystick = new GLib.TimeoutSource (joystick_read_buttons_interval);
        timeout_joystick.set_callback (() => {
            this.joystick.readEvents ();
            return true;
        });
        timeout_joystick.attach (this.loop.get_context ());

        // battery.set_halign (Gtk.Align.END);
        actions_menu.pack_start (clock, true, true, 0);
        actions_menu.add (battery);
        // actions_menu.homogeneous = true;

        // Left Menu
        // left.add (label);
        // left.add (volume);

        // left.add (expander);

        pulse_audio.add (label);
        pulse_audio.add (volume);
        pulse_audio.add (expander);
        pulse_audio.get_style_context ().add_class ("pulse");

        media_control.get_style_context ().add_class ("media-control");
        media_control.add (media_control_label);
        media_control.add (media_control_image);
        media_control.add (media_control_time);

        media_control_h.add (media_prev);
        media_control_h.add (media_play_pause);
        media_control_h.add (media_next);
        media_control_h.homogeneous = true;

        media_control.add (media_control_h);
        left.add (pulse_audio);
        left.add (media_control);

        // Center Menu

        // Right Menu
        rigth.add (clock);
        rigth.add (actions_menu);

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

    public void toggle () {
        if (this.window.visible) {
            this.window.hide ();
        } else {
            this.window.show ();
        }
    }

    public bool visible () {
        return this.window.visible;
    }

    public Gtk.ApplicationWindow get_window () {
        return this.window;
    }

    public void render_pulse (Gtk.Box box, int max_volume) {

        GLib.List<weak Gtk.Widget> children = box.get_children ();
        bool clear_children = children.length () > 0;
        Gtk.Widget focus_child = box.get_focus_child ();
        int focus_id = 0;
        int counter = 0;

        if (clear_children) {

            box.foreach ((el) => {

                if (focus_child is Gtk.Widget && el is Gtk.Widget) {
                    if (focus_child.get_path ().to_string () == el.get_path ().to_string ()) {
                        focus_id = counter;
                    }
                }

                box.remove (el);
                counter++;
            });
        }

        foreach (var application in this.pulse.get_applications ()) {
            string title = (application.name + " - " + application.title);
            int title_size = title.length;
            int title_limit = 50;
            Gtk.Label label;
            Gtk.Scale volume;
            title = title_size < title_limit ? title : title.substring (0, title_limit).concat ("...");

            label = new Gtk.Label (title);
            volume = new Gtk.Scale.with_range (Gtk.Orientation.HORIZONTAL, 0, max_volume, 1);

            volume.set_value (application.volume);
            volume.value_changed.connect ((scale) => {
                int volume_old = application.volume;
                int volume_current = int.parse (scale.get_value ().to_string ());
                int volume_diff = volume_current - volume_old;

                if (volume_current == max_volume || volume_current == 0) {
                    volume.error_bell ();
                }

                if (volume_diff < 0) {
                    this.pulse.volume_down_application (application.id, volume_diff);
                } else {
                    this.pulse.volume_up_application (application.id, volume_diff);
                }
                // application.volume = volume_old + volume_diff;
            });

            box.add (label);
            box.add (volume);
        }

        if (clear_children) {
            counter = 0;

            box.show_all ();
            box.foreach ((el) => {
                if (focus_id == counter) {
                    el.grab_focus ();
                }
                counter++;
            });
        }
    }
}
