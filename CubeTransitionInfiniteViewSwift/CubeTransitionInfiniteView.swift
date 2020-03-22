//
//  CTCubeTransitionInfiniteView.swift
//  CubeTransitionInfiniteViewSwift
//
//  Created by RY on 14/3/20.
//  Copyright © 2020 RongLan. All rights reserved.
//
import Foundation
import UIKit

public enum Direction: Int {
    case undetermined = 0, left, right, bottomUp, topDown
}

public protocol CubeTransitionViewDelegate: NSObject {
    func pageView(atIndex: Int) -> UIView
    func numberofPages() -> Int
    func pageDidChanged(index: Int, direction: Direction)
}

let kCompletionDuration: CFTimeInterval = 0.25

public class CubeTransitionInfiniteView: UIView {
    public weak var delegate: CubeTransitionViewDelegate?
    public var offsetCachedPageNumber: Int = 0
    
    public var pageFlipAnimationDuration: CFTimeInterval = 0
    public var pageResetAnmationDuration: CFTimeInterval = 0
    
    public var gestureSpeedForPageFlipping: CGFloat = 0
    public var gestureDistanceForPageFlipping: CGFloat = 0
    
    private var currentIndex: Int = 0
    private var leftView: UIView
    private var rightView: UIView
    private var width: CGFloat = 0
    private var height: CGFloat = 0
    private var maxRotateAngleForView: CGFloat = 0
    private var translationXWhenGestureEnded: CGFloat = 0
    private var continuousDistance: CGFloat = 0
    private var displayLink: CADisplayLink
    private var timestampWhenGestureEnded: CFTimeInterval = 0
    private var subviewCache: Dictionary = [Int: UIView]()
    private var isAnimationOn: Bool = false
    private var shouldChangePage: Bool = false

