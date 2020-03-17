FROM gcr.io/google.com/cloudsdktool/cloud-sdk:alpine

#environment vars
ENV HELM_VERSION v3.1.2
ENV CONSUL_TEMPLATE_VERSION 0.24.1
ENV YQ_VERSION 3.2.1


#install consul-template
ADD https://releases.hashicorp.com/consul-template/${CONSUL_TEMPLATE_VERSION}/consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip /

RUN unzip consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip && \
  mv consul-template /usr/local/bin/consul-template &&\
  rm -rf /consul-template_${CONSUL_TEMPLATE_VERSION}_linux_amd64.zip && \
  apk add --no-cache curl

#install yq
RUN wget -O /usr/local/bin/yq "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"

#install apks
RUN apk add --update --no-cache openssl bash ca-certificates curl git jq openssh openjdk7-jre openjdk8 gradle vault \
    && wget -q https://get.helm.sh/helm-${HELM_VERSION}-linux-amd64.tar.gz -O - | tar -xzO linux-amd64/helm > /usr/local/bin/helm \
    && chmod +x /usr/local/bin/helm

# install kubectl
RUN gcloud components install app-engine-java kubectl

# copy down action functions
COPY ["src", "/src/"]

ENTRYPOINT ["/src/main.sh"]
