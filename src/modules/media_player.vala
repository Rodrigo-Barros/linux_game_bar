#! /usr/bin/valac --pkg gio-2.0

[DBus (name = "org.freedesktop.DBus")]
interface Freedesktop : Object {
    public abstract string[] list_names () throws GLib.Error;
}

[DBus (name = "org.mpris.MediaPlayer2.Player")]
interface Player : Object {
    public abstract bool can_go_previous { get; }
    public abstract bool can_play { get; }
    public abstract bool can_go_next { get; }
    public abstract string playback_status { owned get; default = "Stopped"; }
    public abstract bool can_seek { get; default = false; }
    public abstract HashTable<string, Variant> metadata  { owned get; }

    public abstract void previous () throws GLib.Error;
    public abstract void next () throws GLib.Error;
    public abstract void play_pause () throws GLib.Error;
    public abstract void set_position (ObjectPath track_id, int64 position) throws GLib.Error;
}

[DBus (name = "org.freedesktop.DBus.Properties")]
interface Properties : Object {
    public signal void properties_changed (string path, HashTable<string, Variant> info, string[] v);

    public abstract Variant get (string arg_1, string arg_2) throws GLib.Error;
    public abstract HashTable<string, Variant> get_all (string arg_1) throws GLib.Error;
}

public class MediaPlayer : Object {
    Player player = null;
    Properties player_props = null;
    int64 position = 0;

    public MediaPlayer () {
        string player_name = this.getPlayer ();
        if (player_name != null) {
            this.setupPlayer (player_name);
        }
    }

    public void setupPlayer (string player_name) {
        try {
            this.player = Bus.get_proxy_sync (BusType.SESSION, player_name, "/org/mpris/MediaPlayer2");
            this.player_props = Bus.get_proxy_sync (BusType.SESSION, player_name, "/org/mpris/MediaPlayer2");
        } catch (GLib.Error e) {
            stdout.printf ("%s\n", e.message);
        }
    }

    public string[] getBusNames () {
        Freedesktop freedesktop = null;
        string[] bus_names = {};
        try {
            freedesktop = Bus.get_proxy_sync (BusType.SESSION, "org.freedesktop.DBus", "/org/freedesktop/DBus");
            foreach (string name in freedesktop.list_names ()) {
                bus_names += name;
            }
        } catch (GLib.Error e) {
            print ("Dbus Connect Error: %s", e.message);
        }
        return bus_names;
    }

    public string ? getPlayer () {
        string player = null;
        foreach (string name in this.getBusNames ()) {
            if ("org.mpris.MediaPlayer2" in name) {
                player = name;
                break;
            }
        }
        return player;
    }

    public string get_play_image (bool reverse = false) {
        string btn_image = "media-playback-stop-symbolic";

        if (this.player != null) {
            switch (this.player.playback_status) {
            case "Stopped":
                btn_image = "media-playback-stop-symbolic";
                break;
            case "Paused":
                btn_image = "media-playback-start-symbolic";
                break;
            case "Playing":
                btn_image = "media-playback-pause-symbolic";
                break;
            }
        }
        return btn_image;
    }

    public void prev (Gtk.Button btn) {
        bool error = false;
        if (this.player != null) {
            try {
                if (this.player.can_go_previous) {
                    this.player.previous ();
                } else {
                    error = true;
                }
            } catch (GLib.Error e) {
                print ("Error: %s\n", e.message);
            }
        } else {
            error = true;
        }
        if (error)
            btn.error_bell ();
    }

    public void play_pause (Gtk.Button btn) {
        bool error = false;
        if (this.player != null) {
            try {
                if (this.player.can_play) {
                    this.player.play_pause ();
                } else {
                    error = true;
                }
            } catch (GLib.Error e) {
                print ("Error: %s", e.message);
            }
        } else {
            error = true;
        }

        if (error)
            btn.error_bell ();
    }

    public void next (Gtk.Button btn) {
        bool error = false;
        if (this.player != null) {
            try {
                if (this.player.can_go_next) {
                    this.player.next ();
                } else {
                    error = true;
                }
            } catch (GLib.Error e) {
                print ("Error: %s", e.message);
            }
        } else {
            error = true;
        }
        if (error)
            btn.error_bell ();
    }

