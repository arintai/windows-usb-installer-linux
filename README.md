# Windows USB Installer for Linux

This script facilitates the creation of bootable Windows USB drives on Linux systems. It supports various Linux distributions and automates the process of formatting the USB drive, mounting the Windows ISO file, copying necessary files, and unmounting the drives.

## Features

- Easy creation of bootable Windows USB drives on Linux.
- Supports both Windows 10 and Windows 11 ISO files.
- Compatible with a wide range of Linux distributions.
- Enhanced user interaction and error handling.
- Checksum verification for ISO file integrity.

## Requirements

- Linux operating system
- `bash` shell
- `rsync`, `parted`, `wipefs`, `mkfs.vfat`, `mkfs.ntfs`, `udisksctl`, `sha256sum`, `mount`, `umount`, `mkdir`, `cp`, `sync`, `mktemp` utilities

## Usage

1. Clone the repository or download the `winusb-creator.sh` script.
2. Make the script executable: `chmod +x winusb-creator.sh`
3. Run the script with root privileges: `sudo ./winusb-creator.sh [path_to_iso_file] [usb_block_device]`

Example:
sudo ./winusb-creator.sh /path/to/windows.iso /dev/sdX


**Note:** Replace `/path/to/windows.iso` with the path to your Windows ISO file and `/dev/sdX` with the USB block device.

## License

This project is licensed under the GNU General Public License v3.0. See the [LICENSE](LICENSE) file for details.

## Author

This script was authored by Arint.ai.

## Contributions

Contributions are welcome! If you find any issues or have suggestions for improvements, please open an issue or submit a pull request.
