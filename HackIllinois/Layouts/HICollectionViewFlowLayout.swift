//
//  HICollectionViewFlowLayout.swift
//  HackIllinois
//
//  Created by Rauhul Varma on 11/22/17.
//  Copyright © 2017 HackIllinois. All rights reserved.
//

import Foundation
import UIKit

class HICollectionViewFlowLayout: UICollectionViewFlowLayout {
    private let transformIdentity = CATransform3D(m11: 1, m12: 0, m13: 0, m14: 0,
                                                  m21: 0, m22: 1, m23: 0, m24: 0,
                                                  m31: 0, m32: 0, m33: 1, m34: 0,
                                                  m41: 0, m42: 0, m43: 0, m44: 1)

    private var dynamicAnimator: UIDynamicAnimator!
    private var visibleIndexPaths = Set<IndexPath>()
//    private var latestDelta: CGFloat = 0

    // MARK: - Initialization

    override public init() {
        super.init()
        initialize()
    }

    required public init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        initialize()
    }

    private func initialize() {
        dynamicAnimator = UIDynamicAnimator(collectionViewLayout: self)
    }

    // MARK: - Public

    open func resetLayout() {
        dynamicAnimator.removeAllBehaviors()
        prepare()
    }

    // MARK: - Overrides

    override open func prepare() {
        super.prepare()
        guard let collectionView = collectionView else { return }

        // expand the visible rect slightly to avoid flickering when scrolling quickly
        let expandBy: CGFloat = -100
        let visibleRect = CGRect(origin: collectionView.bounds.origin,
                                 size: collectionView.frame.size).insetBy(dx: 0, dy: expandBy)

        guard let visibleItems = super.layoutAttributesForElements(in: visibleRect) else { return }
        let indexPathsInVisibleRect = Set(visibleItems.map{ $0.indexPath })

        removeNoLongerVisibleBehaviors(indexPathsInVisibleRect: indexPathsInVisibleRect)

        let newlyVisibleItems = visibleItems.filter { item in
            return !visibleIndexPaths.contains(item.indexPath)
        }

        addBehaviors(for: newlyVisibleItems)
    }

    override open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let collectionView = collectionView else { return nil }
        let dynamicItems = dynamicAnimator.items(in: rect) as? [UICollectionViewLayoutAttributes]
        dynamicItems?.forEach { item in
            if item.representedElementCategory == .cell {
                item.transform3D = transformIdentity
                let convertedY = item.center.y - collectionView.contentOffset.y - sectionInset.top
    //            item.zIndex = item.indexPath.row

                transformItemIfNeeded(y: convertedY, item: item)
            }
        }
        return dynamicItems
    }

    private func transformItemIfNeeded(y: CGFloat, item: UICollectionViewLayoutAttributes) {
        let height = item.frame.size.height
        guard height > 0, y < height * 0.5 else {
            return
        }

        let scaleFactor = scaleDistributor(x: y, height: height)

        let yDelta = height * 0.5 - y//getYDelta(y: y, itemHeight: item.frame.height)
        item.center.y += yDelta
//        item.frame = item.frame.insetBy(dx: yDelta*0.1, dy: yDelta*0.1)
        item.transform3D = CATransform3DTranslate(transformIdentity, 0, 0, -yDelta)
        item.transform3D = CATransform3DScale(item.transform3D, scaleFactor, scaleFactor, 0)

//        item.alpha = scaleDistributor(x: y, itemHeight: item.frame.height)
    }

    override open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        return dynamicAnimator.layoutAttributesForCell(at: indexPath)
    }

    override open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
//        let scrollView = self.collectionView!
//        let delta = newBounds.origin.y - scrollView.bounds.origin.y
//        latestDelta = delta

