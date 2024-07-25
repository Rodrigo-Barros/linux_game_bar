#! /usr/bin/valac -S --pkg sdl2

public class Joystick {
    public SDL.Input.Joystick[] joysticks;

    Joystick () {
        SDL.init (SDL.InitFlag.EVERYTHING);
        int joysticks = SDL.Input.Joystick.count ();
    }

    public void readEvents () {
    }
}