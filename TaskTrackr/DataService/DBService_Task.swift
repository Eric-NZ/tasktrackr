//
//  DBService_Task.swift
//  TaskTrackr
//
//  Created by Eric Ho on 20/10/18.
//  Copyright © 2018 LomoStudio. All rights reserved.
//
import Foundation
import RealmSwift

extension DatabaseService {
    // get Results of Task
    public func getTaskResult(with username: String) -> List<Task> {
        let alltasks = getRealm().objects(Task.self).sorted(byKeyPath: "timestamp", ascending: false)
        let tasks = alltasks.filter {
            $0.workers.contains(where: {
                $0.username == username
            })
        }
        let taskList = List<Task>()
        for task in tasks {
            taskList.append(task)
        }
        
        return taskList
    }
    
    public func getAllTasks() -> Results<Task> {
        return getRealm().objects(Task.self).sorted(byKeyPath: "timestamp", ascending: false)
    }
    
    /***
     Once Results changed, do nothing but invoke the callback funcion only
     */
    func addTaskResultsObserverForUser(objects: Results<Task>, tableView: UITableView?, callback: @escaping ((List<Task>)->Void), for user: String) -> NotificationToken {
        
        let notificationToken = objects.observe { (changes) in
            let tasks: [Task] = self.getAllTasks().filter({
                $0.workers.contains(where: {
                    $0.username == user
                })
            }).filter({
                let finalLogIndex = $0.stateLogs.count - 1
                return $0.stateLogs[finalLogIndex].taskState != .created
            })
            let taskList = List<Task>()
            for task in tasks {
                taskList.append(task)
            }
            callback(taskList)
        }
        
        return notificationToken
    }
    
    // add (or update) a task object
    public func addTask(add task: Task, _ title: String, _ desc: String, service: Service, workers: [Worker], deadline: Date,
                        locationTuple: LocationTuple,
                        productConsumptions: [ProductConsumption]?,
                        images: [UIImage], taskState: TaskLog.TaskState, update: Bool) {
        let realm = getRealm()
        if update {
            try! realm.write {
                task.workers.removeAll()
                task.workers.append(objectsIn: workers)
                task.setValue(service, forKey: "service")
                task.setValue(title, forKey: "taskTitle")
                task.setValue(desc, forKey: "taskDesc")
                task.setValue(deadline, forKey: "dueDate")
                task.setValue(locationTuple.address, forKey: "address")
                task.setValue(locationTuple.latitude, forKey: "latitude")
                task.setValue(locationTuple.longitude, forKey: "longitude")
                // product consumption
                task.productConsumptions.removeAll()
                task.productConsumptions.append(objectsIn: productConsumptions ?? [])
                // image
                task.images.removeAll()
                task.images.append(objectsIn: convertImagesToDatas(images: images))
            }
        } else {
            task.workers.append(objectsIn: workers)
            task.service = service
            task.taskTitle = title
            task.taskDesc = desc
            task.dueDate = deadline
            // location
            task.address = locationTuple.address
            task.latitude = locationTuple.latitude
            task.longitude = locationTuple.longitude
            // product consumption
            task.productConsumptions.append(objectsIn: productConsumptions ?? [])
            // images
            saveImages(to: task, images: images)
            // add state log
            addTaskStateLog(for: task, to: taskState)
            
            try! realm.write {
                realm.add(task, update: false)
            }
        }
    }
    
    private func saveImages(to task: Task, images: [UIImage]) {
        let numberOfImages = images.count
        for n in 0..<numberOfImages {
            // background thread
            if let data: Data = images[n].jpegData(compressionQuality: 0.5) {
                task.images.append(data)
            }
        }
    }
    
    private func convertImagesToDatas(images: [UIImage]) -> [Data] {
        var datas: [Data] = []
        for n in 0..<images.count {
            if let data = images[n].jpegData(compressionQuality: 0.5) {
                datas.append(data)
            }
        }
        return datas
    }
    
    // change task state
    @discardableResult
    public func addTaskStateLog(for task: Task?, to newState: TaskLog.TaskState?) -> TaskLog.TaskState? {
        guard let task = task else {return nil}
        
        let logs = task.stateLogs
        // if there are no logs in the list, means the task is a new task just created, then append a new log from -1 to 0
        let numberOfLogs = logs.count
        let log = TaskLog()
        if numberOfLogs == 0 {
            log.fromState = -1
            log.taskState = .created
            log.timestamp = Date()
        } else {
            log.fromState = task.stateLogs[numberOfLogs - 1].taskState.rawValue
            log.taskState = newState!
            log.timestamp = Date()
        }
        
        let realm = getRealm()
        // append state change to change list
        try! realm.write {
            task.stateLogs.append(log)
        }
        
        return TaskLog.TaskState(rawValue: log.fromState)
    }
    
    // back to previous state
    public func backToPreviousState(for task: Task?, offset: Int) {
        guard let task = task else { return }
        
        let numberOfDeletion = offset > 1 ? offset : 1
        
        for _ in 0..<numberOfDeletion {
            removeOneTaskStateLog(for: task, nil)
        }
    }
    
    // if the index no designated, remove the last log
    public func removeOneTaskStateLog(for task: Task?, _ index: Int?) {
        guard let task = task else { return }
        
        let realm = getRealm()
        let logs = task.stateLogs
        try! realm.write {
            if let index = index {
                logs.remove(at: index)
            } else {
                logs.removeLast()
            }
        }
    }
    
    // remove all state logs belong to designated task
    public func removeAllTaskStateLog(for task: Task?) {
        guard let task = task else { return }
        
        let realm = getRealm()
        let logs = task.stateLogs
        try! realm.write {
            logs.removeAll()
        }
    }
}
