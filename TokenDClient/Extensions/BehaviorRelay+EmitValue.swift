import Foundation
import RxCocoa

extension BehaviorRelay {
    func emitEvent() {
        self.accept(self.value)
    }
}
