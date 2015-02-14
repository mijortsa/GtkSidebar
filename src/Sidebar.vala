public class Sidebar : Gtk.TreeView {

    public class Item : Object {

        public string name { get; set; }
        public bool visible { get; set; default = true;}
        public Item parent { get; internal set; }
        public string icon_name { get; set; }

        public signal void activated ();

        public Item (string name = "") {
            this.name = name;
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
            children_list.add (item);
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
        // TODO: update item_parent_iter
        Gtk.TreeIter? item_parent_iter = null, item_iter;

        if (item.parent != null) {
            // TODO: add item to hashmap and check if it already exists
            add_item (item.parent);
        }
        data_model.append (out item_iter, item_parent_iter);
        data_model.set (item_iter, Column.ITEM, item, -1);
    }

    private void setup_ui () {
        activate_on_single_click = true;
        headers_visible = false;

        var item_column = new Gtk.TreeViewColumn ();
        item_column.expand = true;

        insert_column (item_column, Column.ITEM);

        var icon_renderer = new Gtk.CellRendererPixbuf ();
        item_column.pack_start (icon_renderer, false);
        item_column.set_cell_data_func (icon_renderer, icon_data_func);

        var name_renderer = new Gtk.CellRendererText ();
        item_column.pack_start (name_renderer, false);
        item_column.set_cell_data_func (name_renderer, name_data_func);
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

    private void icon_data_func (Gtk.CellLayout cell_layout,
                                 Gtk.CellRenderer renderer,
                                 Gtk.TreeModel tree_model,
                                 Gtk.TreeIter iter) {

        var icon_renderer = renderer as Gtk.CellRendererPixbuf;
        assert (icon_renderer != null);

        var item = get_item (iter);

        icon_renderer.visible = item.visible;
        icon_renderer.icon_name = item.icon_name;
    }

    private Item? get_item (Gtk.TreeIter iter) {
        Item? item;
        data_model.get (iter, Column.ITEM, out item, -1);
        return item;
    }

    public override void row_activated (Gtk.TreePath path,
                                        Gtk.TreeViewColumn column) {

        if (column == get_column (Column.ITEM)) {
            Item item;
            Gtk.TreeIter iter;
            if (data_model.get_iter (out iter, path)) {
                item = get_item (iter);
                item.activated ();
            }
        }
    }
}
