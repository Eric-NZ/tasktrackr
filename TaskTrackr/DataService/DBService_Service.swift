//
//  DBServiceService.swift
//  TaskTrackr
//
//  Created by Eric Ho on 20/10/18.
//  Copyright © 2018 LomoStudio. All rights reserved.
//

import Foundation
import RealmSwift

extension DatabaseService {
    // add (or update) a service object
    public func addService(add service: Service, _ title: String?, _ desc: String?, tools: [Tool], models: [ProductModel], update: Bool) {
        
        let realm = getRealm()
        
        if update {
            // if update, ensure removeing all tools & models before appending
            try! realm.write {
                service.tools.removeAll()
                service.models.removeAll()
                service.tools.append(objectsIn: tools)
                service.models.append(objectsIn: models)
                service.setValue(title, forKey: "serviceTitle")
                service.setValue(desc, forKey: "serviceDesc")
                
            }
        } else {
            service.tools.append(objectsIn: tools)
            service.models.append(objectsIn: models)
            service.serviceTitle = title
            service.serviceDesc = desc
            
            try! realm.write {
                realm.add(service, update: false)
            }
        }
    }
    
    public func convertProductsInServiceToTuplesByGroup(service: Service?) ->[(product: Product, models: [ProductModel])] {
        guard let service = service else { return [] }
        let modelsInService = service.models
        var tuples: [(product: Product, models: [ProductModel])] = []
        for model in modelsInService {
            let product = model.product
            if tuples.contains(where: {
                return $0.product == product!
            }) {
                let productIndex = tuples.count - 1
                tuples[productIndex].models.append(model)
            } else {
                tuples.append((product: product!, models: [model]))
            }
        }
        return tuples
    }
}
