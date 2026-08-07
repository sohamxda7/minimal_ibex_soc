zephyr_library()
zephyr_library_sources_ifdef(CONFIG_UART_ARF uart_arf.c)
