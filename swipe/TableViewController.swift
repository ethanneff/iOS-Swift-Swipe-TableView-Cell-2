//
//  TableViewController.swift
//  swipe
//
//  Created by Ethan Neff on 3/11/16.
//  Copyright © 2016 Ethan Neff. All rights reserved.
//

import UIKit

class TableViewController: UITableViewController {
  
  var items = ["one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "eleven", "twelve", "thirteen", "fourteen", "fifteen", "sixteen", "seventeen", "eighteen", "nineteen", "twenty"]
  
  override func viewDidLoad() {
    super.viewDidLoad()

    // custom cell
    let nib = UINib(nibName: "SwipeCell", bundle: nil)
    tableView.registerNib(nib, forCellReuseIdentifier: "cell")
  }
  
  override func numberOfSectionsInTableView(tableView: UITableView) -> Int {
    return 1
  }
  
  override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return items.count
  }
  
  // MARK: - SWIPE
  override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCellWithIdentifier("cell", forIndexPath: indexPath) as! SwipeCell
    cell.swipeDelegate = self
    cell.textLabel?.text = items[indexPath.row]

    // change the trigger locations between swipe gestures
//    cell.firstTrigger = 0.25
//    cell.secondTrigger = 0.50
//    cell.thirdTrigger = 0.75
  
    cell.addSwipeGesture(swipeGesture: SwipeCell.SwipeGesture.Right1, swipeMode: SwipeCell.SwipeMode.Slide, icon: UIImageView(image: UIImage(named: "cross")), color: .blueColor()) { (cell) -> () in
      print(1)
      self.deleteCell(cell: cell)
    }
    cell.addSwipeGesture(swipeGesture: SwipeCell.SwipeGesture.Right2, swipeMode: SwipeCell.SwipeMode.Bounce, icon: UIImageView(image: UIImage(named: "list")), color: .redColor()) { (cell) -> () in
      print(2)
      self.deleteCell(cell: cell)
    }
    cell.addSwipeGesture(swipeGesture: SwipeCell.SwipeGesture.Right3, swipeMode: SwipeCell.SwipeMode.Slide, icon: UIImageView(image: UIImage(named: "clock")), color: .orangeColor()) { (cell) -> () in
      print(3)
      self.deleteCell(cell: cell)
    }
    cell.addSwipeGesture(swipeGesture: SwipeCell.SwipeGesture.Right4, swipeMode: SwipeCell.SwipeMode.Slide, icon: UIImageView(image: UIImage(named: "check")), color: .greenColor()) { (cell) -> () in
      print(4)
      self.deleteCell(cell: cell)
    }
    cell.addSwipeGesture(swipeGesture: SwipeCell.SwipeGesture.Left1, swipeMode: SwipeCell.SwipeMode.Slide, icon: UIImageView(image: UIImage(named: "check")), color: .purpleColor()) { (cell) -> () in
      print(-1)
      self.deleteCell(cell: cell)
    }

    return cell
  }
  
  
  // MARK: - SWIPE OPTIONAL DELEGATE METHODS
  override func swipeTableViewCellDidStartSwiping(cell cell: UITableViewCell) {}
  
  override func swipeTableViewCellDidEndSwiping(cell cell: UITableViewCell) {}
  
  override func swipeTableViewCell(cell cell: UITableViewCell, didSwipeWithPercentage percentage: CGFloat) {}
  
  // MARK: - HELPER METHODS
  func deleteCell(cell cell: UITableViewCell) {
    print("delete cell)")
    tableView.beginUpdates()
    items.removeAtIndex(items.indexOf((cell.textLabel?.text)!)!)
    tableView.indexPathForCell(cell)
    tableView.deleteRowsAtIndexPaths([self.tableView.indexPathForCell(cell)!], withRowAnimation: .Fade)
    tableView.endUpdates()
    print(items)
  }
  
}