    public string get_title (uint title_limit = 50) {
        string title = "No Media";
        Variant title_prop;
        uint title_size;
        if (this.player != null) {
            title_prop = this.get_media_prop ("xesam:title");
            title = title_prop != null? title_prop.get_string () : title;

            title_size = title.length;
            if (title != null) {
                title = title_size < title_limit ? title : title.substring (0, title_limit).concat ("...");
            }
        }

        return title;
    }

    public string get_image () {
        string image = "/usr/share/icons/HighContrast/48x48/animations/process-idle.svg";
        Variant player_image = this.get_media_prop ("mpris:artUrl");
        if (this.player != null) {
            if (player_image != null) {
                image = player_image.get_string ().replace ("file://", "");
            }
        }
        return image;
    }

    public GLib.Variant? get_media_prop (string key) {
        GLib.Variant value = null;

        // if (this.player != null) {
        // this.player.metadata.foreach ((k, v) => {
        // if (key == k) {
        // if (v.get_type () == GLib.VariantType.INT64) {
        // print ("key: %f\n", v.get_int64 ());
        // }
        // value = v;
        // }
        // });
        // }

        if (value == null) {
            try {
                if (this.player_props != null) {

                    Variant meta = this.player_props.get ("org.mpris.MediaPlayer2.Player", "Metadata");
                    string type = meta.get_type_string ();
                    if (type != null && meta.get_type_string () != null) {
                        Variant val = null;
                        string k = null;
                        VariantIter iter = meta.iterator ();
                        while (iter.next ("{sv}", out k, out val)) {
                            if (k == key) {
                                value = val;
                                // print ("%s %s\n", key, val.get_string ());
                                break;
                            }
                        }
                    } else {
                        print ("metadata is null\n");
                    }
                }
            } catch (GLib.Error e) {
                // print ("%s\n", e.message);
                //
            }
        }

        return value;
    }

    public void update_track_time (Gtk.Scale track_widget) {
        bool hide_track_widget = false;
        if (track_widget != null && this.player != null) {
            if (this.player.can_seek) {
                try {
                    track_widget.show ();
                    Gtk.Adjustment adjustment = track_widget.get_adjustment ();
                    int64 position = this.player_props.get ("org.mpris.MediaPlayer2.Player", "Position").get_int64 ();
                    int64 seconds = position / 1000000;
                    uint64 track_duration = this.get_media_prop ("mpris:length").get_int64 () / 1000000;

                    adjustment.set_upper (track_duration);

                    // fix a bug with firefox
                    if (this.player.playback_status == "Playing") {
                        adjustment.set_value (seconds);
                    }
                } catch (GLib.Error e) {
                    print ("media error %s\n", e.message);
                }
            } else {
                hide_track_widget = true;
            }
        }
        if (this.player == null)
            hide_track_widget = true;

        if (hide_track_widget)
            track_widget.hide ();
    }

    public string format_track (double value) {
        int divisao = (int) (value / 60);
        int minutos = divisao > 0 ? divisao : 0;
        int segundos = minutos == 0 ? (int) value : ((int) value) % 60;

        string formato = "";
        formato += minutos < 10 ? "0" + minutos.to_string () : minutos.to_string ();
        formato += ":";
        formato += segundos < 10 ? "0" + segundos.to_string () : segundos.to_string ();
        return formato;
    }

    public void set_position (Gtk.Range range) {
        if (this.player != null) {
            try {
                int64 new_position = (int) range.get_value () * 1000000;
                GLib.ObjectPath track_id = new GLib.ObjectPath (get_media_prop ("mpris:trackid").get_string ());
                int64 diff = (new_position) - (this.position);
                diff = diff < 0 ? diff * -1 : diff;
                if (range.has_focus && (diff) > 1000000) {
                    this.player.set_position (track_id, new_position);
                }
                this.position = new_position;
            } catch (GLib.Error e) {
                print ("%s\n", e.message);
            }
        }
    }
}
