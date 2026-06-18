# rocker/r-ver pinned to match Depends in DESCRIPTION
FROM rocker/r-ver:4.5.3
ENV MAKEFLAGS="-j1"

# use binary packages where possible; pin CRAN mirror
ENV PAK_PKG_TYPE=binary \
    CRAN_MIRROR=https://cloud.r-project.org \
    MAKEFLAGS="-j1"

RUN echo "options(repos = c(CRAN = Sys.getenv('CRAN_MIRROR')))" \
    >> /usr/local/lib/R/etc/Rprofile.site

# system dependencies
COPY sys_deps/sys_deps.sh /tmp/sys_deps.sh
RUN bash /tmp/sys_deps.sh && rm /tmp/sys_deps.sh

# git + ssh for committing and pushing from inside the container
RUN apt-get update && apt-get install -y --no-install-recommends \
    git \
    openssh-client \
    && rm -rf /var/lib/apt/lists/*

# ---------------------------------------------------------------------------
# Python environment for Snakemake + future project scripts.
# pyproject.toml is the Python parallel to DESCRIPTION: add new Python deps
# there, not here. Installed into a dedicated venv rather than system Python
# so it stays isolated and reproducible.
# ---------------------------------------------------------------------------
RUN apt-get update && apt-get install -y --no-install-recommends \
    python3 \
    python3-venv \
    && rm -rf /var/lib/apt/lists/*

RUN python3 -m venv /opt/venv
ENV PATH="/opt/venv/bin:$PATH"

COPY pyproject.toml /home/rproject/pyproject.toml
RUN pip install --no-cache-dir /home/rproject

# install pak
RUN install2.r --error --skipinstalled pak

# copy DESCRIPTION first so Docker can cache the package install layer
WORKDIR /home/rproject
COPY DESCRIPTION /home/rproject/

RUN R -q -e "pak::meta_update()" \
    && R -q -e "pak::local_install_deps('.', ask = FALSE, upgrade = FALSE)"

# copy the rest of the project
COPY . /home/rproject

# install arf (Adaptive R Frontend) + languageserver + httpgd
RUN apt-get update && apt-get install -y --no-install-recommends curl \
    && curl --proto '=https' --tlsv1.2 -LsSf \
    https://github.com/eitsupi/arf/releases/latest/download/arf-console-installer.sh | sh \
    && ln -s /root/.cargo/bin/arf /usr/local/bin/arf \
    && rm -rf /var/lib/apt/lists/*

RUN R -q -e "pak::pkg_install(c('languageserver', 'httpgd'))"

RUN mkdir -p /root/.config/arf
COPY arf.toml /root/.config/arf/arf.toml