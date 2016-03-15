//
//  SwipeTableViewCell.swift
//  swipe
//
//  Created by Ethan Neff on 3/11/16.
//  Copyright © 2016 Ethan Neff. All rights reserved.
//

import UIKit

// delegate for the child
protocol SwipeDelegate: class {
  func swipeTableViewCellDidStartSwiping(cell cell: UITableViewCell)
  
  func swipeTableViewCellDidEndSwiping(cell cell: UITableViewCell)
  
  func swipeTableViewCell(cell cell: UITableViewCell, didSwipeWithPercentage percentage: CGFloat)
}

// make the parent controller conform to the delegate (able to listen)
extension UITableViewController: SwipeDelegate {
  func swipeTableViewCellDidStartSwiping(cell cell: UITableViewCell) {}
  
  func swipeTableViewCellDidEndSwiping(cell cell: UITableViewCell) {}
  
  func swipeTableViewCell(cell cell: UITableViewCell, didSwipeWithPercentage percentage: CGFloat) {}
}

class SwipeCell: UITableViewCell {
  // MARK: - PROPERTIES
  // constants
  let kDurationLowLimit: NSTimeInterval = 0.25;
  let kDurationHighLimit: NSTimeInterval = 0.1;
  let kVelocity: CGFloat = 0.7
  let kDamping: CGFloat = 0.5
  // public properties
  weak var swipeDelegate: SwipeDelegate?
  var shouldDrag = true
  var shouldAnimateIcons = true
  var firstTrigger: CGFloat = 0.15
  var secondTrigger: CGFloat = 0.35
  var thirdTrigger: CGFloat = 0.55
  var forthTrigger: CGFloat = 0.75
  var defaultColor: UIColor = .lightGrayColor()
  // private properties
  private var dragging = false
  private var isExiting = false
  private var contentScreenshotView = UIImageView()
  private var colorIndicatorView = UIView()
  private var iconView = UIView()
  private var direction: SwipeDirection = .Center
  private var swipe: UIPanGestureRecognizer?
  
  private var Left1: SwipeObject?
  private var Left2: SwipeObject?
  private var Left3: SwipeObject?
  private var Left4: SwipeObject?
  private var Right1: SwipeObject?
  private var Right2: SwipeObject?
  private var Right3: SwipeObject?
  private var Right4: SwipeObject?
  
  typealias SwipeCompletion = (cell: UITableViewCell) -> ()
  
  enum SwipeDirection {
    case Center
    case Left
    case Right
  }
  
  enum SwipeGesture {
    case Left1
    case Left2
    case Left3
    case Left4
    case Right1
    case Right2
    case Right3
    case Right4
  }
  
  enum SwipeMode {
    case Bounce
    case Slide
  }
  
  private struct SwipeObject {
    // the swipe gesture object per cell
    var color: UIColor
    var icon: UIView
    var mode: SwipeMode
    var completion: SwipeCompletion
    
    init(color: UIColor, mode: SwipeMode, icon: UIView, completion: SwipeCompletion) {
      self.color = color
      self.mode = mode
      self.icon = icon
      self.completion = completion
    }
  }
  
  //   MARK: - INIT
  override func awakeFromNib() {
    super.awakeFromNib()
  }
  
