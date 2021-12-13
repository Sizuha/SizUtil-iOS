//
//  SizPhoto.swift
//
//

import Foundation
import Photos
import UIKit

open class SizPhotoAlbum: NSObject {
    let albumTitle: String!
    private var assetCollection: PHAssetCollection!

    private override init() {
        fatalError()
    }
    
    public init(title: String) {
        self.albumTitle = title
        super.init()
        
        if let assetCollection = fetchAssetCollectionForAlbum() {
            self.assetCollection = assetCollection
            return
        }
    }

    public func checkAuthorization(completion: @escaping ((_ success: Bool) -> Void)) {
        let authStatus = PHPhotoLibrary.authorizationStatus()
        switch authStatus {
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                self.checkAuthorization(completion: completion)
            }
            
        case .authorized:
            self.createAlbumIfNeeded()
            completion(true)

        default:
            completion(false)
        }
    }

    private func createAlbumIfNeeded() {
        if let assetCollection = fetchAssetCollectionForAlbum() {
            // Album already exists
            self.assetCollection = assetCollection
        } else {
            PHPhotoLibrary.shared().performChanges({
                PHAssetCollectionChangeRequest.creationRequestForAssetCollection(withTitle: self.albumTitle)   // create an asset collection with the album name
            }) { success, error in
                if success {
                    self.assetCollection = self.fetchAssetCollectionForAlbum()
                } else {
                    // Unable to create album
                }
            }
        }
    }

    /// アルバムの中の写真を対象にする
    private func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }
    
    /// 全ての写真を対象にする
    private func fetchAssetAll(completion:@escaping  (_ photosAssets : [PHAsset]) -> Void) {
        var photosAssets : [PHAsset] = []
        
        let fetchOptions = PHFetchOptions()
        fetchOptions.sortDescriptors = [NSSortDescriptor(key:"creationDate", ascending: false)]
        fetchOptions.predicate = NSPredicate(format: "mediaType = %d", PHAssetMediaType.image.rawValue)
        
        let allPhotos = PHAsset.fetchAssets(with: .image, options: fetchOptions)
        allPhotos.enumerateObjects { (asset, index, bool) in
            photosAssets.append(asset)
        }
        completion(photosAssets)
    }
    
    public func add(url: URL, isPhoto: Bool = true, completionHandler: ((Bool, Error?) -> Void)? = nil) {
        self.checkAuthorization { success in
            guard success, self.assetCollection != nil else {
                completionHandler?(false, nil)
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                guard let assetChangeRequest = isPhoto
                    ? PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                    : PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url)
                else { return }
                
                let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
                let enumeration: NSArray = [assetPlaceHolder!]
                albumChangeRequest!.addAssets(enumeration)
            }, completionHandler: completionHandler)
        }
    }

    public func add(urls: [URL], isPhoto: Bool = true, completionHandler: ((Bool, Error?) -> Void)? = nil) {
        self.checkAuthorization { success in
            guard success, self.assetCollection != nil else {
                completionHandler?(false, nil)
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                var assets = [PHObjectPlaceholder]()
                for url in urls {
                    guard
                        let assetChangeRequest = isPhoto
                            ? PHAssetChangeRequest.creationRequestForAssetFromImage(atFileURL: url)
                            : PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: url),
                        let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                    else { continue }
                    assets.append(assetPlaceHolder)
                }
                
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
                let enumeration = NSArray(array: assets)
                albumChangeRequest!.addAssets(enumeration)
            }, completionHandler: completionHandler)
        }
    }
    
    public func add(image: UIImage, completionHandler: ((Bool, Error?) -> Void)? = nil) {
        self.checkAuthorization { success in
            guard success, self.assetCollection != nil else {
                completionHandler?(false, nil)
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
                
                let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
                let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
                let enumeration: NSArray = [assetPlaceHolder!]
                albumChangeRequest!.addAssets(enumeration)
            }, completionHandler: completionHandler)
        }
    }

    /// iOS写真アルバムから、写真などを削除する
    ///
    /// 注意！アルバムからの写真を削除する場合は、必ずユーザー側の確認を得るポップアップが表示される
    /// - Parameters:
    ///   - assets: 削除する対象
    ///   - fromLibrary: false = アルバムからだけではなく、ファイルも削除する
    ///   - completionHandler: 処理完了後
    public func remove(assets: [PHAsset], fromLibrary: Bool = false, completionHandler: ((Bool, Error?) -> Void)? = nil) {
        self.checkAuthorization { success in
            guard
                success,
                let album = self.assetCollection
            else {
                completionHandler?(false, nil)
                return
            }
            
            PHPhotoLibrary.shared().performChanges({
                if fromLibrary {
                    if let request = PHAssetCollectionChangeRequest(for: album) {
                        request.removeAssets(assets as NSArray)
                    }
                    return
                }
                PHAssetChangeRequest.deleteAssets(assets as NSArray)
            }, completionHandler: completionHandler)
        }
    }
    
    public func remove(before date: Date, fromLibrary: Bool = false, completionHandler: ((Bool, Error?) -> Void)? = nil) {
        let targets = list().filter { asset in
            guard let cr_date = asset.creationDate else {
                completionHandler?(false, nil)
                return false
            }
            return cr_date <= date
        }
        remove(assets: targets, fromLibrary: fromLibrary, completionHandler: completionHandler)
    }
    
    public func removeBy(filename: String, fromLibrary: Bool = false, completionHandler: ((Bool, Error?) -> Void)? = nil) {
        let targets = list().filter { asset in
            let imgName = Self.getFilename(from: asset)
            return filename == imgName
        }
        
        guard !targets.isEmpty else {
            completionHandler?(true, nil)
            return
        }
        
        remove(assets: targets, fromLibrary: fromLibrary, completionHandler: completionHandler)
    }
    
    public func list() -> [PHAsset] {
        guard let album = self.assetCollection else { return [] }
        return Self.list(of: album)
    }
    
    public class func list(of collection: PHAssetCollection) -> [PHAsset] {
        var items = [PHAsset]()
        
        let photoAssets = PHAsset.fetchAssets(in: collection, options: nil)
        photoAssets.enumerateObjects { asset, count, stop in
            let asset = asset as PHAsset
            items.append(asset)
        }
        
        return items
    }

    open class func getFilename(from asset: PHAsset, filterExt: [String] = []) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        let fileName = resources.first!.originalFilename.lowercased()
        
        for ext in filterExt {
            let orgExt = ext.localized()
            
            if fileName.hasSuffix(".\(orgExt).jpg"), let r = fileName.range(of: ".\(orgExt).jpg") {
                return fileName.replacingCharacters(in: r, with: ".\(orgExt)")
            }
            else if fileName.hasSuffix(".\(orgExt).jpeg"), let r = fileName.range(of: ".\(orgExt).jpeg") {
                return fileName.replacingCharacters(in: r, with: ".\(orgExt)")
            }
        }
        
        return fileName
    }
    
}
