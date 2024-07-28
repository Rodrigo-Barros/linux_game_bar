#! /usr/bin/valac -S --pkg sdl2

public class Joystick {
    public events[] keybindings = {};

    public struct events {
        string name;
        int index;
    }

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

    public void process_keybinds (SDL.Event event) {
        string bindings = "../keybinds.json";
    }

    public void readEvents () {
        SDL.Event event;
        while (SDL.Event.poll (out event) == 1) {
            this.process_keybinds (event);
        }
    }
}
