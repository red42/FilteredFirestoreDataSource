//
//  FilteredFirestoreCollectionViewDataSource.swift
//  Mangos
//
//  Created by Rafael Matsunaga on 27/09/18.
//  Copyright © 2018 Priced. All rights reserved.
//

import Foundation
import FirebaseUI
import Firebase

class FilteredFirestoreCollectionViewDataSource:NSObject, UICollectionViewDataSource, FilteredBatchedArrayDelegate {
    
    var collectionView:UICollectionView?
    var collection:FilteredBatchedArray?
    var populateCellatIndexPath:(UICollectionView, IndexPath, DocumentSnapshot) -> UICollectionViewCell
    var queryErrorHandler:((Error)->Void)?
    
    var count:Int {
        get {
            return self.collection?.items.count ?? 0
        }
    }
    
    var items:[DocumentSnapshot]? {
        get {
            return self.collection?.items
        }
    }
    
    var query:Query? {
        get {
            return self.collection?.query
        }
    }
    
    init(query: Query, collectionView: UICollectionView, populateCell: @escaping (UICollectionView, IndexPath, DocumentSnapshot) -> UICollectionViewCell) {
        self.populateCellatIndexPath = populateCell
        super.init()
        self.collection = FilteredBatchedArray(query: query, delegate: self)
    }

    func snapshotAtIndex(index:Int)->DocumentSnapshot? {
        return self.collection?.items[index]
    }
    
    func bindToView(view:UICollectionView) {
        self.collectionView = view
        view.dataSource = self
        self.collection?.observeQuery()
    }
    
    func unbind() {
        self.collectionView?.dataSource = nil
        self.collectionView = nil
        self.collection?.stopObserving()
    }

    func setQuery(query:Query) {
        self.collection?.setQuery(query: query)
    }
    
    func setFilter(_ filter:@escaping (DocumentSnapshot) throws -> Bool) {
        self.collection?.setFilter(filter)
    }
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.collection?.items.count ?? 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let snap = self.collection?.items[indexPath.item]
        let cell = self.populateCellatIndexPath(collectionView, indexPath, snap!)
        return cell
    }
    
    func numberOfSections(in collectionView: UICollectionView) -> Int {
        return 1
    }
    
    func batchedArray(_ array: FilteredBatchedArray, didUpdateWith diff: FUISnapshotArrayDiff<DocumentSnapshot>) {
        self.collectionView?.performBatchUpdates({
             
            // delete
            var deletedIndexPaths = [IndexPath]()
            for index in diff.deletedIndexes {
                let deletedIndexPath = IndexPath(item: index.intValue, section: 0)
                deletedIndexPaths.append(deletedIndexPath)
            }
            self.collectionView?.deleteItems(at: deletedIndexPaths)
            
            // change
            var changedIndexPaths = [IndexPath]()
            for index in diff.changedIndexes {
                let changedIndexPath = IndexPath(item: index.intValue, section: 0)
                changedIndexPaths.append(changedIndexPath)
            }
            // Use a delete and insert instead of a reload. See
            // https://stackoverflow.com/questions/42147822/uicollectionview-batchupdate-edge-case-fails
            self.collectionView?.deleteItems(at: changedIndexPaths)
            self.collectionView?.insertItems(at: changedIndexPaths)
            
            // move
            for i in 0 ..< diff.movedInitialIndexes.count {
                let initialIndex = diff.movedInitialIndexes[i].intValue
                let finalIndex = diff.movedResultIndexes[i].intValue
                let initialPath = IndexPath(item: initialIndex, section: 0)
                let finalPath = IndexPath(item: finalIndex, section: 0)
                self.collectionView?.moveItem(at: initialPath, to: finalPath)
            }
            
            // insert
            var insertedIndexPaths = [IndexPath]()
            for index in diff.insertedIndexes {
                let insertedIndexPath = IndexPath(item: index.intValue, section: 0)
                insertedIndexPaths.append(insertedIndexPath)
            }
            self.collectionView?.insertItems(at: insertedIndexPaths)
            
        }, completion: { finished in
            // Reload paths that have been moved.
            var movedIndexPaths:[IndexPath] = [IndexPath]()
            for index in diff.movedResultIndexes {
                let movedIndexPath = IndexPath(item: index.intValue, section: 0)
                movedIndexPaths.append(movedIndexPath)
            }
            self.collectionView?.reloadItems(at: movedIndexPaths)
        })
    }
    
    func batchedArray(_ array: FilteredBatchedArray, queryDidFailWithError error: Error) {
        if self.queryErrorHandler != nil {
            self.queryErrorHandler!(error)
        } else {
            print(String(format:"%@ Unhandled Firestore error: %@. Set the queryErrorHandler property to debug.",
                    self, error.localizedDescription))
        }
    }
    
}

extension UICollectionView {
    func bind(toFirestoreQuery:Query, populateCell:@escaping (UICollectionView, IndexPath, DocumentSnapshot) -> UICollectionViewCell)->FilteredFirestoreCollectionViewDataSource {
        let dataSource = FilteredFirestoreCollectionViewDataSource(query: toFirestoreQuery, collectionView: self, populateCell: populateCell)
        dataSource.bindToView(view: self)
        return dataSource
    }
}
