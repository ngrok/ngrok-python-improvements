import typing as t
import prometheus_client
import ngrok
import logging
import random
import string


class BasicAuth(t.NamedTuple):
    username: str
    password: str


def start_http_server(
    port: int = 8000,
    authtoken: str = None,
    domain: str = None,
    basic_auth: BasicAuth = None,
    policy: str = None,
) -> t.Tuple[ngrok.Listener, t.Callable[[], None]]:
    """
    Starts the prometheus default HTTP exporter server AND an ngrok endpoint forwarding traffic to it, with optional static domain and basic auth protection.

    Keyword arguments:
    port - required. local port for the prometheus builting http server to listen on
    authtoken - optional. authtoken to use. Reads from NGROK_AUTHTOKEN environment variable if omitted. An auth token must be supplied by one of these methods.
    domain - optional but necessary for non-testing use. static domain to use. if not supplied, your external ngrok url will change each time you restart.
    basic_auth - optional. adds basic auth protection if supplied, this is supported out-of-the-box by prometheus scrape configs.
    policy - optional. policy+action configuration json. See ngrok.policy for builder API.

    Returns:
      listener - an ngrok.Listener for the created listener
      shutdown() - a function that can be used to gracefully shut down the ngrok listener and the prometheus HTTP server.
    """
    kwargs = dict()
    if authtoken:
        kwargs["authtoken"] = authtoken
    else:
        kwargs["authtoken_from_env"] = True

    if domain:
        kwargs["domain"] = domain
    else:
        logging.warning(
            "Since domain= was omitted, starting with a random ngrok domain. This will change each time you restart the program."
        )

    auth_is_generated: bool
    if basic_auth:
        kwargs["basic_auth"] = f"{basic_auth.username}:{basic_auth.password}"
        auth_is_generated = False
    else:
        auth_is_generated = True
        random_pw = "".join(
            random.choices(string.ascii_uppercase + string.digits, k=10)
        )
        basic_auth = BasicAuth("root", random_pw)
        logging.warning(
            f'Since basic_auth= was omitted, starting with a random password. This will change each time you restart. The username is "root", the password is: {random_pw}'
        )
        kwargs["basic_auth"] = f"root:{random_pw}"

    if policy:
        kwargs["policy"] = policy

    listener = ngrok.forward(port, **kwargs)

    logging.info(
        f"""
        Prometheus scrape config:
        - job_name: 'my_prometheus_exporter_with_ngrok'
          scrape_interval: 5m
          scrape_timeout: 30s
          static_configs:
              - targets: ['{listener.url()}']
          metrics_path: "/metrics"
          basic_auth:
              username: '{basic_auth.username}'
              password: '{basic_auth.password if auth_is_generated else "redacted"}'
"""
    )

    server, thread = prometheus_client.start_http_server(port)

    def shutdown():
        ngrok.disconnect(listener.url())
        server.shutdown()
        thread.join()

    return listener, shutdown
