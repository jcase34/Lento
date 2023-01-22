//
//  ViewController.swift
//  Lento
//
//  Created by Jacob Case on 1/8/23.
//

import UIKit
import CoreData

class HomeViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    //Properties
    var practiceSessions = [PracticeSession]()
    
    var totalPracticeMinutes: Int16 = 0 {
        didSet {
            updateTableHeaderView()
        }
    }
    
    var totalSessionCount: Int = 0  {
        didSet {
            updateTableHeaderView()
        }
    }
    
    var mainHeaderView: MainHeaderView!

    lazy var fetchedResultsController: NSFetchedResultsController<PracticeSession> = {
        let fetchRequest: NSFetchRequest<PracticeSession> = PracticeSession.fetchRequest()
        
        fetchRequest.sortDescriptors = [NSSortDescriptor(key: #keyPath(PracticeSession.sectionDate), ascending: false)]
        
        let fetchedResultsController = NSFetchedResultsController(fetchRequest: fetchRequest, managedObjectContext: CoreDataManager.shared.managedContext, sectionNameKeyPath: #keyPath(PracticeSession.sectionDate), cacheName: nil)
        
        fetchedResultsController.delegate = self
        return fetchedResultsController
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        print(applicationDocumentsDirectory)
        
        //print(CoreDataManager.shared.deleteExisting(entityName: K.practiceSession, inMoc: CoreDataManager.shared.managedContext))
        
       // configureFRC()
        
        //Stylize
        self.navigationController!.navigationBar.prefersLargeTitles = true
        tableView.rowHeight = UITableView.automaticDimension    

        tableView.tableFooterView = copyrightFooterView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 40))
        
        //cell registration
        tableView.delegate = self
        tableView.dataSource = self
        
        
        mainHeaderView = MainHeaderView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height: 150))
        updateTableHeaderView()
        tableView.tableHeaderView = mainHeaderView
        
        tableView.register(PracticeSessionTableViewCell.self, forCellReuseIdentifier: PracticeSessionTableViewCell.identifier)
        
        totalPracticeMinutes = CoreDataManager.shared.fetchTotalPracticeSessiondMinutes()
        totalSessionCount = CoreDataManager.shared.fetchTotalPracticeSessionCount()
        
        do {
          try fetchedResultsController.performFetch()
        } catch let error as NSError {
          print("Fetching error: \(error), \(error.userInfo)")
        }
        
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "AddItem" {
            //print(segue.identifier)
            let controller = segue.destination as! ItemDetailViewController
            controller.delegate = self
            //controller.managedContext = managedContext
        } else if segue.identifier == "EditItem" {
            //print(segue.identifier)
            let controller = segue.destination as! ItemDetailViewController
            controller.delegate = self
            //controller.managedContext = managedContext
            if let indexPath = sender as? IndexPath {
                //print(indexPath)
                controller.sessionToBeEdited = fetchedResultsController.object(at: indexPath)
            }
        }
    }
    
    func updateTableHeaderView() {
        mainHeaderView.totalMinutesLabel.text = "\(totalPracticeMinutes)"
        mainHeaderView.sessionCountLabel.text = "\(totalSessionCount)"
    }        
}


//MARK: - Self Table View Methods
extension HomeViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 230
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(withIdentifier: PracticeSessionTableViewCell.identifier , for: indexPath) as! PracticeSessionTableViewCell
        let pSession = fetchedResultsController.object(at: indexPath)
        cell.dateLabel.text = formatDateToString(date: pSession.sessionDate!)
        cell.MinutesLabel.text = "\(pSession.minutes):00"
        cell.majorScaleLabel.text = pSession.majorScale
        cell.minorScaleLabel.text = pSession.minorScale
        cell.mainPieceLabel.text = pSession.mainPiece
        cell.sightReadingLabel.text = pSession.sightReading
        cell.improvLabel.text = pSession.improvisation
        cell.repertoireLabel.text = pSession.reportoire
        
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        performSegue(withIdentifier: "EditItem", sender: indexPath)
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle, forRowAt indexPath: IndexPath) {

        if (editingStyle == .delete) {
            let sessionToDelete = fetchedResultsController.object(at: indexPath)
            CoreDataManager.shared.deletePracticeSession(practiceSession: sessionToDelete)
            print("item removed from CD")
        }

        totalPracticeMinutes = CoreDataManager.shared.fetchTotalPracticeSessiondMinutes()
        totalSessionCount = CoreDataManager.shared.fetchTotalPracticeSessionCount()
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
//        print("Number of sections in table \(fetchedResultsController.sections?.count))")
        return fetchedResultsController.sections?.count ?? 0
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        let sectionInfo = fetchedResultsController.sections?[section]
        let sectionCount = sectionInfo?.numberOfObjects
//        print("Number of  rows in section:\(sectionInfo?.name) \(sectionCount)")
        return sectionCount!
    }
    
    
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "YYYY-MM-dd HH:mm:ss Z"
        let sectionInfo = fetchedResultsController.sections?[section]
        let sectionName = sectionInfo?.name
        let sectioDate = dateFormatter.date(from: sectionName!)
        dateFormatter.dateFormat = "MMM YYYY"
        let sectionTitle = dateFormatter.string(from: sectioDate!)
        
        
        return sectionTitle
        
    }
}


