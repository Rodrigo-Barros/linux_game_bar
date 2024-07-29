#! /usr/bin/valac -S --pkg sdl2

public class Controller {
    private Button[] buttons = {};

    public struct Button {
        string button_name;
        uint32 button_id;
    }
    public Button[] getButtons (bool debug = true) {

        if (debug) {
            for (int i = 0; i < this.buttons.length; i++) {
                print ("Button Name: %s, Button id:%d\n", this.buttons[i].button_name, (int) this.buttons[i].button_id);
            }
        }

        return this.buttons;
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

    const uint16 MAX_EXPIRATION = 5000;

    public struct event {
        string button_name;
        uint32 button_id;
        int timestamp;
        string type;
    }

    public event[] events = new event[10];

    public SDL.Input.Joystick[] joysticks = {};

    public Controller controller;

    public bool addEvent (event button_event) {
        bool event_add = false;
        uint32 current_event_id = -1;

        // valida se o botão deve ser inserido no array de eventos
        for (int i = 0; i < this.events.length; i++) {

            // if null we are in first run
            if (this.events[i].type == null) {
                event_add = true;
                current_event_id = i;
                break;
            }
        }

        if (current_event_id == -1) {
            event_add = false;
            stdout.printf ("Todos os slots foram ocupados\n");
        }

        if (event_add) {
            stdout.printf ("O Botão foi adicionado a lista de eventos\n");
            if(current_event_id != -1)
            {
                this.events[current_event_id] = button_event;
            }
        }

        return event_add;
    }

    public event[] getEvents () {
        return this.events;
    }

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
                print ("Joystick GUID: %s\n", SDL.Input.Joystick.get_guid_string (joystick.get_guid ()));
            }
        }
    }

    public string translate_joystick_level (SDL.Input.JoystickPowerLevel power_level) {
        string power_level_status = "NOT FOUND";

        switch (power_level) {
        case SDL.Input.JoystickPowerLevel.EMPTY :
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

        // if (event.type == SDL.EventType.JOYBUTTONUP) {
        // print ("Button: %s, State: %s\n", this.controller.getButtonName (button_id), button_state);
        // }

        if (event.type == SDL.EventType.JOYBUTTONDOWN) {
            Joystick.event e = Joystick.event ();
            string timestamp = new GLib.DateTime.now ().format ("%s");
            string button_name = this.controller.getButtonName (button_id);
            e.button_name = button_name;
            e.button_id = button_id;
            e.type = button_state;
            e.timestamp = int.parse (timestamp);

            this.addEvent (e);

            if (this.controller.getButtonName (button_id) == "CROSS") {
                for (int i = 0; i < this.events.length; i++) {
                    stdout.printf ("BTN NAME: %s\n", this.events[i].button_name);
                }
            }
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
