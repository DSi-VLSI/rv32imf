# RV32IMF Testbench
This repository provides a comprehensive testbench for the [OpenHW Group](https://www.openhwgroup.com/)'s [cv32e40p](https://github.com/openhwgroup/cv32e40p) RISC-V core configured for RV32IMF. The primary goal of this repository is to enable users to run RISC-V assembly and C tests on the RV32IMF core, helping them improve their understanding and skills in working with RISC-V architecture and hardware design.

## Running Simulations

To run simulations, you can use the provided `Makefile`. Below are the key commands:

- **Run a specific test**:
  ```bash
  make run TEST=<test>
  ```
  Replace `<test>` with the name of the test file (e.g., `printf.c` or `addi.s`) located in the `tests` directory.

- **Run a test in debug mode**:
  ```bash
  make run TEST=<test> DEBUG=1
  ```

- **View waveforms**:
  ```bash
  make wave TEST=<test>
  ```
  This will open GTKWave with the generated VCD file.

- **Clean the build directory**:
  ```bash
  make clean
  ```

For more details, run:
```bash
make help
```

## Contributing
#### Contributions to this testbench are welcome! If you find any issues or have suggestions for improvements, please feel free to:
 - Submit bug reports or feature requests through the GitHub issue tracker.
 - Fork the repository and submit pull requests with your changes.
##### Please ensure that your contributions follow the established coding style and include appropriate documentation and tests.

## License

This project is licensed under the Apache License 2.0. See the [LICENSE](LICENSE) file for more details.

## Special Thanks

We would like to express our sincere gratitude to the **OpenHW Group** for developing and open-sourcing the excellent cv32e40p core. Their commitment to open-source hardware is invaluable to the community, and this testbench builds upon their fantastic work. We appreciate their contributions and the collaborative spirit of the open hardware ecosystem.
