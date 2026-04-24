FROM ubuntu:24.04

ARG run_as_user=privacy_filter
ARG run_as_group=privacy_filter
ARG PRIVACY_FILTER_REF=main

ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Asia/Taipei

ENV VIRTUAL_ENV=/opt/venv
ENV PATH="/opt/venv/bin:$PATH"

ENV HOME=/home/privacy_filter
ENV HF_HOME=/home/privacy_filter/.cache/huggingface
ENV OPF_HOME=/home/privacy_filter/.opf
ENV TRANSFORMERS_CACHE=/home/privacy_filter/.cache/huggingface
ENV HF_HUB_DISABLE_TELEMETRY=1

WORKDIR /opt

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        tzdata \
        python3 \
        python3-venv \
        python3-pip \
        git \
        ca-certificates \
        build-essential && \
    ln -snf /usr/share/zoneinfo/Asia/Taipei /etc/localtime && \
    echo "Asia/Taipei" > /etc/timezone && \
    python3 -m venv /opt/venv && \
    /opt/venv/bin/pip install --upgrade pip setuptools wheel

RUN git clone https://github.com/openai/privacy-filter.git /opt/privacy-filter && \
    cd /opt/privacy-filter && \
    git checkout ${PRIVACY_FILTER_REF} && \
    pip install -e /opt/privacy-filter

RUN if ! getent group "${run_as_group}" >/dev/null; then \
        groupadd "${run_as_group}"; \
    fi && \
    useradd \
        --gid "${run_as_group}" \
        --create-home \
        --home-dir /home/${run_as_user} \
        --shell /bin/sh \
        "${run_as_user}" && \
    mkdir -p \
        /home/${run_as_user}/.cache/huggingface \
        /home/${run_as_user}/.opf \
        /work && \
    chown -R ${run_as_user}:${run_as_group} \
        /home/${run_as_user} \
        /work \
        /opt/privacy-filter

USER ${run_as_user}
WORKDIR /work

RUN printf '%s\n' "My email is alice@example.com" | \
    opf --device cpu --output-mode typed >/tmp/opf-build-test.json && \
    test -s /tmp/opf-build-test.json && \
    rm -f /tmp/opf-build-test.json

USER root

RUN apt-get purge -y git build-essential && \
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf \
        /var/lib/apt/lists/* \
        /tmp/* \
        /root/.cache

USER ${run_as_user}
WORKDIR /work

ENTRYPOINT ["opf"]
CMD ["--help"]
