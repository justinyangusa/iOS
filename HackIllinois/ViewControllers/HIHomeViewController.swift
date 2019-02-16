//
//  HIHomeViewController.swift
//  HackIllinois
//
//  Created by HackIllinois Team on 1/12/18.
//  Copyright © 2018 HackIllinois. All rights reserved.
//  This file is part of the Hackillinois iOS App.
//  The Hackillinois iOS App is open source software, released under the University of
//  Illinois/NCSA Open Source License. You should have received a copy of
//  this license in a file with the distribution.
//

import Foundation
import UIKit
import CoreData

class HIHomeViewController: HIEventListViewController {
    // MARK: - Properties
    lazy var fetchedResultsController: NSFetchedResultsController<Event> = {
        let fetchRequest: NSFetchRequest<Event> = Event.fetchRequest()

        fetchRequest.sortDescriptors = [
            NSSortDescriptor(key: "startTime", ascending: true),
            NSSortDescriptor(key: "name", ascending: true)
        ]

        fetchRequest.predicate = currentPredicate()

        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: HICoreDataController.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController.delegate = self

        return fetchedResultsController
    }()

    // MARK: Tabs
    private var currentTab = 0
    private var dataStore: [(displayText: String, predicate: NSPredicate)] = {
        var dataStore = [(displayText: String, predicate: NSPredicate)]()
        let happeningNowPredicate = NSPredicate(format: "(startTime < now()) AND (endTime > now())")
        dataStore.append((displayText: "HAPPENING NOW ", predicate: happeningNowPredicate))

        let inFifteenMinutes = Date(timeIntervalSinceNow: 900)
        let upcomingPredicate = NSPredicate(format: "(startTime < %@) AND (startTime > now())", inFifteenMinutes as NSDate)
        dataStore.append((displayText: "UPCOMING", predicate: upcomingPredicate))

        return dataStore
    }()

    // MARK: Refresh
    private var timer: Timer?

    // MARK: Countdown
    private var countdownDataStoreIndex = 0
    private var staticDataStore: [(date: Date, displayText: String)] = [
        (HIConstants.EVENT_START_TIME, "HACKILLINOIS BEGINS IN"),
        (HIConstants.HACKING_START_TIME, "HACKING BEGINS IN"),
        (HIConstants.HACKING_END_TIME, "HACKING ENDS IN"),
        (HIConstants.EVENT_END_TIME, "HACKILLINOIS ENDS IN")
    ]

    // MARK: Views
    private let countdownContainerView = HIView {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundHIColor = \.baseBackground
    }
    private let countdownInnerContainerView = HIView {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundHIColor = \.baseBackground
    }
    private let countdownTitleLabel = HILabel(style: .title) {
        $0.textAlignment = .center
        $0.numberOfLines = 0
        $0.setContentCompressionResistancePriority(.required, for: .vertical)
    }
    private lazy var countdownViewController = HICountdownViewController(delegate: self)
    private let eventsContainerView = HIView {
        $0.translatesAutoresizingMaskIntoConstraints = false
        $0.backgroundHIColor = \.baseBackground
    }
    private lazy var eventPredicateSegmentedControl = HISegmentedControl(items: dataStore.map { $0.displayText })

    // MARK: Constraints
    private var countdownContainerVerticalLayoutTrailingConstraint: NSLayoutConstraint?
    private var countdownContainerVerticalLayoutBottomConstraint: NSLayoutConstraint?
    private var eventsContainerVerticalLayoutTopConstraint: NSLayoutConstraint?
    private var eventsContainerVerticalLayoutLeadingConstraint: NSLayoutConstraint?
    private var verticalLayoutHeightConstraint: NSLayoutConstraint?

    private var countdownContainerHorizontalLayoutTrailingConstraint: NSLayoutConstraint?
    private var countdownContainerHorizontalLayoutBottomConstraint: NSLayoutConstraint?
    private var eventsContainerHorizontalLayoutTopConstraint: NSLayoutConstraint?
    private var eventsContainerHorizontalLayoutLeadingConstraint: NSLayoutConstraint?
    private var horizontalLayoutWidthConstraint: NSLayoutConstraint?
    private var horizontalLayoutCenterConstraint: NSLayoutConstraint?

}

