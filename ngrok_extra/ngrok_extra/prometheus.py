import typing as t
import prometheus_client
import ngrok
import logging
import random
import string

class BasicAuth(t.NamedTuple):
    username: str
    password: str


def start_http_server(port: int = 8000, authtoken: str = None, domain: str = None, basic_auth: BasicAuth = None) -> t.Tuple[ngrok.Listener, t.Callable[[], None]]:
    """
    Starts the prometheus default HTTP exporter server AND an ngrok endpoint forwarding traffic to it, with optional static domain and basic auth protection.
    
    Keyword arguments:
    port - required. local port for the prometheus builting http server to listen on
    authtoken - optional. authtoken to use. Reads from NGROK_AUTHTOKEN environment variable if omitted. An auth token must be supplied by one of these methods.
    domain - optional but necessary for non-testing use. static domain to use. if not supplied, your external ngrok url will change each time you restart. 
    basic_auth - optional. adds basic auth protection if supplied, this is supported out-of-the-box by prometheus scrape configs.

    Returns: a function that can be used to gracefully shut down the ngrok listener and the prometheus HTTP server.
    """
    kwargs = dict()
    if authtoken:
        kwargs["authtoken"] = authtoken
    else:
        kwargs["authtoken_from_env"] = True

    if domain: 
        kwargs["domain"] = domain
    else:
        logging.warning("Since domain= was omitted, starting with a random ngrok domain. This will change each time you restart the program.")


    if basic_auth:
        kwargs["basic_auth"] = f"{basic_auth.username}:{basic_auth.password}"
    else:
        random_pw = ''.join(random.choices(string.ascii_uppercase + string.digits, k=10))
        logging.warning(f"Since basic_auth= was omitted, starting with a random password. This will change each time you restart. The username is \"root\", the password is: {random_pw}")
        kwargs["basic_auth"] = f"root:{random_pw}"

    
    listener = ngrok.forward(port, **kwargs)

    server, thread = prometheus_client.start_http_server(port)

    def shutdown():
        ngrok.disconnect(listener.url())
        server.shutdown()
        thread.join()
    
    return listener, shutdown


