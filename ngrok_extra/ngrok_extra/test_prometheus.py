from ngrok_extra.prometheus import start_http_server, BasicAuth
import unittest
import time


class TestNgrokUtils(unittest.TestCase):
    def test_prom_server_setup(self):
        listener, shutdown = start_http_server(
            8000,
            domain="joshtestprom.ngrok.dev",
            basic_auth=BasicAuth("josh", "31948ru98yhr4fre7wfy6t"),
        )
        print(listener.url())
        time.sleep(10)
        shutdown()
        print("done")


if __name__ == "__main__":
    unittest.main()