    private var preDirection: Direction = .undetermined
    private var direction: Direction = .undetermined
    
    
    public override init(frame: CGRect) {
        width = frame.width
        height = frame.height
        maxRotateAngleForView = CGFloat(Double.pi / 3)
        offsetCachedPageNumber = 1
        leftView = UIView.init()
        rightView = UIView.init()
        displayLink = CADisplayLink.init()
        
        super.init(frame: frame)
        self.initDisplayLink()
        self.initGesture()
        self.initTransform()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func initDisplayLink() {
        pageFlipAnimationDuration = kCompletionDuration;
        pageResetAnmationDuration = kCompletionDuration;
        
        displayLink = CADisplayLink.init(target: self, selector: #selector(updateTransfromAfterGestureEnded))
        displayLink.isPaused = true;
        displayLink.add(to: RunLoop.current, forMode: .default)
        isAnimationOn = false;
    }
    
    private func initTransform () {
        var perspective: CATransform3D = CATransform3DIdentity
        let screenWidth = UIScreen.main.bounds.size.width
        perspective.m34 = -1.0 / (screenWidth * 2.0)
        self.layer.sublayerTransform = perspective
    }
    
    private func initGesture () {
        if gestureDistanceForPageFlipping == 0 {
            gestureDistanceForPageFlipping = width / 2
        }
        gestureSpeedForPageFlipping = width
        
        preDirection = Direction.undetermined

        let gestureRecognizer:UIPanGestureRecognizer = UIPanGestureRecognizer.init(target: self, action: #selector(handlePanGesture))
        self.addGestureRecognizer(gestureRecognizer)
    }
    
    
    @objc func handlePanGesture(_gestureRecognizer: UIPanGestureRecognizer) {
        if (isAnimationOn) {
            return
        }
        
        let translation = _gestureRecognizer.translation(in: self)
        
        self.determineDirection(fromTranslation:translation)
        
        // slide finger on the screen left and right
        if (self.isDirectionChanged()) {
            self.resetAnimatedSubViews()
        }
        
        if self.shouldDetermineAnimatedView(gestureRecognizer: _gestureRecognizer) {
            self.determineAnimatedSubViews()
        }
        preDirection = direction

        if (self.isDirectionChanged()) {
            return
        }
        
        if (!self.isHorizontalPanGesture()) {
            return
        }
        
        
        if (_gestureRecognizer.state == .ended) {
            let velocity = _gestureRecognizer.velocity(in: self)
            self .onGestureEnded(translation: translation, velocity: velocity)
            return
        }
        
                
        self.animtedViewsBy(translation: translation)
    }
    
    func shouldDetermineAnimatedView(gestureRecognizer: UIPanGestureRecognizer) -> Bool {
        // Determine animated view when gesture changed; because when swifting fast and the
        // previous animation going on, the UIGestureRecognizerStateBegan touch event
        // could be dismissed. 500 is a migic number from experiment.
        let velocity = gestureRecognizer.velocity(in: self);
        let isFastMoving = gestureRecognizer.state == .changed && abs(velocity.x) > 500;
        return preDirection != direction || gestureRecognizer.state == .began || isFastMoving;
    }
    
    func determineDirection(fromTranslation: CGPoint)
    {
        if (fromTranslation.x == 0 && fromTranslation.y == 0) {
            direction = Direction.undetermined;
            return;
        }
        
        let tanValue: CGFloat = fromTranslation.x != 0 ? fromTranslation.y / fromTranslation.x : CGFloat.greatestFiniteMagnitude
;
        if (tanValue > -1 && tanValue < 1) {
            direction = fromTranslation.x > 0 ? .left : .right;
        } else {
            direction = fromTranslation.y > 0 ? .topDown : .bottomUp;
        }
    }
    
    func isHorizontalPanGesture() -> Bool {
        return direction == .left || direction == .right;
    }

    func isDirectionChanged() -> Bool {
        return preDirection != .undetermined && preDirection != direction;
    }
    
    func determineAnimatedSubViews() {
        var leftIdx = currentIndex - 1
        var rightIdx = currentIndex + 1
        if (direction == .left) {
            // Scroll to the left side
            rightIdx = currentIndex
            leftView = self.animatedSubview(index:leftIdx)
            rightView = self.animatedSubview(index: rightIdx)
        } else if (direction == .right) {
            // Scroll to the right Side
            leftIdx = currentIndex;
            leftView = self.animatedSubview(index:leftIdx)
            rightView = self.animatedSubview(index: rightIdx)
        }
    }
    
    func animatedSubview(index: Int) -> UIView {
        let view = subviewCache[index]
        
        if let tView = view {
            return tView
        }
            
        return self.subview(forIndex:index)
    }
    
    func maintainCacheSize() {
        let maxIndex = max((delegate?.numberofPages() ?? 1) - 1 - offsetCachedPageNumber, 1);
        if (currentIndex < offsetCachedPageNumber || currentIndex >= maxIndex) {
            return;
        }
        
        self.removeSubviews();
    }
    
    func subview(forIndex:Int) -> UIView {
        let view = delegate?.pageView(atIndex: forIndex)
        if let tView = view {
            let x = CGFloat(forIndex) * width
            tView.frame = CGRect(x: x, y: 0, width: width, height: height)
            self.addSubview(tView)
            subviewCache[forIndex] = tView
            return tView
        }
        
        return UIView.init()
    }
    
    func removeSubviews() {
        var removeIndex: Int = Int.max;
        if (direction == .left) {
            removeIndex = currentIndex + offsetCachedPageNumber + 1
        } else if (direction == .right) {
            removeIndex = currentIndex - offsetCachedPageNumber - 1
        }
        
        let view = subviewCache[removeIndex]
        if let tView = view {
            tView.removeFromSuperview()
            subviewCache.removeValue(forKey: removeIndex)
        }
     }
    
     public func reloadData() {
        _ = self.subview(forIndex: 0)
     }
    
    func determineIndexBy(translation: CGPoint, velocity:CGPoint) {
        shouldChangePage = false;
        if (self.isScrollingToLeftInFirstView(translation: translation)) {
            return;
        }
        
        if (self.isScrollingToRightInLastView(translation: translation)) {
            return;
        }
        
        shouldChangePage = abs(translation.x) > gestureDistanceForPageFlipping || abs(velocity.x)  > gestureSpeedForPageFlipping;
         
        if (shouldChangePage) {
            let idx = translation.x > 0 ? currentIndex - 1 : currentIndex + 1;
            let maxIndex = (delegate?.numberofPages() ?? Int.max)
            currentIndex = min(max(idx, 0), maxIndex - 1);
        }
    }

    func isScrollingToLeftInFirstView(translation: CGPoint) -> Bool {
        return translation.x > 0 && currentIndex == 0;
    }

    func isScrollingToRightInLastView(translation: CGPoint) -> Bool {
        let maxIndex = (delegate?.numberofPages() ?? Int.max)
        return translation.x < 0 && currentIndex == maxIndex - 1;
    }

    func onGestureEnded(translation:CGPoint, velocity:CGPoint) {
        translationXWhenGestureEnded = translation.x;
        
        self.determineIndexBy(translation: translation, velocity: velocity);
        self.setContinousDistanceAfterGestureEnded(tx: translation.x)
        
        // Continue animation
        timestampWhenGestureEnded = CACurrentMediaTime();
        displayLink.isPaused = false;
        isAnimationOn = true;
    }
    
    func setContinousDistanceAfterGestureEnded(tx: CGFloat) {
        if (shouldChangePage) {
            // The left distance to complete the animation
            continuousDistance = tx > 0 ? width - tx : -width - tx;
        } else {
            // Go back the original position
            continuousDistance = -tx;
        }
    }
     
    @objc func updateTransfromAfterGestureEnded() {
        if (self.shouldAnimationEnded()) {
            self.animationEnded();
            return;
        }

        let currentTx = self.transationXFromInterpolation();
        self.animtedViewsBy(translation: CGPoint.init(x: currentTx, y: 0));
    }
    
    func shouldAnimationEnded () -> Bool {
        let duration = shouldChangePage ? pageFlipAnimationDuration : pageResetAnmationDuration;
        return displayLink.timestamp - timestampWhenGestureEnded > duration && isAnimationOn;
    }

    func animationEnded () {
        // Animation stop
        displayLink.isPaused = true;
        self.updateBoundsAndTransform();
        
        if shouldChangePage {
            delegate?.pageDidChanged(index: currentIndex, direction: direction)
        }
        self.maintainCacheSize();
        
        self.resetAnimatedSubViews();
        isAnimationOn = false;
    }
    
    // Linear interpolation
    func transationXFromInterpolation() -> CGFloat {
        if (shouldChangePage) {
            let timeSlot = CGFloat(displayLink.timestamp - timestampWhenGestureEnded)
            return continuousDistance * timeSlot / CGFloat(pageFlipAnimationDuration) + translationXWhenGestureEnded;
        } else {
            let timeSlot = displayLink.timestamp - timestampWhenGestureEnded
            return translationXWhenGestureEnded * CGFloat( 1 - timeSlot/pageResetAnmationDuration);
        }
    }
    
    func updateBoundsAndTransform() {
        // Change the bounds of the CubeTransitionView
        let bounds = self.bounds;
         
        var originX = bounds.minX;
        if (shouldChangePage) {
            if (direction == .left) {
                originX = bounds.origin.x - width;
            } else if (direction == .right){
                originX = bounds.origin.x + width;
            }
        }
        
        self.bounds = CGRect(x: originX, y: bounds.origin.y, width: bounds.size.width, height: bounds.size.height)
    }

    func resetAnimatedSubViews() {
        leftView.layer.transform = CATransform3DIdentity;
        rightView.layer.transform = CATransform3DIdentity;
    }
    
    func animtedViewsBy(translation: CGPoint) {
        let k = translation.x / width;
        if (translation.x > 0) {
            // Scroll to the left side
            // 0 -> -angle
            let r2 =  k *  maxRotateAngleForView;
            // -angle -> 0
            let r =  r2 - maxRotateAngleForView;
            let gap1 =  width / 2.0 * (1-cos(r));
            let gap2 = width / 2.0 * (1-cos(r2));

            leftView.layer.sublayerTransform = self.transformFrom(rotate:r, translateX:translation.x + gap1, translateZ:sin(r) * width/2);
            rightView.layer.sublayerTransform = self.transformFrom(rotate:r2, translateX:translation.x - gap2, translateZ:-sin(r2) * width/2);
        } else if (translation.x < 0) {
            // scroll right: from 0 --> - M_PI/4
            let r =  k * maxRotateAngleForView;
            let gapWidth1 = width / 2.0 * (1-cos(r));

            // sin(r) < 0
            leftView.layer.sublayerTransform = self.transformFrom(rotate:r, translateX:translation.x + gapWidth1, translateZ:sin(r) * width / 2);
               
            // The angle between the two views should be fixed
            // Angle -> 0
            let r2 = (maxRotateAngleForView + r);
            let gapWidth2 = width / 2.0 * (1-cos(r2));
            // sin(r2) > 0
            rightView.layer.sublayerTransform = self.transformFrom(rotate:r2, translateX:translation.x - gapWidth2, translateZ:-sin(r2) * width / 2);
        }
    }

    func transformFrom(rotate:CGFloat, translateX: CGFloat, translateZ: CGFloat) -> CATransform3D
    {
        let tranform = CATransform3DTranslate(CATransform3DIdentity, translateX, 0, translateZ)
        return CATransform3DRotate(tranform, rotate, 0, 1, 0);
    }

    func dealloc () {
        displayLink .remove(from: RunLoop.current, forMode: .default)
        displayLink .invalidate()
    }
}
