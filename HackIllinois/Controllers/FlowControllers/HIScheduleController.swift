//
//  HIScheduleController.swift
//  HackIllinois
//
//  Created by Rauhul Varma on 2/18/18.
//  Copyright © 2018 HackIllinois. All rights reserved.
//

import Foundation
import UIKit

class HIScheduleController: HIBaseViewController {

    var schedulePages = [UIViewController]()
    var currentPage = 0
    var segmentedControl: HISegmentedControl?
    let pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal)

    init() {
        super.init(nibName: nil, bundle: nil)
        schedulePages = [
            HIScheduleViewController(title: "FRIDAY", predicate: NSPredicate(
                format: "%@ =< start AND start < %@",
                HIApplication.Configuration.FRIDAY_START_TIME as NSDate,
                HIApplication.Configuration.FRIDAY_END_TIME as NSDate
            )),
            HIScheduleViewController(title: "SATURDAY", predicate: NSPredicate(
                format: "%@ =< start AND start < %@",
                HIApplication.Configuration.SATURDAY_START_TIME as NSDate,
                HIApplication.Configuration.SATURDAY_END_TIME as NSDate
            )),
            HIScheduleViewController(title: "SUNDAY", predicate: NSPredicate(
                format: "%@ =< start AND start < %@",
                HIApplication.Configuration.SUNDAY_START_TIME as NSDate,
                HIApplication.Configuration.SUNDAY_END_TIME as NSDate
            ))
        ]
        pageViewController.delegate = self
        pageViewController.dataSource = self

        if let firstSchedulePage = schedulePages.first {
            pageViewController.setViewControllers([firstSchedulePage], direction: .forward, animated: true, completion: nil)
        }
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) should not be used.")
    }
}

// MARK: - Actions
extension HIScheduleController {
    @objc func didSelectTab(_ sender: HISegmentedControl) {
        guard currentPage != sender.selectedIndex else { return }
        let direction: UIPageViewControllerNavigationDirection = sender.selectedIndex > currentPage ? .forward : .reverse
        currentPage = sender.selectedIndex
        pageViewController.setViewControllers([schedulePages[currentPage]], direction: direction, animated: true, completion: nil)
    }
}

// MARK: - UIViewController
extension HIScheduleController {
    override func loadView() {
        super.loadView()

        let items = schedulePages.flatMap { $0.title }
        let segmentedControl = HISegmentedControl(items: items)
        segmentedControl.addTarget(self, action: #selector(didSelectTab(_:)), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(segmentedControl)
        segmentedControl.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor).isActive = true
        segmentedControl.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12).isActive = true
        segmentedControl.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12).isActive = true
        segmentedControl.heightAnchor.constraint(equalToConstant: 34).isActive = true
        self.segmentedControl = segmentedControl

        pageViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.topAnchor.constraint(equalTo: segmentedControl.bottomAnchor).isActive = true
        pageViewController.view.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        pageViewController.view.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        pageViewController.view.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        pageViewController.didMove(toParentViewController: self)

//        pageViewController.view.subviews.flatMap { $0 as? UIScrollView }.first?.delegate = self
    }
}

// MARK: - UINavigationItem Setup
extension HIScheduleController {
    override func setupNavigationItem() {
        super.setupNavigationItem()
        title = "SCHEDULE"
    }
}

// MARK: - UIPageViewControllerDelegate
extension HIScheduleController: UIPageViewControllerDelegate {
    // Sent when a gesture-initiated transition begins.
    func pageViewController(_ pageViewController: UIPageViewController, willTransitionTo pendingViewControllers: [UIViewController]) {
        guard let viewController = pendingViewControllers.first,
            let index = schedulePages.index(of: viewController) else { return }
        segmentedControl?.set(selectedIndex: index)
    }

    func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if !completed {
            guard let viewController = previousViewControllers.first,
                let index = schedulePages.index(of: viewController) else { return }
            segmentedControl?.set(selectedIndex: index, shouldSendControlEvents: false)
        }
//        } else {
//            guard let viewController = pageViewController.viewControllers?.first,
//                let index = schedulePages.index(of: viewController) else { return }
//            segmentedControl?.set(selectedIndex: index)
//        }
    }
}

// MARK: - UIPageViewControllerDataSource
extension HIScheduleController: UIPageViewControllerDataSource {
    func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let index = schedulePages.index(of: viewController), index - 1 >= 0  else { return nil }
        return schedulePages[index - 1]
    }

    func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let index = schedulePages.index(of: viewController), index + 1 < schedulePages.count  else { return nil }
        return schedulePages[index + 1]
    }
}

// MARK: - UIScrollViewDelegate
extension HIScheduleController {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {

    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let point = scrollView.contentOffset
        var fractionComplete: CGFloat
        fractionComplete = fabs(point.x - view.frame.size.width)/view.frame.size.width
        segmentedControl?.animator?.pauseAnimation()
        segmentedControl?.animator?.fractionComplete = fractionComplete
        print("fractionComplete: ", fractionComplete)
    }

    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        guard let animator = segmentedControl?.animator, animator.state == .inactive else { return }
        animator.continueAnimation(withTimingParameters: nil, durationFactor: animator.fractionComplete)
    }
}