  override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
    super.init(style: style, reuseIdentifier: reuseIdentifier)
    initializer()
  }
  
  required init?(coder aDecoder: NSCoder) {
    super.init(coder: aDecoder)
    initializer()
  }
  
  override func prepareForReuse() {
    super.prepareForReuse()
    swipeDealloc()
    initializer()
  }
  
  private func initializer() {
    // layout
    selectionStyle = .None
    separatorInset = UIEdgeInsetsZero
    layoutMargins = UIEdgeInsetsZero
    
    // swipe gesture
    swipe = UIPanGestureRecognizer(target: self, action:"handleSwipeGesture:")
    if let swipe = swipe {
      swipe.delegate = self
      addGestureRecognizer(swipe)
    }
  }
  
  // MARK: - PUBLIC ADD SWIPE
  func addSwipeGesture(swipeGesture swipeGesture: SwipeGesture, swipeMode: SwipeMode, icon: UIImageView, color: UIColor, completion: SwipeCompletion) {
    // public function to add a new gesture on the cell
    switch swipeGesture {
    case .Left1: Left1 = SwipeObject(color: color, mode: swipeMode, icon: icon, completion: completion)
    case .Left2: Left2 = SwipeObject(color: color, mode: swipeMode, icon: icon, completion: completion)
    case .Left3: Left3 = SwipeObject(color: color, mode: swipeMode, icon: icon, completion: completion)
    case .Left4: Left4 = SwipeObject(color: color, mode: swipeMode, icon: icon, completion: completion)
    case .Right1: Right1 = SwipeObject(color: color, mode: swipeMode, icon: icon, completion: completion)
    case .Right2: Right2 = SwipeObject(color: color, mode: swipeMode, icon: icon, completion: completion)
    case .Right3: Right3 = SwipeObject(color: color, mode: swipeMode, icon: icon, completion: completion)
    case .Right4: Right4 = SwipeObject(color: color, mode: swipeMode, icon: icon, completion: completion)
    }
  }
  
  // MARK: - GESTURE RECOGNIZER
  func handleSwipeGesture(gesture: UIPanGestureRecognizer) {
    if !shouldDrag || isExiting {
      return
    }
    
    let state = gesture.state
    let translation = gesture.translationInView(self)
    let velocity = gesture.velocityInView(self)
    let percentage = swipeGetPercentage(offset: CGRectGetMinX(contentScreenshotView.frame), width: CGRectGetWidth(self.bounds))
    let duration = swipeGetAnimationDuration(velocity: velocity)
    let direction = swipeGetDirection(percentage: percentage)
    
    if state == .Began {
      // began
      dragging = true
      swipeDelegate?.swipeTableViewCellDidStartSwiping(cell: self)
      swipeCreateView(state: state)
    }
    if state == .Began || state == .Changed {
      // changed (moving)
      swipeDelegate?.swipeTableViewCell(cell: self, didSwipeWithPercentage: percentage)
      let center: CGPoint = CGPoint(x: contentScreenshotView.center.x + translation.x, y: contentScreenshotView.center.y)
      contentScreenshotView.center = center
      swipeAnimateHold(offset: CGRectGetMinX(contentScreenshotView.frame), direction: direction)
      gesture.setTranslation(CGPointZero, inView: self)
    } else if state == .Cancelled || state == .Ended {
      // ended or cancelled
      dragging = false
      isExiting = true
      swipeDelegate?.swipeTableViewCellDidEndSwiping(cell: self)
      let object = swipeGetObject(percentage: percentage)
      if let object = object {
        let icon = object.icon
        let completion = object.completion
        let mode = object.mode
        
        if swipeGetBeforeTrigger(percentage: percentage, direction: direction) ||  mode == .Bounce {
          // bounce
          swipeDirectionBounce(duration: duration, direction: direction, icon: icon, completion: completion, percentage: percentage)
        } else {
          // slide
          swipeDirectionSlide(duration: duration, direction: direction, icon: icon, completion: completion)
        }
      } else {
        // bounce
        swipeDirectionBounce(duration: duration, direction: direction, icon: nil, completion: nil, percentage: percentage)
      }
    }
  }
  
  override func gestureRecognizerShouldBegin(gestureRecognizer: UIGestureRecognizer) -> Bool {
    // needed to allow scrolling of the tableview
    if let g = gestureRecognizer as? UIPanGestureRecognizer {
      let point: CGPoint = g.velocityInView(self)
      // if moving x instead of y
      if fabs(point.x) > fabs(point.y) {
        // prevent swipe if there is no gesture in that direction
        if !swipeGetGestureDirection(direction: .Left) && point.x < 0 {
          return false
        }
        if !swipeGetGestureDirection(direction: .Right) && point.x > 0 {
          return false
        }
        return true
      }
    }
    return false
  }
  
  // MARK: - BEGIN
  private func swipeCreateView(state state: UIGestureRecognizerState) {
    // get the image of the cell
    let contentViewScreenshotImage: UIImage = swipeScreenShot(self)
    
    colorIndicatorView = UIView(frame: bounds)
    colorIndicatorView.autoresizingMask = ([.FlexibleHeight, .FlexibleWidth])
    colorIndicatorView.backgroundColor = defaultColor
    addSubview(colorIndicatorView)
    
    iconView = UIView()
    iconView.contentMode = .Center
    colorIndicatorView.addSubview(iconView)
    
    contentScreenshotView = UIImageView(image: contentViewScreenshotImage)
    addSubview(contentScreenshotView)
  }
  
  private func swipeScreenShot(view: UIView) -> UIImage {
    // create a snapshot (copy) of the cell
    let scale: CGFloat = UIScreen.mainScreen().scale
    UIGraphicsBeginImageContextWithOptions(view.bounds.size, false, scale)
    view.layer.renderInContext(UIGraphicsGetCurrentContext()!)
    let image: UIImage = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    
    return image
  }
  
  // MARK: - CHANGED
  private func swipeAnimateHold(offset offset: CGFloat, direction: SwipeDirection) {
    // move the cell when swipping
    let percentage = swipeGetPercentage(offset: offset, width: CGRectGetWidth(bounds))
    let object = swipeGetObject(percentage: percentage)
    if let object = object {
      // change to the correct icons and colors
      colorIndicatorView.backgroundColor = swipeGetBeforeTrigger(percentage: percentage, direction: direction) ? defaultColor : object.color
      swipeResetIcon(icon: object.icon)
      swipeUpdateIcon(percentage: percentage, direction: direction, icon: object.icon, isDragging: shouldAnimateIcons)
    } else {
      colorIndicatorView.backgroundColor = defaultColor
    }
  }
  
  private func swipeResetIcon(icon icon: UIView) {
    // remove the old icons when changing between sections
    let subviews = iconView.subviews
    for view in subviews {
      view.removeFromSuperview()
    }
    // add the new icon
    iconView.addSubview(icon)
  }
  
  private func swipeUpdateIcon(percentage percentage: CGFloat, direction: SwipeDirection, icon: UIView, isDragging: Bool) {
    // position the icon when swiping
    var position: CGPoint = CGPointZero
    position.y = CGRectGetHeight(self.bounds) / 2.0
    if isDragging {
      // near the cell
      if percentage >= 0 && percentage < firstTrigger {
        position.x = swipeGetOffset(percentage: (firstTrigger / 2), width: CGRectGetWidth(bounds))
      } else if percentage >= firstTrigger {
        position.x = swipeGetOffset(percentage: percentage - (firstTrigger / 2), width: CGRectGetWidth(bounds))
      } else if percentage < 0 && percentage >= -firstTrigger {
        position.x = CGRectGetWidth(bounds) - swipeGetOffset(percentage: (firstTrigger / 2), width: CGRectGetWidth(bounds))
      } else if percentage < -firstTrigger {
        position.x = CGRectGetWidth(bounds) + swipeGetOffset(percentage: percentage + (firstTrigger / 2), width: CGRectGetWidth(bounds))
      }
    } else {
      // float either left or right
      if direction == .Right {
        position.x = swipeGetOffset(percentage: (firstTrigger / 2), width: CGRectGetWidth(self.bounds))
      } else if direction == .Left {
        position.x = CGRectGetWidth(bounds) - swipeGetOffset(percentage: (firstTrigger / 2), width: CGRectGetWidth(bounds))
      } else {
        return
      }
    }
    let activeViewSize: CGSize = icon.bounds.size
    var activeViewFrame: CGRect = CGRectMake(position.x - activeViewSize.width / 2.0, position.y - activeViewSize.height / 2.0, activeViewSize.width, activeViewSize.height)
    activeViewFrame = CGRectIntegral(activeViewFrame)
    iconView.frame = activeViewFrame
    iconView.alpha = swipeGetAlpha(percentage: percentage)
  }
  
  // MARK: - END
  private func swipeDirectionBounce(duration duration: NSTimeInterval, direction: SwipeDirection, var icon: UIView?, completion: SwipeCompletion?, percentage: CGFloat) {
    if let _ = icon {} else {
      icon = UIView()
    }
    
    UIView.animateWithDuration(duration, delay: 0.0, usingSpringWithDamping: kDamping, initialSpringVelocity: kVelocity, options: .CurveEaseInOut, animations: { () -> Void in
      var frame: CGRect = self.contentScreenshotView.frame
      frame.origin.x = 0
      self.contentScreenshotView.frame = frame
      // Clearing the indicator view
      self.colorIndicatorView.backgroundColor = self.defaultColor
      self.iconView.alpha = 0
      self.swipeUpdateIcon(percentage: 0, direction: direction, icon: icon!, isDragging: self.shouldAnimateIcons)
      }) { (finished) -> Void in
        if let completion = completion where !self.swipeGetBeforeTrigger(percentage: percentage, direction: direction) {
          completion(cell: self)
          self.swipeDealloc()
        } else {
          self.isExiting = false
        }
    }
  }
  
  private func swipeDirectionSlide(duration duration: NSTimeInterval, direction: SwipeDirection, icon: UIView, completion: SwipeCompletion) {
    var origin: CGFloat
    if direction == .Left {
      origin = -CGRectGetWidth(self.bounds)
    } else if direction == .Right {
      origin = CGRectGetWidth(self.bounds)
    } else {
      origin = 0
    }
    
    let percentage: CGFloat = swipeGetPercentage(offset: origin, width: CGRectGetWidth(bounds))
    var frame: CGRect = contentScreenshotView.frame
    frame.origin.x = origin
    
    UIView.animateWithDuration(duration, delay: 0, options: ([.CurveEaseOut, .AllowUserInteraction]), animations: {() -> Void in
      self.contentScreenshotView.frame = frame
      self.iconView.alpha = 0
      self.swipeUpdateIcon(percentage: percentage, direction: direction, icon: icon, isDragging: self.shouldAnimateIcons)
      }, completion: {(finished: Bool) -> Void in
        completion(cell: self)
        self.swipeDealloc()
    })
  }
  
  private func swipeDealloc() {
    print("dealloc")
    // delay for animated delete of cell
    self.swipeDelegate = nil
    self.swipe = nil
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, Int64(0.3 * Double(NSEC_PER_SEC))), dispatch_get_main_queue()) {
      self.isExiting = false
      self.iconView.removeFromSuperview()
      self.colorIndicatorView.removeFromSuperview()
      self.contentScreenshotView.removeFromSuperview()
    }
  }
  
  
  // MARK: - GET
  private func swipeGetObject(percentage percentage: CGFloat) -> SwipeObject? {
    // determine if swipe object exits
    var object: SwipeObject?
    if let left1 = Left1 where percentage >= 0 {
      object = left1
    }
    if let left2 = Left2 where percentage >= secondTrigger {
      object = left2
    }
    if let left3 = Left3 where percentage >= thirdTrigger {
      object = left3
    }
    if let left4 = Left4 where percentage >= forthTrigger {
      object = left4
    }
    
    if let right1 = Right1 where percentage <= 0 {
      object = right1
    }
    if let right2 = Right2 where percentage <= -secondTrigger {
      object = right2
    }
    if let right3 = Right3 where percentage <= -thirdTrigger {
      object = right3
    }
    if let right4 = Right4 where percentage <= -forthTrigger {
      object = right4
    }
    
    return object
  }
  
  private func swipeGetBeforeTrigger(percentage percentage: CGFloat, direction: SwipeDirection) -> Bool {
    // if before the first trigger, do not run completion and bounce back
    if (direction == .Left && percentage > -firstTrigger) || (direction == .Right && percentage < firstTrigger) {
      return true
    }
    
    return false
  }
  
  
  private func swipeGetPercentage(offset offset: CGFloat, width: CGFloat) -> CGFloat {
    // get the percentage of the user drag
    var percentage = offset / width
    if percentage < -1.0 {
      percentage = -1.0
    } else if percentage > 1.0 {
      percentage = 1.0
    }
    
    return percentage
  }
  
  private func swipeGetOffset(percentage percentage: CGFloat, width: CGFloat) -> CGFloat {
    // get the offset of the user drag
    var offset: CGFloat = percentage * width
    if offset < -width {
      offset = -width
    } else if offset > width {
      offset = width
    }
    
    return offset
  }
  
  private func swipeGetAnimationDuration(velocity velocity: CGPoint) -> NSTimeInterval {
    // get the duration for the completing swipe
    let width: CGFloat = CGRectGetWidth(self.bounds)
    let animationDurationDiff: NSTimeInterval = kDurationHighLimit - kDurationLowLimit
    var horizontalVelocity: CGFloat = velocity.x
    
    if horizontalVelocity < -width {
      horizontalVelocity = -width
    } else if horizontalVelocity > width {
      horizontalVelocity = width
    }
    
    let diff = abs(((horizontalVelocity / width) * CGFloat(animationDurationDiff)))
    
    return (kDurationHighLimit + kDurationLowLimit) - NSTimeInterval(diff)
  }
  
  func swipeGetAlpha(percentage percentage: CGFloat) -> CGFloat {
    // set the alpha of the icon before the first trigger
    var alpha: CGFloat
    if percentage >= 0 && percentage < firstTrigger {
      alpha = percentage / firstTrigger
    } else if percentage < 0 && percentage > -firstTrigger {
      alpha = fabs(percentage / firstTrigger)
    } else {
      alpha = 1.0
    }
    
    return alpha
  }
  
  private func swipeGetDirection(percentage percentage: CGFloat) -> SwipeDirection {
    // get the direction either left or right
    if percentage < 0 {
      return .Left
    } else if percentage > 0 {
      return .Right
    } else {
      return .Center
    }
  }
  
  private func swipeGetGestureDirection(direction direction:SwipeDirection) -> Bool {
    // used to prevent swiping if there is not gesture in a direction
    switch direction {
    case .Left:
      if let _ = Left1 {
        return true
      }
      if let _ = Left2 {
        return true
      }
      if let _ = Left3 {
        return true
      }
      if let _ = Left4 {
        return true
      }
      break
    case .Right:
      if let _ = Right1 {
        return true
      }
      if let _ = Right2 {
        return true
      }
      if let _ = Right3 {
        return true
      }
      if let _ = Right4 {
        return true
      }
      break
    case .Center: return false
    }
    
    return false
  }
}