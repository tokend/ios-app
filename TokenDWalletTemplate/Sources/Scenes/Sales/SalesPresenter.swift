import UIKit

protocol SalesPresentationLogic {
    func presentSectionsUpdated(response: Sales.Event.SectionsUpdated.Response)
    func presentLoadingStatusDidChange(response: Sales.Event.LoadingStatusDidChange.Response)
    func presentEmptyResult(response: Sales.Event.EmptyResult.Response)
}

extension Sales {
    typealias PresentationLogic = SalesPresentationLogic
    
    struct Presenter {
        
        private let presenterDispatch: PresenterDispatch
        private let investedAmountFormatter: InvestedAmountFormatter
        
        private let verticalSpacing: CGFloat = 5.0
        
        init(
            presenterDispatch: PresenterDispatch,
            investedAmountFormatter: InvestedAmountFormatter
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.investedAmountFormatter = investedAmountFormatter
        }
        
        // MARK: - Private
        
        private func getTimeText(
            sale: Sales.Model.SaleModel
            ) -> (timeText: NSAttributedString, isUpcomming: Bool) {
            
            let isUpcomming: Bool
            let attributedDaysRemaining: NSAttributedString
            
            if sale.startDate > Date() {
                isUpcomming = true
                
                let components = Calendar.current.dateComponents(
                    [Calendar.Component.day],
                    from: Date(),
                    to: sale.startDate
                )
                
                let days = "\(components.day ?? 0)"
                let daysAttributed = NSAttributedString(
                    string: days,
                    attributes: [
                        .foregroundColor: Theme.Colors.accentColor
                    ]
                )
                
                attributedDaysRemaining = LocalizedAtrributed(
                    .days_to_start,
                    attributes: [
                        .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                    ],
                    replace: [
                        .days_to_start_replace_days: daysAttributed
                    ]
                )
            } else {
                isUpcomming = false
                
                let components = Calendar.current.dateComponents(
                    [Calendar.Component.day],
                    from: Date(),
                    to: sale.endDate
                )
                
                if let days = components.day,
                    days >= 0 {
                    
                    let daysFormatted = "\(days)"
                    let daysAttributed = NSAttributedString(
                        string: daysFormatted,
                        attributes: [
                            .foregroundColor: Theme.Colors.accentColor
                        ]
                    )
                    
                    attributedDaysRemaining = LocalizedAtrributed(
                        .days_to_go,
                        attributes: [
                            .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                        ],
                        replace: [
                            .days_to_go_replace_days: daysAttributed
                        ]
                    )
                } else {
                    attributedDaysRemaining = LocalizedAtrributed(
                        .ended,
                        attributes: [
                            .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                        ],
                        replace: [:]
                    )
                }
            }
            
            return (attributedDaysRemaining, isUpcomming)
        }
    }
}

extension Sales.Presenter: Sales.PresentationLogic {
    
    func presentSectionsUpdated(response: Sales.Event.SectionsUpdated.Response) {
        let sections = response.sections.map { (sectioModel) -> Sales.Model.SectionViewModel in
            return Sales.Model.SectionViewModel(cells: sectioModel.sales.map({ (sale) -> CellViewAnyModel in
                let name = sale.name
                let asset = sale.asset
                
                let paragraphStyle = NSMutableParagraphStyle()
                paragraphStyle.lineSpacing = self.verticalSpacing
                let attributedDescription = NSAttributedString(
                    string: sale.description,
                    attributes: [
                        .paragraphStyle: paragraphStyle
                    ]
                )
                
                let saleName = "\(name) (\(asset))"
                let investedAmountFormatted = self.investedAmountFormatter.formatAmount(
                    sale.investmentAmount,
                    currency: sale.investmentAsset
                )
                let investedAmountFormattedAttributed = NSAttributedString(
                    string: investedAmountFormatted,
                    attributes: [
                        .foregroundColor: Theme.Colors.accentColor
                    ]
                )
                
                let attributedInvetsedAmount = LocalizedAtrributed(
                    .invested,
                    attributes: [
                        .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                    ],
                    replace: [
                        .invested_replace_amount: investedAmountFormattedAttributed
                    ]
                )
                
                let investedPercentage = sale.investmentPercentage
                let investedPercentageRounded = Int(roundf(investedPercentage * 100))
                let investedPercentageText = "\(investedPercentageRounded)%"
                let attributedInvestedPercentageText = NSAttributedString(
                    string: investedPercentageText,
                    attributes: [
                        .foregroundColor: Theme.Colors.accentColor
                    ]
                )
                
                let attributedInvestedPercentage = LocalizedAtrributed(
                    .percent_funded,
                    attributes: [
                        .foregroundColor: Theme.Colors.textOnContentBackgroundColor
                    ],
                    replace: [
                        .percent_funded_replace_percent: attributedInvestedPercentageText
                    ]
                )
                
                let timeText = self.getTimeText(sale: sale)
                
                return Sales.SaleListCell.ViewModel(
                    imageUrl: sale.imageURL,
                    name: saleName,
                    description: attributedDescription,
                    investedAmountText: attributedInvetsedAmount,
                    investedPercentage: sale.investmentPercentage,
                    investedPercentageText: attributedInvestedPercentage,
                    isUpcomming: timeText.isUpcomming,
                    timeText: timeText.timeText,
                    saleIdentifier: sale.saleIdentifier,
                    asset: sale.asset
                )
            }))
        }
        
        let viewModel = Sales.Event.SectionsUpdated.ViewModel(
            sections: sections
        )
        self.presenterDispatch.display { displayLogic in
            displayLogic.displaySectionsUpdated(viewModel: viewModel)
        }
    }
    
    func presentLoadingStatusDidChange(response: Sales.Event.LoadingStatusDidChange.Response) {
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayLoadingStatusDidChange(viewModel: response)
        }
    }
    
    func presentEmptyResult(response: Sales.Event.EmptyResult.Response) {
        let viewModel = Sales.Event.EmptyResult.ViewModel(message: response.message)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displayEmptyResult(viewModel: viewModel)
        }
    }
}
