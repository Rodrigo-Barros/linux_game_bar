#! /usr/bin/valac -S --pkg libpulse
public class Pulse : GLib.Object {
    protected PulseAudio.MainLoop mainloop;
    protected PulseAudio.Context context;
    protected PulseAudio.Context.Flags flags = PulseAudio.Context.Flags.NOFAIL;
    protected Application[] applications = {};

    public struct Application {
        uint32 id;
        string name;
        string title;
        PulseAudio.CVolume volume;
    }

    protected string default_sink;

    delegate void resolveContext (PulseAudio.Context c);

    public uint32 _volume;
    public uint32 volume {
        get { return _volume; }
        set { _volume = value > PulseAudio.Volume.NORM ? PulseAudio.Volume.NORM : value; }
    }

    public void init () {
        this.mainloop = new PulseAudio.MainLoop ();
        this.context = new PulseAudio.Context (this.mainloop.get_api (), null);
        this.applications = this.get_applications ();
    }

    private void exec (resolveContext callback) {
        this.context.set_state_callback ((c) => {
            PulseAudio.Context.State state = c.get_state ();

            if (state == PulseAudio.Context.State.READY) {
                print ("READY\n");
                callback (c);
            }

            if (c.get_state () == PulseAudio.Context.State.AUTHORIZING) {
                print ("AUTHORIZING\n");
            }

            if (c.get_state () == PulseAudio.Context.State.CONNECTING) {
                print ("CONNETING\n");
            }

            if (c.get_state () == PulseAudio.Context.State.SETTING_NAME) {
                print ("SETTING_NAME\n");
            }

            if (c.get_state () == PulseAudio.Context.State.UNCONNECTED) {
                print ("UNCONNECTED\n");
            }

            if (c.get_state () == PulseAudio.Context.State.TERMINATED) {
            }
        });
        this.context.connect (null, this.flags);

        this.mainloop.run ();
    }

    private Application[] get_applications () {
        Application[] applications = {};
        this.exec ((c) => {
            c.get_sink_input_info_list ((c, sink, eol) => {
                if (eol == 0) {
                    // PulseAudio.CVolume volume = sink.volume;
                    // string app = sink.proplist.gets (PulseAudio.Proplist.PROP_APPLICATION_NAME);
                    // string title = sink.name;
                    // stdout.printf ("App: %s,title: %s, volume:%s \n", app, title, volume.to_string ());
                    Application application = Application ();
                    application.name = sink.proplist.gets (PulseAudio.Proplist.PROP_APPLICATION_NAME);;
                    application.title = sink.name;
                    application.id = sink.index;
                    application.volume = sink.volume;
                    applications += application;
                }
                if (eol == 1) {
                    c.disconnect ();
                }
            });
        });

        return applications;
    }

    public string get_default_sink () {
        this.exec ((c) => {
            c.get_server_info ((c, serverInfo) => {
                string default_sink = serverInfo.default_sink_name;
                // string default_source = serverInfo.default_source_name;
                print ("sink %s\n", default_sink);
                this.default_sink = default_sink;

                // sai do loop de eventos
                c.disconnect ();
            });
        });

        return this.default_sink;
    }

    public bool volume_down (int id, int decrease) {
        for (int i = 0; i < this.applications.length; i++) {
            string application_name = this.applications[i].name;
            int application_id = (int) this.applications[i].id;
            PulseAudio.CVolume volume = this.applications[i].volume;

            int volume_min = 0;
            uint32 volume_anterior = volume.avg ();
            int percentual = (int) ((volume_anterior / (float) PulseAudio.Volume.NORM) * 100);
            uint32 volume_atual = ((int) volume_anterior - decrease);

            if (volume_atual < volume_min) {
                stdout.printf ("Não é possível abaixar o volume abaixo de 0");
                return false;
            }


            if (application_id == id) {
                // this.init

                print ("exit code: %d\n ", this.mainloop.get_retval ());
                stdout.printf ("Volume Anterior: %d, Volume Atual:%d\n", (int) volume_anterior, (int) volume_atual);
                stdout.printf ("Definindo o valor de %d para a aplicação %s\n", (int) volume_atual, application_name);
                return true;
            }
        }

        stdout.printf ("Não foi possível achar a aplicação com id %d\n", id);
        return false;
    }

    public bool volume_up (string application, int increase) {
        return false;
    }
}
