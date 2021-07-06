import UIKit
import DifferenceKit

extension Array where Element == CellViewAnyModel {
    static func == (left: Self, right: Self) -> Bool {
        guard left.count == right.count else { return false }
        return !zip(left, right).contains { !$0.0.anyDifferentiable.isContentEqual(to: $0.1.anyDifferentiable) }
    }
}

extension Array where Element == CellViewAnyModel {
    var anyDifferentiables: [AnyDifferentiable] {
        map { $0.anyDifferentiable }
    }
}

extension Array where Element == AnyDifferentiable {
    var cellViewAnyModels: [CellViewAnyModel] {
        anyModels(from: self)
    }
}

private func anyModels<C: Swift.Collection>(
    from elements: C
) -> [CellViewAnyModel]
    where C.Element == AnyDifferentiable {

    elements.compactMap {
        guard let viewModel = $0.base as? CellViewAnyModel
            else {
                print(.fatalError(error: "Cannot cast \($0.base) to CellViewAnyModel"))
                return nil
        }
        return viewModel
    }
}

protocol SectionViewModel {
    var cells: [CellViewAnyModel] { get }

    init(
        source: Self,
        elements: [CellViewAnyModel]
    )
}

extension SectionViewModel {
    func cellsEqualTo(_ cells: [CellViewAnyModel]) -> Bool {
        return self.cells == cells
    }
}

extension DifferentiableSection where Self: SectionViewModel, Collection == [AnyDifferentiable] {
    var elements: [AnyDifferentiable] {
        cells.anyDifferentiables
    }

    init<C>(
        source: Self,
        elements: C
    ) where C: Swift.Collection,
        C.Element == Collection.Element {

            self.init(
                source: source,
                elements: Self.cellViewAnyModels(from: elements)
            )
    }

    static func cellViewAnyModels<C: Swift.Collection>(
        from elements: C
    ) -> [CellViewAnyModel]
        where C.Element == Collection.Element {

            return anyModels(from: elements)
    }
}

public protocol CellViewAnyModel {
    
    static var cellAnyType: UIView.Type { get }
    static var identifier: String { get }
    func setupAny(cell: UIView)
    var anyDifferentiable: AnyDifferentiable { get }
}

public protocol CellViewModel: CellViewAnyModel, Hashable, Differentiable {
    
    associatedtype CellType: UIView
    func setup(cell: CellType)
}

extension CellViewModel {
    
    public static var cellAnyType: UIView.Type { return CellType.self }
    public static var identifier: String { return String(describing: self) }
    
    public func setupAny(cell: UIView) {
        guard let castedCell = cell as? CellType else {
            fatalError("Cannot cast cell \(cell) to \(CellType.self)")
        }
        self.setup(cell: castedCell)
    }

    public var hashValue: Int { fatalError("Override") }
    public func hash(into hasher: inout Hasher) {
        fatalError("Override")
    }

    public static func == (lhs: Self, rhs: Self) -> Bool { fatalError("Override") }

    public var anyDifferentiable: AnyDifferentiable {
        return AnyDifferentiable(self)
    }
}

// MARK: - Size provider

public protocol UICollectionViewCellSizeProvider {
    func size(with collectionViewWidth: CGFloat) -> CGSize
}

public protocol UITableViewCellHeightProvider {
    func height(with tableViewWidth: CGFloat) -> CGFloat
}

public protocol UITableViewHeaderFooterViewHeightProvider {
    func height(with tableViewWidth: CGFloat) -> CGFloat
}

// MARK: - UITableView

extension UITableView {
    
    public func dequeueReusableCell(
        with model: CellViewAnyModel,
        for indexPath: IndexPath
        ) -> UITableViewCell {
        
        let identifier = type(of: model).cellAnyType.defaultNibName()
        let cell = self.dequeueReusableCell(withIdentifier: identifier, for: indexPath)
        
        model.setupAny(cell: cell)
        
        return cell
    }
    
    public func register(nibModels: [CellViewAnyModel.Type]) {
        for model in nibModels {
            let identifier = model.cellAnyType.defaultNibName()
            let cellNib = model.cellAnyType.defaultNib()
            self.register(cellNib, forCellReuseIdentifier: identifier)
        }
    }
    
    public func register(classes: [CellViewAnyModel.Type]) {
        for model in classes {
            let identifier = model.cellAnyType.defaultNibName()
            self.register(model.cellAnyType, forCellReuseIdentifier: identifier)
        }
    }
}

// MARK: UICollectionView

extension UICollectionView {

    func dequeueReusableCell(
        with model: CellViewAnyModel,
        for indexPath: IndexPath
        ) -> UICollectionViewCell {

        let identifier = type(of: model).cellAnyType.defaultNibName()
        let cell = self.dequeueReusableCell(
            withReuseIdentifier: identifier,
            for: indexPath
        )

        model.setupAny(cell: cell)

        return cell
    }

