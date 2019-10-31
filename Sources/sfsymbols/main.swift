import Foundation
import SPMUtility
import SFSymbolsCore


do {
    // The first argument is always the executable, drop it
    let arguments = Array(CommandLine.arguments.dropFirst())
    let configuration = try parseConfiguration(arguments)
    
    try configuration.run()
    
} catch let error as ArgumentParserError {
    print(error.description)
} catch let error {
    print(error.localizedDescription)
}
