FROM atlassian/default-image:3 AS base
WORKDIR /helm
RUN wget https://get.helm.sh/helm-v3.9.4-linux-amd64.tar.gz
RUN tar -zxvf helm-v3.9.4-linux-amd64.tar.gz
RUN curl -LO https://dl.k8s.io/release/v1.25.0/bin/linux/amd64/kubectl


FROM atlassian/default-image:3
COPY --from=base --chmod=777 /helm/linux-amd64/helm /usr/bin/helm
COPY --from=base --chmod=777 /helm/kubectl /usr/bin/kubectl