    func register(nibModels: [CellViewAnyModel.Type]) {
        for model in nibModels {
            let identifier = model.cellAnyType.defaultNibName()
            let cellNib = model.cellAnyType.defaultNib()
            self.register(cellNib, forCellWithReuseIdentifier: identifier)
        }
    }

    func register(classes: [CellViewAnyModel.Type]) {
        for model in classes {
            let identifier = model.cellAnyType.defaultNibName()
            self.register(model.cellAnyType, forCellWithReuseIdentifier: identifier)
        }
    }
}

// MARK: - HeaderFooterViewModel

protocol HeaderFooterViewAnyModel {
    static var headerFooterAnyType: UIView.Type { get }
    func setupAny(headerFooter: UIView)
    func equalsTo(another: HeaderFooterViewAnyModel) -> Bool
}

protocol HeaderFooterViewModel: HeaderFooterViewAnyModel, Equatable {
    associatedtype HeaderFooterType: UIView
    func setup(headerFooter: HeaderFooterType)
}

extension HeaderFooterViewModel {
    var hashValue: Int { fatalError("Override") }

    static func == (lhs: Self, rhs: Self) -> Bool { fatalError("Override") }

    func equalsTo(another: HeaderFooterViewAnyModel) -> Bool {
        guard let another = another as? Self else { return false }
        return self == another
    }
}

extension HeaderFooterViewModel {
    static var headerFooterAnyType: UIView.Type { return HeaderFooterType.self }

    func setupAny(headerFooter: UIView) {
        guard let castedHeaderFooter = headerFooter as? HeaderFooterType else {
            fatalError("Cannot cast cell \(headerFooter) to \(HeaderFooterType.self)")
        }
        self.setup(headerFooter: castedHeaderFooter)
    }
}

extension Optional where Wrapped == HeaderFooterViewAnyModel {

    func equalsTo(another: HeaderFooterViewAnyModel?) -> Bool {
        switch (self, another) {

        case (.none, .none):
            return true

        case (.some(let s), .some(let another)):
            return s.equalsTo(another: another)

        case (.some, .none),
             (.none, .some):
            return false
        }
    }
}

// MARK: UITableView

extension UITableView {
    func dequeueReusableHeaderFooterView(
        with model: HeaderFooterViewAnyModel
        ) -> UITableViewHeaderFooterView {

        let identifier = type(of: model).headerFooterAnyType.defaultNibName()
        guard let headerFooter = self.dequeueReusableHeaderFooterView(withIdentifier: identifier) else {
            fatalError("No reusable header footer view for identifier \(identifier)")
        }

        model.setupAny(headerFooter: headerFooter)

        return headerFooter
    }

    func register(nibModels: [HeaderFooterViewAnyModel.Type]) {
        for model in nibModels {
            let identifier = model.headerFooterAnyType.defaultNibName()
            let headerFooterNib = model.headerFooterAnyType.defaultNib()
            self.register(
                headerFooterNib,
                forHeaderFooterViewReuseIdentifier: identifier
            )
        }
    }

    func register(classes: [HeaderFooterViewAnyModel.Type]) {
        for model in classes {
            let identifier = model.headerFooterAnyType.defaultNibName()
            self.register(
                model.headerFooterAnyType,
                forHeaderFooterViewReuseIdentifier: identifier
            )
        }
    }
}

// MARK: UICollectionView

extension UICollectionView {
    func dequeueReusableHeaderFooterView(
        with model: HeaderFooterViewAnyModel,
        ofKind kind: String,
        for indexPath: IndexPath
    ) -> UICollectionReusableView {

        let identifier = type(of: model).headerFooterAnyType.defaultNibName()
        let headerFooter = self.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: identifier,
            for: indexPath
        )

        model.setupAny(headerFooter: headerFooter)

        return headerFooter
    }

    func register(nibModels: [(model: HeaderFooterViewAnyModel.Type, kind: String)]) {
        for tuple in nibModels {
            let identifier = tuple.model.headerFooterAnyType.defaultNibName()
            let headerFooterNib = tuple.model.headerFooterAnyType.defaultNib()
            self.register(
                headerFooterNib,
                forSupplementaryViewOfKind: tuple.kind,
                withReuseIdentifier: identifier
            )
        }
    }

    func register(classes: [(model: HeaderFooterViewAnyModel.Type, kind: String)]) {
        for tuple in classes {
            let identifier = tuple.model.headerFooterAnyType.defaultNibName()
            register(
                tuple.model.headerFooterAnyType,
                forSupplementaryViewOfKind: tuple.kind,
                withReuseIdentifier: identifier
            )
        }
    }
}
