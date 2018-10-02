//
//  FilteredBatchedArray.swift
//  Mangos
//
//  Created by Rafael Matsunaga on 28/09/18.
//  Copyright © 2018 Priced. All rights reserved.
//

import Foundation
import FirebaseUI

class FilteredBatchedArray {
    
    var observer:ListenerRegistration?
    var isInSync = true
    var items = [DocumentSnapshot]()
    var idsToHide = [String]()
    var delegate:FilteredBatchedArrayDelegate?
    var query:Query
    var count:Int {
        get {
            return self.items.count
        }
    }
    
    var filter:((DocumentSnapshot) throws -> Bool)? = nil
    
    init(query:Query, delegate:FilteredBatchedArrayDelegate) {
        self.delegate = delegate
        self.query = query
    }
    
    func observeQuery() {
        
        if observer != nil {
            return
        }
        
        weak var weakSelf = self
        observer = query.addSnapshotListener({ (snapshot, error) in
            
            if error != nil {
                print(String(format: "Firestore error: %@", error!.localizedDescription))
                
                weakSelf?.delegate?.batchedArray(weakSelf!, queryDidFailWithError: error!)
            }
            
            var diff:FUISnapshotArrayDiff<DocumentSnapshot>
            
            // filter documents
            
            var filteredItems = [DocumentSnapshot]()
            if self.filter != nil {
                filteredItems = (snapshot?.documents.filter(self.filter!))!
            }

//            for snapshot in (snapshot?.documents)! {
//                if !(weakSelf?.idsToHide.contains(snapshot.documentID))! {
//                    filteredItems.append(snapshot)
//                }
//            }
            
            if (weakSelf?.isInSync)! {
                diff = FUISnapshotArrayDiff(initialArray: weakSelf!.items, resultArray: filteredItems, documentChanges: (snapshot?.documentChanges)!)
            } else {
                diff = FUISnapshotArrayDiff(initialArray: weakSelf!.items, resultArray: filteredItems)
            }
            
            weakSelf!.items = filteredItems
            weakSelf!.isInSync = true
            
            weakSelf?.delegate?.batchedArray(weakSelf!, didUpdateWith: diff)
            
        })
        
    }
    
    func stopObserving() {
        if self.observer == nil {
            return
        }
        self.observer?.remove()
        self.observer = nil
        self.isInSync = false
    }
    
    func setQuery(query: Query) {
        let wasObserving = self.observer != nil
        self.stopObserving()
        self.query = query
        if wasObserving {
            self.observeQuery()
        }
    }

    func setFilter(_ filter:@escaping (DocumentSnapshot) throws -> Bool) {
        let wasObserving = self.observer != nil
        self.stopObserving()
        self.filter = filter
        if wasObserving {
            self.observeQuery()
        }
    }

    func objectAtIndex(index:Int)->DocumentSnapshot {
        return self.items[index]
    }
    
    func objectAtIndexSubscript(index:Int)->DocumentSnapshot {
        return self.objectAtIndex(index:index)
    }
    
    deinit {
        self.stopObserving()
    }
}

protocol FilteredBatchedArrayDelegate {
    
    func batchedArray(_ batchedArray:FilteredBatchedArray, queryDidFailWithError:Error)
    func batchedArray(_ batchedArray:FilteredBatchedArray, didUpdateWith:FUISnapshotArrayDiff<DocumentSnapshot>)
    
}
