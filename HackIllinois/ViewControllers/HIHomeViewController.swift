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

        fetchRequest.predicate = NSPredicate(format: "startTime < now() AND endTime > now()")

        let fetchedResultsController = NSFetchedResultsController(
            fetchRequest: fetchRequest,
            managedObjectContext: HICoreDataController.shared.viewContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        fetchedResultsController.delegate = self

        return fetchedResultsController
    }()

    private let countdownTitleLabel = HILabel(style: .title)
    private lazy var countdownViewController = HICountdownViewController(delegate: self)
    private let happeningNowLabel = HILabel(style: .title) {
        $0.text = "HAPPENING NOW"
    }

    private var countdownDataStoreIndex = 0
    private var staticDataStore: [(date: Date, displayText: String)] = [
        (HIConstants.EVENT_START_TIME, "HACKILLINOIS BEGINS IN"),
        (HIConstants.HACKING_START_TIME, "HACKING BEGINS IN"),
        (HIConstants.HACKING_END_TIME, "HACKING ENDS IN"),
        (HIConstants.EVENT_END_TIME, "HACKILLINOIS ENDS IN")
    ]

    private var timer: Timer?
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

        view.addSubview(happeningNowLabel)
        happeningNowLabel.topAnchor.constraint(equalTo: countdownViewController.view.bottomAnchor, constant: 16).isActive = true
        happeningNowLabel.constrain(to: view.safeAreaLayoutGuide, trailingInset: 0, leadingInset: 0)

        let tableView = HITableView()
        view.addSubview(tableView)
        tableView.topAnchor.constraint(equalTo: happeningNowLabel.bottomAnchor, constant: 5).isActive = true
        tableView.constrain(to: view.safeAreaLayoutGuide, trailingInset: 0, leadingInset: 0)
        tableView.constrain(to: view, bottomInset: 0)
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
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        teardownPredicateRefreshTimer()
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