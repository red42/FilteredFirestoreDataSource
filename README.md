# FilteredFirestoreDatasource
Drop-in iOS filterable replacements for [FirebaseUI](https://github.com/firebase/FirebaseUI-iOS)'s FUIBatchedArray and FUIFirestoreCollectionViewDataSource in Swift.

Unlike FirebaseUI on Android, the iOS FUIFirestoreCollectionViewDataSource is not easily extendable, so filtering the data is a challenge.

These drop-in replacements for FUIBatchedArray and FUIFirestoreCollectionViewDataSource provide a setFilter(_:) method to allow a DocumentSnapshot filter to be set on the datasource, which is applied on FilteredBatchedArray's snapshot listener.

The filter is a closure applicable to a [DocumentSnapshot] array. In other words, a (DocumentSnapshot)->Bool closure.

## Usage
```
dataSource = collectionView.bind(toFirestoreQuery: query) { (collectionView, indexPath, documentSnapshot) -> UICollectionViewCell in
  // populateCell body
}

dataSource.setFilter({ goodIdArray.contains($0.documentID) })
```

A FUIFirestoreTableViewDataSource version should be trivial to implement.