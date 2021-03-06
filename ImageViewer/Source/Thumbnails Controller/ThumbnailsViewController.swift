//
//  ThumbnailsViewController.swift
//  ImageViewer
//
//  Created by Zeno Foltin on 07/07/2016.
//  Copyright © 2016 MailOnline. All rights reserved.
//

import UIKit

class ThumbnailsViewController: UICollectionViewController, UICollectionViewDelegateFlowLayout, UINavigationBarDelegate {

    fileprivate let reuseIdentifier = "ThumbnailCell"
    fileprivate let sectionInsets = UIEdgeInsets(top: 50.0, left: 20.0, bottom: 50.0, right: 20.0)
    fileprivate var isAnimating = false
    fileprivate let rotationAnimationDuration = 0.2

    var onItemSelected: ((Int) -> Void)?
    let layout = UICollectionViewFlowLayout()
    weak var itemsDataSource: GalleryItemsDataSource!
    var closeButton: UIButton?
    var closeLayout: ButtonLayout?
    
    /// An optional Image which will be visible during the load of GalleryItem FetchImageBlock
    var placeHolderImage : UIImage? = nil
    
    //An optional indicator which will be visible during the load of GalleryItem FetchImageBlock
    var useActivityIndicator = false
    var thumbnailsactivityIndicatorViewStyle : UIActivityIndicatorViewStyle = .white
    var thumbnailsactivityIndicatorViewColor : UIColor = UIColor.white

    required init(itemsDataSource: GalleryItemsDataSource) {
        self.itemsDataSource = itemsDataSource

        super.init(collectionViewLayout: layout)

        NotificationCenter.default.addObserver(self, selector: #selector(rotate), name: NSNotification.Name.UIDeviceOrientationDidChange, object: nil)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    
    /// Called when re-initializing to make sure we have the latest data.
    /// Allows us to cache our instance
    /// - Parameter itemsDataSource: data source
    public func updateDataSource(itemsDataSource: GalleryItemsDataSource) {
        self.itemsDataSource = itemsDataSource
        self.collectionView?.reloadData()
    }
    
    func rotate() {
        guard UIApplication.isPortraitOnly else { return }

        guard UIDevice.current.orientation.isFlat == false &&
            isAnimating == false else { return }

        isAnimating = true

        UIView.animate(withDuration: rotationAnimationDuration, delay: 0, options: UIViewAnimationOptions.curveLinear, animations: { [weak self] () -> Void in
            self?.view.transform = windowRotationTransform()
            self?.view.bounds = rotationAdjustedBounds()
            self?.view.setNeedsLayout()
            self?.view.layoutIfNeeded()

            })
        { [weak self] finished  in
            self?.isAnimating = false
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()

        let screenWidth = self.view.frame.width
        layout.sectionInset = UIEdgeInsets(top: 50, left: 8, bottom: 8, right: 8)
        layout.itemSize = CGSize(width: screenWidth/3 - 8, height: screenWidth/3 - 8)
        layout.minimumInteritemSpacing = 4
        layout.minimumLineSpacing = 4

        self.collectionView?.register(ThumbnailCell.self, forCellWithReuseIdentifier: reuseIdentifier)

        addCloseButton()
    }

    fileprivate func addCloseButton() {
        guard let closeButton = closeButton, let closeLayout = closeLayout else { return }

        switch closeLayout {
        case .pinRight(let marginTop, let marginRight):
            closeButton.autoresizingMask = [.flexibleBottomMargin, .flexibleLeftMargin]
            closeButton.frame.origin.x = self.view.bounds.size.width - marginRight - closeButton.bounds.size.width
            closeButton.frame.origin.y = marginTop
        case .pinLeft(let marginTop, let marginLeft):
            closeButton.autoresizingMask = [.flexibleBottomMargin, .flexibleRightMargin]
            closeButton.frame.origin.x = marginLeft
            closeButton.frame.origin.y = marginTop
        }

        closeButton.addTarget(self, action: #selector(close), for: .touchUpInside)

        self.view.addSubview(closeButton)
    }

    func close() {
        self.dismiss(animated: true, completion: nil)
    }

    override func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return itemsDataSource.itemCount()
    }

    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: reuseIdentifier, for: indexPath) as! ThumbnailCell

        let item = itemsDataSource.provideGalleryItem((indexPath as NSIndexPath).row)
        
        var activityIndicatorView : UIActivityIndicatorView? = nil
        
        if let ph : UIImage = self.placeHolderImage {
            cell.imageView.image = ph
        } else if (useActivityIndicator) {
            activityIndicatorView = UIActivityIndicatorView(activityIndicatorStyle: thumbnailsactivityIndicatorViewStyle)
            activityIndicatorView!.color = thumbnailsactivityIndicatorViewColor
            activityIndicatorView!.hidesWhenStopped = true
            activityIndicatorView!.center = cell.contentView.boundsCenter
            cell.imageView.addSubview(activityIndicatorView!)
            activityIndicatorView!.startAnimating()
        }
        
        
        switch item {

        case .image(let fetchImageBlock):

            fetchImageBlock() { image in

                if let image = image {
                    cell.imageView.image = image
                    activityIndicatorView?.stopAnimating()
                }
            }

        case .video(let fetchImageBlock, _):

            fetchImageBlock() { image in

                if let image = image {

                    cell.imageView.image = image
                    activityIndicatorView?.stopAnimating()
                }
            }

        case .custom(let fetchImageBlock, _):

            fetchImageBlock() { image in

                if let image = image {

                    cell.imageView.image = image
                    activityIndicatorView?.stopAnimating()
                }
            }
        }

        return cell
    }

    override func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        onItemSelected?((indexPath as NSIndexPath).row)
        close()
    }
}
