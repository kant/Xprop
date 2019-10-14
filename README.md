## Problem

Xcode has got a shortcut `Control-6` or `View ➭ Standard Editor ➭ Show Document Items` to navigate between methods in the source file. This command is awesome, but has one annoying problem: the popup menu includes all top-level identifiers including “private” properties and synthesizers.

## Solution

The plugin Xprop will hide all garbage from the Document Items menu. As result, no more distraction.

## Installation

Click the ZIP button to download a project, open it in Xcode and press `Command-B` or `Product ➭ Build`, then relaunch Xcode and move the project into Trash.

## Usage

Hit the command `View ➭ Standard Editor ➭ Hide Properties from Document Items` in the main menu.

## Support

Please contact me in [Twitter](http://twitter.com/vadimshpakovski) if something does not work or you have any questions.

## Copyright

Xprop is licensed under the 2-clause BSD license.

## Geek?

Building plugins for Xcode is interesting and really easy. I started by looking into the project sources listed on [StackOverflow](http://stackoverflow.com/a/13181049/26980).
