//
//  CategoryViewController.swift
//  Todoey
//
//  Created by Sunehar Sandhu on 12/15/20.
//

import UIKit
import CoreData
import ChameleonFramework

class CategoryViewController: SwipeTableViewController {
    
    var categories = [Category]()
    let navBarAppearance = UINavigationBarAppearance()
    let context = (UIApplication.shared.delegate as! AppDelegate).persistentContainer.viewContext
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        loadCategories()
        
        tableView.separatorStyle = .none
        
        defaultNavBarStyle()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        defaultNavBarStyle()
    }
    
    func defaultNavBarStyle() {
        guard let navBar = navigationController?.navigationBar else {
            fatalError("Nagivation controller does not exist")
        }
        
        navBarAppearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navBarAppearance.backgroundColor = .systemBlue
        navBar.standardAppearance = navBarAppearance
        navBar.scrollEdgeAppearance = navBarAppearance
    }
    
    // MARK: - TableView DataSource Methods
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return categories.count
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = super.tableView(tableView, cellForRowAt: indexPath)
        
        let category = categories[indexPath.row]
         
        guard let categoryColor = UIColor(hexString: category.color!) else {
            fatalError()
        }
        
        cell.backgroundColor = UIColor(hexString: category.color ?? "1D9BF6")
        
        cell.textLabel?.text = category.name ?? "No Categories Added Yet"
        cell.textLabel?.textColor = ContrastColorOf(categoryColor, returnFlat: true)
        
        return cell
    }
    
    // MARK: - Data Manipulation Methods
    
    func saveCategories(shouldReload: Bool = true) {
        do {
            try context.save()
        } catch {
            print("Error saving data. \(error)")
        }
        
        if shouldReload {
            tableView.reloadData()
        }
    }
    
    func loadCategories(with request: NSFetchRequest<Category> = Category.fetchRequest()) {
        
        do {
            categories = try context.fetch(request)
        } catch {
            print("Error retreiving data. \(error)")
        }
        
        tableView.reloadData()
    }
    
    func delete(at indexPath: IndexPath) {
        let cell = indexPath.row
        context.delete(categories[cell])
        categories.remove(at: cell)
        
        saveCategories(shouldReload: false)
        
    }
    
    // MARK: - Delete data from Swipe
    override func updateModel(at indexPath: IndexPath) {
        delete(at: indexPath)
    }
    
    // MARK: - TableView Delegate Methods
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "goToItems", sender: self)
        
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        let destinationVC = segue.destination as! TodoListViewController
        
        if let indexPath = tableView.indexPathForSelectedRow {
            destinationVC.selectedCategory = categories[indexPath.row]
        }
    }
    
    // MARK: - Add New Categories
    
    @IBAction func addButtonPressed(_ sender: UIBarButtonItem) {
        
        var textField = UITextField()
        
        let alert = UIAlertController(title: "Add a new category", message: "", preferredStyle: .alert)
        let action = UIAlertAction(title: "Add", style: .default) { (action) in
            // this is what will happen once the user clicks the add button on the UIAlert
            
            let newCategory = Category(context: self.context)
            newCategory.name = textField.text!
            newCategory.color = UIColor.randomFlat().hexValue()
            
            self.categories.append(newCategory)
            
            self.saveCategories()
        }
        
        alert.addAction(action)
        alert.addTextField { (field) in
            field.placeholder = "Add a new category"
            textField = field
        }
        
        present(alert, animated: true, completion: nil)
    }
}

