import UIKit
import CoreData
import ChameleonFramework

class TodoListViewController: SwipeTableViewController {
    
    @IBOutlet weak var searchBar: UISearchBar!
    
    var itemArray = [Item]()
    
    var selectedCategory: Category? {
        didSet {
            loadItems()
        }
    }
    
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        tableView.separatorStyle = .none
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        if let colorHex = selectedCategory?.color {
            
            let navBarAppearance = UINavigationBarAppearance()
            
            title = selectedCategory!.name
            
            guard let navBar = navigationController?.navigationBar else {
                fatalError("Nagivation controller does not exist")
            }
            
            if let tintColor = UIColor(hexString: colorHex) {
                navBarAppearance.backgroundColor = UIColor(hexString: colorHex)
                navBar.tintColor = ContrastColorOf(tintColor, returnFlat: true)
                navBarAppearance.largeTitleTextAttributes = [.foregroundColor: ContrastColorOf(tintColor, returnFlat: true)]
                navBar.standardAppearance = navBarAppearance
                navBar.scrollEdgeAppearance = navBarAppearance
                searchBar.barTintColor = tintColor
            }
        }
    }
    
    // MARK: - TableView Datasource Methods
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return itemArray.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        let item = itemArray[indexPath.row]
        
        cell.textLabel?.text = item.title ?? "No items added"
        let parentColor = UIColor(hexString: selectedCategory?.color ?? "1D9BF6")
        if let color = parentColor?.darken(byPercentage: CGFloat(indexPath.row) / CGFloat(itemArray.count)) {
            cell.backgroundColor = color
            // this will allow contrast of the checkmark
            cell.tintColor = ContrastColorOf(color, returnFlat: true)
            cell.textLabel?.textColor = ContrastColorOf(color, returnFlat: true)
        }
        
        cell.accessoryType = item.done ? .checkmark : .none
        
        return cell
    }
    
    // MARK: - TableView Delegate Methods
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        itemArray[indexPath.row].done = !itemArray[indexPath.row].done
        
        saveItems()
        
        // this allows the selection to flash instead of staying gray
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    // MARK: - Add New Items
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add new Todoey Item", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add Item", style: .default) { (action) in
            // this is what will happen once the user clicks the add button on the UIAlert
            
            let newItem = Item(context: self.context)
            newItem.title = textField.text!
            newItem.done = false
            newItem.parentCategory = self.selectedCategory
            self.itemArray.append(newItem)
            
            self.saveItems()
        }
        
        alert.addTextField { (alertTextField) in
            alertTextField.placeholder = "Create new item"
            textField = alertTextField
        }
        
        
        alert.addAction(action)
        
        // shows the alert view
        present(alert, animated: true, completion: nil)
    }
    
    // MARK: - Model Manipulation Methods
    
    func saveItems(shouldReload: Bool = true) {
        do {
            try context.save()
        } catch {
            print("Error saving data. \(error)")
        }
        
        if shouldReload {
            tableView.reloadData()
        }
    }
    
    func loadItems(with request: NSFetchRequest<Item> = Item.fetchRequest(), predicate: NSPredicate? = nil) {
        
        let categoryPredicate = NSPredicate(format: "parentCategory.name MATCHES %@", selectedCategory!.name!)
        
        if let additionalPredicate = predicate {
            request.predicate = NSCompoundPredicate(andPredicateWithSubpredicates: [categoryPredicate, additionalPredicate])
        }
        else {
            request.predicate = categoryPredicate
        }
        
        do {
            itemArray = try context.fetch(request)
        } catch{
            print("Error fetching data. \(error)")
        }
        
        tableView.reloadData()
    }
    
    func delete(at indexPath: IndexPath) {
        let cell = indexPath.row
        context.delete(itemArray[cell])
        itemArray.remove(at: cell)
        
        saveItems(shouldReload: false)
    }
    
    // MARK: - Delete data from Swipe
    override func updateModel(at indexPath: IndexPath) {
        delete(at: indexPath)
    }
}

// MARK: - SearchBar Methods
extension TodoListViewController: UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        let request: NSFetchRequest<Item> = Item.fetchRequest()
        
        /*
         [c] case insensitive: lowercase & uppercase values are treated the same
         [d] diacritic insensitive: special characters treated as the base character
         */
        let predicate = NSPredicate(format: "title CONTAINS[cd] %@", searchBar.text!)
        
        // expects an array
        request.sortDescriptors = [NSSortDescriptor(key: "title", ascending: true)]
        
        loadItems(with: request, predicate: predicate)
    }
    
    func searchBar(_ searchBar: UISearchBar, textDidChange searchText: String) {
        if searchBar.text?.count == 0 {
            loadItems()
            
            // takes away the cursor and the keyboard
            DispatchQueue.main.async {
                searchBar.resignFirstResponder()
            }
        }
    }
}

