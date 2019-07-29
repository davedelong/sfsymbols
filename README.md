# `sfsymbols`

`sfsymbols` is a quick-and-dirty command-line tool to export the shapes inside the SF Symbols font as code. You can choose to export the shapes in either Swift or Objective-C, or as SVG. There's also basic support for `NSBezierPath` as well.

This is posted mainly as a proof-of-concept. Use it at your own risk.

## Usage

Open the xcodeproj and build the project, then run the resulting `sfsymbols` tool from the command line.

You'll need to pass in these arguments:

1. `-output`: The folder in which the code should be dumped
2. `-format`: The language in which the code should be generated. Valid values are listed in the `-help`.
3. `-font-size`: The size (in points) of the font to use when exporting. If omitted, a default size will be chosen. Something like `512` generates nicely large SVGs.