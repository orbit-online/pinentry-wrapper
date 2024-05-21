# pinentry-wrapper

A wrapper script for [pinentry](https://www.gnupg.org/related_software/pinentry/index.html)
that handles cross-platform wonkyness (especially through WSL).  
The interface to create a prompt has been simplified and converted into
commandline options (or alternatively environment variables).

## Installation

See [the latest release](https://github.com/orbit-online/pinentry-wrapper/releases/latest) for instructions.

## Usage

```
Pinentry Wrapper - Cross-platform pinentry script with a CLI interface
Usage:
  pinentry-wrapper [options] [PROMPT]

Options:
  -d --desc TEXT    Text to appear below the prompt
                    [default: \${PINENTRY_DESC:-}]
  -o --ok TEXT      Text for the OK button
                    [default: \${PINENTRY_OK:-OK}]
  -c --cancel TEXT  Text for the Cancel button
                    [default: \${PINENTRY_CANCEL:-Cancel}]
  -e --error TEXT   Set an error text
                    [default: \${PINENTRY_ERROR:-}]

Note:
  PROMPT can be overriden with \$PINENTRY_PROMPT
  If PROMPT is not defined or overridden, the default is 'Enter your password'
```