// MARK: - Actions
extension HIHomeViewController {
    @objc func didSelectTab(_ sender: HISegmentedControl) {
        currentTab = sender.selectedIndex
        updatePredicate()
        animateReload()
    }

    func updatePredicate() {
        fetchedResultsController.fetchRequest.predicate = currentPredicate()
    }

    func currentPredicate() -> NSPredicate {
        return dataStore[currentTab].predicate
    }

    func animateReload() {
        try? fetchedResultsController.performFetch()
        animateTableViewReload()
    }
}

// MARK: - UIViewController
extension HIHomeViewController {
    override func loadView() {
        super.loadView()

        view.addSubview(countdownContainerView)
        view.addSubview(eventsContainerView)
        countdownContainerView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        countdownContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true

        countdownContainerVerticalLayoutTrailingConstraint =
            countdownContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        countdownContainerVerticalLayoutBottomConstraint =
            countdownContainerView.bottomAnchor.constraint(equalTo: eventsContainerView.topAnchor)
        countdownContainerHorizontalLayoutTrailingConstraint =
            countdownContainerView.trailingAnchor.constraint(equalTo: eventsContainerView.leadingAnchor)
        countdownContainerHorizontalLayoutBottomConstraint =
            countdownContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        eventsContainerView.trailingAnchor.constraint(equalTo: view.trailingAnchor).isActive = true
        eventsContainerView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true

        eventsContainerVerticalLayoutTopConstraint =
            eventsContainerView.topAnchor.constraint(equalTo: countdownContainerView.bottomAnchor)
        eventsContainerVerticalLayoutLeadingConstraint =
            eventsContainerView.leadingAnchor.constraint(equalTo: view.leadingAnchor)
        eventsContainerHorizontalLayoutTopConstraint =
            eventsContainerView.topAnchor.constraint(equalTo: view.topAnchor)
        eventsContainerHorizontalLayoutLeadingConstraint =
            eventsContainerView.leadingAnchor.constraint(equalTo: countdownContainerView.trailingAnchor)

        horizontalLayoutWidthConstraint =
            countdownContainerView.widthAnchor.constraint(equalTo: eventsContainerView.widthAnchor)

        // CountdownContainerView
        countdownContainerView.addSubview(countdownInnerContainerView)
        countdownInnerContainerView.constrain(to: countdownContainerView, trailingInset: 0, leadingInset: 0)
        horizontalLayoutCenterConstraint =
            countdownInnerContainerView.centerYAnchor.constraint(equalTo: countdownContainerView.centerYAnchor, constant: -40)
        verticalLayoutHeightConstraint =
            countdownInnerContainerView.heightAnchor.constraint(equalTo: countdownContainerView.heightAnchor)

        countdownInnerContainerView.addSubview(countdownTitleLabel)
        countdownTitleLabel.constrain(to: countdownInnerContainerView.safeAreaLayoutGuide, topInset: 20, trailingInset: 0, leadingInset: 0)

        countdownViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(countdownViewController)
        countdownInnerContainerView.addSubview(countdownViewController.view)
        countdownViewController.view.topAnchor.constraint(equalTo: countdownTitleLabel.bottomAnchor, constant: 8).isActive = true
        countdownViewController.view.bottomAnchor.constraint(equalTo: countdownInnerContainerView.safeAreaLayoutGuide.bottomAnchor).isActive = true
        countdownViewController.view.constrain(to: countdownInnerContainerView.safeAreaLayoutGuide, trailingInset: -20, leadingInset: 20)
        countdownViewController.view.heightAnchor.constraint(equalToConstant: 150).isActive = true
        countdownViewController.didMove(toParent: self)

        // EventsContainerView
        eventPredicateSegmentedControl.addTarget(self, action: #selector(didSelectTab(_:)), for: .valueChanged)
        eventsContainerView.addSubview(eventPredicateSegmentedControl)
        eventPredicateSegmentedControl.constrain(to: eventsContainerView.safeAreaLayoutGuide, topInset: 0, trailingInset: -12, leadingInset: 12)
        eventPredicateSegmentedControl.heightAnchor.constraint(equalToConstant: 50).isActive = true

        let tableView = HITableView()
        eventsContainerView.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: eventPredicateSegmentedControl.bottomAnchor).isActive = true
        tableView.constrain(to: eventsContainerView.safeAreaLayoutGuide, trailingInset: 0, leadingInset: 0)
        tableView.constrain(to: eventsContainerView, bottomInset: 0)
        self.tableView = tableView
    }

