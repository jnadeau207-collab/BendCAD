from native_tooling import bootstrap_tools, checkout_occt


def main() -> None:
    bootstrap_tools()
    checkout_occt()


if __name__ == "__main__":
    main()
