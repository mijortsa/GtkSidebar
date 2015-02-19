public class Sidebar : Gtk.TreeView {

    // TODO: add signals for icon and right click
    // TODO: item types needed -> progressbar item
    public class Item : Object {

        public string name { get; set; }
        public bool visible { get; set; default = true; }
        public Item parent { get; internal set; }

        public bool icon1_visible { get; set; default = false; }
        private string _icon1;
        public string? icon1 {
            get {
                return _icon1;
            }
            set {
                if (value != null) {
                    icon1_visible = true;
                    _icon1 = value;
                } else {
                    icon1_visible = false;
                }
            }
        }

        public bool icon2_visible { get; set; default = false; }
        private string _icon2;
        public string? icon2 {
            get {
                return _icon2;
            }
            set {
                if (value != null) {
                    icon2_visible = true;
                    _icon2 = value;
                } else {
                    icon2_visible = false;
                }
            }
        }

        public signal void activated ();

        public Item (string name = "") {
            this.name = name;
        }

        public virtual Gtk.Menu? get_context_menu () {
            return null;
        }
    }

    public class ExpandableItem : Item {
        private bool _expanded = false;
        public bool expanded {
            get {
                return _expanded;
            }
            set {
                if (value != _expanded) {
                    _expanded = value;
                    toggled ();
                }
            }
        }

        public Gee.Collection<Item> children {
            owned get {
                var children_list_copy = new Gee.ArrayList<Item> ();
                children_list_copy.add_all (children_list);
                return children_list_copy;
            }
        }

        // TODO: toggled is not yet called
        public signal void toggled ();
        public signal void child_added (Item item);
        public signal void child_removed (Item item);

        private Gee.Collection<Item> children_list = new Gee.ArrayList<Item> ();

        public ExpandableItem (string name = "") {
            base(name);
        }

        public bool contains (Item item) {
            return item in children_list;
        }

        public void add (Item item) {
            item.parent = this;
            children_list.add (item);
            child_added (item);
        }

        public void remove (Item item) {
            children_list.remove (item);
            child_removed (item);
            item.parent = null;
        }

        public void clear () {
            foreach (var item in children) {
                remove (item);
            }
        }
    }

    private class ItemWrapper : Object {

        private Gtk.TreeRowReference? row_reference;

        public bool valid {
            get {
                if (row_reference != null) {
                    var rref = (!) row_reference;
                    return rref.valid ();
                } else {
                    return false;
                }
            }
        }

        public Gtk.TreePath? path {
            owned get {
                return valid ? row_reference.get_path () : null;
            }
        }

        public Gtk.TreeIter? iter {
            owned get {
                Gtk.TreeIter? it = null;
                if (valid) {
                    var _path = this.path;
                    Gtk.TreeIter iter_tmp;
                    if (row_reference.get_model ().get_iter (out iter_tmp, _path)) {
                        it = iter_tmp;
                    }
                }
                return it;
            }
        }


        public ItemWrapper (Gtk.TreeStore store, Gtk.TreeIter iter) {
            row_reference = new Gtk.TreeRowReference (store,
                                                      store.get_path (iter));
        }
    }

    /*
     * Sidebar class begins here
     */

    public Item? selected {
        owned get {
            return get_selected_item ();
        }
    }
    private Gee.HashMap<Item, ItemWrapper> items = new Gee.HashMap<Item, ItemWrapper> ();

    private Gtk.TreeStore data_model;

    private enum Column {
        ITEM,
        N_ITEMS
    }

    public Sidebar () {
        data_model = new Gtk.TreeStore (Column.N_ITEMS,
                                        typeof (Item));
        model = data_model;
        setup_ui ();
    }

    public void add_item (Item item) {
        Gtk.TreeIter? item_parent_iter = null, item_iter;

        if (item.parent != null) {
            if (!has_item (item.parent)) {
                add_item (item.parent);
            }
            item_parent_iter = get_item_iter (item.parent);

            assert (item_parent_iter != null);
        }

        data_model.append (out item_iter, item_parent_iter);
        data_model.set (item_iter, Column.ITEM, item, -1);

        items.set (item, new ItemWrapper (data_model, item_iter));

        var ex_item = item as ExpandableItem;
        if (ex_item != null) {
            foreach (var child_item in ex_item.children) {
                add_item (child_item);
            }
        }
    }

    public bool has_item (Item item) {
        return items.has_key (item);
    }

    private void setup_ui () {
        // TODO: setup the item in the following format
        // [icon] [title] [progress bar] [icon]
        activate_on_single_click = true;
        headers_visible = false;

        var item_column = new Gtk.TreeViewColumn ();
        item_column.expand = true;

        insert_column (item_column, Column.ITEM);

        var icon1_renderer = new Gtk.CellRendererPixbuf ();
        item_column.pack_start (icon1_renderer, false);
        item_column.set_cell_data_func (icon1_renderer, icon1_data_func);

        var name_renderer = new Gtk.CellRendererText ();
        item_column.pack_start (name_renderer, false);
        item_column.set_cell_data_func (name_renderer, name_data_func);

        var icon2_renderer = new Gtk.CellRendererPixbuf ();
        item_column.pack_end (icon2_renderer, false);
        item_column.set_cell_data_func (icon2_renderer, icon2_data_func);

    }

    private void name_data_func (Gtk.CellLayout cell_layout,
                                 Gtk.CellRenderer renderer,
                                 Gtk.TreeModel tree_model,
                                 Gtk.TreeIter iter) {

        var text_renderer = renderer as Gtk.CellRendererText;
        assert (text_renderer != null);

        Item? item;
        tree_model.get (iter, Column.ITEM, out item, -1);

        text_renderer.visible = item.visible;
        text_renderer.text = item.name;
    }

    private void icon1_data_func (Gtk.CellLayout cell_layout,
                                  Gtk.CellRenderer renderer,
                                  Gtk.TreeModel tree_model,
                                  Gtk.TreeIter iter) {

        var icon_renderer = renderer as Gtk.CellRendererPixbuf;
        assert (icon_renderer != null);

        var item = get_item (iter);

        icon_renderer.visible = item.icon1_visible;
        icon_renderer.icon_name = item.icon1;
    }

    private void icon2_data_func (Gtk.CellLayout cell_layout,
                                  Gtk.CellRenderer renderer,
                                  Gtk.TreeModel tree_model,
                                  Gtk.TreeIter iter) {

        var icon_renderer = renderer as Gtk.CellRendererPixbuf;
        assert (icon_renderer != null);

        var item = get_item (iter);

        icon_renderer.visible = item.icon2_visible;
        icon_renderer.icon_name = item.icon2;
    }
    private bool popup_context_menu (Item? item, Gdk.EventButton? ev) {
        if (item != null) {
            var menu = item.get_context_menu ();
            if (menu != null) {
                var time = (ev != null) ? ev.time : Gtk.get_current_event_time ();
                var button = (ev != null) ? ev.button : 0;

                menu.attach_to_widget (this, null);

                if (ev != null) {
                    menu.popup (null, null, null, button, time);
                } else {
                    menu.popup (null, null, menu_position_func, button, time);
                    menu.select_first (false);
                }

                return true;
            }
        }

        return false;
    }

    private void menu_position_func (Gtk.Menu menu, out int x,
                                     out int y, out bool push_in) {

        push_in = true;
        x = y = 0;

        var path = data_model.get_path (get_item_iter (selected));
        if (path == null)
            return;

        // Try to find the position of the item
        Gdk.Rectangle item_bin_coords;
        get_cell_area (path, get_column (Column.ITEM), out item_bin_coords);

        int item_y = item_bin_coords.y + item_bin_coords.height / 2;
        int item_x = item_bin_coords.x;

        int widget_x, widget_y;
        convert_bin_window_to_widget_coords (item_x, item_y, out widget_x, out widget_y);

        get_window ().get_origin (out x, out y);
        x += widget_x.clamp (0, get_allocated_width ());
        y += widget_y.clamp (0, get_allocated_height ());

        Gtk.Requisition menu_req;
        menu.get_preferred_size (out menu_req, null);
        y -= menu_req.width;
    }

    private Item? get_item (Gtk.TreeIter iter) {
        Item? item;
        data_model.get (iter, Column.ITEM, out item, -1);
        return item;
    }

    private Gtk.TreeIter get_item_iter (Item item) {
        var wrapped_item = items.get (item);
        return wrapped_item.iter;
    }

    private Item? get_item_from_path (Gtk.TreePath path) {
        Gtk.TreeIter iter;
        Item? item = null;

        if (data_model.get_iter (out iter, path)) {
            item = get_item (iter);
        }
        return item;
    }

    private Item? get_selected_item () {
        var selection = get_selection ();

        Gtk.TreeIter iter;
        selection.get_selected (null, out iter);
        return get_item (iter);
    }

    public override void row_activated (Gtk.TreePath path,
                                        Gtk.TreeViewColumn column) {

        if (column == get_column (Column.ITEM)) {
            Item item = get_item_from_path (path);
            item.activated ();
        }
    }

    public override bool button_press_event (Gdk.EventButton ev) {
        if (ev.window != get_bin_window ()) {
            return base.button_press_event (ev);
        }

        Gtk.TreePath path;
        Gtk.TreeViewColumn column;
        int x, y, cell_x, cell_y;

        x = (int) ev.x;
        y = (int) ev.y;

        if (get_path_at_pos (x, y, out path, out column,
                             out cell_x, out cell_y)) {

            var item = get_item_from_path (path);

            Gdk.Rectangle start_cell_area;
            get_cell_area (path, get_column (0), out start_cell_area);
            cell_x -= start_cell_area.x;

            if (item != null && column == get_column (Column.ITEM)) {

                if (ev.button == Gdk.BUTTON_SECONDARY) {
                    popup_context_menu (item, ev);
                }
            }
        }
        return base.button_press_event (ev);
    }
}
