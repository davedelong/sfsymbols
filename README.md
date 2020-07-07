# `sfsymbols`

`sfsymbols` is a quick-and-dirty command-line tool to export the shapes inside the SF Symbols font.

## Install

#### Command line

```sh
cd sfsymbols
swift build -c release
ln -s ${PWD}/.build/release/sfsymbols /usr/local/bin/sfsymbols
```

#### Xcode

Open the `Package.swift` and build the project, then run the resulting `sfsymbols` tool from the command line.

## Usage

Output all icons to a folder called symbols in png format
```sh
sfsymbols --output symbols --format png
```

Output all icons with `heart` in the symbol name in svg format to the current directory
```sh
sfsymbols --symbol-name heart.*
```

There are several options you may specify:

- `--symbol-name`: A pattern to limit which symbols are exported. Example: `*.fill` or `*cloud*`.

- `--font-file`: An path to a specific SF Symbols ttf file. If you leave out this argument, then `sfsymbols` will attempt to locate an installed copy of `SF Symbols.app` on your machine and use the font packaged inside there.

- `--font-weight`: A specific font-weight to use for exporting symbols. Valid values are:
    - `ultralight`
    - `thin`
    - `light`
    - `regular`
    - `medium`
    - `semibold`
    - `bold`
    - `heavy`
    - `black`
    
    If you leave out this argument, then `regular` will be used. Also, depending on the specified `--font-file`, not all copies of the SF Symbols font may contain all weights.
    
- `--font-size`: The size (in points) to use when exporting symbols. If you leave this argument out, then the default size of `44` will be used.

- `--symbol-size`: The size of the shape to use. Valid values are `small`, `medium`, and `large`. The default value is `large`.

- `--output`: The folder where exported shapes should be created. Defaults to the current working directory.

- `--format`: The format in which you'd like shapes exported. Valid values are:
    - `ios-swift`: `UIBezierPath`-based code in Swift 
    - `ios-objc`:  `UIBezierPath`-based code in Objective-C
    - `macos-swift`:  `NSBezierPath`-based code in Swift
    - `macos-objc`:  `NSBezierPath`-based code in Objective-C
    - `svg`: SVG files
    - `png`: PNG images
    - `pdf`: PDF images 
    - `iconset`: An `SFSymbols.xcassets` bundle of 1x, 2x, and 3x template PNGs
    - `iconset-pdf`: An `SFSymbols.xcassets` bundle of vector template PDFs
    
    The default value is `svg`.

## Disclaimer

This is posted mainly as a proof-of-concept. Use it at your own risk.

It is your responsibility to make sure you are following the terms and conditions of using Apple's symbols. For more information, see [https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/](https://developer.apple.com/design/human-interface-guidelines/sf-symbols/overview/).
