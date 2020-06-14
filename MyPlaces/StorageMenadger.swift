//
//  StorageMenadger.swift
//  MyPlaces
//
//  Created by Виталий Липовецкий on 14.06.2020.
//  Copyright © 2020 Виталий Липовецкий. All rights reserved.
//

import RealmSwift

let realm = try! Realm()

class StorageManager {
    
    static func saveObject(_ place: Place) {
        
        try! realm.write {
            realm.add(place)
        }
        
    }
    
    static func deleteObject(_ place: Place) {
        
        try? realm.write {
            realm.delete(place)
        }
    }
    
}
