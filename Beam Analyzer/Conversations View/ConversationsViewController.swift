//
//  ConversationsViewController.swift
//  Beam Analyzer
//
//  Created by Mehmet Ali Kısacık on 20.03.2023.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

final class ConversationsViewController: UIViewController, UITableViewDelegate {
    
    private let conversationsTableView: UITableView = {
        let tableView = UITableView()
        tableView.register(ConversationTableViewCell.self, forCellReuseIdentifier: "cell")
        
        return tableView
    }()
    
    weak var coordinator: AppCoordinator?
    private let viewModel = ConversationsViewModel()
    private var disposeBag = DisposeBag()
    
    var deflectionCalculation: DeflectionCalculation?
    
    init() {
        super.init(nibName: nil, bundle: nil)
    }
    
    init(deflectionCalculation: DeflectionCalculation) {
        self.deflectionCalculation = deflectionCalculation
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.fetchConversations()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        makeConstraints()
        showLoadingAnimation()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        viewModel.removeListeners()
        // disposeBag = DisposeBag()
    }
    
    private func setupViews() {
        view.addSubview(conversationsTableView)
        view.backgroundColor = .systemBackground
        bindTableView()
    }
    
    private func makeConstraints() {
        conversationsTableView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func bindTableView() {
        conversationsTableView.rx.setDelegate(self).disposed(by: disposeBag)
        viewModel.userNames.bind(to: conversationsTableView.rx.items(cellIdentifier: "cell", cellType: ConversationTableViewCell.self)) { (_, userName, cell) in
            cell.textLabel?.text = userName
            cell.accessoryType = .disclosureIndicator
        }.disposed(by: disposeBag)
        
        conversationsTableView.rx.modelSelected(String.self).subscribe(onNext: { [weak self] userName in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.showLoadingAnimation()
            }
            
            self.viewModel.fetchUser(userName: userName) { [weak self] user in
                guard let self = self else { return }
                DispatchQueue.main.async {
                    self.hideLoadingAnimation()
                }
                
                if let user {
                    if let result = deflectionCalculation?.result {
                        let chatVC = ChatViewController(receiverUser: user)
                        chatVC.coordinator = self.coordinator
                        
                        chatVC.viewModel.sendMessage(message: String(result))
                        self.present(chatVC, animated: true)
                    } else {
                        self.coordinator?.navigateToChat(with: user)
                    }
                } else {
                    self.showError()
                }
                
            }
            
            print("SelectedItem: \(userName)")
        }).disposed(by: disposeBag)
        
        viewModel.userNames.bind { _ in
            DispatchQueue.main.async {
                self.hideLoadingAnimation()
            }
        }.disposed(by: disposeBag)
    }
    
}
