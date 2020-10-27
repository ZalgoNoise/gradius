# gRadius
A light-weight Docker container for a FreeRadius deployment configured with Google Workspace Secure LDAP

![CI](https://github.com/ZalgoNoise/gradius/workflows/CI/badge.svg)

______

_To Do: A better `README.md`_

### Container Runtime

Place your extracted `.key`/`.crt` combination from Google Workspace in a folder (e.g.~/GoogleLDAP)

Replace the environment variables added to the container with your own


```bash
docker run                                  \
    -it                                     \
    -v /path/to/cert:/data                  \
    -e FREERADIUS_USERNAME=YOUR_LDAP_USER   \
    -e FREERADIUS_PASSWORD=YOUR_LDAP_PASS   \
    -e FREERADIUS_BASEDN=YOUR_BASE_DN       \
    -p 18120:18120                          \
    --name gradius                          \
    zalgonoise/gradius:latest
```

Or, if you have these environment variables in a file:


```bash
docker run                          \
    -it                             \
    -v /path/to/cert:/data          \
    --env-file /path/to/env/file    \
    -p 18120:18120                  \
    --name gradius                  \
    zalgonoise/gradius:latest
```
