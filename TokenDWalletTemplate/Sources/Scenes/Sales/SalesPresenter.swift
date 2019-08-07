import Foundation

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
        
        init(
            presenterDispatch: PresenterDispatch,
            investedAmountFormatter: InvestedAmountFormatter
            ) {
            
            self.presenterDispatch = presenterDispatch
            self.investedAmountFormatter = investedAmountFormatter
        }
        
        // MARK: - Private
        
        private func getTimeText(sale: Sales.Model.SaleModel) -> (timeText: String, isUpcomming: Bool) {
            let daysRemaining: String
            let isUpcomming: Bool
            
            if sale.startDate > Date() {
                let components = Calendar.current.dateComponents(
                    [Calendar.Component.day],
                    from: Date(),
                    to: sale.startDate
                )
                
                let days = components.day ?? 0
                let startsInString =  "\(days) days"
                
                isUpcomming = true
                
                daysRemaining = ["Starts in ", startsInString].joined()
            } else {
                isUpcomming = false
                
                let components = Calendar.current.dateComponents(
                    [Calendar.Component.day],
                    from: Date(),
                    to: sale.endDate
                )
                
                if let days = components.day,
                    days >= 0 {
                    let daysRemainingString =  "\(days) days"
                    daysRemaining = [daysRemainingString, " left"].joined()
                } else {
                    daysRemaining = "ended"
                }
            }
            
            return (daysRemaining, isUpcomming)
        }
    }
}

extension Sales.Presenter: Sales.PresentationLogic {
    func presentSectionsUpdated(response: Sales.Event.SectionsUpdated.Response) {
        let sections = response.sections.map { (sectioModel) -> Sales.Model.SectionViewModel in
            return Sales.Model.SectionViewModel(cells: sectioModel.sales.map({ (sale) -> CellViewAnyModel in
                let saleName = "\(sale.name) (\(sale.asset))"
                let investedAmountFormatted = self.investedAmountFormatter.formatAmount(
                    sale.investmentAmount,
                    currency: sale.investmentAsset
                )
                let investedAmount = "\(investedAmountFormatted) invested"
                let investedPercentage = sale.investmentPercentage
                let investedPercentageRounded = Int(roundf(investedPercentage * 100))
                let investedPercentageText = "\(investedPercentageRounded)%"
                let investorsText = "\(sale.investorsCount) investors"
                let timeText = self.getTimeText(sale: sale)
                
                return Sales.SaleListCell.ViewModel(
                    imageUrl: sale.imageURL,
                    name: saleName,
                    description: sale.description,
                    investedAmountText: investedAmount,
                    investedPercentage: sale.investmentPercentage,
                    investedPercentageText: investedPercentageText,
                    investorsText: investorsText,
                    isUpcomming: timeText.isUpcomming,
                    timeText: timeText.timeText,
                    saleIdentifier: sale.saleIdentifier
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
