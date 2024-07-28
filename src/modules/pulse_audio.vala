#! /usr/bin/valac -S --pkg libpulse
public class Pulse : GLib.Object {
    protected PulseAudio.MainLoop mainloop;
    protected PulseAudio.Context context;
    protected PulseAudio.Context.Flags flags = PulseAudio.Context.Flags.NOFAIL;

    public struct Application {
        uint32 id;
        string name;
        string title;
        PulseAudio.CVolume volume;
    }

    protected string default_sink;

    delegate void resolveContext (PulseAudio.Context c);

    private void exec (resolveContext callback) {
        this.mainloop = new PulseAudio.MainLoop ();
        this.context = new PulseAudio.Context (this.mainloop.get_api (), "Liux Game Bar");
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
                c.disconnect ();
                this.mainloop.quit (0);
            }
        });
        this.context.connect (null, this.flags);

        this.mainloop.run ();
    }

    public Application[] get_applications () {
        Application[] applications = {};
        this.exec ((c) => {
            c.get_sink_input_info_list ((c, sink, eol) => {
                if (eol == 0) {
                    // PulseAudio.CVolume volume = sink.volume;
                    // string app = sink.proplist.gets (PulseAudio.Proplist.PROP_APPLICATION_NAME);
                    // string title = sink.name;
                    Application application = Application ();
                    application.name = sink.proplist.gets (PulseAudio.Proplist.PROP_APPLICATION_NAME);
                    application.title = sink.name;
                    application.id = sink.index;
                    application.volume = sink.volume;
                    applications += application;
                    stdout.printf ("App: %s,title: %s, volume:%s \n", application.name, application.title, application.volume.to_string ());
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

    public bool volume_down (uint32 id, int decrease) {
        Application[] applications = this.get_applications ();
        for (int i = 0; i < applications.length; i++) {
            string application_name = applications[i].name;
            int application_id = (int) applications[i].id;
            PulseAudio.CVolume volume = applications[i].volume;

            int volume_min = 0;
            uint32 volume_anterior = volume.avg ();
            float valor_diminuicao = (((float) PulseAudio.Volume.NORM * decrease)) / 100;
            float percentual_diminuicao = (100 * valor_diminuicao) / (float) PulseAudio.Volume.NORM;
            uint32 volume_atual = ((int) volume_anterior - (int) valor_diminuicao);


            print ("valor dimiuicao: %f\n", valor_diminuicao);
            print ("percentual dimiuicao: %f\n", percentual_diminuicao);

            if ((int) volume_atual <= volume_min) {
                volume_atual = volume_min;
            }


            if (application_id == id) {
                stdout.printf ("Volume Anterior: %d, Volume Atual:%d\n", (int) volume_anterior, (int) volume_atual);
                stdout.printf ("Definindo o valor de %d para a aplicação %s\n", (int) volume_atual, application_name);

                this.exec ((c) => {
                    volume.set (volume.channels, volume_atual);
                    c.set_sink_input_volume (application_id, volume, (c) => {
                        print ("Volume definido para %d\n", (int) volume_atual);
                        c.disconnect ();
                    });
                });
                return true;
            }
        }

        stdout.printf ("Não foi possível achar a aplicação com id %d\n", (int) id);
        return false;
    }

    public bool volume_up (uint32 id, uint8 increase) {
        Application[] applications = this.get_applications ();
        for (int i = 0; i < applications.length; i++) {
            string application_name = applications[i].name;
            int application_id = (int) applications[i].id;
            PulseAudio.CVolume volume = applications[i].volume;

            uint32 volume_max = PulseAudio.Volume.NORM;
            uint32 volume_anterior = volume.avg ();
            float valor_aumento = (((float) PulseAudio.Volume.NORM * increase)) / 100;
            float percentual_aumento = (100 * valor_aumento) / (float) PulseAudio.Volume.NORM;
            uint32 volume_atual = ((int) volume_anterior + (int) valor_aumento);


            print ("valor aumento: %f\n", valor_aumento);
            print ("percentual diminuicao: %f\n", percentual_aumento);

            if ((int) volume_atual >= volume_max) {
                volume_atual = volume_max;
            }


            if (application_id == id) {
                stdout.printf ("Volume Anterior: %d, Volume Atual:%d\n", (int) volume_anterior, (int) volume_atual);
                stdout.printf ("Definindo o valor de %d para a aplicação %s\n", (int) volume_atual, application_name);

                this.exec ((c) => {
                    volume.set (volume.channels, volume_atual);
                    c.set_sink_input_volume (application_id, volume, (c) => {
                        print ("Volume definido para %d\n", (int) volume_atual);
                        c.disconnect ();
                    });
                });
                return true;
            }
        }

        stdout.printf ("Não foi possível achar a aplicação com id %d\n", (int) id);
        return false;
    }
}
