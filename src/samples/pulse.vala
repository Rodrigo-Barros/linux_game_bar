#! /usr/bin/valac -S --pkg libpulse
using GLib;
using PulseAudio;

void main () {
    PulseAudio.MainLoop mainLoop = new PulseAudio.MainLoop ();

    // Inicializa o contexto do PulseAudio
    PulseAudio.Context context = new PulseAudio.Context (mainLoop.get_api (), null);
    context.set_state_callback ((c) => {
        PulseAudio.Context.State state = c.get_state ();
        if (state == Context.State.AUTHORIZING) {
            stdout.printf ("State: AUTHORIZING\n");
        }
        if (state == Context.State.FAILED) {
            stdout.printf ("State: FAILED\n");
        }
        if (state == Context.State.SETTING_NAME) {
            stdout.printf ("State: SETTING_NAME\n");
        }
        if (state == Context.State.TERMINATED) {
            stdout.printf ("State: TERMINATED\n");
        }
        if (state == Context.State.UNCONNECTED) {
            stdout.printf ("State: UNCONNECTED\n");
        }

        if (state == Context.State.READY) {

            stdout.printf ("State: READY\n");
            stdout.printf ("Socket: %s\n", c.get_server ());
            stdout.printf ("API_VERSION: %d\n", PulseAudio.API_VERSION);

            // obtém as informações do servidor
            c.get_server_info ((c, serverInfo) => {
                string default_sink = serverInfo.default_sink_name;
                string default_source = serverInfo.default_source_name;

                stdout.printf ("server name: %s\n", serverInfo.server_name);
                stdout.printf ("server version: %s\n", serverInfo.server_version);
                stdout.printf ("user name: %s\n", serverInfo.user_name);
                stdout.printf ("default sink: %s\n", serverInfo.default_sink_name);
                stdout.printf ("default source: %s\n", serverInfo.default_source_name);

                // pega o dispositivo padrão do sistema
                c.get_sink_info_by_name (default_sink, (c, sink, eol) => {
                    if (eol == 0) {
                        var volume = sink.volume;

                        volume.set (volume.channels, PulseAudio.Volume.NORM);


                        print ("Volume MAX NORM %x\n", PulseAudio.Volume.NORM);
                        print ("Channels %s\n", volume.channels.to_string ());
                        c.set_sink_volume_by_name (default_sink, volume);
                    }
                });

                // lista os programas que estão reproduzindo som atualmente
                c.get_sink_input_info_list ((c, sinkInput, eol) => {
                    if (eol == 0) {
                        stdout.printf ("Sink ID %d\n", ((int) sinkInput.index));
                        stdout.printf ("%s: %s\n", sinkInput.proplist.gets (Proplist.PROP_APPLICATION_NAME), sinkInput.name);
                        // stdout.printf ("Sink Title: %s\n", sinkInput.name);

                        var new_volume = sinkInput.volume.set (sinkInput.volume.channels, 10);

                        c.set_sink_input_volume (sinkInput.index, new_volume);
                    }
                });
            });
        }
    });
    context.connect (null, PulseAudio.Context.Flags.NOFAIL, null);
    mainLoop.run ();
}
