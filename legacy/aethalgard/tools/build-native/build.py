from native_tooling import (
    bootstrap_tools,
    build_assembly_host,
    build_kernel_host,
    build_occt,
    checkout_occt,
)


def main() -> None:
    bootstrap_tools()
    checkout_occt()
    build_occt()
    build_kernel_host()
    build_assembly_host()


if __name__ == "__main__":
    main()
