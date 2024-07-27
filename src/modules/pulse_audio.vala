#! /usr/bin/valac -S --pkg libpulse
public class Pulse : GLib.Object {
    protected PulseAudio.MainLoop mainloop;
    protected PulseAudio.Context context;
    protected PulseAudio.Context.Flags flags = PulseAudio.Context.Flags.NOFAIL;

    protected string default_sink;

    delegate void resolveContext (PulseAudio.Context c);

    public uint32 _volume;
    public uint32 volume {
        get { return _volume; }
        set { _volume = value > PulseAudio.Volume.NORM ? PulseAudio.Volume.NORM : value; }
    }

    public Pulse () {
        this.mainloop = new PulseAudio.MainLoop ();
        this.context = new PulseAudio.Context (this.mainloop.get_api (), null);
    }

    private void exec (resolveContext callback) {
        this.context.set_state_callback ((c) => {
            PulseAudio.Context.State state = c.get_state ();

            if (state == PulseAudio.Context.State.READY) {
                callback (c);
            }
        });
        this.context.connect (null, this.flags);
        this.mainloop.run ();
    }

    public void get_applications () {
        this.exec ((c) => {
            c.get_sink_input_info_list ((c, sink, eol) => {
                if (eol == 0) {
                    PulseAudio.CVolume volume = sink.volume;
                    string app = sink.proplist.gets (PulseAudio.Proplist.PROP_APPLICATION_NAME);
                    string title = sink.name;
                    stdout.printf ("App: %s,title: %s, volume:%s\n", app, title, volume.to_string ());
                }
            });
        });
    }

    public string get_default_sink () {
        this.exec ((c) => {
            c.get_server_info ((c, serverInfo) => {
                string default_sink = serverInfo.default_sink_name;
                // string default_source = serverInfo.default_source_name;

                this.default_sink = default_sink;

                // sai do loop de eventos
                c.disconnect ();
                this.mainloop.quit (0);
            });
        });

        return this.default_sink;
    }

    public bool volume_down (PulseAudio.SinkInputInfo sink, int decrease) {
        return false;
    }

    public bool volume_up (PulseAudio.SinkInputInfo sink, int increase) {
        return false;
    }
}
