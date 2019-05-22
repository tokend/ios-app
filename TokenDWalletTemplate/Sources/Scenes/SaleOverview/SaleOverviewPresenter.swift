import UIKit

public protocol SaleOverviewPresentationLogic {
    
    typealias Event = SaleOverview.Event
    
    func presentSaleUpdated(response: Event.SaleUpdated.Response)
}

extension SaleOverview {
    
    public typealias PresentationLogic = SaleOverviewPresentationLogic
    
    @objc(SaleOverviewPresenter)
    public class Presenter: NSObject {
        
        public typealias Event = SaleOverview.Event
        public typealias Model = SaleOverview.Model
        
        // MARK: - Private properties
        
        private let presenterDispatch: PresenterDispatch
        private let investedAmountFormatter: InvestedAmountFormatter
        
        private let verticalSpacing: CGFloat = 5.0
        
        // MARK: -
        
        public init(
            presenterDispatch: PresenterDispatch,
            investedAmountFormatter: InvestedAmountFormatter
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.investedAmountFormatter = investedAmountFormatter
        }
        
        // MARK: - Private
        
        private func createOverviewViewModel(
            sale: Model.OverviewModel
            ) -> Model.OverviewViewModel {
            
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
            
            let overviewContent = self.clearEscapedCharacters(sale.overviewContent)
            
            return Model.OverviewViewModel(
                imageUrl: sale.imageUrl,
                name: saleName,
                description: attributedDescription,
                youtubeVideoUrl: sale.youtubeVideoUrl,
                investedAmountText: attributedInvetsedAmount,
                investedPercentage: sale.investmentPercentage,
                investedPercentageText: attributedInvestedPercentage,
                timeText: timeText.timeText,
                overviewContent: overviewContent
            )
        }
        
        private func getTimeText(
            sale: Model.OverviewModel
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
        
        private func clearEscapedCharacters(_ string: String?) -> String? {
            return string?
                .replacingOccurrences(of: "\\n", with: "\n")
                .replacingOccurrences(of: "\"", with: "")
                .replacingOccurrences(of: "\\'", with: "\'")
                .replacingOccurrences(of: "\\t", with: "\t")
                .replacingOccurrences(of: "\\\\", with: "\\")
        }
    }
}

extension SaleOverview.Presenter: SaleOverview.PresentationLogic {
    
    public func presentSaleUpdated(response: Event.SaleUpdated.Response) {
        let overviewModel = self.createOverviewViewModel(sale: response.model)
        let viewModel = Event.SaleUpdated.ViewModel(model: overviewModel)
        self.presenterDispatch.display { (displayLogic) in
            displayLogic.displaySaleUpdated(viewModel: viewModel)
        }
    }
}
