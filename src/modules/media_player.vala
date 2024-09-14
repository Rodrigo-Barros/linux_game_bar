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
    public abstract string playback_status { owned get; }
    public abstract HashTable<string, Variant> metadata  { owned get; }

    public abstract void previous () throws GLib.Error;
    public abstract void next () throws GLib.Error;
    public abstract void play_pause () throws GLib.Error;
}

public class MediaPlayer : Object {
    Player player = null;

    public MediaPlayer () {
        string player_name = this.getPlayer ();
        try {
            this.player = Bus.get_proxy_sync (BusType.SESSION, player_name, "/org/mpris/MediaPlayer2");
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

    public string getPlayer () {
        string player = "";
        foreach (string name in this.getBusNames ()) {
            if ("org.mpris.MediaPlayer2" in name) {
                player = name;
                break;
            }
        }
        return player;
    }

    public string get_play_image (bool reverse = false) {
        string btn_image = "";
        if (this.player != null) {
            if (reverse == false) {
                btn_image = this.player.playback_status == "Paused" ? "media-playback-start-symbolic" : "media-playback-pause-symbolic";
            } else {
                btn_image = this.player.playback_status == "Paused" ? "media-playback-pause-symbolic" : "media-playback-start-symbolic";
            }
        }
        return btn_image;
    }

    public void prev (Gtk.Button btn) {
        if (this.player != null) {
            try {
                if (this.player.can_go_previous) {
                    this.player.previous ();
                }
            } catch (GLib.Error e) {
                print ("Error: %s\n", e.message);
            }
        }
    }

    public void play_pause (Gtk.Button btn) {
        if (this.player != null) {
            try {
                if (this.player.can_play) {
                    Gtk.Image image = new Gtk.Image ();
                    this.player.play_pause ();
                    string btn_image = this.get_play_image (true);
                    btn.set_image (image);
                    image.set_from_icon_name (btn_image, Gtk.IconSize.BUTTON);
                }
            } catch (GLib.Error e) {
                print ("Error: %s", e.message);
            }
        }
    }

    public void next (Gtk.Button btn) {
        if (this.player != null) {
            try {
                if (this.player.can_go_next) {
                    this.player.next ();
                }
            } catch (GLib.Error e) {
                print ("Error: %s", e.message);
            }
        }
    }

    public string get_title (uint title_limit = 50) {
        string title = "";
        uint title_size;
        if (this.player != null) {
            title = this.get_media_prop ("xesam:title");
            title = title != null ? title : null;
            title_size = title.length;

            if (title != null) {
                title = title_size < title_limit ? title : title.substring (0, title_limit).concat ("...");
            }
        }

        return title;
    }

    public string get_image () {
        string image = "";
        if (this.player != null) {
            image = this.get_media_prop ("mpris:artUrl").replace ("file://", "");
        }
        return image;
    }

    public string get_media_prop (string key) {
        string value = "";

        if (this.player != null) {
            this.player.metadata.foreach ((k, v) => {
                if (key == k) {
                    value = v.get_string ();
                }
            });
        }

        return value;
    }
}
