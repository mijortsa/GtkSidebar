public class Application : Gtk.Window {
    private Gtk.Paned layout;

	public Application () {
		this.title = "Sidebar Demo";
		this.destroy.connect (Gtk.main_quit);
		this.set_default_size (600, 600);

        setup_ui ();
	}

    private void setup_ui () {
        layout = new Gtk.Paned (Gtk.Orientation.HORIZONTAL);

        setup_view ();

        layout.show_all ();
        add (layout);
    }

    private void setup_view () {
        var container = new Gtk.Grid ();

        var stack = new Gtk.Stack ();
        stack.margin = 12;
        stack.add_titled (new Gtk.Label ("Box 1"), "box-1", "Box 1");
        stack.add_titled (new Gtk.Label ("Box 2"), "box-2", "Box 2");

        var switcher  = new Gtk.StackSwitcher ();
        switcher.margin = 12;
        switcher.set_stack (stack);

        container.attach (switcher, 0 , 0, 1, 1);
        container.attach (stack, 0 , 1, 1, 1);

        var sidebar = new Sidebar ();

        var item1 = new Sidebar.Item ("Box 1");
        item1.icon1 = "go-previous-symbolic";
        item1.icon2 = "edit-delete-symbolic";


        item1.activated.connect (() => {
            print ("Item 1\n");
            stack.set_visible_child_name ("box-1");
        });

        var item2 = new Sidebar.Item ("Box 2");
        item2.icon2 = "editdelete";
        item2.activated.connect (() => {
            print ("Item 2\n");
            stack.set_visible_child_name ("box-2");
        });

        var ex_item = new Sidebar.ExpandableItem ("Parent");
        ex_item.add (item2);

        sidebar.add_item (item1);
        sidebar.add_item (ex_item);

        layout.add1 (sidebar);
        layout.add2 (container);
	}

	public static int main (string[] args) {	 
		Gtk.init (ref args);

		Application sample = new Application ();
		sample.show_all ();
		Gtk.main ();
		return 0;
	}
}