    override func viewDidLoad() {
        _fetchedResultsController = fetchedResultsController as? NSFetchedResultsController<NSManagedObject>
        super.viewDidLoad()
        setupRefreshControl()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPredicateRefreshTimer()
        activateContraints(for: view.frame.size)
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        teardownPredicateRefreshTimer()
    }

    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        view.layoutIfNeeded()
        activateContraints(for: size)
        coordinator.animate(alongsideTransition: { [weak self] (_) in
            self?.view.layoutIfNeeded()
        }, completion: nil)
    }

    func activateContraints(for size: CGSize) {
        if size.height > size.width {
            countdownContainerVerticalLayoutTrailingConstraint?.isActive = true
            countdownContainerVerticalLayoutBottomConstraint?.isActive = true
            eventsContainerVerticalLayoutTopConstraint?.isActive = true
            eventsContainerVerticalLayoutLeadingConstraint?.isActive = true
            verticalLayoutHeightConstraint?.isActive = true

            eventsContainerHorizontalLayoutTopConstraint?.isActive = false
            eventsContainerHorizontalLayoutLeadingConstraint?.isActive = false
            countdownContainerHorizontalLayoutTrailingConstraint?.isActive = false
            countdownContainerHorizontalLayoutBottomConstraint?.isActive = false
            horizontalLayoutWidthConstraint?.isActive = false
            horizontalLayoutCenterConstraint?.isActive = false
        } else {
            countdownContainerVerticalLayoutTrailingConstraint?.isActive = false
            countdownContainerVerticalLayoutBottomConstraint?.isActive = false
            eventsContainerVerticalLayoutTopConstraint?.isActive = false
            eventsContainerVerticalLayoutLeadingConstraint?.isActive = false
            verticalLayoutHeightConstraint?.isActive = false

            eventsContainerHorizontalLayoutTopConstraint?.isActive = true
            eventsContainerHorizontalLayoutLeadingConstraint?.isActive = true
            countdownContainerHorizontalLayoutTrailingConstraint?.isActive = true
            countdownContainerHorizontalLayoutBottomConstraint?.isActive = true
            horizontalLayoutWidthConstraint?.isActive = true
            horizontalLayoutCenterConstraint?.isActive = true
        }
    }
}

// MARK: - UINavigationItem Setup
extension HIHomeViewController {
    @objc dynamic override func setupNavigationItem() {
        super.setupNavigationItem()
        title = "HOME"
    }
}

extension HIHomeViewController: HICountdownViewControllerDelegate {
    func countdownToDateFor(countdownViewController: HICountdownViewController) -> Date? {
        let now = Date()
        while countdownDataStoreIndex < staticDataStore.count {
            let currDate = staticDataStore[countdownDataStoreIndex].date
            if currDate > now {
                countdownTitleLabel.text = staticDataStore[countdownDataStoreIndex].displayText
                return currDate
            }
            countdownDataStoreIndex += 1
        }
        return nil
    }
}

extension HIHomeViewController {
    func setupPredicateRefreshTimer() {
        timer = Timer.scheduledTimer(
            timeInterval: 30,
            target: self,
            selector: #selector(refreshPredicate),
            userInfo: nil,
            repeats: true
        )
    }

    @objc func refreshPredicate() {
        try? fetchedResultsController.performFetch()
        animateTableViewReload()
    }

    func teardownPredicateRefreshTimer() {
        timer?.invalidate()
        timer = nil
    }
}
