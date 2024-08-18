using Gee;

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
        double timestamp;
        string type;
    }

    public event[] events = new event[3];

    public SDL.Input.Joystick[] joysticks = {};

    public Controller controller;

    public bool addEvent (event button_event) {
        uint32 current_event_id = -1;

        for (int i = 0; i < this.events.length; i++) {
            if (this.events[i].button_name == null) {
                current_event_id = i;
                break;
            }
        }

        if (current_event_id == -1) {
            // print ("Todos os slots foram Ocupados\n");
            current_event_id = 0;
            for (int i = this.events.length; i > 1; i--) {
                this.events[i - 1] = this.events[i - 2];
            }
        }

        if (current_event_id != -1) {
            this.events[current_event_id] = button_event;

            event[] eventsOrdered = this.getEventsOrdered ();

            // combination.split (" ");
            for (int i = 0; i < eventsOrdered.length; i++) {
                var item = eventsOrdered[i];
                // print ("[%d] Button: %s Timestamp:%f\n", i, item.button_name, item.timestamp);
            }
            string pressed_buttons = "";
            string combination = "L1 R1";

            for (int i = combination.split (" ").length - 1; i >= 0; i-- ) {
                if (eventsOrdered[i].timestamp > 0) {
                    pressed_buttons += eventsOrdered[i].button_name + " ";
                }
            }

            pressed_buttons = pressed_buttons.strip ();
        }



        return true;
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

    public void wait_event (SDL.Event event) {
        string button_state = event.jbutton.state == 1 ? "pressed" : "release";
        uint32 button_id = event.button.which > 255 ? event.button.which - 256 : event.button.which;

        if (event.type == SDL.EventType.JOYBUTTONDOWN) {
            Joystick.event joystickEvent = Joystick.event ();
            string timestamp = new GLib.DateTime.now ().format ("%s.%f");
            string button_name = this.controller.getButtonName (button_id);
            joystickEvent.button_name = button_name;
            joystickEvent.button_id = button_id;
            joystickEvent.type = button_state;
            joystickEvent.timestamp = double.parse (timestamp);

            this.addEvent (joystickEvent);
            this.process_buttons ();
        }


        if (event.type == SDL.EventType.QUIT) {
            print ("Exiting....\n");
            Posix.exit (0);
        }
    }

    public void process_buttons () {
        event[] eventsOrdered = this.getEventsOrdered ();
        string pressed_buttons = "";
        event[] matchedEvents = new event[0];
        string combination = "L1 R1";
        double maximum_delay = 1.00;
        bool aceptable_delay = false;

        for (int i = combination.split (" ").length - 1; i >= 0; i-- ) {
            if (eventsOrdered[i].timestamp > 0) {
                matchedEvents += eventsOrdered[i];
                pressed_buttons += eventsOrdered[i].button_name + " ";
            }
        }

        if (matchedEvents.length > 1) {
            double event_start = matchedEvents[0].timestamp;
            double event_end = matchedEvents[matchedEvents.length - 1].timestamp;
            double event_diff = event_end - event_start;
            aceptable_delay = event_diff < maximum_delay;
            print ("Event diff %f\n", event_diff);
            print ("Maximun delay %f\n", maximum_delay);
            print ("Aceptable Delay %s\n", aceptable_delay.to_string ());
            pressed_buttons = pressed_buttons.strip ();
            if (combination == pressed_buttons && aceptable_delay) {
                print ("Match found\n");
            }
        }
    }

    public void readEvents () {
        SDL.Event event;
        while (SDL.Event.poll (out event) == 1) {
            this.wait_event (event);
        }
    }

    public event[] getEventsOrdered () {
        bool swapped = true;
        int j = 0;
        event tmp;
        event[] ordered = this.events;

        while (swapped) {
            swapped = false;
            j++;
            for (int i = 0; i < ordered.length - j; i++) {
                if (ordered[i].timestamp < ordered[i + 1].timestamp) {
                    tmp = ordered[i];
                    ordered[i] = ordered[i + 1];
                    ordered[i + 1] = tmp;
                    swapped = true;
                }
            }
        }

        return ordered;
    }
}
