using Gee;

public class Controller {
    private Button[] buttons = {};

    public struct Button {
        string button_name;
        uint32 button_id;
    }
    public Button[] getButtons (bool debug = true) {
        if (GLib.Environment.get_variable ("DEBUG_JOYSTICK") != null) {
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

    public struct ButtonsPressed {
        double delay;
        string[] buttons;
    }

    public event[] events = new event[3];

    public SDL.Input.Joystick[] joysticks = {};

    public Controller controller;

    public GLib.Object modules;

    public bool addEvent (event button_event) {
        uint slots_livres = this.events.length;

        for (int i = 0; i < this.events.length; i++) {
            if (this.events[i].button_name != null) {
                slots_livres--;
            }

            if (this.events[i].button_name == null) {
                this.events[i] = button_event;
                break;
            }
        }

        if (slots_livres == 0) {
            uint last = this.events.length - 1;
            for (int i = 0; i < this.events.length; i++) {
                bool is_last = last == i;
                if (!is_last) {
                    this.events[i] = this.events[i + 1];
                }
            }

            this.events[last] = button_event;
        }

        return true;
    }

    public event[] getEvents () {
        return this.events;
    }

    SDL.Input.JoystickPowerLevel power_level;

    public MainWindow window;

    public Joystick (MainWindow window) {

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
                this.power_level = joystick.get_current_powerlevel ();

                if (GLib.Environment.get_variable ("DEBUG_JOYSTICK") != null) {
                    print ("Joystick %s\n", joystick_name);
                    print ("Joystick Power: %s\n", power_level);
                    print ("Joystick GUID: %s\n", SDL.Input.Joystick.get_guid_string (joystick.get_guid ()));
                }
            }
        }
        this.window = window;
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

    public string get_battery_icon () {
        string battery_icon = "";
        SDL.Input.Joystick joystick = new SDL.Input.Joystick (0);
        SDL.Input.JoystickPowerLevel level = joystick.get_current_powerlevel ();

        switch (level) {
        case SDL.Input.JoystickPowerLevel.EMPTY:
            battery_icon = "battery-level-0-charging-symbolic";
            break;
        case SDL.Input.JoystickPowerLevel.LOW:
            battery_icon = "battery-level-10-charging-symbolic";
            break;
        case SDL.Input.JoystickPowerLevel.MEDIUM:
            battery_icon = "battery-level-50-charging-symbolic";
            break;
        case SDL.Input.JoystickPowerLevel.FULL:
        case SDL.Input.JoystickPowerLevel.MAX:
            battery_icon = "battery-level-100-symbolic";
            break;
        case SDL.Input.JoystickPowerLevel.UNKNOWN:
            battery_icon = "drive-harddisk-usb-symbolic";
            break;
        case SDL.Input.JoystickPowerLevel.WIRED:
            battery_icon = "input-gaming-symbolic";
            break;
        }

        return battery_icon;
    }

    public void wait_event (SDL.Event event) {
        string button_state = event.jbutton.state == 1 ? "pressed" : "release";
        uint32 button_id = event.jbutton.button;
        Gtk.Widget current_widget = this.window.get_window ().get_focus ();

        if (event.type == SDL.EventType.JOYBUTTONDOWN) {
            Joystick.event joystickEvent = Joystick.event ();
            string timestamp = new GLib.DateTime.now ().format ("%s.%f");
            string button_name = this.controller.getButtonName (button_id);
            joystickEvent.button_name = button_name;
            joystickEvent.button_id = button_id;
            joystickEvent.type = button_state;
            joystickEvent.timestamp = double.parse (timestamp);

            if (button_name == "ARROW_DOWN" && this.window.visible ()) {
                this.window.get_window ().child_focus (Gtk.DirectionType.DOWN);
            }
            if (button_name == "ARROW_UP" && this.window.visible ()) {
                this.window.get_window ().child_focus (Gtk.DirectionType.UP);
            }

            if (!(current_widget is Gtk.Scale)) {

                if (button_name == "ARROW_LEFT" && this.window.visible ()) {
                    this.window.get_window ().child_focus (Gtk.DirectionType.LEFT);
                }

                if (button_name == "ARROW_RIGHT" && this.window.visible ()) {
                    this.window.get_window ().child_focus (Gtk.DirectionType.RIGHT);
                }
            }


            if (current_widget is Gtk.Scale) {
                double value = current_widget.get_value ();
                double increase = Settings.get ("modules.pulseaudio.increase").get_double ();
                double decrease = Settings.get ("modules.pulseaudio.decrease").get_double ();
                double new_value = value;
                if (button_name == "ARROW_LEFT" && this.window.visible ()) {
                    new_value = value - increase;
                }

                if (button_name == "ARROW_RIGHT" && this.window.visible ()) {
                    new_value = value + decrease;
                }
                current_widget.set_value (new_value);
            }

            if (button_name == "CROSS" && this.window.visible ()) {
                if (current_widget is Gtk.Button) {
                    current_widget.clicked ();
                }
            }

            if (current_widget is Gtk.Expander) {
                bool expanded = current_widget.expanded;
                if (button_name == "CROSS" && this.window.visible ()) {
                    expanded = !expanded;
                }

                current_widget.expanded = expanded;
            }

            this.addEvent (joystickEvent);

            this.process_buttons ();
        }

        if (event.type == SDL.EventType.QUIT) {
            print ("Exiting....\n");
            Posix.exit (0);
        }
    }

    public void process_buttons () {
        ButtonsPressed buttons_pressed = this.getButtonsPressed (2);
        double delay = 0;

        // print ("button_pressed: %s\n", string.joinv (" ", buttons_pressed.buttons));

        Json.Node keybindings = Settings.get ("modules.joystick.keybindings");

        keybindings.get_array ().foreach_element ((array, index, element) => {
            try {
                string[] combination = new string[0];
                string[] action_arguments = new string[0];

                string config = Json.to_string (element, false);
                delay = Settings.get ("delay", config).get_int ();
                delay = delay / 1000;
                Json.Array buttons = Settings.get ("buttons", config).get_array ();
                Json.Array action = Settings.get ("action", config).get_array ();

                buttons.foreach_element ((buttons, index, element) => {
                    combination += element.get_string ();
                });
                action.foreach_element ((buttons, index, element) => {
                    action_arguments += element.get_string ();
                });


                bool acceptable_delay = buttons_pressed.delay < delay;
                bool trigger_action = string.joinv (" ", combination) == string.joinv (" ", buttons_pressed.buttons);

                if (trigger_action && acceptable_delay) {
                    print ("delay: %f\n", delay);
                    print ("Combinação %s\n", string.joinv (" ", combination));
                    print ("Action %s\n", string.joinv (" ", action_arguments));

                    print ("Delay de acionamento %f\n", buttons_pressed.delay);
                    print ("Combinação de teclas encontrada\n");
                    this.exec_action (action_arguments);
                }
            } catch (GLib.Error e) {
                print ("Error %s\n", e.message);
            }
        });
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

    public ButtonsPressed getButtonsPressed (int size = 0) {
        event[] eventsOrdered = this.getEventsOrdered ();
        string[] buttons = new string[0];
        string[] combination = new string[0];
        double[] buttons_timestamp = new double[size];
        ButtonsPressed buttonsPressed = this.ButtonsPressed ();

        foreach (event event in eventsOrdered) {
            if (event.button_name != null) {
                buttons += event.button_name;
            }
        }

        combination = buttons;

        if (buttons.length > 1 && size > 0) {
            combination = new string[0];
            for (int i = size - 1; i >= 0; i--) {
                event event = eventsOrdered[i];
                if (event.button_name != null) {
                    combination += event.button_name;
                    buttons_timestamp += event.timestamp;
                }
            }
        }

        buttonsPressed.buttons = combination;
        buttonsPressed.delay = eventsOrdered[0].timestamp - eventsOrdered[size - 1].timestamp;

        return buttonsPressed;
    }

    public void exec_action (string[] action_arguments) {
        string command = action_arguments[0];
        string[] arguments = new string[0];
        if (action_arguments.length > 1) {
            for (int i = 1; i < action_arguments.length; i++) {
                arguments += action_arguments[i];
            }
        }
        this.window.action.execCommand (command, arguments);
    }
}
