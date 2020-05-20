import Foundation
import ArgumentParser
import SFSymbolsCore

extension SFSymbols {

    func run() {
        do {
            let configuration = try constructConfiguration()
            try configuration.run()
        } catch {
            print(error.localizedDescription)
        }
    }
}

SFSymbols.main()
