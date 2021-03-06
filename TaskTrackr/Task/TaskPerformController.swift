//
//  TaskPerformController.swift
//  TaskTrackr
//
//  Created by Eric Ho on 13/11/18.
//  Copyright © 2018 LomoStudio. All rights reserved.
//

import UIKit
import RealmSwift

class TaskPerformController: UIViewController {
    var tableView: TimelineTableView!
    var taskNotification: NotificationToken?
    var allTasks: Results<Task> = DatabaseService.shared.getAllTasks()
    var myTasks = List<Task>()
    let username = AuthenticationService.shared.currentUsername
    
    init() {
        super.init(nibName: nil, bundle: nil)
        commonInit()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        commonInit()
    }
    
    deinit {
        taskNotification?.invalidate()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        taskNotification = DatabaseService.shared.addTaskResultsObserverForUser(objects: allTasks, tableView: tableView, callback: {
            self.myTasks = $0
            self.tableView.reloadData()
            
            // notification
            
            
        }, for: self.username!)
        
        // setup auto layout
        setupLayout()
        // setup data source
        setupDataSource()
    }

    private func commonInit() {
        tableView = TimelineTableView()
        
        view.backgroundColor = UIColor.white
        title = "Perform"
        tabBarItem.image = UIImage(named: "tab_to-do-list")
    }
    
    func setupLayout() {
        tableView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(tableView)
        tableView.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor).isActive = true
        tableView.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
    }
    
    func setupDataSource() {
        tableView.numberOfSections {
            return self.myTasks.count
        }
        
        tableView.dataForHeader {
            let formatter = DateFormatter()
            formatter.dateFormat = "dd/MM/yyyy"
            
            let task = self.myTasks[$0]
            var headerData = SectionData()
            // title
            headerData.title = task.taskTitle
            // desc
            let postInfo = String(format: "Created by %@, on %@", "Manager", formatter.string(from: task.timestamp))
            headerData.subTitle = postInfo
            // address
            headerData.bulletSecond = task.address
            // due date
            let dueDateString = formatter.string(from: task.dueDate)
            headerData.bulletThird = String(format: "Deadline: %@", dueDateString)
            // workers
            headerData.bulletFirst = self.buildWorkerAttributedText(workers: task.workers)
            // image
            if task.images.count > 0 {
                headerData.image = UIImage(data: task.images[0])!
            }
            
            return headerData
        }
        
        tableView.numberOfRowsInSection {
            return self.myTasks[$0].stateLogs.count
        }
        // MARK: - setup cell data
        tableView.dataForRowAtIndexPath {
            let task = self.myTasks[$0.section]
            let stateLog = task.stateLogs[$0.row]
            var cellData = CellData()
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            formatter.dateFormat = "dd/MM/yyyy HH:mm:ss"
            
            // the buttons are only available where it is the last row
            let isFinalCell: Bool = $0.row == task.stateLogs.count - 1
            cellData.illustrateTitleBold = isFinalCell ? true : false
            
            switch stateLog.taskState {
            case .created:
                cellData.timeText = formatter.string(from: stateLog.timestamp)
                cellData.illustrateTitle = "Created"
                cellData.illustrateTitleBold = isFinalCell ? true : false
                cellData.illustrateImage = UIImage(named: "created")
                cellData.isFirstCell = true
                cellData.buttonAttributes = isFinalCell ? [CellData.ButtonAttributeTuple(0, self, UIImage(named: "next"), {()->Void in
                    // callback closure
                }), CellData.ButtonAttributeTuple(1, self, UIImage(named: "edit"), {
                    // callback closure
                    
                    
                }), CellData.ButtonAttributeTuple(2, self, UIImage(named: "trash"), {()->Void in
                    // callback closure
                    
                }), CellData.ButtonAttributeTuple(3, self, UIImage(named: "info"), {()->Void in
                    // callback closure
                    
                })] : []
            case .pending:
                cellData.timeText = formatter.string(from: stateLog.timestamp)
                cellData.illustrateTitle = "Pending"
                cellData.illustrateImage = UIImage(named: "pending")
                cellData.buttonAttributes = isFinalCell ? [CellData.ButtonAttributeTuple(0, self, UIImage(named: "go"), {()->Void in
                    // callback closure: push the task forward to next state with offset + 1
                    self.changeTaskState(for: task, nextState: .processing)
                    
                }), CellData.ButtonAttributeTuple(1, self, UIImage(named: "comment"), {()->Void in
                    // callback closure
                    
                }), CellData.ButtonAttributeTuple(2, self, UIImage(named: "info"), {()->Void in
                    // callback closure
                    
                })] : []
            case .processing:
                cellData.timeText = formatter.string(from: stateLog.timestamp)
                cellData.illustrateTitle = "Processing"
                cellData.illustrateImage = UIImage(named: "processing")
                cellData.buttonAttributes = isFinalCell ? [CellData.ButtonAttributeTuple(0, self, UIImage(named: "done"), {
                    self.changeTaskState(for: task, nextState: .finished)
                }), CellData.ButtonAttributeTuple(1, self, UIImage(named: "comment"), {()->Void in
                    // callback closure
                    
                }), CellData.ButtonAttributeTuple(2, self, UIImage(named: "info"), {()->Void in
                    // callback closure
                    
                })] : []
            case .finished:
                cellData.timeText = formatter.string(from: stateLog.timestamp)
                cellData.illustrateTitle = "Finished"
                cellData.illustrateTitleColor = UIColor.blue
                cellData.illustrateImage = UIImage(named: "finished")
                cellData.isFinalCell = true
                cellData.buttonAttributes = isFinalCell ? [CellData.ButtonAttributeTuple(0, self, UIImage(named: "info"), {()->Void in
                    // callback closure
                    
                })] : []
            case .failed:
                cellData.timeText = formatter.string(from: stateLog.timestamp)
                cellData.illustrateTitle = "Failed"
                cellData.illustrateTitleColor = UIColor.red
                cellData.illustrateImage = UIImage(named: "failed")
                cellData.isFinalCell = true
                cellData.buttonAttributes = isFinalCell ? [CellData.ButtonAttributeTuple(0, self, UIImage(named: "archive"), {()->Void in
                    // callback closure
                    
                }), CellData.ButtonAttributeTuple(1, self, UIImage(named: "trash"), {()->Void in
                    // callback closure
                    
                }), CellData.ButtonAttributeTuple(2, self, UIImage(named: "info"), {()->Void in
                    // callback closure
                    
                })] : []
            }
            
            return cellData
        }
    }
    
    private func buildWorkerAttributedText(workers: List<Worker>) -> NSAttributedString {
        let attributedText: NSMutableAttributedString = NSMutableAttributedString()
        attributedText.append(NSAttributedString(string: "Worker: ", attributes: [:]))
        
        // if there are no workers
        if workers.count == 0 {
            let warning = "No worker designated. "
            attributedText.append(NSAttributedString(string: warning, attributes: [.foregroundColor: UIColor.red]))
        } else {
            var workerString = ""
            for worker in workers {
                workerString.append(contentsOf: worker.firstName!)
                workerString.append(contentsOf: "; ")
            }
            // remove last "; "
            workerString.removeLast(2)
            attributedText.append(NSAttributedString(string: workerString, attributes: [.font : UIFont.boldSystemFont(ofSize: 12)]))
        }
        
        
        return attributedText
    }
    
    private func changeTaskState(for task: Task, nextState: TaskLog.TaskState) {
        DatabaseService.shared.addTaskStateLog(for: task, to: nextState)
    }
}
