#! /usr/bin/valac -S --pkg sdl2

public class Joystick {
    public SDL.Input.Joystick[] joysticks = {};

    public Joystick () {
        // SDL.Input.Joystick[] _joysticks = {};
        SDL.init (SDL.InitFlag.EVERYTHING);
        int joysticks = SDL.Input.Joystick.count ();
        if (joysticks > 0) {
            for (int i = 0; i < joysticks; i++) {
                this.joysticks[i] = new SDL.Input.Joystick (i);
            }
        }
    }

    public void readEvents () {
    }
}