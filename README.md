# zshrc-modular

A modular approach to managing your Zsh configuration.

## Overview

This repo contains a set of scripts and configurations that help you keep your Zsh environment organized and portable. By splitting your `.zshrc` into multiple files, you can easily maintain different settings for various tasks.

## Installation

1. Clone this repository:

   ```bash
   git clone https://github.com/your-username/zshrc-modular.git
   ```

2. Navigate into the cloned directory:

   ```bash
   cd zshrc-modular
   ```

3. Run the install script:

   ```bash
   bash install
   ```

   This backs up your existing Zsh files, creates a `backups` directory, and copies the new configuration files into place.

## File Structure

- `zshrc` and `zprofile`: Main configuration files controlling shell behavior.

- `zshrc.d/`: Additional configuration snippets that can be enabled or disabled independently.

- `install`: Script that backs up existing configs, then deploys these modular files.

## Contributing

Feel free to open an issue or submit a pull request for any improvements or new
modules.

## License

Distributed under the MIT License. See `LICENSE` for details.
