class Settings {
    public static Json.Node get (string setting, string data = "") {
        Json.Parser parser = new Json.Parser ();

        if (data == "") {
            parser.load_from_file ("../src/settings.json");
        } else {
            parser.load_from_data (data);
        }

        Json.Node node = parser.get_root ();
        Json.Object object = node.get_object ();
        Json.Node value = null;
        var keys = setting.split (".");
        string key_first = keys[0];

        foreach (string key in object.get_members ()) {
            var item = object.get_member (key);
            if (key == key_first && keys.length == 1) {
                value = item;
            } else if (key == key_first) {
                switch (item.get_node_type ()) {
                case Json.NodeType.VALUE:
                    print ("aqui\n");
                    value = item;
                    break;
                case Json.NodeType.OBJECT:
                    string new_data = Json.to_string (item, true);
                    string[] new_keys = keys[1 : keys.length];
                    string new_setting = "";
                    for (int i = 0; i < new_keys.length; i++) {
                        bool is_last = i == new_keys.length - 1;
                        if (is_last) {
                            new_setting += new_keys[i] + "";
                        } else {
                            new_setting += new_keys[i] + ".";
                        }
                    }

                    value = Settings.get (new_setting, new_data);
                    break;
                }
            }
        }

        return value;
    }
}
