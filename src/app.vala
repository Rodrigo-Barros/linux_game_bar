public class App {
    static void main (string[] args) {
        var pulse = new Pulse ();
        pulse.init ();

        pulse.volume_down (609, 10);
        pulse.get_default_sink ();

        // Pulse.Application[] apps = pulse.get_applications ();
        // print ("aqui:%s \n", pulse.get_default_sink ());
    }
}