//        let touchLocation = collectionView!.panGestureRecognizer.location(in: collectionView)

        dynamicAnimator.behaviors.flatMap { $0 as? UIAttachmentBehavior }.forEach { behavior in
            let attrs = behavior.items.first as! UICollectionViewLayoutAttributes
//            attrs.center = getUpdatedBehaviorItemCenter(behavior: behavior, touchLocation: touchLocation)
            self.dynamicAnimator.updateItem(usingCurrentState: attrs)
        }
        return false
    }

    // MARK: - Utils

    private func removeNoLongerVisibleBehaviors(indexPathsInVisibleRect indexPaths: Set<IndexPath>) {
        //get no longer visible behaviors
        let noLongerVisibleBehaviours = dynamicAnimator.behaviors.filter { behavior in
            guard let behavior = behavior as? UIAttachmentBehavior,
                let item = behavior.items.first as? UICollectionViewLayoutAttributes else { return false }
            return !indexPaths.contains(item.indexPath)
        }

        //remove no longer visible behaviors
        noLongerVisibleBehaviours.forEach { behavior in
            guard let behavior = behavior as? UIAttachmentBehavior,
                let item = behavior.items.first as? UICollectionViewLayoutAttributes else { return }
            self.dynamicAnimator.removeBehavior(behavior)
            self.visibleIndexPaths.remove(item.indexPath)
        }
    }

    private func addBehaviors(for items: [UICollectionViewLayoutAttributes]) {
//        guard let collectionView = collectionView else { return }
//        let touchLocation = collectionView.panGestureRecognizer.location(in: collectionView)

        items.forEach { item in
            let springBehaviour = UIAttachmentBehavior(item: item, attachedToAnchor: item.center)
//
//            springBehaviour.length = 0.0
//            springBehaviour.damping = 0.8
//            springBehaviour.frequency = 1.0

//            if !CGPoint.zero.equalTo(touchLocation) {
//                item.center = getUpdatedBehaviorItemCenter(behavior: springBehaviour, touchLocation: touchLocation)
//            }

            self.dynamicAnimator.addBehavior(springBehaviour)
            self.visibleIndexPaths.insert(item.indexPath)
        }
    }

//    private func getUpdatedBehaviorItemCenter(behavior: UIAttachmentBehavior,
//                                              touchLocation: CGPoint) -> CGPoint {
//        let yDistanceFromTouch = fabs(touchLocation.y - behavior.anchorPoint.y)
//        let xDistanceFromTouch = fabs(touchLocation.x - behavior.anchorPoint.x)
//        let scrollResistance = (yDistanceFromTouch + xDistanceFromTouch) / (15 * 100)
//
//        let attrs = behavior.items.first as! UICollectionViewLayoutAttributes
//        var center = attrs.center
//        if latestDelta < 0 {
//            center.y += max(latestDelta, latestDelta * scrollResistance)
//        } else {
//            center.y += min(latestDelta, latestDelta * scrollResistance)
//        }
//        return center
//    }

    // MARK: - Distribution functions

    /**
     Distribution function that start as a square root function and levels off when reaches y = 1.
     - parameter x: X parameter of the function. Current layout implementation uses center.y coordinate of collectionView cells.
     - parameter threshold: The x coordinate where function gets value 1.
     - parameter xOrigin: x coordinate of the function origin.
     */
//    private func distributor(x: CGFloat, threshold: CGFloat, xOrigin: CGFloat) -> CGFloat {
//        guard threshold > xOrigin else { return 1 }
//        var arg = (x - xOrigin)/(threshold - xOrigin)
//        arg = max(0, arg)
//        let y = sqrt(arg)
//        return min(1, y)
//    }

    private func scaleDistributor(x: CGFloat, height: CGFloat) -> CGFloat {
        let threshold = height * 0.5
        let xOrigin = -height * 4

        guard threshold > xOrigin else { return 1 }
        var arg = (x - xOrigin)/(threshold - xOrigin)
        arg = max(0, arg)
        let y = sqrt(arg)
        return min(1, y)



//        return distributor(x: x, threshold: height * 0.5, xOrigin: -height * 4)
    }

//    private func alphaDistributor(x: CGFloat, itemHeight: CGFloat) -> CGFloat {
//        return distributor(x: x, threshold: itemHeight * 0.5, xOrigin: -itemHeight)
//    }

//    private func getYDelta(y: CGFloat, itemHeight: CGFloat) -> CGFloat {
//        return itemHeight * 0.5 - y
//    }


}


