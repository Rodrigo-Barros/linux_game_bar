#! /usr/bin/valac -S --pkg sdl2

public class Controller {
    private Button[] buttons = {};

    private struct Button {
        string button_name;
        uint32 button_id;
    }
    public void getButtons () {
        for (int i = 0; i < this.buttons.length; i++) {
            print ("Button Name: %s, Button id:%d\n", this.buttons[i].button_name, (int) this.buttons[i].button_id);
        }
    }

    public void addButton (string button_name, uint32 button_id) {
        Button button = Button ();
        button.button_name = button_name;
        button.button_id = button_id;
        this.buttons += button;
    }

    public string getButtonName (uint32 button_id) {
        string button_name = "";
        for (int i = 0; i < this.buttons.length; i++) {
            Button button = this.buttons[i];
            if (button.button_id == button_id) {
                button_name = button.button_name;
            }
        }
        return button_name;
    }

    public static Controller init (string controller_name) {
        Controller controller_profile;
        switch (controller_name) {
        case "PS4 Controller":
            controller_profile = new PS4Controller ();
            break;
        default:
            controller_profile = new PS4Controller ();
            break;
        }

        return new PS4Controller ();
    }
}

public class PS4Controller : Controller {

    public PS4Controller () {
        this.addButton ("CROSS", 0);
        this.addButton ("CIRCLE", 1);
        this.addButton ("SQUARE", 2);
        this.addButton ("TRIANGLE", 3);
        this.addButton ("SHARE", 4);
        this.addButton ("PLAYSTATION", 5);
        this.addButton ("OPTIONS", 6);
        this.addButton ("LEFT_STICK", 7);
        this.addButton ("RIGHT_STICK", 8);
        this.addButton ("L1", 9);
        this.addButton ("R1", 10);
        this.addButton ("ARROW_UP", 11);
        this.addButton ("ARROW_DOWN", 12);
        this.addButton ("ARROW_LEFT", 13);
        this.addButton ("ARROW_RIGHT", 14);
        this.addButton ("TOCHPAD", 15);

        this.getButtons ();
    }
}

public class Joystick {
    public events[] keybindings = {};

    public struct events {
        string name;
        int index;
    }

    public SDL.Input.Joystick[] joysticks = {};

    public Controller controller;

    public Joystick () {
        // SDL.Input.Joystick[] _joysticks = {};
        SDL.init (SDL.InitFlag.EVERYTHING);
        int joysticks = SDL.Input.Joystick.count ();
        if (joysticks > 0) {
            for (int i = 0; i < joysticks; i++) {
                this.joysticks[i] = new SDL.Input.Joystick (i);
                unowned SDL.Input.Joystick joystick = this.joysticks[i];
                string joystick_name = joystick.get_name ();
                string power_level = this.translate_joystick_level (joystick.get_current_powerlevel ());
                this.controller = Controller.init (joystick_name);

                print ("Joystick %s\n", joystick_name);
                print ("Joystick Power: %s\n", power_level);
                // print ("Joystick GUID: %s\n", );
            }
        }
    }

    public string translate_joystick_level (SDL.Input.JoystickPowerLevel power_level) {
        string power_level_status = "NOT FOUND";

        switch (power_level) {
        case SDL.Input.JoystickPowerLevel.EMPTY:
            power_level_status = "EMPTY";
            break;

        case SDL.Input.JoystickPowerLevel.FULL:
            power_level_status = "FULL";
            break;

        case SDL.Input.JoystickPowerLevel.LOW:
            power_level_status = "LOW";
            break;

        case SDL.Input.JoystickPowerLevel.MAX:
            power_level_status = "MAX";
            break;

        case SDL.Input.JoystickPowerLevel.MEDIUM:
            power_level_status = "MEDIUM";
            break;

        case SDL.Input.JoystickPowerLevel.UNKNOWN:
            power_level_status = "UNKNOW";
            break;

        case SDL.Input.JoystickPowerLevel.WIRED:
            power_level_status = "WIRED";
            break;
        }

        return power_level_status;
    }

    public void process_keybinds (SDL.Event event) {
        string button_state = event.jbutton.state == 1 ? "pressed" : "release";
        uint32 button_id = event.button.which > 255 ? event.button.which - 256 : event.button.which;

        if (event.type == SDL.EventType.JOYBUTTONUP) {
            print ("Button: %s, State: %s\n", this.controller.getButtonName (button_id), button_state);
        }

        if (event.type == SDL.EventType.JOYBUTTONDOWN) {
            print ("Button: %s, State: %s\n", this.controller.getButtonName (button_id), button_state);
        }

        if (event.type == SDL.EventType.QUIT) {
            print ("Exiting....\n");
            Posix.exit (0);
        }
    }

    public void readEvents () {
        SDL.Event event;
        while (SDL.Event.poll (out event) == 1) {
            this.process_keybinds (event);
        }
    }
}
