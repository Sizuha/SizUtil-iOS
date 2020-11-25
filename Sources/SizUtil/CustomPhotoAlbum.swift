//
//  CustomPhotoAlbum.swift
//

import Foundation
import UIKit
import Photos

class CustomPhotoAlbum: NSObject {
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

    private func checkAuthorizationWithHandler(completion: @escaping ((_ success: Bool) -> Void)) {
		let authStatus = PHPhotoLibrary.authorizationStatus()
		switch authStatus {
		case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                self.checkAuthorizationWithHandler(completion: completion)
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

    private func fetchAssetCollectionForAlbum() -> PHAssetCollection? {
        let fetchOptions = PHFetchOptions()
        fetchOptions.predicate = NSPredicate(format: "title = %@", albumTitle)
        let collection = PHAssetCollection.fetchAssetCollections(with: .album, subtype: .any, options: fetchOptions)

        if let _: AnyObject = collection.firstObject {
            return collection.firstObject
        }
        return nil
    }
	
    func add(url: URL, isPhoto: Bool = true, completionHandler: ((Bool, Error?) -> Void)? = nil) {
		self.checkAuthorizationWithHandler { success in
			guard success, self.assetCollection != nil else { return }
			
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

    func save(image: UIImage, completionHandler: ((Bool, Error?) -> Void)? = nil) {
        self.checkAuthorizationWithHandler { success in
			guard success, self.assetCollection != nil else { return }
			
            PHPhotoLibrary.shared().performChanges({
				let assetChangeRequest = PHAssetChangeRequest.creationRequestForAsset(from: image)
				
				let assetPlaceHolder = assetChangeRequest.placeholderForCreatedAsset
				let albumChangeRequest = PHAssetCollectionChangeRequest(for: self.assetCollection)
				let enumeration: NSArray = [assetPlaceHolder!]
				albumChangeRequest!.addAssets(enumeration)
			}, completionHandler: completionHandler)
        }
    }

    
    /*
     注意！
     アルバムからの写真を削除する場合は、必ずユーザー側の確認を得るポップアップが表示される
     */
    
    func remove(assets: [PHAsset], fromLibrary: Bool = false, completionHandler: ((Bool, Error?) -> Void)? = nil) {
		self.checkAuthorizationWithHandler { success in
			guard
				success,
				let album = self.assetCollection
			else { return }
			
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
	
	func remove(before date: Date, fromLibrary: Bool = false, completionHandler: ((Bool, Error?) -> Void)? = nil) {
		let targets = list().filter { asset in
			guard let cr_date = asset.creationDate else { return false }
			return cr_date <= date
		}
        remove(assets: targets, fromLibrary: fromLibrary, completionHandler: completionHandler)
	}
    
    func removeBy(filename: String, fromLibrary: Bool = false, completionHandler: ((Bool, Error?) -> Void)? = nil) {
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
	
	func list() -> [PHAsset] {
		guard let album = self.assetCollection else { return [] }
		var items = [PHAsset]()
		
		let photoAssets = PHAsset.fetchAssets(in: album, options: nil)
		photoAssets.enumerateObjects { asset, count, stop in
			let asset = asset as PHAsset
			items.append(asset)
		}
		
		return items
	}
    
    static func getFilename(from asset: PHAsset, ext: [String] = []) -> String {
        let resources = PHAssetResource.assetResources(for: asset)
        let fileName = resources.first!.originalFilename
        
        for orgExt in ext {
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