// MARK: - Cell-wise paging
extension HICollectionViewFlowLayout  {

    override func targetContentOffset(forProposedContentOffset proposedContentOffset: CGPoint,
                                           withScrollingVelocity velocity: CGPoint) -> CGPoint {
        let latestOffset = super.targetContentOffset(forProposedContentOffset: proposedContentOffset, withScrollingVelocity: velocity)

        let row = ((proposedContentOffset.y) / (itemSize.height + minimumLineSpacing)).rounded()

        let calculatedOffset = row * itemSize.height + row * minimumLineSpacing
        let targetOffset = CGPoint(x: latestOffset.x, y: calculatedOffset)
        return targetOffset
    }

}


// MARK: - Sticky headers
class HICollectionViewFlowLayout22: UICollectionViewFlowLayout {
    override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        return true
    }

    override func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        guard let layoutAttributes = super.layoutAttributesForElements(in: rect) else { return nil }

        // Helpers
        let sectionsToAdd = NSMutableIndexSet()
        var newLayoutAttributes = [UICollectionViewLayoutAttributes]()

        for layoutAttributesSet in layoutAttributes {
            if layoutAttributesSet.representedElementCategory == .cell {
                // Add Layout Attributes
                newLayoutAttributes.append(layoutAttributesSet)

                // Update Sections to Add
                sectionsToAdd.add(layoutAttributesSet.indexPath.section)

            } else if layoutAttributesSet.representedElementCategory == .supplementaryView {
                // Update Sections to Add
                sectionsToAdd.add(layoutAttributesSet.indexPath.section)
            }
        }

        for section in sectionsToAdd {
            let indexPath = IndexPath(item: 0, section: section)

            if let sectionAttributes = layoutAttributesForSupplementaryView(ofKind: UICollectionElementKindSectionHeader, at: indexPath) {
                newLayoutAttributes.append(sectionAttributes)
            }
        }

        return newLayoutAttributes
    }

    override func layoutAttributesForSupplementaryView(ofKind elementKind: String, at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        guard let layoutAttributes = super.layoutAttributesForSupplementaryView(ofKind: elementKind, at: indexPath) else { return nil }
        guard let boundaries = boundaries(forSection: indexPath.section) else { return layoutAttributes }
        guard let collectionView = collectionView else { return layoutAttributes }

        // Helpers
        let contentOffsetY = collectionView.contentOffset.y
        var frameForSupplementaryView = layoutAttributes.frame

        let minimum = boundaries.minimum - frameForSupplementaryView.height
        let maximum = boundaries.maximum - frameForSupplementaryView.height

        if contentOffsetY < minimum {
            frameForSupplementaryView.origin.y = minimum
        } else if contentOffsetY > maximum {
            frameForSupplementaryView.origin.y = maximum
        } else {
            frameForSupplementaryView.origin.y = contentOffsetY
        }

        layoutAttributes.frame = frameForSupplementaryView

        return layoutAttributes
    }

    func boundaries(forSection section: Int) -> (minimum: CGFloat, maximum: CGFloat)? {
        // Helpers
        var result = (minimum: CGFloat(0.0), maximum: CGFloat(0.0))

        // Exit Early
        guard let collectionView = collectionView else { return result }

        // Fetch Number of Items for Section
        let numberOfItems = collectionView.numberOfItems(inSection: section)

        // Exit Early
        guard numberOfItems > 0 else { return result }

        if let firstItem = layoutAttributesForItem(at: IndexPath(item: 0, section: section)),
            let lastItem = layoutAttributesForItem(at: IndexPath(item: (numberOfItems - 1), section: section)) {
            result.minimum = firstItem.frame.minY
            result.maximum = lastItem.frame.maxY

            // Take Header Size Into Account
            result.minimum -= headerReferenceSize.height
            result.maximum -= headerReferenceSize.height

            // Take Section Inset Into Account
            result.minimum -= sectionInset.top
            result.maximum += (sectionInset.top + sectionInset.bottom)
        }

        return result
    }


}
