import UIKit

protocol CellViewAnyModel {
    static var cellAnyType: UIView.Type { get }
    func setupAny(cell: UIView)
}

protocol CellViewModel: CellViewAnyModel {
    associatedtype CellType: UIView
    func setup(cell: CellType)
}

extension CellViewModel {
    static var cellAnyType: UIView.Type { return CellType.self }
    
    func setupAny(cell: UIView) {
        // swiftlint:disable force_cast
        self.setup(cell: cell as! CellType)
        // swiftlint:enable force_cast
    }
}

extension UITableView {
    func dequeueReusableCell(with model: CellViewAnyModel, for indexPath: IndexPath) -> UITableViewCell {
        let identifier = type(of: model).cellAnyType.defaultNibName()
        let cell = self.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        model.setupAny(cell: cell)
        
        return cell
    }
    
    func register(nibModels: [CellViewAnyModel.Type]) {
        for model in nibModels {
            let identifier = model.cellAnyType.defaultNibName()
            let cellNib = model.cellAnyType.defaultNib()
            self.register(cellNib, forCellReuseIdentifier: identifier)
        }
    }
    
    func register(classes: [CellViewAnyModel.Type]) {
        for model in classes {
            let identifier = model.cellAnyType.defaultNibName()
            self.register(model.cellAnyType, forCellReuseIdentifier: identifier)
        }
    }
}
