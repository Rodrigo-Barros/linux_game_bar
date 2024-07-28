public class App {
    static void main (string[] args) {
        var pulse = new Pulse ();

        // return an array containing all applications/windows using pulse audio
        var applications = pulse.get_applications ();
        pulse.volume_up (applications[1].id, 10);
        pulse.get_default_sink ();

        // Pulse.Application[] apps = pulse.get_applications ();
        // print ("aqui:%s \n", pulse.get_default_sink ());
    }
}
