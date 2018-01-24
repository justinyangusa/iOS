//
//  HIUserDetailViewController.swift
//  HackIllinois
//
//  Created by Sujay Patwardhan on 1/18/18.
//  Copyright © 2018 HackIllinois. All rights reserved.
//

import Foundation
import UIKit

protocol HIUserDetailViewControllerDelegate: class {
    func willDismissViewController(_ viewController: HIUserDetailViewController, animated: Bool)
    func didDismissViewController(_ viewController: HIUserDetailViewController, animated: Bool)
}

class HIUserDetailViewController: HIBaseViewController {
    // MARK: - Properties
    weak var delegate: HIUserDetailViewControllerDelegate?

    var qrCode = UIView()
    var userNameLabel = UILabel()
    var userInfoLabel = UILabel()

    var emergencyContactNameLabel = UILabel()
    var emergencyContactPhoneLabel = UILabel()
    var emergencyContactEmailLabel = UILabel()

    // MARK: - Outlets
    var animationView: UIView!
}

// MARK: - Actions
extension HIUserDetailViewController {
    func dismiss() {
        let animated = true
        delegate?.willDismissViewController(self, animated: animated)
        dismiss(animated: animated) {
            self.delegate?.didDismissViewController(self, animated: animated)
        }
    }
}

// MARK: - UIViewController
extension HIUserDetailViewController {

    override func loadView() {
        super.loadView()

        let userDetailContainer = UIView()
        userDetailContainer.layer.cornerRadius = 8
        userDetailContainer.backgroundColor = HIColor.white
        userDetailContainer.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(userDetailContainer)
        userDetailContainer.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 13).isActive = true
        userDetailContainer.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 12).isActive = true
        userDetailContainer.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -12).isActive = true
        userDetailContainer.heightAnchor.constraint(equalToConstant: 430).isActive = true

        qrCode.backgroundColor = HIColor.darkIndigo
        qrCode.translatesAutoresizingMaskIntoConstraints = false
        userDetailContainer.addSubview(qrCode)
        qrCode.topAnchor.constraint(equalTo: userDetailContainer.topAnchor, constant: 48).isActive = true
        qrCode.leadingAnchor.constraint(equalTo: userDetailContainer.leadingAnchor, constant: 42).isActive = true
        qrCode.trailingAnchor.constraint(equalTo: userDetailContainer.trailingAnchor, constant: -42).isActive = true
        qrCode.heightAnchor.constraint(equalTo: qrCode.widthAnchor).isActive = true

        let userDataStackContainer = UIView()
        userDataStackContainer.translatesAutoresizingMaskIntoConstraints = false
        userDetailContainer.addSubview(userDataStackContainer)
        userDataStackContainer.topAnchor.constraint(equalTo: qrCode.bottomAnchor).isActive = true
        userDataStackContainer.bottomAnchor.constraint(equalTo: userDetailContainer.bottomAnchor).isActive = true
        userDataStackContainer.centerXAnchor.constraint(equalTo: userDetailContainer.centerXAnchor).isActive = true

        let userDataStackView = UIStackView()
        userDataStackView.translatesAutoresizingMaskIntoConstraints = false
        userDataStackContainer.addSubview(userDataStackView)
        userDataStackView.leadingAnchor.constraint(equalTo: userDataStackContainer.leadingAnchor).isActive = true
        userDataStackView.trailingAnchor.constraint(equalTo: userDataStackContainer.trailingAnchor).isActive = true
        userDataStackView.centerYAnchor.constraint(equalTo: userDataStackContainer.centerYAnchor).isActive = true
        userDataStackView.axis = .vertical
        userDataStackView.alignment = .center

        userNameLabel.text = "JOHN DOE"
        userNameLabel.textColor = HIColor.darkIndigo
        userNameLabel.font = UIFont.systemFont(ofSize: 15, weight: .bold)
        userNameLabel.translatesAutoresizingMaskIntoConstraints = false
        userDataStackView.addArrangedSubview(userNameLabel)

        userInfoLabel.text = "NO DIETARY RESTRICTIONS"
        userInfoLabel.textColor = HIColor.hotPink
        userInfoLabel.font = UIFont.systemFont(ofSize: 13, weight: .light)
        userInfoLabel.translatesAutoresizingMaskIntoConstraints = false
        userDataStackView.addArrangedSubview(userInfoLabel)

        // TODO: verify fonts with sketch
        let emergencyContactTitle = UILabel()
        emergencyContactTitle.text = "EMERGENCY CONTACT"
        emergencyContactTitle.textColor = HIColor.darkIndigo
        emergencyContactTitle.font = UIFont.systemFont(ofSize: 13, weight: .bold)
        emergencyContactTitle.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emergencyContactTitle)
        emergencyContactTitle.topAnchor.constraint(equalTo: userDetailContainer.bottomAnchor, constant: 29).isActive = true
        emergencyContactTitle.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        emergencyContactTitle.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        emergencyContactTitle.heightAnchor.constraint(equalToConstant: 22).isActive = true

        let emergencyContactStackView = UIStackView()
        emergencyContactStackView.axis = .vertical
        emergencyContactStackView.distribution = .fillEqually
        emergencyContactStackView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(emergencyContactStackView)
        emergencyContactStackView.topAnchor.constraint(equalTo: emergencyContactTitle.bottomAnchor, constant: 7).isActive = true
        emergencyContactStackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 24).isActive = true
        emergencyContactStackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -24).isActive = true
        emergencyContactStackView.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -42).isActive = true
        emergencyContactStackView.heightAnchor.constraint(equalToConstant: 60)

        emergencyContactNameLabel.text = "JANE DOE"
        emergencyContactNameLabel.textColor = HIColor.hotPink
        emergencyContactNameLabel.font = UIFont.systemFont(ofSize: 13, weight: .light)
        emergencyContactNameLabel.translatesAutoresizingMaskIntoConstraints = false
        emergencyContactStackView.addArrangedSubview(emergencyContactNameLabel)

        emergencyContactPhoneLabel.text = "630 - 000 - 9090"
        emergencyContactPhoneLabel.textColor = HIColor.hotPink
        emergencyContactPhoneLabel.font = UIFont.systemFont(ofSize: 13, weight: .light)
        emergencyContactPhoneLabel.translatesAutoresizingMaskIntoConstraints = false
        emergencyContactStackView.addArrangedSubview(emergencyContactPhoneLabel)

        emergencyContactEmailLabel.text = "jane@doe.com"
        emergencyContactEmailLabel.textColor = HIColor.hotPink
        emergencyContactEmailLabel.font = UIFont.systemFont(ofSize: 13, weight: .light)
        emergencyContactEmailLabel.translatesAutoresizingMaskIntoConstraints = false
        emergencyContactStackView.addArrangedSubview(emergencyContactEmailLabel)

    }

    override func viewDidLoad() {
        super.viewDidLoad()
        //        animation.loopAnimation = true
        //        animation.frame.size = animationView.frame.size
        //        animation.frame.origin = .zero
        //        animationView.addSubview(animation)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        //        animation.completionBlock = { (_) in
        //            print("done")
        //        }
        //        animation.play()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        //        animation.stop()
    }
}

// MARK: - UINavigationItem Setup
extension HIUserDetailViewController {
    @objc dynamic override func setupNavigationItem() {
        super.setupNavigationItem()
        title = "PROFILE"
    }
}
