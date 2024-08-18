public class App {
    private void run (string[] args) {
        var pulse = new Pulse ();
        var joystick = new Joystick ();
        while (true) {
            joystick.readEvents ();
        }
    }

    static void main (string[] args) {
        MainWindow.render (args);
    }
}
