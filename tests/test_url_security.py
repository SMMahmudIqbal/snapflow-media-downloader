import socket
import unittest
from unittest.mock import patch
from api.downloader import UnsafeSourceURL, validate_source_url


def dns_answer(ip):
    return [(socket.AF_INET, socket.SOCK_STREAM, 6, "", (ip, 443))]

class SourceURLPolicyTests(unittest.TestCase):
    @patch("api.downloader.socket.getaddrinfo", return_value=dns_answer("93.184.216.34"))
    def test_supported_https_media_host_with_public_dns_is_accepted(self, _):
        url = "https://www.youtube.com/watch?v=example"
        self.assertEqual(validate_source_url(url), url)

    def test_unsupported_host_is_rejected(self):
        with self.assertRaises(UnsafeSourceURL):
            validate_source_url("https://example.com/video")

    def test_http_is_rejected(self):
        with self.assertRaises(UnsafeSourceURL):
            validate_source_url("http://www.youtube.com/watch?v=example")

    def test_credentials_and_nonstandard_ports_are_rejected(self):
        for url in ("https://user:pass@www.youtube.com/watch?v=x", "https://www.youtube.com:8443/watch?v=x"):
            with self.subTest(url=url), self.assertRaises(UnsafeSourceURL):
                validate_source_url(url)

    @patch("api.downloader.socket.getaddrinfo", return_value=dns_answer("127.0.0.1"))
    def test_supported_domain_resolving_to_loopback_is_rejected(self, _):
        with self.assertRaises(UnsafeSourceURL):
            validate_source_url("https://www.youtube.com/watch?v=example")

    @patch("api.downloader.socket.getaddrinfo", return_value=[])
    def test_unresolvable_host_is_rejected(self, _):
        with self.assertRaises(UnsafeSourceURL):
            validate_source_url("https://www.youtube.com/watch?v=example")

if __name__ == "__main__":
    unittest.main()
