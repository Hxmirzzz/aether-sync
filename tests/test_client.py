import unittest
from unittest.mock import patch, MagicMock
import requests
from src.api.client import ApiClient
from src.core.config import settings

class TestApiClient(unittest.TestCase):

    @patch('src.api.client.requests.Session.post')
    def test_authentication_success(self, mock_post):
        """Valida que el cliente extraiga el token y actualice los headers."""

        mock_response = MagicMock()
        mock_response.status_code = 200
        mock_response.json.return_value = {"token": "fake_jwt_token_123"}
        mock_post.return_value = mock_response

        client = ApiClient("https://fake-api.com/api/v1/")

        self.assertIn("Authorization", client.session.headers)
        self.assertEqual(client.session.headers["Authorization"], "Bearer fake_jwt_token_123")

        mock_post.assert_called_once()

    @patch('src.api.client.requests.Session.post')
    @patch('src.api.client.requests.Session.get')
    def test_get_endpoints(self, mock_get, mock_post):
        """Valida que el cliente recupere correctamente el diccionario de rutas."""

        mock_post_response = MagicMock()
        mock_post_response.status_code = 200
        mock_post_response.json.return_value = {"token": "fake"}
        mock_post.return_value = mock_post_response

        mock_get_response = MagicMock()
        mock_get_response.status_code = 200
        mock_get_response.json.return_value = {
            "clients": "https://fake/api/v1/clients/",
            "points": "https://fake/api/v1/points/"
        }
        mock_get.return_value = mock_get_response

        client = ApiClient("https://fake-api.com/api/v1/")
        endpoints = client.get_endpoints()

        self.assertIn("clients", endpoints)
        self.assertEqual(endpoints["points"], "https://fake/api/v1/points/")

    @patch('src.api.client.requests.Session.post')
    def test_authentication_failure(self, mock_post):
        """Valida que si las credenciales son incorrectas, el sistema explote (Fail Fast)."""

        mock_response = MagicMock()
        mock_response.status_code = 401
        mock_response.raise_for_status.side_effect = requests.exceptions.HTTPError("401 Unauthorized")
        mock_post.return_value = mock_response

        with self.assertRaises(requests.exceptions.HTTPError):
            ApiClient("https://fake-api.com/api/v1/")