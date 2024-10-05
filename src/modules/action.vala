public class Action {
    public HashTable<string, ActionCommand> commands;

    public void addCommand (string command, ActionCommand.runCommand callback) {
        ActionCommand action = new ActionCommand (callback);
        this.commands.insert (command, action);
    }

    public void execCommand (string command, string[] arguments) {
        ActionCommand action = this.commands.get (command);
        action.run (arguments);
    }

    private MainWindow app;

    public Action (MainWindow app) {

        this.commands = new HashTable<string, ActionCommand> (str_hash, str_equal);
        this.app = app;

        this.addCommand ("Window::Toggle", (args) => {
            this.app.toggle ();
        });
        this.addCommand ("Pulse::VolumeUp", (args) => {
            print ("Executando volume UP\n");
            Pulse.DefaultSink default_sink = this.app.pulse.get_default_sink ();
            uint32 increase = (uint32) Settings.get ("modules.pulseaudio.increase").get_int ();
            this.app.pulse.volume_up_sink (default_sink, increase);
        });
        this.addCommand ("Pulse::VolumeDown", (args) => {
            print ("Executando volume DOWN\n");
            Pulse.DefaultSink default_sink = this.app.pulse.get_default_sink ();
            int decrease = (int) Settings.get ("modules.pulseaudio.decrease").get_int ();
            this.app.pulse.volume_down_sink (default_sink, decrease);
        });
        this.addCommand ("ShellScript::exec", (args) => {
            string script = args[0];
            string[] script_args = new string[0];
            for (int i = 1; i < args.length; i++) {
                script_args += args[i];
            }

            try {
                Subprocess process = new Subprocess.newv (args, SubprocessFlags.INHERIT_FDS);
            } catch (GLib.Error e) {
                print ("Erro ao executar o script [%s] %s %s\n", script, string.joinv (" ", script_args), e.message);
            }
            // Posix.fork ();
            // Posix.execvp (script, script_args);
        });
    }
}

public class ActionCommand {
    public delegate void runCommand (string[] arguments);

    public string[] arguments;
    public runCommand callback;

    public ActionCommand (runCommand callback) {
        this.callback = callback;
    }

    public void run (string[] arguments) {
        this.callback (arguments);
    }
}
