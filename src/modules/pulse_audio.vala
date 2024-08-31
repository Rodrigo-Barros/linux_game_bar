#! /usr/bin/valac -S --pkg libpulse
public class Pulse : GLib.Object {
    protected PulseAudio.MainLoop mainloop;
    protected PulseAudio.Context context;
    protected PulseAudio.Context.Flags flags = PulseAudio.Context.Flags.NOFAIL;

    public struct Application {
        uint32 id;
        string name;
        string title;
        string icon;
        int volume;
        PulseAudio.CVolume cvolume;
    }

    public struct DefaultSink {
        uint32 id;
        string name;
        int volume;
        PulseAudio.CVolume cvolume;
    }

    delegate void resolveContext (PulseAudio.Context c);

    private void exec (resolveContext callback) {
        this.mainloop = new PulseAudio.MainLoop ();
        this.context = new PulseAudio.Context (this.mainloop.get_api (), "Liux Game Bar");
        this.context.set_state_callback ((c) => {
            PulseAudio.Context.State state = c.get_state ();

            if (state == PulseAudio.Context.State.READY) {
                // print ("READY\n");
                callback (c);
            }

            if (c.get_state () == PulseAudio.Context.State.AUTHORIZING) {
                // print ("AUTHORIZING\n");
            }

            if (c.get_state () == PulseAudio.Context.State.CONNECTING) {
                // print ("CONNETING\n");
            }

            if (c.get_state () == PulseAudio.Context.State.SETTING_NAME) {
                // print ("SETTING_NAME\n");
            }

            if (c.get_state () == PulseAudio.Context.State.UNCONNECTED) {
                // print ("UNCONNECTED\n");
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
                    application.cvolume = sink.volume;
                    application.icon = sink.proplist.gets (PulseAudio.Proplist.PROP_APPLICATION_ICON_NAME);
                    application.volume = int.parse (sink.volume.avg ().sprint ().replace ("%", ""));
                    applications += application;
                    if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                        stdout.printf ("App: %s,title: %s, volume:%s \n", application.name, application.title, application.cvolume.to_string ());
                    }
                }
                if (eol == 1) {
                    c.disconnect ();
                }
            });
        });

        return applications;
    }

    public Application get_application (uint32 id) {
        foreach (Application application in this.get_applications ()) {
            if (application.id == id) {
                return application;
            }
        }
        return this.get_applications ()[0];
    }

    public DefaultSink get_default_sink () {
        DefaultSink default_sink = DefaultSink ();
        this.exec ((c) => {
            c.get_server_info ((c, serverInfo) => {
                string sink_name = serverInfo.default_sink_name;
                // string default_source = serverInfo.default_source_name;
                // print ("sink %s\n", sink_name);
                default_sink.name = sink_name;
                // sai do loop de eventos
                c.disconnect ();
            });
        });

        this.exec ((c) => {
            c.get_sink_info_by_name (default_sink.name, (c, SinkInfo, eol) => {
                if (eol == 0) {
                    default_sink.volume = int.parse (SinkInfo.volume.avg ().sprint ().replace ("%", ""));
                    default_sink.cvolume = SinkInfo.volume;
                    default_sink.id = SinkInfo.index;
                }
                if (eol == 1) {
                    c.disconnect ();
                }
            });
        });

        return default_sink;
    }

    public void volume_up_sink (DefaultSink default_sink, uint32 increase) {
        uint32 volume_max = PulseAudio.Volume.NORM;
        uint32 volume_old = default_sink.volume;
        uint32 volume_current = volume_old + increase > volume_max ? volume_max : volume_old + increase;
        uint32 volume_new = ((volume_max * volume_current) / 100);

        this.exec ((c) => {
            default_sink.cvolume.set (default_sink.cvolume.channels, volume_new);
            c.set_sink_volume_by_index (default_sink.id, default_sink.cvolume, (c) => {
                if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                    print ("Volume definido para %d\n", (int) volume_new);
                }
                c.disconnect ();
            });
        });
    }

    public void volume_down_sink (DefaultSink default_sink, int decrease) {
        decrease = decrease < 0 ? decrease * -1 : decrease;

        uint32 volume_max = PulseAudio.Volume.NORM;
        uint32 volume_old = default_sink.volume;
        uint32 volume_current = volume_old - decrease < 0 ? 0 : volume_old - decrease;
        uint32 volume_new = (volume_max * volume_current) / 100;

        if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
            print ("DECREASE %f\n", decrease);
            print ("OLD %f\n", volume_old);
            print ("CURRENT %f\n", volume_current);
            print ("NEW %f\n", volume_current);
        }

        this.exec ((c) => {
            default_sink.cvolume.set (default_sink.cvolume.channels, volume_new);
            c.set_sink_volume_by_index (default_sink.id, default_sink.cvolume, (c) => {
                if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                    print ("Volume definido para %d\n", (int) volume_new);
                }
                c.disconnect ();
            });
        });
    }

    public bool volume_down_application (uint32 id, int decrease) {
        Application[] applications = this.get_applications ();
        for (int i = 0; i < applications.length; i++) {
            string application_name = applications[i].name;
            int application_id = (int) applications[i].id;
            PulseAudio.CVolume volume = applications[i].cvolume;

            uint32 volume_min = PulseAudio.Volume.MUTED;
            uint32 volume_anterior = volume.avg ();
            float valor_diminuicao = (((float) PulseAudio.Volume.NORM * decrease)) / 100;
            float percentual_aumento = (100 * valor_diminuicao) / (float) PulseAudio.Volume.NORM;
            uint32 volume_atual = ((int) volume_anterior + (int) valor_diminuicao);

            if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                print ("valor aumento: %f\n", valor_diminuicao);
                print ("percentual diminuicao: %f\n", percentual_aumento);
            }
            if ((int) volume_atual <= volume_min) {
                volume_atual = volume_min;
            }


            if (application_id == id) {
                if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                    stdout.printf ("Volume Anterior: %d, Volume Atual:%d\n", (int) volume_anterior, (int) volume_atual);
                    stdout.printf ("Definindo o valor de %d para a aplicação %s\n", (int) volume_atual, application_name);
                }
                this.exec ((c) => {
                    volume.set (volume.channels, volume_atual);
                    c.set_sink_input_volume (application_id, volume, (c) => {
                        if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                            print ("Volume definido para %d\n", (int) volume_atual);
                        }
                        c.disconnect ();
                    });
                });
                return true;
            }
        }

        stdout.printf ("Não foi possível achar a aplicação com id %d\n", (int) id);
        return false;
    }

    public bool volume_up_application (uint32 id, int increase) {
        Application[] applications = this.get_applications ();
        for (int i = 0; i < applications.length; i++) {
            string application_name = applications[i].name;
            int application_id = (int) applications[i].id;
            PulseAudio.CVolume volume = applications[i].cvolume;

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
                if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                    stdout.printf ("Volume Anterior: %d, Volume Atual:%d\n", (int) volume_anterior, (int) volume_atual);
                    stdout.printf ("Definindo o valor de %d para a aplicação %s\n", (int) volume_atual, application_name);
                }
                this.exec ((c) => {
                    volume.set (volume.channels, volume_atual);
                    c.set_sink_input_volume (application_id, volume, (c) => {
                        if (GLib.Environment.get_variable ("DEBUG_PULSE") != null) {
                            print ("Volume definido para %d\n", (int) volume_atual);
                        }
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
