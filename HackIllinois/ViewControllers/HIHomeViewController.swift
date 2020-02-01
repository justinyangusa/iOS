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
            sectionNameKeyPath: "upcomingIdentifier",
            cacheName: nil
        )

        fetchedResultsController.delegate = self

        return fetchedResultsController
    }()

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

    private let countdownTitleLabel = HILabel(style: .title)
    private lazy var countdownViewController = HICountdownViewController(delegate: self)
    private let happeningNowLabel = HILabel(style: .title) {
        $0.text = "HAPPENING NOW"
    }

    private var countdownDataStoreIndex = 0
    private var staticDataStore: [(date: Date, displayText: String)] = [
        (HITimeDataSource.shared.eventTimes.eventStart, "HACKILLINOIS BEGINS IN"),
        (HITimeDataSource.shared.eventTimes.hackStart, "HACKING BEGINS IN"),
        (HITimeDataSource.shared.eventTimes.hackEnd, "HACKING ENDS IN"),
        (HITimeDataSource.shared.eventTimes.eventEnd, "HACKILLINOIS ENDS IN")
    ]

    private var timer: Timer?
    private var eventTableView = HITableView()
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
        let inFifteenMinutes = Date(timeIntervalSinceNow: 900)
        return NSPredicate(format: "(%@ > startTime) AND (now() < endTime)", inFifteenMinutes as NSDate)
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

        view.addSubview(countdownTitleLabel)
        countdownTitleLabel.constrain(to: view.safeAreaLayoutGuide, topInset: 20, trailingInset: 0, leadingInset: 0)

        countdownViewController.view.translatesAutoresizingMaskIntoConstraints = false
        addChild(countdownViewController)
        view.addSubview(countdownViewController.view)
        countdownViewController.view.topAnchor.constraint(equalTo: countdownTitleLabel.bottomAnchor, constant: 8).isActive = true
        countdownViewController.view.constrain(to: view.safeAreaLayoutGuide, trailingInset: -20, leadingInset: 20)
        countdownViewController.view.constrain(height: 150)
        countdownViewController.didMove(toParent: self)

        view.addSubview(eventTableView)
        eventTableView.topAnchor.constraint(equalTo: countdownViewController.view.bottomAnchor).isActive = true
        eventTableView.constrain(to: view.safeAreaLayoutGuide, trailingInset: 0, leadingInset: 0)
        eventTableView.constrain(to: view, bottomInset: 0)
        eventTableView.contentInset = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
        eventTableView.scrollIndicatorInsets = UIEdgeInsets(top: 30, left: 0, bottom: 0, right: 0)
    }

    override func viewDidLoad() {
        _fetchedResultsController = fetchedResultsController as? NSFetchedResultsController<NSManagedObject>
        super.viewDidLoad()
        setupRefreshControl()
        setupEventTableView()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        setupPredicateRefreshTimer()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        teardownPredicateRefreshTimer()
    }
}

// MARK: - UITableViewSetup Setup
extension HIHomeViewController {
    func setupEventTableView() {
        eventTableView.delegate = self
        eventTableView.dataSource = self
        eventTableView.register(HIHomeHeader.self, forHeaderFooterViewReuseIdentifier: HIHomeHeader.identifier)
        eventTableView.register(HIEventCell.self, forCellReuseIdentifier: HIEventCell.identifier)
    }

}

// MARK: - UINavigationItem Setup
extension HIHomeViewController {
    @objc dynamic override func setupNavigationItem() {
        super.setupNavigationItem()
        title = "HOME"
    }
}

// MARK: - UITableViewDataSource
extension HIHomeViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        let numSec = super.numberOfSections(in: tableView)
        print("SECTIONS::\(numSec)")
        return numSec
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: HIEventCell.identifier, for: indexPath)
        if let cell = cell as? HIEventCell, let event = _fetchedResultsController?.object(at: indexPath) as? Event {
            cell <- event
            cell.delegate = self
            cell.indexPath = indexPath
        }
        return cell
    }

     func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: HIHomeHeader.identifier)
        if section == 0 {
            if let header = header as? HIHomeHeader {
                header.titleLabel.textHIColor = \.accent
                header.titleLabel.text = "ONGOING"
                header.titleLabel.textAlignment = .center
                header.titleLabel.font = HIAppearance.Font.homeHeader
            }
        } else if section == 1 {
            if let header = header as? HIHomeHeader {
                header.titleLabel.textHIColor = \.baseText
                header.titleLabel.text = "UPCOMING"
                header.titleLabel.textAlignment = .center
                header.titleLabel.font = HIAppearance.Font.homeHeader
            }
        }
        return header
    }
}

// MARK: - UITabBarItem Setup
extension HIHomeViewController {
    override func setupTabBarItem() {
        tabBarItem = UITabBarItem(title: "Home", image: #imageLiteral(resourceName: "home"), tag: 0)
    }
}

// MARK: - Actions
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
        updatePredicate()
        try? fetchedResultsController.performFetch()
        animateTableViewReload()
    }

    func teardownPredicateRefreshTimer() {
        timer?.invalidate()
        timer = nil
    }
}
