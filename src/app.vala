public class App {
    private void run (string[] args) {
        var pulse = new Pulse ();
        var joystick = new Joystick ();
        while (true) {
            joystick.readEvents ();
        }
    }

    static void main (string[] args) {
        App app = new App ();
        app.run (args);

        // Pulse.Application[] apps = pulse.get_applications ();
        // print ("aqui:%s \n", pulse.get_default_sink ());
    }
}
