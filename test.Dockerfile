FROM centos:7

# ---- Fix CentOS 7 EOL repos (CRITICAL STEP) ----
RUN sed -i 's|^mirrorlist=|#mirrorlist=|g' /etc/yum.repos.d/CentOS-Base.repo \
    && sed -i 's|^#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g' /etc/yum.repos.d/CentOS-Base.repo

# ---- Versions ----
ENV PYTHON_VERSION=3.7.5
ENV PYTHON_BIN=/usr/local/bin/python3.7

# ---- Install build dependencies ----
RUN yum -y install \
        gcc \
        gcc-c++ \
        make \
        epel-release \
        openssl-devel \
        bzip2-devel \
        libffi-devel \
        tcl-devel \
        tk-devel \
        rpm-build \
        curl \
        wget \
    && yum clean all

# ---- Build Python from source ----
RUN curl -fsSL https://www.python.org/ftp/python/${PYTHON_VERSION}/Python-${PYTHON_VERSION}.tgz -o Python-${PYTHON_VERSION}.tgz \
    && tar xzf Python-${PYTHON_VERSION}.tgz \
    && cd Python-${PYTHON_VERSION} \
    && ./configure --enable-optimizations \
    && make altinstall \
    && cd / \
    && rm -rf Python-${PYTHON_VERSION}*

# ---- Install pip for Python 3.7 ----
RUN curl -fsSL https://bootstrap.pypa.io/pip/3.7/get-pip.py -o get-pip.py \
    && ${PYTHON_BIN} get-pip.py \
    && rm -f get-pip.py

# ---- Install virtualenv (command you want to test) ----
RUN ${PYTHON_BIN} -m pip install --ignore-installed virtualenv

# ---- Verify ----
RUN ${PYTHON_BIN} --version && virtualenv --version

CMD ["python3.7", "--version"]
