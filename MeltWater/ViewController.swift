//
//  ViewController.swift
//  MeltWater
//
//  Created by Arfhan Ahmad on 8/10/18.
//  Copyright © 2018 Arfhan Ahmad. All rights reserved.
//

import UIKit
import CoreData


extension Int {
    var stringValue:String {
        return "\(self)"
    }
}
class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var holder = [JsonModel]()
    var dbHolder = [NSManagedObject]()
    
    @objc var pullToRefresh: UIRefreshControl!
    
    @IBOutlet weak var tableView: UITableView!
    @objc func jsonDataParsing () {
        
        let jsonURLString = "https://api.github.com/gists/public"
        
        guard let url = URL(string: jsonURLString) else {return}
        URLSession.shared.dataTask(with: url) { (data, response, err) in
            
            guard let data = data else {return}
            
            do {
                self.holder = try JSONDecoder().decode([JsonModel].self, from: data)
                self.holder.reverse()
                for gist in self.holder {
                    self.save(gist)
                }
                self.dbHolder = self.fetchAll()
                print("No Gist: ", self.dbHolder.count)
                self.dbHolder.reverse()
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                }
                
            } catch _ {
                print("Error")
            }
            DispatchQueue.main.async {
                self.pullToRefresh.endRefreshing()
            }
        }.resume()

    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
//        deleteAll() // To empty database
        pullToRefresh = UIRefreshControl()
        pullToRefresh.attributedTitle = NSAttributedString(string: "Pull To Refresh")
        pullToRefresh.addTarget(self, action: #selector(refreshList), for: UIControlEvents.valueChanged)
        tableView.addSubview(pullToRefresh)
        
        _ = Timer.scheduledTimer(timeInterval: 15, target: self, selector: #selector (jsonDataParsing), userInfo: nil, repeats: true)
        
        jsonDataParsing()
    }

    @objc func refreshList() {
        pullToRefresh.beginRefreshing()
        self.jsonDataParsing()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  dbHolder.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath) as! JsonDataTableViewCell
        cell.fileNameLabel.text = dbHolder[indexPath.row].value(forKey: "filename") as? String
        cell.descriptionLabel.text = dbHolder[indexPath.row].value(forKey: "desc") as? String
        let num = dbHolder[indexPath.row].value(forKey: "comment_no")!
        cell.numberOfCommentsLabel.text = "\(num)"
        cell.logInIDLabel.text = dbHolder[indexPath.row].value(forKey: "login") as? String
        cell.timeDateLabel.text = formatDate(string: (dbHolder[indexPath.row].value(forKey: "created_at") as? String)!)
        
        
        if let imageURL = URL(string: (dbHolder[indexPath.row].value(forKey: "avatar_url"))! as! String) {
            DispatchQueue.global().async {
                let data = try? Data(contentsOf: imageURL)
                if let data = data {
                    let image = UIImage(data: data)
                    DispatchQueue.main.async {
                        cell.avatarImageView.image = image
                    }
                }
            }
        }
        
        return cell
    }
    
    func formatDate(string: String) -> String {
        let dateFormatter = DateFormatter()
        let tempLocale = dateFormatter.locale // save locale temporarily
        dateFormatter.locale = Locale(identifier: "en_US_POSIX") // set locale to reliable US_POSIX
        dateFormatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
        let date = dateFormatter.date(from: string)!
        dateFormatter.dateFormat = "MMM dd, yyyy - hh:mm a"
        dateFormatter.locale = tempLocale // reset the locale
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alert = UIAlertController(title: dbHolder[indexPath.row].value(forKey: "filename") as? String, message: dbHolder[indexPath.row].value(forKey: "description") as? String, preferredStyle: UIAlertControllerStyle.alert)
        
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { action in
            switch action.style{
            case .default:
                print("default")
            case .cancel:
                print("cancel")
                
            case .destructive:
                print("destructive")
            }}))
        self.present(alert, animated: true, completion: nil)
    }
    
    func save(_ newGist: JsonModel) {

        if ifExists(newGist.id!) {return}
        
        guard let appDeligate = UIApplication.shared.delegate as? AppDelegate else {return}
        let managedContext = appDeligate.persistentContainer.viewContext
        let entity = NSEntityDescription.entity(forEntityName: "Gist", in:  managedContext)
        let Gist = NSManagedObject(entity: entity!, insertInto: managedContext)
        
        Gist.setValue(newGist.id, forKey: "id")
        Gist.setValue(newGist.description, forKey: "desc")
        Gist.setValue(newGist.owner?.avatar_url, forKey: "avatar_url")
        Gist.setValue(newGist.comments, forKey: "comment_no")
        Gist.setValue(newGist.files?.filename, forKey: "filename")
        Gist.setValue(newGist.owner?.login, forKey: "login")
        Gist.setValue(newGist.created_at, forKey: "created_at")

        do {
            try managedContext.save()

        } catch let err as NSError {
            print(err)
        }
        
    }
    
    func ifExists(_ id: String) -> Bool {
        guard let appDeligate = UIApplication.shared.delegate as? AppDelegate else {return false}
        let managedContext = appDeligate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Gist")
        fetchRequest.predicate = NSPredicate(format: "id = %@", id)

        var results: [NSManagedObject] = []

        do {
            results = try managedContext.fetch(fetchRequest)
        }
        catch {
            print("error executing fetch request: \(error)")
        }
        return results.count > 0
    }
    func fetchAll() -> [NSManagedObject] {
        guard let appDeligate = UIApplication.shared.delegate as? AppDelegate else {return []}
        let managedContext = appDeligate.persistentContainer.viewContext
        let fetchRequest = NSFetchRequest<NSManagedObject>(entityName: "Gist")
        
        var results: [NSManagedObject] = []
        
        do {
            results = try managedContext.fetch(fetchRequest)
        }
        catch {
            print("error executing fetch request: \(error)")
        }
        
        return results
    }
    
    func deleteAll() {
        
        guard let appDeligate = UIApplication.shared.delegate as? AppDelegate else {return}
        let managedContext = appDeligate.persistentContainer.viewContext
        let fetch = NSFetchRequest<NSFetchRequestResult>(entityName: "Gist")
        let request = NSBatchDeleteRequest(fetchRequest: fetch)
        do {
            try managedContext.execute(request)
        } catch let err {
            print(err)
        }
        
    }
    
}