//MARK: - ItemDetailViewControllerDelegate Methods
extension HomeViewController: ItemDetailViewControllerDelegate {
    func ItemDetailViewControllerDidCancel(_ controller: ItemDetailViewController) {
        //print("cancel tapped")
        navigationController?.popViewController(animated: true)
    }
    
    func ItemDetailViewController(_ controller: ItemDetailViewController, didFinishAddingSession practiceSession: PracticeSession) {
        navigationController?.popViewController(animated: true)
        
        //After adding a session, fetchedResultsController will be notified an use it's delegate methods
        //to update the tableview accordingly
        totalPracticeMinutes = CoreDataManager.shared.fetchTotalPracticeSessiondMinutes()
        totalSessionCount = CoreDataManager.shared.fetchTotalPracticeSessionCount()
    }
    
    func ItemDetailViewController(_ controller: ItemDetailViewController, didFinishEditingSession practiceSession: PracticeSession) {

        //After adding a session, fetchedResultsController will be notified an use it's delegate methods
        //to update the tableview accordingly
        totalPracticeMinutes = CoreDataManager.shared.fetchTotalPracticeSessiondMinutes()
        totalSessionCount = CoreDataManager.shared.fetchTotalPracticeSessionCount()
        navigationController?.popViewController(animated: true)
    }
        
}



//MARK: - FetchResultsController Delegate method to update TableView
extension HomeViewController: NSFetchedResultsControllerDelegate {
    func controllerDidChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("change occurred on table")
        tableView.endUpdates()
    }


    func controllerWillChangeContent(_ controller: NSFetchedResultsController<NSFetchRequestResult>) {
        print("finished updates")
        tableView.beginUpdates()
    }


    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange anObject: Any, at indexPath: IndexPath?, for type: NSFetchedResultsChangeType, newIndexPath: IndexPath?) {
        switch type {
        case .insert:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        case .delete:
            tableView.deleteRows(at: [indexPath!], with: .automatic)
        case .update:
            let cell = tableView.cellForRow(at: indexPath!) as! PracticeSessionTableViewCell
            let pSession = fetchedResultsController.object(at: indexPath!)
            cell.dateLabel.text = formatDateToString(date: pSession.sessionDate!)
            cell.MinutesLabel.text = "\(pSession.minutes):00"
            cell.majorScaleLabel.text = pSession.majorScale
            cell.minorScaleLabel.text = pSession.minorScale
            cell.mainPieceLabel.text = pSession.mainPiece
            cell.sightReadingLabel.text = pSession.sightReading
            cell.improvLabel.text = pSession.improvisation
            cell.repertoireLabel.text = pSession.reportoire
        case .move:
            tableView.insertRows(at: [newIndexPath!], with: .automatic)
        default:
            return
        }
    }

    func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChange sectionInfo: NSFetchedResultsSectionInfo, atSectionIndex sectionIndex: Int, for type: NSFetchedResultsChangeType) {
        
          let indexSet = IndexSet(integer: sectionIndex)
          switch type {
          case .insert:
            tableView.insertSections(indexSet, with: .automatic)
          case .delete:
            tableView.deleteSections(indexSet, with: .automatic)
          default: break
          }
    }
}



